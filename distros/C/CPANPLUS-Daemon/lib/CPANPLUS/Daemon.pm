package CPANPLUS::Daemon;

use strict;
use vars qw[$VERSION];

use IO::String;
use Params::Check               qw[check];
use POE                         qw[Component::Server::TCP];
use CPANPLUS::Shell             qw[Default];
use Locale::Maketext::Simple    Class => 'CPANPLUS', Style => 'gettext';

use base 'Object::Accessor';

local $Params::Check::VERBOSE = 1;

$VERSION = '0.02';

=pod

=head1 NAME

CPANPLUS::Daemon -- Remote CPANPLUS access

=head1 SYNOPSIS

    ### from the command line
    cpanpd -p secret                        # using defaults
    cpanpd -P 666 -u my_user -p secret      # options provided, recommended

    ### using the API
    use CPANPLUS::Daemon;
    $daemon = CPANPLUS::Daemon->new(
                            username    => 'my_user',
                            password    => 'secret',
                            port        => 666,
                        );
    $daemon->run;
    
    ### (dis)connecting to the daemon, from the default shell
    CPAN Terminal> /connect --user=my_user --pass=secret localhost 666
    ...
    CPAN Terminal> /disconnect
    
=head1 DESCRIPTION

C<CPANPLUS::Daemon> let's you run a daemon that listens on a specified 
port and can act as a remote backend to your L<CPANPLUS::Shell::Default>.

You can use the L<CPANPLUS::Shell::Default> shell to connect to the
daemon. 
Note that both sides (ie, both the server and the client) ideally 
should run the same version of the L<CPANPLUS::Shell::Default>, to 
ensure maximum compatibillity

See the L<CPANPLUS::Shell::Default> documentation on how to connect
to a remote daemon.

=head1 METHODS

=head2 $daemon = CPANPLUS::Daemon->new(password => $pass, [username => $user, port => $port]);

Creates a new C<CPANPLUS::Daemon> object, based on the following paremeters:

=over 4

=item password (required)

The password needed to connect to this server instance

=item username (optional)

The user needed to connect to this server instance. Defaults to C<cpanpd>.

=item port

The port number this server instance will listen on. Defaults to C<1337>.

=back

=cut

sub new {
    my $class = shift;
    my %hash  = @_;
    my $self  = bless {}, $class;

    my $tmpl = {
        password    => { required   => 1 },
        username    => { default    => 'cpanpd' },
        port        => { default    => 1337 },
    };        

    $self->mk_accessors( qw[conf shell], keys %$tmpl );

    $self->shell( CPANPLUS::Shell->new() );
    $self->conf(  $self->shell->backend->configure_object );


    my $args = check( $tmpl, \%hash ) or return;

    ### make sure to disable the pager ###
    $self->conf->set_program( pager => '' );

    ### store all provided opts as accessors
    $self->$_( $args->{$_} ) for keys %$tmpl;

    return $self;
}

=head2 $daemon->run( [stdout => \*OUT, stderr => \*ERR] );

This actually makes the daemon active. Note that from here on, you lose 
control of the program, and it is handed to the daemon. You can now 
only exit the program via a C<SIGINT> or another way that terminates 
the process.

You can override where the daemon sends its output by supplying the an
alternate filehandle via the C<stdout> and C<stderr> parameter

=cut

sub run {
    my $self = shift;
    my %hash = @_;

    $|++;
    ### redirect STDOUT and STDERR ###
    local *STDOUT_SAVE;
    local *STDERR_SAVE;

    open( STDOUT_SAVE, ">&STDOUT" ) or warn loc("Couldn't dup STDOUT: %1");
    open( STDERR_SAVE, ">&STDERR" ) or warn loc("Couldn't dup STDERR: %1");

    my($stdout_fh, $stderr_fh);
    my $tmpl = {
        stdout  => { default => \*STDOUT_SAVE, store => \$stdout_fh },
        stderr  => { default => \*STDERR_SAVE, store => \$stderr_fh },
    };
    
    check( $tmpl, \%hash ) or return;

    #close *STDOUT; close *STDERR;
    *STDERR = *STDOUT;

    POE::Component::Server::TCP->new(
        Alias       => "cpanpd",
        Port        => $self->port,
        ClientInput => sub {
            my ($session, $heap, $input) = @_[SESSION, HEAP, ARG0];

            my $remote_host          =  $heap->{remote_ip} .':'.
                                        $heap->{remote_port};
            my($user,$pass,$command) =  split "\0", $input;

            my $status;     # the status value to return 0 || 1
            my $msg;        # the message we'll send back
            my $locmsg;     # the message we'll print locally

            unless( $user eq $self->username and $pass eq $self->password ) {

                $status = 0;
                $msg    = loc(  "Remote command failed: Invalid password ".
                                "for user '%1'\n", $user). "\n";
                $locmsg = "[$remote_host] ". $msg;

            } else {

                ### print it now anyway, so we can see what the daemon
                ### is currently doing
                print $stdout_fh loc("[%1] Running '%2'\n",
                                        $remote_host, $command );

                $status = 1;

                ### VERSION verification for compatibility ###
                if( $command =~ /^VERSION=(.+)$/ ) {
                    my $local_ver   = $CPANPLUS::Shell::Default::VERSION;
                    my $remote_ver  = $1 || 0;

                    if( $local_ver != $remote_ver) {
                        $msg = loc("Differing shell versions detected:\n".
                                    "Local:     %1\n".
                                    "Remote:    %2\n".
                                    "Continuing is not advised, do so at your ".
                                    "own risk", $local_ver, $remote_ver);

                        $locmsg =  loc( '[%1] Differing version detected'.
                                        '. remote: %1 local %2',
                                        $remote_host, $remote_ver,
                                        $local_ver ). "\n";
                    } else {
                        $msg =      loc("Connection accepted" );
                        $locmsg =   loc('[%1] Connection accepted',
                                        $remote_host ). "\n";
                    }

                ### normal command ###
                } else {
                    tie *STDOUT, 'IO::String';
                    $self->shell->dispatch_on_input( input => $command );

                    seek( STDOUT, 0, 0 );

                    $msg .= join "", <STDOUT>;
                }
            }

            ### print the local message, send back and answer + status
            print $stdout_fh $locmsg;
            $heap->{client}->put( $status ."\0". $msg);
        }
    );

    print $stdout_fh loc("Starting '%1' on port %2...", 'cpanpd', $self->port ).$/;

    $poe_kernel->run;

    print $stdout_fh loc("Exiting '%1'...", 'cpanpd').$/;
    exit 0;
}

1;

=head1 AUTHOR

This module by Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

This module is copyright (c) 2005 Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software; you may redistribute and/or modify it 
under the same terms as Perl itself.

=cut

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
