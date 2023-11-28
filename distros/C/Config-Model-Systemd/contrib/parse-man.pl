#!/usr/bin/perl
#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2008-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use strict;
use warnings;
use 5.22.0;
use utf8;
use open      qw(:std :encoding(UTF-8)); # undeclared streams in UTF-8

use lib 'lib';

use XML::Twig;
use Path::Tiny;
use Config::Model::Itself 2.012;
use Config::Model::Exception;
use Getopt::Long;
use Text::Wrap;
$Text::Wrap::columns = 120;

use experimental qw/postderef signatures/ ;
no warnings qw/experimental::postderef experimental::signatures/;

# default class name is Systemd::Section::ucfirst($item)
my @service_list = qw/service socket timer/;
my @list = qw/exec kill resource-control unit/;

my $unknown_param_msg = "Unexpected systemd parameter. Please contact cme author to update systemd model.";

# Override the default class name
# Please remove the old generated model if a class name is changed.
my %map = (
    'exec' => 'Common::Exec',
    'kill' => 'Common::Kill',
    'resource-control' => 'Common::ResourceControl',
);

my %opt;
GetOptions (\%opt, "from=s") or die("Error in command line arguments\n");

die "Missing '-from' option " unless $opt{from};

my ($systemd_version) = (`systemctl --version` =~ m/(\d+)/) ;
die "Cannot find systemd version" unless $systemd_version;

say "Parsing man pages of systemd $systemd_version";

# make sure that Systemd model is created from scratch
path('lib/Config/Model/models')->remove_tree;

my $systemd_path = path($opt{from});
die "Can't open directory ".$opt{from}."\n" unless $systemd_path->is_dir;

my $systemd_man_path = $systemd_path->child('man');

Config::Model::Exception::Trace(1);

