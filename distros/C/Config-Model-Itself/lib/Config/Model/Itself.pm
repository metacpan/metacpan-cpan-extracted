#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Itself 2.021;

use Mouse ;
use Config::Model 2.134;
use 5.014; # for the /r modifier

use IO::File ;
use Log::Log4perl 1.11;
use Carp ;
use Data::Dumper ;
use Scalar::Util qw/weaken/;
use File::Find ;
use File::Path ;
use File::Basename ;
use Data::Compare ;
use Path::Tiny 0.062;
use Mouse::Util::TypeConstraints;

my $logger = Log::Log4perl::get_logger("Backend::Itself");

subtype 'ModelPathTiny' => as 'Object' => where { $_->isa('Path::Tiny') };

coerce 'ModelPathTiny'  => from 'Str'  => via {path($_)} ;

# find all .pl file in model_dir and load them...

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_;

    my $legacy = delete $args{model_object};
    if ($legacy) {
        $args{config_model} = $legacy->instance->config_model;
        $args{meta_instance} = $legacy->instance;
        $args{meta_root} = $legacy;
    }
    return $class->$orig( %args );
};

has 'config_model' => (
    is => 'ro',
    isa => 'Config::Model',
    lazy_build => 1,
) ;


sub _build_config_model {
    my $self = shift;
    # don't trigger builders below
    if ($self->{meta_root}) {
        return $self->meta_root->instance->config_model;
    }
    elsif ($self->{meta_instance}) {
        return $self->meta_instance->config_model;
    }
    else {
        return Config::Model -> new ( ) ;
    }
}

has check        => (is =>'ro', isa => 'Bool', default => 1) ;

has 'meta_instance' => (
    is =>'ro',
    isa =>'Config::Model::Instance',
    lazy_build => 1,
) ;

sub _build_meta_instance {
    my $self = shift;

    # don't trigger builders below
    if ($self->{meta_root}) {
        return $self->meta_root->instance;
    }
    else {
        # load Config::Model model
        return $self->config_model->instance (
            root_class_name => 'Itself::Model' ,
            instance_name   => 'meta_model' ,
            check => $self->check,
        );
    }

}

has meta_root => (
    is =>'ro',
    isa =>'Config::Model::Node',
    lazy_build => 1,
) ;

sub _build_meta_root {
    my $self = shift;

    return $self->meta_instance -> config_root ;
}

has cm_lib_dir   => (
    is =>'ro',
    isa => 'ModelPathTiny',
    lazy_build => 1,
    coerce => 1
) ;

sub _build_cm_lib_dir {
    my $self = shift;
    my $p =  path('lib/Config/Model');
    if (! $p->is_dir) {
        $p->mkpath(0, oct(755)) || die "can't create $p:$!";
    }
    return $p;
}

has force_write  => (is =>'ro', isa => 'Bool', default => 0) ;
has root_model   => (is =>'ro', isa => 'str');

has modified_classes => (
    is =>'rw',
    isa =>'HashRef[Bool]',
    traits => ['Hash'],
    default => sub { {} } ,
    handles => {
        clear_classes => 'clear',
        set_class => 'set',
        class_was_changed => 'get' ,
        class_known => 'exists',
    }
) ;

has model_dir => (
    is => 'ro',
    isa => 'ModelPathTiny',
    lazy_build => 1,
);

sub _build_model_dir {
    my $self = shift;
    my $md = $self->cm_lib_dir->child('models');
    $md->mkpath;
    return $md;
}

sub BUILD {
    my $self = shift;

    # avoid memory cycle
    weaken($self);

    my $cb = sub {
        my %args = @_ ;
        my $p = $args{path} || '' ;
        return unless $p =~ /^class/ ;
        return unless $args{index}; # may be empty when class order is changed
        return if $self->class_was_changed($args{index}) ;
        $logger->info("class $args{index} was modified");

        $self->add_modified_class($args{index}) ;
    } ;
    $self->meta_instance -> on_change_cb($cb) ;

}

sub add_tracked_class {
    my $self = shift;
    $self->set_class(shift,0) ;
}

sub add_modified_class {
    my $self = shift;
    $self->set_class(shift,1) ;
}

sub class_needs_write {
    my $self = shift;
    my $name =  shift;
    return ($self->force_write or not $self->class_known($name) or $self->class_was_changed($name)) ;
}

