#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2008-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package ParseMan;

# This module is used by parse_man.pl to generate Ssh models
# and should not be shippped to CPAN

use strict;
use warnings;

use 5.22.0;
use utf8;

use lib qw(lib contrib/lib);
use experimental qw/postderef signatures/ ;
use XML::Twig;
use List::MoreUtils qw/any/;

use Exporter 'import';

our @EXPORT = qw(parse_html_man_page create_load_data create_class_boilerplate);

sub parse_html_man_page ($html_man_page) {

    my %data = (
        element_list => [],
        element_data => {},
    );
    my $config_class;
    my $parameter ;

    my $manpage = sub ($t, $elt) {
        my $man = $elt->first_child('refentrytitle')->text;
        my $nb = $elt->first_child('manvolnum')->text;
        $elt->set_text( qq!L<$man($nb)>!);
    };

    my $turn_to_pod_c = sub { my $t = $_->text(); $_->set_text("C<$t>");};

    my $ssh_param = sub {
        # remove B<> that was added by a twig_handler
        ($parameter) = ($_->text() =~ /B<(\w+)>/);
        push $data{element_list}->@*, $parameter;
        $data{element_data}{$parameter} = [];
    };

    my $ssh_data = sub {
        my $text = $_->text();
        $text =~ s/([\w-]+)\((\d+)\)/L<$1($2)>/g;
        push $data{element_data}{$parameter}->@*, $text if $parameter;
    };

    my $twig = XML::Twig->new (
        twig_handlers => {
            'html/body/p[@style="margin-top: 1em"]/[string(b)=~ /^[A-Z]+\w/]'
                => $ssh_param,
            # try to stop at the section after the parameter list
            'html/body/p[@style="margin-top: 1em"]/[string(b)=~ /^[A-Z\s]+$/]'
                => sub { $parameter = '';},
            'html/body/p' => $ssh_data,
            'b' => sub { my $t = $_->text; $_->set_text("B<$t>")},
            'i' => sub { my $t = $_->text; $_->set_text("I<$t>")},
        }
    );

    $twig->parse_html($html_man_page);
    return \%data;
}

sub setup_choice {
    my (@choices, %choice_hash) ;

    return (
        sub {
            foreach my $v (@_) {
                next if $choice_hash{$v};
                push @choices, $v;
                $choice_hash{$v} = 1;
            }
        },
        sub { return @choices;}
    );
}

my $ssh_host = 'type=hash index_type=string cargo type=node '
    .'config_class_name=Ssh::HostElement';
my $ssh_forward = 'type=list cargo type=node config_class_name="Ssh::PortForward"';
my $uniline = 'type=leaf value_type=uniline';
my $uniline_list = "type=list cargo $uniline";
my %override = (
    all => {
        IPQoS => 'type=leaf value_type=uniline upstream_default="af21 cs1"',
    },
    ssh => {
        # description is too complex to parse
        EscapeChar => $uniline,
        ControlPersist => $uniline,
        Host => $ssh_host,
        IdentityFile => $uniline_list,
        LocalForward => $ssh_forward,
        Match => $ssh_host,
        StrictHostKeyChecking => 'type=leaf value_type=enum '
            . 'choice=yes,accept-new,no,off,ask upstream_default=ask',
        KbdInteractiveDevices => $uniline_list,
        PreferredAuthentications => $uniline_list,
        RemoteForward => $ssh_forward,
    },
    sshd => {
        AuthenticationMethods => $uniline,
        AuthorizedKeysFile => $uniline_list,
        AuthorizedPrincipalsFile => 'type=leaf value_type=uniline upstream_default="none"',
        ChrootDirectory => 'type=leaf value_type=uniline upstream_default="none"',
        ForceCommand => 'type=leaf value_type=uniline upstream_default="none"',
        Subsystem => 'type=hash index_type=string '
            . 'cargo type=leaf value_type=uniline mandatory=1 - - ',
        MaxStartups => 'type=leaf value_type=uniline upstream_default=10',
        VersionAddendum => $uniline,
    }
);