sub parse_xml ($list, $map) {

    my %data = ( element => [] );
    my $config_class;
    my $file ;
    my $subsystem;

    my $desc = sub ($t, $elt) {
        my $txt = $elt->text;
        # there's black magic in XML::Twig that trash error message
        # contained in an error object.  So the error must be stringified
        # explicitly before being sent upward

        # but it's easier to store data and handle it later outside of XML::Twig realm
        $data{class}{$config_class} //= [];
        push $data{class}{$config_class}->@*, $txt;
    };

    my $manpage = sub ($t, $elt) {
        my $man = $elt->first_child('refentrytitle')->text;
        my $nb = $elt->first_child('manvolnum')->text;
        $elt->set_text( qq!L<$man($nb)>!);
    };

    my $condition_variable = sub  ($t, $elt) {
        my @var_list = $elt->children('term') ;
        my $listitem = $elt->first_child('listitem');
        my $pre_doc = $listitem->first_child_text('para');
        my $post_doc = $listitem->last_child_text('para');
        foreach my $var_elt (@var_list) {
            my $var_name = $var_elt->text;
            my ($var_doc_elt) = $listitem->get_xpath(qq!./para/varname[string()="$var_name"]!);
            # say "condition_variable $var_name found at ",$var_doc_elt->path;
            my ($name, $extra_info) = $var_name =~ /C<([\w-]+)=([^>]*)>/ ;
            die "Error: cannot extract parameter name from '$var_name'" unless defined $name;
            my $desc = join ("\n\n", $pre_doc, $var_doc_elt->parent->text, $post_doc);
            push $data{element}->@*, [$config_class => $name => $desc => $extra_info];
        }
    };

    my $variable = sub  ($t, $elt) {
        if ($systemd_version < 244 and $elt->first_child_text('term') =~ /^C<Condition/) {
            return $condition_variable->($t, $elt);
        }

        my @para_text = map {$_->text} $elt->first_child('listitem')->children(qr/para|programlisting/);
        my $desc = join("\n\n", @para_text);

        # detect deprecated param and what replaces them
        my @supersedes ;
        if ($desc =~ /settings? (?:are|is) deprecated. Use ([\w=\s,]+)./) {
            my $capture = $1;
            @supersedes = $capture =~ /(\w+)=/g;
        }

        # apply substitution only on variable names (FooBar=). The regexp must test
        # for capital letter and C<..> to avoid breaking URL parameters
        $desc =~ s/C<([A-Z]\w+)=>/C<$1>/g;

        # detect verbatim parts setup with programlisting tag
        $desc =~ s/^\+-\+/    /gm;

        # no need to have more than 2 \n to separate paragraphs
        $desc =~ s/\n{3,}/\n\n/g;

        foreach my $term_elt ($elt->children('term')) {
            my $var_elt = $term_elt->first_child('varname');
            next unless $var_elt;

            my $varname = $var_elt->text;
            my ($name, $extra_info) = $varname =~ /C<([\w-]+)=([^>]*)>/ ;

            next unless defined $name;
            say "-  $config_class: storing parameter $name";

            # we hope that deprecated items are listed in the same order with the new items
            push $data{element}->@*, [$config_class => $name => $desc => $extra_info => shift @supersedes ];
        }
    };

    my $set_config_class = sub ($name) {
        $config_class = 'Systemd::'.( $map->{$name} || 'Section::'.ucfirst($name));
        say "Parsing class $config_class from " . $file->basename(".xml") . ':';
    };

    my $parse_sub_title = sub {
        my $t = $_->text();
        if ($t =~ /\[(\w+)\] Section Options/ ) {
            $set_config_class->($1) ;
        }
    };
    my $turn_to_pod_c = sub {
        my $t = $_->text();
        # takes care of constant embedded in literal blocks
        return if $t =~ /^C</;
        $_->set_text($t =~ /[<>]/ ? "C<< $t >>" : "C<$t>");
    };

    my $twig = XML::Twig->new (
        twig_handlers => {
            'refsect1/title' => $parse_sub_title,
            'refsect1[string(title)=~ /Description/]/para' => $desc,
            'refsect2/title' => $parse_sub_title,
            # only found in systemd.unit (so far)
            'refsect2[string(title)=~ /Conditions/]/para' => $desc,
            'citerefentry' => $manpage,
            'literal' => $turn_to_pod_c,
            'option' => $turn_to_pod_c,
            'filename' => $turn_to_pod_c,
            'constant' => $turn_to_pod_c,
            ulink => sub {my $url = $_->{att}{url}; my $t = $_->text();$_->set_text("L<$t|$url>"); },
            # this also remove the indentation of programlisting
            # element,
            'para' => sub { $_->subs_text(qr/\n\s+/,"\n"); 1;},
            # hack: use my own tag which is removed later to create
            # code block. Can't directly indent text as the content of
            # para element is also indented (and cleanup above)
            'programlisting' => sub {my $t = $_->text(); $t =~ s/\n\s*/\n+-+/g; $_->set_text("\n\n+-+$t\n\n");},
            # varname handling is done before the variable handling
            # below
            'varname' => $turn_to_pod_c,
            'refsect1/variablelist/varlistentry' => $variable,
            'refsect2/variablelist/varlistentry' => $variable,
        }
    );

    foreach my $_subsystem ($list->@*) {
        $subsystem = $_subsystem;
        $file = $systemd_man_path->child("systemd.$subsystem.xml");
        $set_config_class->($subsystem);
        $twig->parsefile($file);
    }

    return \%data;
}

sub check_for_list ($element, $description) {
    my $is_list = 0;
    $is_list ||= $element =~ /^(Exec|Condition)/ ;
    # Requires list and its siblings parameters. See systemd.unit
    $is_list ||= $element =~ /^(Requires|Requisite|Wants|BindsTo|PartOf|Conflicts)$/ ;
    # see systemd.resource-control
    $is_list ||= $element =~ /^(DeviceAllow)$/ ;
    # see systemd.socket
    $is_list ||= $element =~ /^Listen/ ;
    $is_list ||= $description =~ /may be (specified|used) more than once/i ;

    return $is_list ? qw/type=list cargo/ : () ;
}

