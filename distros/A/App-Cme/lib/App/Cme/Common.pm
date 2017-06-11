#
# This file is part of App-Cme
#
# This software is Copyright (c) 2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
#ABSTRACT: Common methods for App::Cme

package App::Cme::Common;
$App::Cme::Common::VERSION = '1.020';
use strict;
use warnings;
use 5.10.1;

use Config::Model 2.103;
use Config::Model::Lister;
use Pod::POM;
use Pod::POM::View::Text;
use Scalar::Util qw/blessed/;
use Path::Tiny;
use Encode qw(decode_utf8);

sub cme_global_options {
  my ( $class, $app ) = @_;

  my @global_options = (
      [ "model-dir=s"        => "Specify an alternate directory to find model files"],
      [ "try-app-as-model!"  => "try to load a model using directly the application name "
                              . "specified as 3rd parameter on the command line"],
      [ "save!"              => "Force a save even if no change was done" ],
      [ "force-load!"        => "Load file even if error are found in data. Bad data are discarded (imply save)"],
      [ "create!"            => "start from scratch."],
      [ "root-dir=s"         => "Change root directory. Mostly used for test"],
      [ "file=s"             => "Specify a target file"],
      [ "backend=s"          => "Specify a read/write backend"],
      [ "trace|stack-trace!" => "Provides a full stack trace when exiting on error"],
      [ "verbose=s"         => "Verbosity level (1, 2, 3  or info, debug, trace)"],
      # no bundling
      { getopt_conf => [ qw/no_bundling/ ] }
  );

  return (
      @global_options,
  );
}

sub check_unknown_args {
    my ($self, $args) = @_;

    my @unknown_options = grep { /^-/ } @$args ;
    # $self->usage_error("Unknown option: @unknown_options") if @unknown_options;
    warn("Unknown option: @unknown_options. Unknown option will soon be a fatal error.") if @unknown_options;
}

# modifies $args in place
sub process_args {
    my ($self, $opt, $args) = @_;

    # see Debian #839593 and perlunicook(1) section X 13
    @$args = map { decode_utf8($_, 1) } @$args;

    my ( $categories, $appli_info, $appli_map ) = Config::Model::Lister::available_models;
    my $application = shift @$args;

    my $root_model = $appli_map->{$application};
    $root_model ||= $application if $opt->{try_app_as_model};

    Config::Model::Exception::Any->Trace(1) if $opt->{trace};

    if ( not defined $root_model ) {
        die "Can't locate model for application '$application'.\n"
            . "Run 'cme list' for the list of models available on your system.\n"
            . "You may need to install another Config::Model Perl module.\n"
            . "See the available models there: https://github.com/dod38fr/config-model/wiki/Available-models-and-backends\n";
    }

    say "cme: using $root_model model" unless $opt->{quiet};

    my $command = (split('::', ref($self)))[-1] ;

    # @ARGV should be [ $config_file ] [ modification_instructions ]
    my $config_file;
    if ( $appli_info->{$application}{require_config_file} ) {
        $config_file = $opt->{file} || shift @$args ;
        $self->usage_error(
            "no config file specified. Command should be 'cme $command $application configuration_file'",
        ) unless $config_file;
    }
    elsif ( $appli_info->{$application}{allow_config_file_override}) {
        $config_file = $opt->{file};
    }

    if ( $appli_info->{$application}{require_backend_argument} ) {
        # let the backend handle a missing arg and provide a clear error message
        my $b_arg = $opt->{_backend_arg} = shift @$args ;
        if (not $b_arg) {
            my $message = $appli_info->{$application}{backend_argument_info} ;
            my $insert = $message ? " ( $message )": '';
            die "application $application requires a 3rd argument$insert. "
                . "I.e. 'cme $command $application <backend_arg>'";
        }
    }

    # remove legacy '~~'
    if ($args->[0] and $args->[0] eq '~~') {
        warn "Argument '~~' was a bad idea and is now ignored. Use -file option to "
            ."specify a target file or just forget about '~~' argument\n";
        shift @$args;
    }

    # override (or specify) configuration dir
    $opt->{_config_dir} = $appli_info->{$application}{config_dir};

    $opt->{_application} = $application ;
    $opt->{_config_file} = $config_file;
    $opt->{_root_model}  = $root_model;
}


