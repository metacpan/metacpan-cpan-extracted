#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# ABSTRACT: Work on the configuration model of an application

package App::Cme::Command::meta ;
$App::Cme::Command::meta::VERSION = '2.009';
use strict ;
use warnings ;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model 2.075;

use Config::Model::Itself ;
use YAML::Tiny;

use Tk ;
use Config::Model::TkUI ;
use Config::Model::Itself::TkEditUI ;
use Path::Tiny ;

my %meta_cmd = (
    check => \&check,
    dump => \&dump_cds,
    'dump-yaml' => \&dump_yaml,
    'gen-dot' => \&gen_dot,
    edit => \&edit,
    save => \&save,
    plugin => \&plugin,
);

sub validate_args {
    my ($self, $opt, $args) = @_;

    my $mc = $opt->{'_meta_command'} = shift @$args  || die "please specify meta sub command\n";

    if (not $meta_cmd{$mc}) {
        die "Unexpected meta sub command: '$mc'. Expected ".join(' ', sort keys %meta_cmd)."\n";
    }

    my ( $categories, $appli_info, $appli_map ) = Config::Model::Lister::available_models;
    my $application = shift @$args;

    if ($mc eq 'plugin') {
        unless ($application) {
            die "Missing application name after 'plugin' command";
        }
        $opt->{_root_model} = $appli_map->{$application}
            || die "Unknown application $application";
    }
    elsif ($application) {
        $opt->{_root_model} = $appli_map->{$application} || $application;
    }

    Config::Model::Exception::Any->Trace(1) if $opt->{trace};

    $opt->{_application} = $application ;

}