sub setup_element ($meta_root, $config_class, $element, $desc, $extra_info, $supersedes) {

    my @log;

    if (not $meta_root->fetch_element('class')->exists($config_class)) {
        say "Creating model class $config_class";
        $meta_root->load( steps => [
            qq!class:$config_class!,
            q!generated_by="parseman.pl from systemd doc"!,
            qq!accept:".*" type=leaf value_type=uniline warn="$unknown_param_msg"!
        ]);
    }
    my $step = "class:$config_class element:$element";

    my $obj = $meta_root->grab(step => $step, autoadd => 1);

    # trim description (which is not saved in this sub) to simplify
    # the regexp below
    $desc =~ s/[\s\n]+/ /g;

    my $value_type
        = $desc =~ /Takes a boolean argument or/ ? 'enum'
        : $desc =~ /Takes an? (boolean|integer)/ ? $1
        : $desc =~ /Takes time \(in seconds\)/   ? 'integer'
        : $desc =~ /allowed range/i              ? 'integer'
        : $desc =~ /Takes one of/                ? 'enum'
        : $desc =~ /Takes the same values as/    ? 'enum'
        : $extra_info =~ /\w\|\w/                ? 'enum'
        :                                          'uniline';

    if ($extra_info and $value_type ne 'enum') {
        push @log, "did not use extra info: $extra_info" unless
            scalar grep {$extra_info eq $_} qw/weight range/;
    }

    my ($min, $max);
    if ($desc =~ /Takes an integer between ([-\d]+) (?:\([\w\s]+\))? and ([-\d]+)/) {
        ($min, $max) = ($1, $2);
        push @log, "integer between $min and $max";
    }
    if ($desc =~ /allowed range is ([-\d]+) to ([-\d]+)/) {
        ($min, $max) = ($1, $2);
        push @log, "integer range is $min to $max";
    }

    my @load ;
    my @load_extra;

    if ($value_type eq 'integer' and $desc =~ /usual suffixes K/) {
        $value_type = 'uniline';
        push @load_extra , q!match="^\d+(?i)[KMG]$"!;
    }

    push @load, check_for_list($element, $desc);

    push @load, 'type=leaf', "value_type=$value_type";

    push @load_extra, 'write_as=no,yes' if $value_type eq 'boolean';


    if ($value_type eq 'enum') {
        my @choices;

        # handle "Takes the same settings as ..." (seen only for enum)
        if ($desc =~ /takes the same values as the (?:setting )?C<(\w+)>/i) {
            my $other = $1;
            my $other_obj = $obj->grab("- element:$other");
            @choices = $other_obj->fetch_element('choice')->fetch;
            say "Copy enum choices from $other to ", $obj->location;
        }
        elsif ($extra_info =~ /\w\|\w/) {
            @choices = split /\|/, $extra_info ;
        }
        elsif ($desc =~ /Takes a boolean argument or /) {
            my ($choices) = ($desc =~ /Takes a boolean argument or (?:the )?(?:special values|architecture identifiers\s*)?([^.]+?)\./);
            @choices = ('no','yes');
            push @choices, extract_choices($choices);
            push @load, qw/replace:false=no replace:true=yes replace:0=no replace:1=yes/;
        }

        if ($desc =~ /Takes one of/) {
            my ($choices) = ($desc =~ /Takes one of ([^.]+?)(?:\.|to test)/);
            @choices = extract_choices($choices);
        }

        die "Error in $config_class: cannot find the values of $element enum type from «$desc»\n"
            unless @choices;
        push @log, "enum choices are '".join("', '", sort @choices)."'";
        push @load_extra, 'choice='.join(',',sort @choices);
    }


    push @load_extra, "min=$min" if defined $min;
    push @load_extra, "max=$max" if defined $max;

    if ($value_type eq 'integer' and $desc =~ /defaults? (?:value )?(?:to|is) (\d+)/i) {
        push @load_extra, "upstream_default=$1" ;
    }

    if ($supersedes) {
        push @load_extra, "status=deprecated";

        push @log, "deprecated in favor of $supersedes";
        # put migration in place for the other element
        my $new = $meta_root->grab(
            step => "class:$config_class element:$supersedes",
            autoadd => 1
        );
        $new->load(steps => qq!migrate_from variables:old="- $element" formula="\$old"!);
    }
    $obj->load(step => [@load, @load_extra]);

    say "class $config_class element $element:\n\t".join("\n\t", @log) if @log;
    return $obj;
}

sub extract_choices($choices) {
    my @choices = ($choices =~ m!C<([/\w\-+]+)>!g );
    if ($choices =~ m{possibly prefixed with (?:a )?C<([!\w]+)>} ) {
        push @choices, map { "$1$_"} @choices;
    }
    return @choices;
}

