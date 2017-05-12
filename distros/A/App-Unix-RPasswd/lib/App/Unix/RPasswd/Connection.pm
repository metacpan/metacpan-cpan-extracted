package App::Unix::RPasswd::Connection;
# This is an internal module of App::Unix::RPasswd

use feature ':5.10';
use Moo;
use Expect;

our $VERSION = '0.53';
our $AUTHOR  = 'Claudio Ramirez <nxadm@cpan.org>';

has 'user' => (
    is       => 'ro',
    #isa      => 'Str',
    required => 1,
);

has 'ssh_args' => (
    is       => 'ro',
    #isa      => 'ArrayRef[Str]',
    required => 1,
);

sub run {
    my ( $self, $server, $new_pass, $debug ) = @_;
    my $success = 0;
    my $exp = Expect->new();
    $exp->raw_pty(1);
    $exp->log_stdout(0) if !$debug;
    $exp->spawn( $self->_construct_cmd($server) )
      or warn 'Cannot change the password of '
      . $self->user
      . "\@$server: $!\n";
    $exp->expect(
        "10",
        [
            qr/password:/i => sub {
                my $exp = shift;
                $exp->send( $new_pass . "\r" );
                exp_continue;
              }
        ]
    );
    $exp->soft_close();
    $success = ( $exp->exitstatus == 0 ) ? 1 : 0;    # shell -> perl status
    if ( $success == 1 ) {
        say "Password changed on $server.";
    }
    else {
        warn "Failed to change the password on $server.\n";
    }
    return $success;
}

sub _construct_cmd {
    my ( $self, $server ) = @_;
    my @command = (
        @{ $self->ssh_args },
        $server, '/usr/bin/passwd', $self->user
    );
    return @command;
}

1;
