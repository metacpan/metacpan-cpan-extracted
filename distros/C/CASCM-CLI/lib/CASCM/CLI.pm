package CASCM::CLI;

#######################
# LOAD MODULES
#######################
use 5.008001;

use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);

use File::Spec;
use Config::Tiny;
use File::HomeDir;
use CASCM::Wrapper;
use Log::Any::Adapter;
use Hash::Merge qw(merge);
use Getopt::Mini ( later => 1 );
use Log::Any::Adapter::Callback;
use Getopt::Long qw(GetOptionsFromArray);
use Object::Tiny qw(cascm exitval context);

#######################
# VERSION
#######################
our $VERSION = '0.1.1';

#######################
# RUNNER
#######################
sub run {
    my ( $self, @args ) = @_;

    # Initialize
    $self->_init();
    local @ARGV = ();

    # Parse main arguments
    my $main_options = {};
    GetOptionsFromArray( \@args, $main_options, $self->_main_opt_spec() )
      or $self->_print_bad_opts();

    # Get Subcommand
    my $subcmd = shift @args;
    if ( $subcmd and ( $subcmd !~ m{^[a-z]+$}xi ) ) {
        $self->_print_bad_subcmd($subcmd);
    }

    # Get Subcommand options
    my %sub_options = getopt(
        hungry_flags => 1,
        argv         => [@args],
    );
    delete $sub_options{_argv} if exists $sub_options{_argv};

    # Get Subcommand arguments
    my @sub_args;
    if ( exists $sub_options{''} ) {
        if ( ref( $sub_options{''} ) eq 'ARRAY' ) {
            push( @sub_args, @{ $sub_options{''} } );
        }
        else {
            push( @sub_args, $sub_options{''} );
        }
        delete $sub_options{''};
    } ## end if ( exists $sub_options...)

    # Make lowercase
    $subcmd = '' if not defined $subcmd;
    $subcmd = lc($subcmd);

    # Check for help
    if ( ( $subcmd eq 'help' ) or ( $main_options->{help} ) ) {
        $self->_print_help();
        exit 0;
    } ## end if ( ( $subcmd eq 'help'...))

    # Check for version
    if ( ( $subcmd eq 'version' ) or ( $main_options->{version} ) ) {
        $self->_print_version();
        exit 0;
    } ## end if ( ( $subcmd eq 'version'...))

    # Check for Subcommand
    if ( not $subcmd ) {
        $self->_print_help();
        exit 1;
    } ## end if ( not $subcmd )

    # Initialize Logger
    $self->_init_logger();

    # Initialize context
    $self->_init_context( $main_options->{context} || '' );

    # Initialize CASCM
    $self->_init_cascm();

    # Check if subcommand is supported
    if ( not $self->cascm()->can($subcmd) ) {
        $self->_print_bad_subcmd($subcmd);
    }

    # Run subcommand
    $self->cascm()->$subcmd( {%sub_options}, @sub_args );
    $self->{exitval} = $self->cascm()->exitval();

  return 1;
} ## end sub run

#######################
# INTERNAL
#######################

# Initialize
sub _init {
    my ($self) = @_;

    # Setup getopt long
    Getopt::Long::Configure('default');
    Getopt::Long::Configure('pass_through');
    Getopt::Long::Configure('no_auto_abbrev');

    # Set exit value
    $self->{exitval} = 0;

  return 1;
} ## end sub _init

# Main option spec
sub _main_opt_spec {

  return (
        'help',       # Print Help
        'version',    # Print Version
        'context=s',  # Set Context file
    );

} ## end sub _main_opt_spec


sub _print_bad_opts {
    print STDERR "Invalid Options. See 'hv --help'\n";
    exit 1;
} ## end sub _print_bad_opts


sub _print_bad_subcmd {
    my ( $self, $cmd ) = @_;
    print STDERR "Invalid command '$cmd'. See 'hv --help'\n";
    exit 1;
} ## end sub _print_bad_subcmd


sub _print_help {
    my ($self) = @_;

    $self->_print_version();

    print <<'_EO_HELP';
USAGE: hv [options] command [command_options] [arguments]

Options:

    help        Print this message
    version     Print version information
    context     Specify the context file

Commands:

    This is typically your Harvest CLI command
    Please see the documentation of CASCM::Wrapper for the list of
        supported commands
    Command options and arguments are passed through to the harvest CLI

--
_EO_HELP

  return 1;
} ## end sub _print_help


sub _print_version {
    my ($self) = @_;
    print "hv version-${VERSION}\n";
  return 1;
} ## end sub _print_version