sub read_app_files {
    my $self = shift;
    my $force_load = shift || 0;
    my $read_from =  shift ;
    my $application = shift ;

    my $app_dir = $read_from || $self->model_dir->parent;
    my %apps;
    my %map;
    $logger->info("reading app files from ".$app_dir);
    foreach my $dir ( $app_dir->children(qr/\.d$/) ) {

        $logger->info("reading app dir ".$dir);
        foreach my $file ( $dir->children() ) {
            next if $file =~ m!/README!;
            next if $file =~ /(~|\.bak|\.orig)$/;
            next if $application and $file->basename ne $application;

            # bad categories are filtered by the model
            my %data = ( category => $dir->basename('.d') );
            $logger->info("reading app file ".$file);

            foreach ($file->lines({ chomp => 1})) {
                s/^\s+//;
                s/\s+$//;
                s/#.*//;
                my ( $k, $v ) = split /\s*=\s*/;
                next unless $v;
                $data{$k} = $v;
            }

            my $appli = $file->basename;
            $apps{$appli} = $data{model} ;
            $map{$appli} = $file;

            $self->meta_root->load_data(
                data => { application => { $appli => \%data } },
                check => $force_load ? 'no' : 'yes'
            ) ;
        }
    }

    $self->{app_map} = \%map;

    return \%apps;
}

sub read_all {
    my $self = shift ;
    my %args = @_ ;

    my $force_load = delete $args{force_load} || 0 ;
    my $read_from ;
    my $model_dir ;
    if ($args{read_from}) {
        $read_from = path (delete $args{read_from});
        die "Cannot read from unknown dir ".$read_from unless $read_from->is_dir;
        $model_dir = $read_from->child('models');
        die "Cannot read from unknown dir ".$model_dir unless $model_dir->is_dir;
    }

    my $apps = $self-> read_app_files($force_load, $read_from, delete $args{application});

    my $root_model_arg = delete $args{root_model} || '';
    my $model = $apps->{$root_model_arg} || $root_model_arg ;
    my $legacy = delete $args{legacy} ;

    croak "read_all: unexpected parameters ",join(' ', keys %args) if %args ;

    my $dir = $self->model_dir;
    $dir->mkpath ;

    my $root_model_file = $model ;
    $root_model_file =~ s!::!/!g ;
    my $read_dir = $model_dir || $dir;
    $logger->info("searching model files in ".$read_dir);

    my @files ;
    my $wanted = sub {
        push @files, $_ if ( $_->is_file and /\.pl$/
                                 and m!$read_dir/$root_model_file\b!
                                 and not m!\.d/!
                           ) ;
    } ;
    $read_dir->visit($wanted, { recurse => 1} ) ;

    my %read_models ;
    my %class_file_map ;

    my @all_models = $self->load_model_files(
        $read_dir, \@files, $legacy, \%class_file_map, \%read_models
    );

    $self->{root_model} = $model || (sort @all_models)[0];

    # Create all classes listed in %read_models to avoid problems with
    # include statement while calling load_data
    my $root_obj = $self->meta_root ;
    my $class_element = $root_obj->fetch_element('class') ;
    foreach my $class (sort keys %read_models) {
        $class_element->fetch_with_id($class);
    }

    #require Tk::ObjScanner; Tk::ObjScanner::scan_object(\%read_models) ;

    $logger->info("loading all extracted data in Config::Model::Itself");
    # load with a array ref to avoid warnings about missing order
    $root_obj->load_data(
        data => {class => [ %read_models ] },
        check => $force_load ? 'no' : 'yes'
    ) ;

    $self->read_model_annotations( $dir, $root_obj, \@files);

    return $self->{map} = \%class_file_map ;
}

