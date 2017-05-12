##############################################################
package AOLserver::CtrlPort;
##############################################################

use 5.006;
use strict;
use warnings;

use Net::Telnet;
use Log::Log4perl qw(:easy);

our $VERSION    = '0.02';
our $CVSVERSION = '$Revision: 1.3 $';

=head1 NAME

AOLserver::CtrlPort - Execute Commands on AOLserver's Control Port

=head1 SYNOPSIS

    use AOLserver::CtrlPort;

    my $conn = AOLserver::CtrlPort->new(
        Host     => 'myhost',
        Port     => 3456,
        User     => 'username',
        Password => 'password',
    );

    my $out = $conn->send_cmds(<<EOT);
        info tclversion
    EOT

    print $out, "\n";

=head1 DESCRIPTION

C<AOLserver::CtrlPort> uses C<Net::Telnet> to connect to a running
AOLserver's control port, issues commands there and returns the 
output.

It is useful for creating test suites for AOLserver applications which
can be controlled via the control port. 

To configure AOLserver's control port, use settings similar to the following
ones:

    ns_section "ns/server/${servername}/module/nscp"
        ns_param address myhostname
        ns_param port 3334
        ns_param echopassword 1
        ns_param cpcmdlogging 1

    ns_section "ns/server/${servername}/module/nscp/users"
        ns_param user "username:3G5/H31peci.o:"
                           # That's "username:password"

    ns_section "ns/server/${servername}/modules"
        ns_param nscp ${bindir}/nscp.so

This lets AOLserver enable the control port on server C<myhostname> on port
3334. Authentication is on, the username is C<username> and the
password is C<password> (hashed to C<3G5/H31peci.o> with a program
like C<htpasswd>).

=head2 METHODS

=over 4

=item AOLserver::CtrlPort-E<gt>new(...)

Creates a new control port client object. The following options
are available to the constructor:

=over 4

=item Port

The port AOLserver is listening to for control port commands.

=item Host

The control port C<address> as defined in the configuration.

=item Timeout

Number of seconds after which the client will time out if the
server doesn't send a response.

=item User

User name for control port login defaults to the empty string
for non-protected control ports.

=item Password

Password for control port login defaults to the empty string
for non-protected control ports.

=back

=cut

############################################################
sub new {
############################################################
    my ($class, @options) = @_;

    my %options = (
        Timeout         => 10,
        #Port            => '3456',
        Host            => 'localhost',
        Prompt          => '/> $/',
        User            => '',
        Password        => '',
        @options);

    my $user   = $options{User};
    my $passwd = $options{Password};

    delete $options{User};
    delete $options{Password};

    my $t = Net::Telnet->new(%options);

    DEBUG("Connecting to port=$options{Host}:$options{Port}");
    $t->open();

    my $self = { telnet => $t,
               };

    $t->login("", "");

    DEBUG("Waiting for prompt");
    $t->waitfor();

    bless $self, $class;
}

=item $conn->send_cmds("$cmd1\ncmd2\n...")

Send one or more commands, separated by newlines, AOLserver's
control port. The method will return the server's response as a string.
Typically, this will look like

    $out = $conn->send_cmds(<<EOT);
        info tclversion
        info commands
    EOT

and return the newline-separated response as a single string.

=cut

############################################################
sub send_cmds {
############################################################
    my ($self, $lines) = @_;

    my $output = "";
    my $line_output;

    for (split "\n", $lines) {
        DEBUG("Send: [$_]");
        $line_output = join "", $self->{telnet}->cmd("$_");
        # Last line is the prompt, scrap it
        $line_output =~ s/^.*\Z//m;
        DEBUG("Recv: [$line_output]");
        $output .= $line_output;
    }

    return $output;
}

1;

=back

=head1 Debugging

AOLserver::CtrlPort is Log4perl enabled. If your scripts don't do 
what you want and you need to find out which messages are being sent
back and forth, you can easily bump up AOLserver::CtrlPort's
internal debugging level by saying something like

    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);

in your test script before any AOLserver::CtrlPort commands are called.

Please check out the Log::Log4perl documentation for details.

=head1 AUTHOR

Mike Schilli, 2004, m@perlmeister.com

=cut