sub _init_logger {
    my ($self) = @_;

    Log::Any::Adapter->set(
        'Callback',
        min_level  => 'info',
        logging_cb => sub {
            my ( $method, $self, $format, @params ) = @_;
            chomp( $format, @params );
            $method = uc($method);
            if ( ( $method eq 'WARNING' ) or ( $method eq 'ERROR' ) ) {
                print STDERR "[$method] $format\n";
            }
            else {
                print "[$method] $format\n";
            }
        },
    );

  return 1;
} ## end sub _init_logger


sub _init_context {
    my ( $self, $main_ctx_file ) = @_;

    # Check for system-wide context in $CASCM_HOME
    my $system_context = {};
    my $cascm_home = $ENV{CA_SCM_HOME} || $ENV{HARVEST_HOME} || '';
    if ($cascm_home) {
        my $system_ctx_file = File::Spec->catfile( $cascm_home, 'hvcontext' );
        if ( -e $system_ctx_file ) {
            $system_context = $self->_load_context($system_ctx_file);
        }
    } ## end if ($cascm_home)

    # Check for user's context file
    my $user_context = {};
    my $user_ctx_file;
    if ( $ENV{HVCONTEXT} ) {
        $user_ctx_file = $ENV{HVCONTEXT};
    }
    else {
        my $homedir = File::HomeDir->my_home();
        if ( $homedir and -e $homedir ) {
            $user_ctx_file = File::Spec->catfile( $homedir, '.hvcontext' );
        }
    } ## end else [ if ( $ENV{HVCONTEXT} )]
    if ( -e $user_ctx_file ) {
        $user_context = $self->_load_context($user_ctx_file);
    }

    # Check for current context
    my $current_context = {};
    my $current_ctx_file;
    if ($main_ctx_file) {
        $current_ctx_file = $main_ctx_file;
    }
    else {
        $current_ctx_file = '.hvcontext';
    }
    if ( -e $current_ctx_file ) {
        $current_context = $self->_load_context($current_ctx_file);
    }

    # Merge Context
    my $current_and_user = merge( $current_context,  $user_context );
    my $context          = merge( $current_and_user, $system_context );

    $self->{context} = $context;
  return 1;
} ## end sub _init_context


sub _load_context {
    my ( $self, $file ) = @_;

    my $config = Config::Tiny->read($file)
      or die "ERROR: Failed to read $file";

    my $context = {};
    foreach ( keys %{$config} ) {
        if   ( $_ eq '_' ) { $context->{global} = $config->{$_}; }
        else               { $context->{$_}     = $config->{$_}; }
    } ## end foreach ( keys %{$config} )

  return $context;
} ## end sub _load_context


sub _init_cascm {
    my ($self) = @_;
    my $cascm = CASCM::Wrapper->new(
        {
            parse_logs => 1,
        }
    );
    $cascm->set_context( $self->context() );
    $self->{cascm} = $cascm;
  return 1;
} ## end sub _init_cascm

#######################
1;

__END__

#######################
# POD SECTION
#######################
=pod

=head1 NAME

CASCM::CLI - A unified CLI for CA Harvest SCM

=head1 USAGE

    hv [options] subcommand [options] [arguments]

=head1 DESCRIPTION

C<hv> provides a unified, context aware CLI for CA Harvest SCM.

=head1 CONTEXT

C<hv> looks for, collects, merges and passes on context and options to
underlying Harvest commands. This allows context to be configured in
various locations.

Context files are C<.ini> files. Please see the documentation in
L<CASCM::Wrapper> for the format and examples of context files.

The following precedence is used when merging context from various
sources.

=over

=item command-line

    hv hci -st Developement

Harvest CLI options can be provided directly on the command line, just
like you would when running harvest commands directly

=item Project-specific Context

The project context is a context file C<.hvcontext> in the current
directory

=item User-specific Context

The user's context file defaults to C<.hvcontext> in the user's home
directory. This can also be specified using the C<HVCONTEXT>
environment variable.

=item System-wide Context

The system wide context file defaults to C<$CA_SCM_HOME/hvcontext> or
C<$HARVEST_HOME/hvcontext>

=back

=head1 LOGGING

Unlike harvest commands, C<hv> will, by default, log to STDOUT(or
STDERR). Harvest specific log files are not created.

=head1 SUBCOMMANDS

Almost all harvest commands are supported as subcommands. Please see
L<CASCM::Wrapper> for a full list of supported commands.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<https://github.com/mithun/perl-cascm-cli/issues>

=head1 AUTHOR

Mithun Ayachit C<mithun@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014, Mithun Ayachit. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

=cut