sub load_model_files {
    my ($self, $read_dir, $files, $legacy, $class_file_map, $read_models) = @_;

    my @all_models;
    for my $file (@$files) {
        $logger->info("loading config file $file");

        # now apply some translation to read model
        # - translate legacy warp parameters
        # - expand elements name
        my @legacy = $legacy ? ( legacy => $legacy ) : () ;
        my $tmp_model = Config::Model -> new( skip_include => 1, @legacy ) ;

        # @models order is important to write configuration class back in the same
        # order as the declaration
        my @models = $tmp_model -> load ( 'Tmp' , $file->absolute ) ;
        push @all_models, @models;

        my $rel_file = $file ;
        $rel_file =~ s/^$read_dir\/?//;
        die "wrong reg_exp" if $file eq $rel_file ;
        $class_file_map->{$rel_file} = \@models ;

        # - move experience, description and level status into parameter info.
        foreach my $model_name (@models) {
            $read_models->{$model_name} = $self->normalize_model($model_name, $tmp_model);
        }
    }
    return @all_models;
}

sub normalize_model {
    my ($self, $model_name, $tmp_model) = @_;

    # no need to dclone model as Config::Model object is temporary
    my $raw_model =  $tmp_model -> get_raw_model( $model_name ) ;
    my $new_model =  $tmp_model -> get_model_clone( $model_name ) ;

    $self->upgrade_model($model_name, $new_model);

    # track read class to identify later classes added by user
    $self->add_tracked_class($model_name);

    # some modifications may be done to cope with older model styles. If a modif
    # was done, mark the class as changed so it will be saved later
    $self->add_modified_class($model_name) unless Compare($raw_model, $new_model) ;

    foreach my $item (qw/description summary level experience status/) {
        foreach my $elt_name (keys %{$new_model->{element}}) {
            my $moved_data = delete $new_model->{$item}{$elt_name}  ;
            next unless defined $moved_data ;
            $new_model->{element}{$elt_name}{$item} = $moved_data ;
        }
        delete $new_model->{$item} ;
    }

    # Since accept specs and elements are stored in a ordered hash,
    # load_data expects a array ref instead of a hash ref.
    # Build this array ref taking the order into
    # account
    foreach my $what (qw/element accept/) {
        my $list  = delete $new_model -> {$what.'_list'} ;
        my $h     = delete $new_model -> {$what} ;
        $new_model -> {$what} = [] ;
        foreach my $name (@$list) {
            push @{$new_model->{$what}}, $name, $h->{$name}
        }
        ;
    }

    # remove hash key with undefined values
    foreach my $name (keys %$new_model) {
        if (not defined $new_model->{$name} or $new_model->{$name} eq '') {
            delete $new_model->{$name};
        }
    }
    return $new_model ;
}

sub read_model_annotations {
    my ($self, $dir, $root_obj, $files) = @_;

    # load annotations and comment header
    for my $file (@$files) {
        $logger->info("loading annotations from file $file");
        my $fh = IO::File->new($file) || die "Can't open $file: $!" ;
        my @lines = $fh->getlines ;
        $fh->close;
        $root_obj->load_pod_annotation(join('',@lines)) ;

        my @headers ;
        foreach my $l (@lines) {
            if ($l =~ /^\s*#/ or $l =~ /^\s*$/){
                push @headers, $l
            }
            else {
                last;
            }
        }
        my $rel_file = $file ;
        $rel_file =~ s/^$dir\/?//;
        $self->{header}{$rel_file} = \@headers;
    }
}

# can be removed end of 2019 (after buster is released)
sub upgrade_model {
    my ($self, $config_class_name, $model) = @_ ;

    my $multi_backend = 0;
    foreach my $config (qw/read_config write_config/) {
        my $ref = $model->{$config};
        if ($ref and ref($ref) eq 'ARRAY') {
            if (@$ref == 1) {
                $model->{$config} = $ref->[0];
            }
            elsif (@$ref > 1){
                $logger->warn("$config_class_name $config: cannot migrate multiple backends to rw_config");
                $multi_backend++;
            }
        }
    }

    if ($model->{read_config} and not $multi_backend) {
        say ("Model $config_class_name: moving read_config specification to rw_config");
        $model->{rw_config} = delete $model->{read_config};
    }

    if ($model->{write_config} and not $multi_backend) {
        say "Model $config_class_name: merging write_config specification in rw_config";
        if (not $multi_backend) {
            foreach my $spec ( keys %{$model->{write_config}} ) {
                $model->{rw_config}{$spec} = $model->{write_config}{$spec}
            } ;
            delete $model->{write_config};
        }
    }
}

