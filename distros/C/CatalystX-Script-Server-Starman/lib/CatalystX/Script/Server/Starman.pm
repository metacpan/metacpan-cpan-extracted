package CatalystX::Script::Server::Starman;
use Moose;
use MooseX::Types::Moose qw/ Str Int /;
use Pod::Usage;
use Pod::Find qw(pod_where);
use namespace::autoclean;

our $VERSION = '0.02';

extends 'Catalyst::Script::Server';

has '+fork' => ( default => 1, init_arg => undef );

has [qw/ keepalive restart restart_delay restart_regex restart_directory/] => ( init_arg => undef, is => 'ro' );

has workers => (
    isa => Int,
    is => 'ro',
    default => 5,
);

has [qw/
    min_servers
    min_spare_servers
    max_spare_servers
    max_servers
    max_requests
    backlog
/] => ( isa => Int, is => 'ro' );

has [qw/
    user
    group
/] => ( isa => Str, is => 'ro' );

around _plack_loader_args => sub {
    my ($orig, $self, @args) = @_;
    my %out = $self->$orig(@args);
    foreach my $key (qw/
        workers
        min_servers
        min_spare_servers
        max_spare_servers
        max_servers
        max_requests
        backlog
        user
        group
    /) {
        $out{$key} = $self->$key();
    }
    return %out;
};

sub _getopt_full_usage {
    my $self = shift;
    pod2usage( -input => pod_where({-inc => 1}, __PACKAGE__), -verbose => 2 );
    exit 0;
}

1;

=head1 NAME

CatalystX::Script::Server::Starman - Replace the development server with Starman

=head1 SYNOPSIS

    myapp_server.pl [options]

       -d --debug           force debug mode
       -f --fork            handle each request in a new process
                            (defaults to false)
       -? --help            display this help and exits
       -h --host            host (defaults to all)
       -p --port            port (defaults to 3000)
       --follow_symlinks    follow symlinks in search directories
                            (defaults to false. this is a no-op on Win32)
       --background         run the process in the background
       --pidfile            specify filename for pid file
       --workers            Initial number of workers to spawn (defaults to 5)
       --min_servers        Minimum number of worker processes runnning
       --min_spare_servers  Minimum number of spare workers (more are forked
                            if there are less spare than this)
       --max_spare_servers  Maximum number of spare workers (workers are killed
                            if there are more spare than this)
       --max_servers        Maximum number of workers in total.
       --max_requests       Maximum number of requests each worker will handle
       --backlog            Number of backlogged connections allowed
       --user               User to run as
       --group              Group to run as

     See also:
       perldoc Starman
       perldoc plackup
       perldoc Catalyst::PSGI

=head1 DESCRIPTION

A Catalyst extension to replace the development server with L<Starman>.

This module replaces the functionality of L<Catalyst::Engine::HTTP::Prefork>,
which is now deprecated.

It provides access to the prefork engine specific options which were previously
added by hacking your server script.

=head1 Adding this to your application

Just add a server script module to your application which inherits from this
package.

L<Catalyst::ScriptRunner> will automatically detect and use it when
script/myapp_server.pl is started.

For example:

    package MyApp::Script::Server;
    use Moose;
    use namespace::autoclean;

    extends 'CatalystX::Script::Server::Starman';

    1;

=head1 SEE ALSO

L<plackup> - can be used to start your application C<.psgi> under Starman

L<Catalyst::PSGI>

=head1 AUTHOR

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut

