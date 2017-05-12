use strict;

use Test::More tests => 7;

use AnyEvent;
use AnyEvent::Run;
use File::Spec::Functions;
use FindBin qw($Bin);

use lib catfile($Bin, 'lib');

run( 
    name => 'string cmd',
    cmd  => 'echo test',
);

run(
    name     => 'arrayref cmd',
    cmd      => [ 'echo', 'test' ],
    priority => 19,
);

run(
    name => 'arrayref cmd + args',
    cmd  => [ 'echo' ],
    args => [ 'test' ],
);

run(
    name  => 'stdin',
    cmd   => [ $^X, catfile($Bin, 'echo.plt') ],
    stdin => 1,
);

run(
    name => 'coderef',
    cmd  => sub { print "test\n" },
);

run(
    name     => 'exec class',
    class    => 'AERunTest',
    priority => 19,
);

run(
    name   => 'exec class + method',
    class  => 'AERunTest',
    method => 'stdin',
    stdin  => 1,
);

sub run {
    my %args = @_;
    
    my $testname = delete $args{name};
    my $stdin    = delete $args{stdin};
    
    my $cv = AnyEvent->condvar;

    my $handle = AnyEvent::Run->new(
        %args,
        on_read => sub {
            my $handle = shift;
            like( $handle->{rbuf}, qr/test(\r)?\n/, "$testname ok" );
            $cv->send;
        },
        on_error => sub {
            my ($handle, $fatal, $msg) = @_;
            fail($msg);
            $cv->send;
        },
    );
    
    # Timeout in case of error
    my $w = AnyEvent->timer( after => 2, cb => sub {
        fail("$testname timed out");
        $cv->send;
    } );
    
    if ( $stdin ) {
        $handle->push_write("test\n");
    }

    $cv->recv;
}