# internal
sub get_perl_data_model{
    my $self = shift ;
    my %args = @_ ;
    my $root_obj = $self->{meta_root};
    my $class_name = $args{class_name}
      || croak __PACKAGE__," read: undefined class name";

    my $class_element = $root_obj->fetch_element('class') ;

    # skip if class was deleted during edition
    return unless $class_element->defined($class_name) ;

    my $class_elt = $class_element -> fetch_with_id($class_name) ;

    my $model = $class_elt->dump_as_data ;

    # now apply some translation to read model
    # - Do NOT translate legacy warp parameters
    # - Do not compact elements name

    # don't forget to add name
    $model->{name} = $class_name if keys %$model;

    return $model ;
}

sub write_app_files {
    my $self = shift;

    my $app_dir = $self->cm_lib_dir;
    my $app_obj = $self->meta_root->fetch_element('application');

    foreach my $app_name ( $app_obj->fetch_all_indexes ) {
        $logger->debug("writing $app_name...");
        my $app = $app_obj->fetch_with_id($app_name);
        my $cat_dir_name = $app->fetch_element_value( name =>'category' ).'.d';
        $app_dir->child($cat_dir_name)->mkpath();
        my $app_file = $app_dir->child($cat_dir_name)->child($app->index_value) ;

        my @lines ;
        foreach my $name ( $app->children ) {
            next if $name eq 'category'; # saved as directory above

            my $v = $app->fetch_element_value($name); # need to spit out 0 ?
            next unless defined $v;
            push @lines, "$name = $v\n";

        }
        $logger->info("writing file ".$app_file);
        $app_file->spew(@lines);
        delete $self->{app_map}{$app_name};
    }

    # prune removed app files
    foreach my $old_file ( values %{$self->{app_map}}) {
        $logger->debug("Removing $old_file.");
        $old_file->remove;
    }
}

sub write_all {
    my $self = shift ;
    my %args = @_ ;
    my $root_obj = $self->meta_root ;
    my $dir = $self->model_dir ;

    croak "write_all: unexpected parameters ",join(' ', keys %args) if %args ;

    $self->write_app_files;

    my $map = $self->{map} ;

    $dir->mkpath;

    # get list of all classes loaded by the editor
    my %loaded_classes
      = map { ($_ => 1); }
        $root_obj->fetch_element('class')->fetch_all_indexes ;

    # remove classes that are listed in map
    foreach my $file (keys %$map) {
        foreach my $class_name (@{$map->{$file}}) {
            delete $loaded_classes{$class_name} ;
        }
    }

    # add remaining classes in map
    my %new_map;
    foreach my $class (keys %loaded_classes) {
        my $f = $class =~ s!::!/!gr;
        $new_map{"$f.pl"} = [ $class ] ;
    }

    my %map_to_write = (%$map,%new_map) ;

    foreach my $file (keys %map_to_write) {
        my ($data,$notes) = $self->check_model_to_write($file, \%map_to_write, \%loaded_classes);
        next unless @$data ; # don't write empty model
        write_model_file ($dir->child($file), $self->{header}{$file}, $notes, $data);
    }

    $self->meta_instance->clear_changes ;
}

sub check_model_to_write {
    my ($self, $file, $map_to_write, $loaded_classes) = @_;
    $logger->info("checking model file $file");

    my @data ;
    my @notes ;
    my $file_needs_write = 0;

    # check if any a class of a file was modified
    foreach my $class_name (@{$map_to_write->{$file}}) {
        $file_needs_write++ if $self->class_needs_write($class_name);
        $logger->info("file $file class $class_name needs write ",$file_needs_write);
    }

    if ($file_needs_write) {
        foreach my $class_name (@{$map_to_write->{$file}}) {
            $logger->info("writing class $class_name");
            my $model = $self-> get_perl_data_model(class_name => $class_name) ;
            push @data, $model if defined $model and keys %$model;

            my $node = $self->{meta_root}->grab("class:".$class_name) ;
            push @notes, $node->dump_annotations_as_pod ;
            # remove class name from above list
            delete $loaded_classes->{$class_name} ;
        }
    }

    return (\@data, \@notes);
}