sub opt_spec {
    my ( $class, $app ) = @_;

    return (
		[
            "dir=s"         => "directory where to read and write a model",
            {default => 'lib/Config/Model'}
        ],
        [
            "dumptype=s" => "dump every values (full), only preset values "
            . "or only customized values (default)",
            {callbacks => { 'expected values' => sub { $_[0] =~ m/^full|preset|custom$/ ; }}}
        ],
		[ "open-item=s"   => "force the UI to open the specified node"],
		[ "plugin-file=s" => "create a model plugin in this file" ],
        [ "load-yaml=s"   => "load model from YAML file" ],
        [ "load=s"        => "load model from cds file (Config::Model serialisation file)"],
        [ "system!"       => "read model from system files" ],
        [ "test-and-quit=s" => "Used for tests" ],
        $class->cme_global_options()
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [ ".join(' | ', sort keys %meta_cmd)." ] your_model_class ";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub read_data {
    my $load_file = shift ;

    my @data ;
    if ( $load_file eq '-' ) {
        @data = <STDIN> ;
    }
    else {
        open(LOAD,$load_file) || die "cannot open load file $load_file:$!";
        @data = <LOAD> ;
        close LOAD;
    }

    return wantarray ? @data : join('',@data);
}

sub load_optional_data {
    my ($self, $args, $opt, $root_model, $meta_root) = @_;

    if (defined $opt->{load}) {
        my $data = read_data($opt->{load}) ;
        $data = qq(class:"$root_model" ).$data unless $data =~ /^\s*class:/ ;
        $meta_root->load($data);
    }

    if (defined $opt->{'load-yaml'}) {
        my $yaml = read_data($opt->{'load-yaml'}) ;
        my $pdata = Load($yaml) ;
        $meta_root->load_data($pdata) ;
    }
}

sub load_meta_model {
    my ($self, $opt, $args) = @_;

    my $root_model = $opt->{_root_model};
    my $cm_lib_dir = path(split m!/!, $opt->{dir}) ; # replace with cm_lib_dir ???

    if (! $cm_lib_dir->is_dir) {
        $cm_lib_dir->mkpath(0, 0755) || die "can't create $cm_lib_dir:$!";
    }

    my $meta_model = $self->{meta_model} = Config::Model -> new();

    my $meta_inst = $meta_model->instance(
        root_class_name => 'Itself::Model',
        instance_name   => 'meta',
        check           => $opt->{'force-load'} ? 'no' : 'yes',
    );

    my $meta_root = $meta_inst -> config_root ;

    my $system_cm_lib_dir = $INC{'Config/Model.pm'} ;
    $system_cm_lib_dir =~ s/\.pm//;

    return ($meta_inst, $meta_root, $cm_lib_dir, path($system_cm_lib_dir));
}

sub load_meta_root {
    my ($self, $opt, $args) = @_;

    my ($meta_inst, $meta_root, $cm_lib_dir, $system_cm_lib_dir) = $self->load_meta_model($opt,$args);

    my $root_model = $opt->{_root_model};

    say "Reading model from $system_cm_lib_dir" if $opt->system();

    # now load model
    my $rw_obj = Config::Model::Itself -> new(
        model_object => $meta_root,
        cm_lib_dir   => $cm_lib_dir->canonpath
    );

    $meta_inst->initial_load_start ;

    my @read_args = (
        force_load => $opt->{'force-load'},
        root_model => $root_model,
        # legacy     => 'ignore',
    );
    if ($opt->system()) {
        push @read_args,
            application => $opt->{_application},
            read_from => $system_cm_lib_dir ;
    }
    $rw_obj->read_all(@read_args);

    $meta_inst->initial_load_stop ;

    $self->load_optional_data($args, $opt, $root_model, $meta_root) ;

    my $write_sub = sub {
            my $wr_dir = shift || $cm_lib_dir ;
            $rw_obj->write_all( );
        } ;
    return ($rw_obj, $cm_lib_dir, $meta_root, $write_sub);
}

sub load_meta_plugin {
    my ($self, $opt, $args) = @_;

    my ($meta_inst, $meta_root, $cm_lib_dir, $system_cm_lib_dir) = $self->load_meta_model($opt, $args);

    my $root_model = $opt->{_root_model};
    my $meta_cm_lib_dir = $opt->dev ? $cm_lib_dir : $system_cm_lib_dir ;
    my $plugin_name = shift @$args or die "missing plugin file name after application name.";

    if ($plugin_name =~ s/\.pl$//) {
        warn "removed '.pl' deprecated suffix from plugin name\n";
    }

    say "Preparing plugin $plugin_name for model $root_model found in $meta_cm_lib_dir";
    say "Use -dev option to create a plugin for a local model (i.e. in $cm_lib_dir)"
        unless $opt->dev;

    # now load model
    my $rw_obj = Config::Model::Itself -> new(
        model_object => $meta_root,
        cm_lib_dir   => $meta_cm_lib_dir->canonpath,
    ) ;

    $meta_inst->initial_load_start ;
    $meta_inst->layered_start;

    $rw_obj->read_all(
        force_load => $opt->{'force-load'},
        root_model => $root_model,
        # legacy     => 'ignore',
    );

    $meta_inst->layered_stop;

    # load any existing plugin file
    $rw_obj->read_model_plugin(
        plugin_dir => $cm_lib_dir.'/models/',
        plugin_name => $plugin_name
    ) ;

    $meta_inst->initial_load_stop ;

    $self->load_optional_data($args, $opt, $root_model, $meta_root) ;
    my $root_model_dir = $root_model ;
    $root_model_dir =~ s!::!/!g;
    my $write_sub = sub {
            $rw_obj->write_model_plugin(
                plugin_dir => "$cm_lib_dir/models/$root_model_dir.d",
                plugin_name => $plugin_name
            );
        } ;

    return ($rw_obj, $cm_lib_dir, $meta_root, $write_sub);
}

sub execute {
    my ($self, $opt, $args) = @_;

    # how to specify root-model when starting from scratch ?
    # ask question and fill application file ?

    my $cmd_sub = $meta_cmd{$opt->{_meta_command}};

    $self->$cmd_sub($opt, $args);
}

sub save {
    my ($self, $opt, $args) = @_;
    my ($rw_obj, $cm_lib_dir, $meta_root, $write_sub) = $self->load_meta_root($opt, $args) ;

    say "Saving ",$rw_obj->root_model. ' model'. ($opt->dir ? ' in '.$opt->dir : '');
    &$write_sub;
}

sub gen_dot {
    my ($self, $opt, $args) = @_;
    my ($rw_obj, $cm_lib_dir, $meta_root, $write_sub) = $self->load_meta_root($opt, $args) ;

    my $out = shift @$args || "model.dot";
    say "Creating dot file $out";
    path($out) -> spew( $rw_obj->get_dot_diagram );
}

sub check {
    my ($self, $opt, $args) = @_;

    say "loading model" unless $opt->{quiet};
    my ($rw_obj, $cm_lib_dir, $meta_root, $write_sub) = $self->load_meta_root($opt, $args) ;

    Config::Model::ObjTreeScanner->new( leaf_cb => sub { } )->scan_node( undef, $meta_root );

    say "checking data" unless $opt->{quiet};
    $meta_root->dump_tree( mode => 'full' );
    say "check done" unless $opt->{quiet};

    my $ouch = $meta_root->instance->has_warning;

    if ( $opt->{strict} and $ouch ) {
        die "Found $ouch warnings in strict mode\n";
    }

}

sub dump_cds {
    my ($self, $opt, $args) = @_;
    my ($rw_obj, $cm_lib_dir, $meta_root, $write_sub) = $self->load_meta_root($opt, $args) ;

    my $dump_file = shift @$args || 'model.cds';
    say "Dumping ".$rw_obj->root_model." in $dump_file";

    my $dump_string = $meta_root->dump_tree( mode => $opt->{dumptype} || 'custom' ) ;

    path($dump_file)->spew($dump_string);
}

sub dump_yaml{
    my ($self, $opt, $args) = @_;
    my ($rw_obj, $cm_lib_dir, $meta_root, $write_sub) = $self->load_meta_root($opt, $args) ;

    require YAML::Tiny;
    import YAML::Tiny qw/Dump/;
    my $dump_file = shift @$args || 'model.yml';
    say "Dumping ".$rw_obj->root_model." in $dump_file";

    my $dump_string = Dump($meta_root->dump_as_data(ordered_hash_as_list => 0)) ;

    path($dump_file)->spew($dump_string);

}

sub plugin {
    my ($self, $opt, $args) = @_;
    my @info = $self->load_meta_plugin($opt, $args) ;
    $self->_edit($opt, $args, @info);
}

sub edit {
    my ($self, $opt, $args) = @_;
    my @info = $self->load_meta_root($opt, $args) ;
    $self->_edit($opt, $args, @info);
}

sub _edit {
    my ($self, $opt, $args, $rw_obj, $cm_lib_dir, $meta_root, $write_sub) = @_;

    my $root_model = $rw_obj->root_model;
    my $mw = MainWindow-> new;

    $mw->withdraw ;
    # Thanks to Jerome Quelin for the tip
    $mw->optionAdd('*BorderWidth' => 1);

    my $cmu = $mw->ConfigModelEditUI(
        -root       => $meta_root,
        -store_sub  => $write_sub,
        -model_name => $root_model,
        -cm_lib_dir => $cm_lib_dir
    );

    my $open_item = $opt->{'open-item'};
    if ($root_model and not $meta_root->fetch_element('class')->fetch_size) {
        $open_item ||=  qq(class:"$root_model" );
    }
    else {
        $open_item ||= 'class';
    }

    my $obj = $meta_root->grab($open_item) ;
    $cmu->after(10, sub { $cmu->force_element_display($obj) });

    if (my $taq = $opt->test_and_quit ) {
        my $bail_out = sub {
            warn "save failed: $_[0]\n" if @_;
            $cmu -> quit;
        } ;

        $cmu->after( 2000 , sub {
            if ($taq =~ /s/) {
                say "Test mode: save and quit";
               $cmu->save( $bail_out );
            }
            else {
                say "Test mode: quit only";
                &$bail_out
            }
        });
    }
    &MainLoop ; # Tk's
    say "Exited GUI";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Command::meta - Work on the configuration model of an application

=head1 VERSION

version 2.009

=head1 SYNOPSIS

  # edit meta model
  cme meta [ options ] edit [ model_class ]

  # check meta model
  cme meta [ options ] check [ model_class ]

  # model plugin mode
  cme meta [options] plugin application plugin_name

=head1 DESCRIPTION

C<cme meta edit> provides a Perl/Tk graphical interface to create or
edit configuration models that will be used by L<Config::Model>.

This tool enables you to create configuration checker or editor for
configuration files of an application.

=head1 USAGE

C<cme meta> supports several sub commands like C<edit> or C<plugin>. These
sub commands are detailed below.

=head2 edit

C<cme meta edit> is the most useful sub command. It will read and
write model file from C<./lib/Config/Model/models> directory.

Only configuration models matching the optional 4th parameter will be loaded. I.e.

  cme meta edit Xorg

will load models C<Xorg> (file C<Xorg.pl>) and all other C<Xorg::*> like
C<Xorg::Screen> (file C<Xorg/Screen.pl>).

Besides C<edit>, the following sub commands are available:

=head2 check

C<cme meta check> reads the model files from
C<./lib/Config/Model/models> directory and checks their validity.

=head2 plugin

This sub command is used to create model plugins. A model plugin is an
addendum to an existing model. The resulting file is saved in a
C<.d> directory besides the original file to be taken into account.

For instance:

 $ cme meta plugin dpkg my-plugin
 # perform additions to Dpkg and Dpkg::Control and save
 $ find lib/Config/Model/models/Dpkg.d -type f
 lib/Config/Model/models/Debian/Dpkg.d/my-plugin/Dpkg.pl
 lib/Config/Model/models/Debian/Dpkg.d/my-plugin/Dpkg/Control.pl

Use C<-dev> option if you need to add plugins to a model located in
current directory.

=head2 gen-dot [ file.dot ]

Create a dot file that represent the structure of the configuration
model. By default, the generated dot file is C<model.dot>

 $ cme meta gen-dot Itself itself.dot
 $ dot -T png itself.dot > itself.png

C<include> are represented by solid lines. Class usage
(i.e. C<config_class_name> parameter) is represented by dashed
lines. The name of the element is attached to the dashed line.

=head2 dump [ file.cds ]

Dump configuration content in the specified file (or C<model.cds>) using
Config::Model dump string syntax (hence the C<cds> file extension).
See L<Config::Model::Loader> for details on the syntax)

By default, dump only custom values, i.e. different from application
built-in values or model default values. See -dumptype option for
other types of dump

 $ cme meta dump Itself

=head2 dump-yaml [ file.yml ]

Dump configuration content in the specified file (or C<model.yml>) in
YAML format.

=head2 save

Force a save of the model even if no edition was done. This option is
useful to migrate a model when Config::Model model feature changes.

=head1 Options

=over

=item -system

Read model from system files, i.e. from installed files, not from
C<./lib> directory.

=item -trace

Provides a full stack trace when exiting on error.

=item -load <cds_file_to_load> | -

Load model from cds file (using Config::Model serialisation format,
typically done with -dump option). This option can be used with
C<save> to directly save a model loaded from the cds file or from
STDIN.

=item -load-yaml <yaml_file_to_load> | -

Load configuration data in model from YAML file. This
option can be used with C<save> to directly save a model loaded from
a YAML file or from STDIN.

=item -force-load

Load file even if error are found in data. Bad data are loaded, but should be cleaned up
before saving the model. See menu C<< File -> check >> in the GUI.

=item -dumptype [ full | preset | custom ]

Choose to dump every values (full), only preset values or only
customized values (default) (only for C<dump> sub command)

=item -open-item 'path'

In graphical mode, force the UI to open the specified node. E.g.

 -open_item 'class:Fstab::FsLine element:fs_mntopts rules'

=back

=head1 LOGGING

All Config::Model logging was moved from klunky debug and
verbose prints to L<Log::Log4perl>. Logging can be configured in the
following files:

=over

=item *

 ~/.log4config-model

=item *

 /etc/log4config-model.conf

=back

Without these files, the following Log4perl config is used:

 log4perl.logger=WARN, Screen
 log4perl.appender.Screen        = Log::Log4perl::Appender::Screen
 log4perl.appender.Screen.stderr = 0
 log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
 log4perl.appender.Screen.layout.ConversionPattern = %d %m %n

Log4Perl categories are shown in L<cme/LOGGING>

=head1 Dogfooding

The GUI shown by C<cme meta edit> is created from a configuration
model that describes the structure and parameters of a configuration
model. (which explains the "Itself" name. This module could also be
named C<Config::Model::DogFooding>).

This explains why the GUI shown by C<cme meta edit> looks like the GUI
shown by C<cme edit>: the same GUI generator is used.

If you're new to L<Config::Model>, I'd advise not to peek under
C<Config::Model::Itself> hood lest you loose your sanity.

=head1 AUTHOR

Dominique Dumont, ddumont at cpan dot org

=head1 SEE ALSO

=over

=item *

L<Config::Model::Manual::ModelCreationIntroduction>

=item *

L<cme>,

=item *

L<Config::Model>,

=item *

L<Config::Model::Itself>,

=item *

L<Config::Model::Node>,

=item *

L<Config::Model::Instance>,

=item *

L<Config::Model::HashId>,

=item *

L<Config::Model::ListId>,

=item *

L<Config::Model::WarpedNode>,

=item *

L<Config::Model::Value>

=back

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007-2017 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