sub model {
    my ($self, $opt, $args) = @_;

    my @levels = qw/WARN INFO DEBUG TRACE/;
    my $optv = $opt->{verbose} ;

    my $log_level;
    if (defined $optv) {
        if ($optv =~ /^\d$/) {
            $log_level =  $levels[$opt->{verbose}];
        }
        else {
            ($log_level) = grep { /^$optv/i } @levels;
        }
        if (not $log_level) {
            die "unknown log level $optv. Must be 1 ,2, 3 or warn, info, debug, trace.\n" ;
        }
    }


    my %cm_args;
    $cm_args{model_dir} = $opt->{model_dir} if $opt->{model_dir};
    $cm_args{log_level} = $log_level if $log_level;

    return $self->{_model} ||= Config::Model->new( %cm_args );
}

sub instance {
    my ($self, $opt, $args) = @_;

    return
        $self->{_instance}
        ||= $self->model->instance(
            root_class_name => $opt->{_root_model},
            instance_name   => $opt->{_application},
            application     => $opt->{_application},
            root_dir        => $opt->{root_dir},
            check           => $opt->{force_load} ? 'no' : 'yes',
            auto_create     => $opt->{create},
            backend         => $opt->{backend},
            backend_arg     => $opt->{_backend_arg},
            backup          => $opt->{backup},
            config_file     => $opt->{_config_file},
            config_dir      => $opt->{_config_dir},
        );

}

sub init_cme {
    my $self = shift;
    # model and inst are deleted if not kept in a scope
    return ( $self->model(@_) , $self->instance(@_), $self->instance->config_root );
}

sub save {
    my ($self,$inst,$opt) = @_;

    $inst->say_changes unless $opt->{quiet};

    # if load was forced, must write back to clean up errors (even if they are not changes
    # at semantic level, i.e. removed unnecessary stuff)
    $inst->write_back( force => $opt->{force_load} || $opt->{save} );

}

sub run_tk_ui {
    my ($self, $root, $opt) = @_;

    require Config::Model::TkUI;
    require Tk;
    require Tk::ErrorDialog;
    Tk->import;

    no warnings 'once';
    my $mw = MainWindow->new;
    $mw->withdraw;

    # Thanks to Jerome Quelin for the tip
    $mw->optionAdd( '*BorderWidth' => 1 );

    my $cmu = $mw->ConfigModelUI(
        -root       => $root,
    );

    $root->instance->on_message_cb(sub{$cmu->show_message(@_);});

    if ($opt->{open_item}) {
        my $obj = $root->grab($opt->{open_item});
        $cmu->force_element_display($obj);
    }

    &MainLoop;    # Tk's
}

sub run_shell_ui ($$$) {
    my ($self, $term_class, $inst) = @_;

    my $shell_ui = $term_class->new (
        root   => $inst->config_root,
        title  => $inst->application . ' configuration',
        prompt => ' >',
    );

    # engage in user interaction
    $shell_ui->run_loop;
}

sub get_documentation {
    my ($self) = @_;

    my $parser = Pod::POM->new();
    my $pkg = blessed ($self);
    $pkg =~ s!::!/!g;
    my $pom = $parser->parse_file($INC{$pkg.'.pm'})
        || die $parser->error();

    my $sections = $pom->head1();
    my @ret ;
    foreach my $s (@$sections) {
        push (@ret ,$s) if $s->title() =~ /DESCRIPTION|EXIT/;
    }
    return join ("", map { Pod::POM::View::Text->print($_)} @ret) . "Options:\n";;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Common - Common methods for App::Cme

=head1 VERSION

version 1.020

=head1 SYNOPSIS

 # Internal. Used by App::Cme::Command::*

=head1 DESCRIPTION

Common methods for all cme commands

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