sub write_model_plugin {
    my $self = shift ;
    my %args = @_ ;
    my $plugin_dir = delete $args{plugin_dir}
      || croak __PACKAGE__," write_model_plugin: undefined plugin_dir";
    my $plugin_name = delete $args{plugin_name}
        || croak __PACKAGE__," write_model_plugin: undefined plugin_name";
    croak "write_model_plugin: unexpected parameters ",join(' ', keys %args) if %args ;

    my $model = $self->meta_root->dump_as_data(mode => 'custom') ;
    # print (Dumper( $model)) ;

    my @raw_data = @{$model->{class} || []} ;
    while (@raw_data) {
        my ( $class , $data ) = splice @raw_data,0,2 ;
        $data ->{name} = $class ;

        # does not distinguish between notes from underlying model or snipper notes ...
        my @notes = $self->meta_root->grab("class:$class")->dump_annotations_as_pod ;
        my $plugin_file = $class.'.pl';
        $plugin_file =~ s!::!/!g;
        write_model_file ("$plugin_dir/$plugin_name/$plugin_file", [], \@notes, [ $data ]);
    }

    $self->meta_instance->clear_changes ;
}

sub read_model_plugin {
    my $self = shift ;
    my %args = @_ ;
    my $plugin_dir = delete $args{plugin_dir}
      || croak __PACKAGE__," write_model_plugin: undefined plugin_dir";
    my $plugin_name = delete $args{plugin_name}
      || croak __PACKAGE__," read_model_plugin: undefined plugin_name";

    croak "read_model_plugin: unexpected parameters ",join(' ', keys %args) if %args ;

    my @files ;
    my $wanted = sub {
        my $n = $File::Find::name ;
        push @files, $n if (-f $_ and not /~$/
                            and $n !~ /CVS/
                            and $n !~ m!.(svn|orig|pod)$!
                            and $n =~ m!\.d/$plugin_name!
                           ) ;
    } ;
    find ($wanted, $plugin_dir ) ;

    foreach my $load_file (@files) {
        $self->read_plugin_file($load_file);
    }
}

sub read_plugin_file {
    my ($self, $load_file) = @_;

    $logger->info("trying to read plugin $load_file");
    my $class_element = $self->meta_root->fetch_element('class') ;

    $load_file = "./$load_file" if $load_file !~ m!^/! and -e $load_file;

    my $plugin = do $load_file ;

    unless ($plugin) {
        if ($@) {die "couldn't parse $load_file: $@"; }
        elsif (not defined $plugin) {die  "couldn't do $load_file: $!"}
        else { die  "couldn't run $load_file" ;}
    }

    # there should be only only class in each plugin file
    foreach my $model (@$plugin) {
        my $class_name = delete $model->{name} ;
        # load with a array ref to avoid warnings about missing order
        $class_element->fetch_with_id($class_name)->load_data( $model ) ;
    }

    # load annotations
    $logger->info("loading annotations from plugin file $load_file");
    my $fh = IO::File->new($load_file) || die "Can't open $load_file: $!" ;
    my @lines = $fh->getlines ;
    $fh->close;
    $self->meta_root->load_pod_annotation(join('',@lines)) ;
}

#
# New subroutine "write_model_file" extracted - Mon Mar 12 13:38:29 2012.
#
sub write_model_file {
    my $wr_file  = shift;
    my $comments = shift ;
    my $notes    = shift;
    my $data     = shift;

    my $wr_dir = dirname($wr_file);
    unless ( -d $wr_dir ) {
        mkpath( $wr_dir, 0, oct(755) ) || die "Can't mkpath $wr_dir:$!";
    }

    my $wr = IO::File->new( $wr_file, '>' )
      || croak "Cannot open file $wr_file:$!" ;
    $logger->info("in $wr_file");

    my $dumper = Data::Dumper->new( [ \@$data ] );
    $dumper->Indent(1);    # avoid too deep indentation
    $dumper->Terse(1);     # allow unnamed variables in dump
    $dumper->Sortkeys(1);     # sort keys in hash

    my $dump = $dumper->Dump;

    # munge pod text embedded in values to avoid spurious pod formatting
    $dump =~ s/\n=/\n'.'=/g;

    $wr->print( @$comments ) ;
    $wr->print( "use strict;\nuse warnings;\n\n" );
    $wr->print( "return $dump;\n\n" );

    $wr->print( join( "\n", @$notes ) );

    $wr->close;

}