sub move_deprecated_element ($meta_root, $from, $to) {
    say "Handling move of service/$from to unit/$to...";
    # create deprecated moved element in Service for backward compat
    my $warn = $from eq $to ? "$from is now part of Unit."
        : "service/$from is now Unit/$to.";
    $meta_root->load( steps => [
        'class:Systemd::Section::Service',
        qq!element:$from type=leaf value_type=uniline status=deprecated!,
        qq!warn="$warn"!
    ]);

    # Due to the fact that Unit are used in Service, Timer, Socket but
    # only Service needs backward compat, a special Unit class is created
    # for each Service.

    # Saving $to definition stored from data extracted from Systemd
    # doc
    my $from_element_dump = $meta_root->grab(
        "class:Systemd::Section::Unit element:$to"
    )->dump_tree;

    # remove $from element from common Unit class
    $meta_root->load("class:Systemd::Section::Unit element:.rm($to)");

    foreach my $service (@service_list) {
        my $unit_class = "Systemd::Section::". ucfirst($service).'Unit';

        # inject $from element in Special Unit class
        $meta_root
            ->grab("class:$unit_class element:$to")
            ->load($from_element_dump);

        # make sure that special Unit class provide all elements from
        # common Unit class
        $meta_root->load(steps => [
            "class:$unit_class include=Systemd::Section::Unit",
            'accept:".*" type=leaf value_type=uniline warn="$unknown_param_msg"'
        ]);
    }

    # inject the migration instruction that retrieve $from element setting
    # from Service class (where it's deprecated) and copy them to the new
    # $from element in Unit class in a service file (hence this migration
    # instruction is done only in ServiceUnit class)
    $meta_root->load( steps => [
        qq!class:Systemd::Section::ServiceUnit element:$to!,
        qq!migrate_from variables:service="- - Service $from" formula="\$service"!
    ]);
}

my $data = parse_xml([@list, @service_list], \%map) ;

# Itself constructor returns an object to read or write the data
# structure containing the model to be edited
my $rw_obj = Config::Model::Itself -> new () ;

# now load the existing model to be edited
$rw_obj -> read_all() ;
my $meta_root = $rw_obj->meta_root;

# remove old generated classes
foreach my $config_class ($meta_root->fetch_element('class')->fetch_all_indexes) {
    my $gen = $meta_root->grab_value(
        step => qq!class:$config_class generated_by!,
        mode => 'loose',
    );
    next unless $gen and $gen =~ /parse-man/;
    $meta_root->load(qq!class:-$config_class!);
}


say "Creating systemd model...";

foreach my $config_class (keys $data->{class}->%*) {
    say "Creating model class $config_class";
    my $desc_ref = $data->{class}{$config_class};

    # cleanup leading white space and add formatting
    my $desc_text = join("\n\n", map { s/\n[\t ]+/\n/gr =~ s/C<([A-Z]\w+)=>/C<$1>/gr;} $desc_ref->@*);

    $desc_text.="\nThis configuration class was generated from systemd documentation.\n"
        ."by L<parse-man.pl|https://github.com/dod38fr/config-model-systemd/contrib/parse-man.pl>\n";

    # detect verbatim parts setup with programlisting tag
    $desc_text =~ s/^\+-\+/    /gm;

    my $steps = "class:$config_class class_description";
    $meta_root->grab(step => $steps, autoadd => 1)->store($desc_text);

    $meta_root->load( steps => [
        qq!class:$config_class generated_by="parse-man.pl from systemd $systemd_version doc"!,
        qq!copyright:0="2010-2016 Lennart Poettering and others"!,
        qq!copyright:1="2016 Dominique Dumont"!,
        qq!license="LGPLv2.1+"!,
        qq!accept:".*" type=leaf value_type=uniline warn="$unknown_param_msg"!,
    ]);
}

foreach my $cdata ($data->{element}->@*) {
    my ($config_class, $element, $desc, $extra_info, $supersedes) = $cdata->@*;

    my $obj = setup_element ($meta_root, $config_class, $element, $desc, $extra_info, $supersedes);

    $desc =~ s/ +$//gm;
    $obj->fetch_element("description")->store(wrap('','',$desc));
}

say "Tweaking systemd model...";

$meta_root->load(
    'class:Systemd::Section::Service generated_by="parse-man.pl from systemd doc"
     include:=Systemd::Common::ResourceControl,Systemd::Common::Exec,Systemd::Common::Kill'
);