sub create_load_data ($ssh_system, $name, @desc) {
    my $bold_name = shift @desc; # drop '<b>Keyword</b>'
    my $desc = join('', @desc);

    return $override{$ssh_system}{$name} if $override{$ssh_system}{$name};
    return $override{'all'}{$name} if $override{'all'}{$name};

    # trim description (which is not saved in this sub) to simplify
    # the regexp below
    $desc =~ s/[\s\n]+/ /g;
    my (%choice_hash, $value_type);
    my @load_extra;
    my ($set_choice, $get_choices) = setup_choice();

    # handle "The argument must be B<yes>, B<no> (the default) or B<ask>."
    if ($desc =~ /(?:argument|option)s? (?:to this keyword )?(?:are|\w+ be)([^.]+)\./i) {
        my $str = $1;
        $set_choice->( $str =~ /B<([\w-]+)>/g );
    }

    if (my @values = ($desc =~ /(?:(?:if|when|with) (?:(?:$bold_name|th(?:e|is) option) (?:is )?)?set to|A value of|setting this to|The default(?: is|,)|Accepted values are) B<(\w+)>/gi)) {
        $set_choice->(@values);
    }

    if (my @values = ($desc =~ /The possible values are:([^.]+)\./gi)) {
        my $str = $1;
        $set_choice->( $str =~ /([A-Z\d]+)/g );
    }

    my @choices = $get_choices->();
    if (@choices == 1 and $choices[0] eq 'no') {
        # assume the other choice is 'yes'
        push @choices, 'yes';
    }
    if (@choices == 1 and $choices[0] eq 'yes') {
        push @choices, 'no';
    }

    if ($desc =~ /(Specif\w+|Sets?) (a|the) (maximum )?(number|timeout)/) {
        $value_type = 'integer';
        if ($desc =~ /The default(?: value)?(?: is|,) (\d+)/) {
            push @load_extra, "upstream_default=$1";
        }
    }
    elsif (@choices == 1) {
        die "Parser error: Cannot create an enum with only once choice ($name): @choices\n",
            "Description is:\n $desc\n";
    }
    elsif (@choices == 2 and any { /^yes|no$/ } @choices) {
        $value_type = 'boolean';
        push @load_extra, 'write_as=no,yes';
    }
    elsif (@choices) {
        $value_type = 'enum';
        push @load_extra, 'choice='.join(',',@choices);
    }

    if ($desc =~ m!The default(?: is|,) [BI]<([\w/:]+)>! or
            $desc =~ /The default(?: is|,) ([A-Z]{3,}\d?)\b/ or
            $desc =~ /B<([\w]+)> \(the default\)/) {
        push @load_extra, "upstream_default=$1";
    }

    $value_type //= 'uniline';

    my @load ;
    if ($desc =~ /multiple (\w+ ){1,2}may be (specified|separated)|keyword can be followed by a list of/i) {
        @load = ('type=list', 'cargo');
    }
    # TODO:
    # CanonicalDomains depends on CanonicalizeHostname -> order problem, use move on model

    push @load, 'type=leaf', "value_type=$value_type";

    return join(' ',@load, @load_extra);
}

my ($ssh_version) = (`ssh -V 2>&1` =~ /OpenSSH_([\w\.]+)/);

sub create_class_boilerplate ($meta_root, $ssh_system,  $config_class) {
    my $desc_text="This configuration class was generated from $ssh_system documentation.\n"
        ."by L<parse-man.pl|https://github.com/dod38fr/config-model-openssh/contrib/parse-man.pl>\n";

    my $steps = "class:$config_class class_description";
    $meta_root->grab(step => $steps, autoadd => 1)->store($desc_text);

    $meta_root->load( steps => [
        qq!class:$config_class generated_by="parse-man.pl from $ssh_system  $ssh_version doc"!,
        qq!license=LGPL2!,
        qq!accept:".*" type=leaf value_type=uniline!,
        qq!summary="boilerplate parameter that may hide a typo"!,
        qq!warn="Unknown parameter. Please make sure there\'s no typo and contact the author"!,
    ]);
}

1;