sub list_class_element {
    my $self = shift ;
    my $pad  =  shift || '' ;

    my $res = '';
    my $meta_class = $self->{meta_root}->fetch_element('class') ;
    foreach my $class_name ($meta_class->fetch_all_indexes ) {
        $res .= $self->list_one_class_element($class_name) ;
    }
    return $res ;
}

sub list_one_class_element {
    my $self = shift ;
    my $class_name = shift || return '' ;
    my $pad  =  shift || '' ;

    my $res = $pad."Class: $class_name\n";
    my $meta_class = $self->{meta_root}->fetch_element('class')
       -> fetch_with_id($class_name) ;

    my @elts = $meta_class->fetch_element('element')->fetch_all_indexes ;

    my @include = $meta_class->fetch_element('include')->fetch_all_values ;
    my $inc_after = $meta_class->grab_value('include_after') ;

    if (@include and not defined $inc_after) {
        foreach my $inc (@include) {
            $res .= $self->list_one_class_element($inc,$pad.'  ') ;
        }
    }

    return $res unless @elts ;

    foreach my $elt_name ( @elts) {
        my $type = $meta_class->grab_value("element:$elt_name type") ;

        $res .= $pad."  - $elt_name ($type)\n";
        if (@include and defined $inc_after and $inc_after eq $elt_name) {
            foreach my $inc (@include) {
                $res .= $self->list_one_class_element($inc,$pad.'  ') ;
            }
        }
    }
    return $res ;
}


sub get_dot_diagram {
    my $self = shift ;
    my $dot = "digraph model {\n" ;

    my $meta_class = $self->{meta_root}->fetch_element('class') ;
    foreach my $class_name ($meta_class->fetch_all_indexes ) {
        my $d_class = $class_name ;
        $d_class =~ s/::/__/g;

        my $elt_list = '';
        my $use = '';

        my $class_obj =  $self->{meta_root}->grab(qq!class:"$class_name"!);
        my @elts =  $class_obj ->grab(qq!element!) ->fetch_all_indexes ;
        foreach my $elt_name ( @elts ) {
            my $of = '';
            my $elt_obj = $class_obj->grab(qq!element:"$elt_name"!) ;
            my $type = $elt_obj->grab_value("type") ;
            if ($type =~ /^list|hash$/) {
                my $cargo = $elt_obj->grab("cargo");
                my $ct = $cargo->grab_value("type") ;
                $of = " of $ct" ;
                $use .= $self->scan_used_class($d_class,$elt_name,$cargo);
            }
            else {
                $use .= $self->scan_used_class($d_class,$elt_name,$elt_obj);
            }
            $elt_list .= "- $elt_name ($type$of)\\n";
        }

        $dot .= $d_class
             .  qq! [shape=box label="$class_name\\n$elt_list"];\n!
             .  $use . "\n";

        $dot .= $self->scan_includes($class_name, $class_obj) ;
    }

    $dot .="}\n";

    return $dot ;
}

sub scan_includes {
    my ($self,$class_name, $class_obj) = @_ ;
    my $d_class = $class_name ;
    $d_class =~ s/::/__/g;

    my @includes = $class_obj->grab('include')->fetch_all_values ;
    my $dot = '';
    foreach my $c (@includes) {
        say "$class_name includes $c";
        my $t = $c;
        $t =~ s/::/__/g;
        $dot.= qq!$d_class -> $t ;\n!;
    }
    return $dot;
}

sub scan_used_class {
    my ($self,$d_class,$elt_name, $elt_obj) = @_ ;

    # define leaf call back
    my $disp_leaf = sub {
        my ($scanner, $data_ref, $node,$element_name,$index, $leaf_object) = @_ ;
        return unless $element_name eq 'config_class_name';
        my $v =  $leaf_object->fetch;
        return unless $v;
        $v =~ s/::/__/g;
        $$data_ref .= qq!$d_class -> $v !
            . qq![ style=dashed, label="$elt_name" ];\n!;
    } ;

    # simple scanner, (print all values)
    my $scan = Config::Model::ObjTreeScanner-> new (
        leaf_cb => $disp_leaf, # only mandatory parameter
    ) ;

    my $result = '' ;
    $scan->scan_node(\$result, $elt_obj) ;
    return $result ;
}

__PACKAGE__->meta->make_immutable;

1;