# doc for IOSchedulingClass is too complicated to parse,
$meta_root->load(
    '! class:Systemd::Common::Exec
       element:IOSchedulingClass value_type=enum
                                 choice=0,1,2,3,none,realtime,best-effort,idle'
);

# these warping instructions are used for most services. Services are
# disabled when a service file is a symlink to /dev/null
my $common_warp = qq!warp follow:disable="- disable" rules:\$disable level=hidden - - !;

foreach my $service (@service_list) {
    my $name = ucfirst($service);
    my $sub_class = 'Systemd::'.( $map{$name} || 'Section::'.ucfirst($name));

    my $unit_class = $name.'Unit';
    # make sure that the unit class exists (and fill it later when needed)
    $meta_root->load("class:Systemd::Section::$unit_class");

    foreach my $class_name ("Systemd::$name", "Systemd::StandAlone::$name") {
        # create class that hold the service created by parsing man page
        $meta_root->load(
            qq!
            class:$class_name
              generated_by="parse-man.pl from systemd doc"
              accept:".*"
                type=leaf
                value_type=uniline
                warn="$unknown_param_msg" - -!
        );
    }

    $meta_root->load(
        qq!
        class:Systemd::$name
          element:disable
            type=leaf
            value_type=boolean
            upstream_default=0
            summary="disable configuration file supplied by the vendor"
            description="When true, cme will disable a configuration file supplied by the vendor by placing place a symlink to /dev/null with the same filename as the vendor configuration file. See L<systemd-system.conf> for details." -
          element:$name
            type=warped_node
            config_class_name=$sub_class
            $common_warp -
          element:Unit
            type=warped_node
            config_class_name=Systemd::Section::$unit_class
            $common_warp -
          element:Install
            type=warped_node
            config_class_name=Systemd::Section::Install
            $common_warp -
          rw_config
            backend=Systemd::Unit
            file=&index.$service
            auto_delete=1
            auto_create=1 !
    );

    $meta_root->load(
        qq!
        class:Systemd::StandAlone::$name
          element:$name
            type=node
            config_class_name=$sub_class -
          element:Unit
            type=node
            config_class_name=Systemd::Section::$unit_class -
          element:Install
            type=node
            config_class_name=Systemd::Section::Install -
          rw_config
            backend=Systemd::Unit
            auto_delete=1
            auto_create=1 !
    );

    # Link the class above to base Systemd class
    $meta_root->load(
        qq!
        class:Systemd
          generated_by="parse-man.pl from systemd doc"
          element:$service
            type=hash
            index_type=string
            cargo
              type=node
              config_class_name=Systemd::$name - -
          rw_config
            backend=Systemd
            auto_create=1
            auto_delete=1 -
          !
    );
}

my @moved = qw/FailureAction SuccessAction StartLimitBurst StartLimitInterval RebootArgument/;
my %move_target = qw/StartLimitInterval StartLimitIntervalSec/;

# check also src/core/load-fragment-gperf.gperf.m4 is systemd source
# for "compatibility" elements
foreach my $from (@moved) {
    my $to = $move_target{$from} || $from;
    move_deprecated_element($meta_root, $from, $to);
}

# StartLimitInterval is also deprecated in Unit
say "Handling move of StartLimitInterval to StartLimitIntervalSec in unit";
$meta_root->load( steps => [
    'class:Systemd::Section::Unit',
    qq!element:StartLimitInterval type=leaf value_type=uniline status=deprecated!,
    qq!warn="StartLimitInterval is now StartLimitIntervalSec."!
]);

# handle migration from both service and unit
$meta_root->load( steps => [
    qq!class:Systemd::Section::ServiceUnit element:StartLimitIntervalSec!,
    qq!migrate_from variables:unit="- StartLimitInterval"!,
    # $service variable is defined in move_deprecated element function
    q!use_eval=1 formula="$unit || $service"!
]);

# renamed element in Unit
say "Handling move of OnFailureIsolate to OnFailureJobMode in unit";
$meta_root->load( steps => [
    'class:Systemd::Section::Unit',
    q!element:OnFailureIsolate type=leaf value_type=uniline status=deprecated!,
    q!warn="OnFailureIsolate is now OnFailureJobMode." -!,
    q!element:OnFailureJobMode!,
    q!migrate_from variables:unit="- OnFailureIsolate"!,
    q!formula="$unit"!
]);


say "Saving systemd model...";
$rw_obj->write_all;

say "Done.";
