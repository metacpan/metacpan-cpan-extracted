package App::JESP::Cmd::CommandJESP;
$App::JESP::Cmd::CommandJESP::VERSION = '0.013';

use base qw/App::JESP::Cmd::Command/;
use strict; use warnings;

use App::JESP;
use Log::Any qw/$log/;

=head1 NAME

App::JESP::Cmd::CommandJESP - Superclass for commands in need of a App::JESP instance.

=cut

=head2 opt_spec

Common options for App::JESP based commands.

=cut

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [ 'home=s' =>
              "The home directory where the plan.json lives" ],
        [ 'dsn=s' =>
              "The DSN to connect to the DB. See https://metacpan.org/pod/DBI#parse_dsn for DSN format"
              ."\nExamples:\n"
              ."\n dbi:mysql:database=testdb;host=localhost;port=3306"
              ."\n dbi:SQLite:dbname=demo/test.db"
              ."\n dbi:Pg:dbname=testdb;host=localhost;port=5432"
              ."\n"

          ],
        [ 'username=s' =>
              "The username to connect to the DB", { default => undef } ],
        [ 'password=s' =>
              "The password to connect to the DB", { default => undef } ],
        [ 'prefix=s' =>
              "The prefix for all jesp metatables. Defaults to 'jesp_'" ],
        $class->options($app),
    )
}

=head2 options

Override this in subclasses to add options to opt_spec

=cut

sub options{return ();}

=head2 validate_args

Do some stuff with validate args.

=cut

sub validate_args {
    my ( $self, $opts, $args ) = @_;
    unless( $opts->dsn() ){ die "Missing 'dsn' option. Run with -h\n"; }
    unless( $opts->home() ){ die "Missing 'home' option. Run with -h\n"; }

    # Time to build the JESP
    $log->debug("Building App::JESP instance");
    my $jesp = App::JESP->new({
        dsn => $opts->dsn(),
        home => $opts->home(),
        ( $opts->username() ? ( username => $opts->username() ) : ( username => undef ) ),
        ( $opts->password() ? ( password => $opts->password() ) : ( password => undef ) ),
    });
    $log->debug("App::JESP instance built");

    # Inject __jesp in myself.
    # Yes this is a bit dirty, but it works.
    $self->{__jesp} = $jesp;
    $self->validate( $opts, $args );
}

=head2 validate

Override that in subclasses to validate further.

=cut

sub validate{};

=head2 jesp

Returns the current JESP instance.

=cut

sub jesp{
    my ($self) = @_;
    return $self->{__jesp};
}

1;