# ABSTRACT: Model (or schema) editor for Config::Model

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Itself - Model (or schema) editor for Config::Model

=head1 VERSION

version 2.021

=head1 SYNOPSIS

 # Itself constructor returns an object to read or write the data
 # structure containing the model to be edited
 my $meta_model = Config::Model::Itself -> new( ) ;

 # now load the model to be edited
 $meta_model -> read_all( ) ;

 # For Curses UI prepare a call-back to write model
 my $wr_back = sub { $meta_model->write_all(); }

 # create Curses user interface
 my $dialog = Config::Model::CursesUI-> new (
      store => $wr_back,
 ) ;

 # start Curses dialog to edit the mode
 $dialog->start( $meta_model->config_root )  ;

 # that's it. When user quits curses interface, Curses will call
 # $wr_back sub ref to write the modified model.

=head1 DESCRIPTION

Config::Itself module and its model files provide a model of Config:Model
(hence the Itself name).

Let's step back a little to explain. Any configuration data is, in
essence, structured data. A
configuration model is a way to describe the structure and relation of
all items of a configuration data set.

This configuration model is also expressed as structured data. This
structure data follows a set of rules which are
described for humans in L<Config::Model>.

The structure and rules documented in L<Config::Model> are also
expressed in a model in the files provided with
C<Config::Model::Itself>.

Hence the possibity to verify, modify configuration data provided by
L<Config::Model> can also be applied on configuration models. Using the
same user interface.

From a Perl point of view, Config::Model::Itself provides a class
dedicated to read and write a set of model files.

=head1 Constructor

=head2 new ( [ cm_lib_dir => ... ] )

Creates a new read/write handler. If no model_object is passed, the required
objects are created. C<cm_lib_dir> specifies where are the model files (defaults to
C<./lib/Config/Model>.

C<cm_lib_dir> is either a C<Path::Tiny> object or a string.

By default, this constructor will create all necessary
C<Config::Model*> objects.  If needed, you can pass already created
object with options C<config_model> (L<Config::Model> object),
C<meta_instance> (L<Config::Model::Instance> object) or C<meta_root>
(L<Config::Model::Node> object).

=head2 Methods

=head1 read_all ( [ root_model => ... ], [ force_load => 1 ] )

Load all the model files contained in C<model_dir> and all its
subdirectories. C<root_model> is used to filter the classes read.

Use C<force_load> if you are trying to load a model containing errors.

C<read_all> returns a hash ref containing ( class_name => file_name , ...)

=head2 write_all

Will write back configuration model in the specified directory. The
structure of the read directory is respected.

=head2 write_model_plugin( plugin_dir => foo, plugin_name => bar )

Write plugin models in the  passed C<plugin_dir> directory. The written file is path is
made of plugin name and class names. E.g. a plugin named C<bar> for class
C<Foo::Bar> is written in C<bar/Foo/Bar.pl> file. This file is to be used
by L<augment_config_class|Config::Model/"augment_config_class (name => '...', class_data )">

=head2 read_model_plugin( plugin_dir => foo, plugin_name => bar.pl )

This method searched recursively C<$plugin_dir/$plugin_name> and load
all C<*.pl> files found there.

=head2 list_class_element

Returns a string listing all the class and elements. Useful for
debugging your configuration model.

=head2 get_dot_diagram

Returns a graphviz dot file that represents the structure of the
configuration model:

=over

=item *

C<include> relations are represented by solid lines

=item *

Class usage (i.e. C<config_class_name> parameter) is represented by
dashed lines. The name of the element is attached to the dashed line.

=back

=head1 BUGS

Test menu entries are created from the content of C<application> model
parameter.  Unfortunately, there's no way to build the menu
dynamically. So user cme must be restarted to change the menu if the
application list is changed.

=head1 CREDITS

Here's the list of people who helped improve this project:

=over

=item Gregor Herrmann

=back

Thanks for the patches !

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Node>, L<Path::Tiny>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007-2019 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Config-Model-Itself>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Config-Model-Itself>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Config-Model-Itself>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Config::Model::Itself>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<ddumont at cpan.org>, or through
the web interface at L<https://github.com/dod38fr/config-model-itself/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/dod38fr/config-model-itself>

  git clone git://github.com/dod38fr/config-model-itself.git

=cut
