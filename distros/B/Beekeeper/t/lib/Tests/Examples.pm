package Tests::Examples;

use strict;
use warnings;

use Test::Class;
use Test::More;
use base 'Test::Class';

use AnyEvent;
use AnyEvent::Handle;
use IPC::Open3;

my $VERBOSE = $ENV{'HARNESS_IS_VERBOSE'};


sub run_cmd {
    my ($self, @cmds) = @_;

    my ($chld_in, $chld_out);
    open3($chld_in, $chld_out, 0, '/bin/bash');

    my $test_end = AnyEvent->condvar;
    my $output = '';

    my $stdin; $stdin = AnyEvent::Handle->new(
        fh => $chld_in,
        on_error => $test_end,
    );

    my $stdout; $stdout = AnyEvent::Handle->new(
        fh => $chld_out,
        on_error => $test_end,
        on_read => sub {
            $VERBOSE && diag $stdout->{rbuf};
            $output .= $stdout->{rbuf};
            $stdout->{rbuf} = '';
            $test_end->send if $output =~ s/### TEST_END ###\n$//s;
        },
    );

    push @cmds, 'echo -e "### TEST_END ###"';

    foreach my $cmd (@cmds) {

        if ($cmd =~ m/^await (\d+)$/s) {
            $self->async_wait($1);
            next;
        }

        $stdin->push_write("$cmd\n");
    }

    $test_end->recv;

    return $output;
}

sub async_wait {
    my ($self, $time) = @_;
    my $cv = AnyEvent->condvar; 
    my $tmr = AnyEvent->timer( after => $time, cb => $cv ); 
    $cv->recv;
}


sub check_01_supported_os : Test(startup => 1) {
    my ($self) =  @_;

    unless ($^O eq 'linux') {
        $self->BAILOUT("OS unsupported");
    }

    ok( 1, "Supported OS ($^O)");
}

sub check_02_author_testing : Test(startup => 1) {
    my ($self) =  @_;

    unless ($ENV{'AUTHOR_TESTING'}) {
        # Fiddling with shell stdin/stdout makes test fail when run by cpanm or dzil
        $self->SKIP_ALL("This test fails when run by cpanm or dzil");
    }

    ok( 1, "Author testing");
}

sub check_03_dzil_release_testing : Test(startup => 1) {
    my ($self) =  @_;

    if ($ENV{'RELEASE_TESTING'}) {
        # But 'dzil test' pass just fine
        $self->SKIP_ALL("This test fails when run by 'dzil release'");
    }

    ok( 1, "Not dzil release testing");
}

sub test_01_example_basic : Test(1) {
    my ($self) =  @_;

    my $output = $self->run_cmd(
        'cd examples/basic',
        'source setup.sh',
        './run.sh',
        'await 2',
        './client.pl',
        './run.sh stop',
    );

    my $expected = quotemeta qq{
    Using configs from  .../examples/basic/config
    Using modules from  .../examples/basic/lib:.../lib
    Using commands from .../bin
    Starting pool of MyApp workers: beekeeper-myapp.
    HELLO!
    Stopping pool of MyApp workers: beekeeper-myapp.
    };

    $expected =~ s/^\\\n//;
    $expected =~ s/\\\n/\\n\n/g;
    $expected =~ s/^(\\ )+/\\s*/mg;
    $expected =~ s/(\\\.){3}/.*?/g;

    like( $output, qr/$expected/x, "basic example output");
}

sub test_02_example_flood : Test(1) {
    my ($self) =  @_;

    my $output = $self->run_cmd(
        'cd examples/flood',
        'source setup.sh',
        './run.sh',
        'await 2',
        './flood.pl -b',
        './run.sh stop',
    );

    my $expected = quotemeta qq{
    Using configs from  .../examples/flood/config
    Using modules from  .../examples/flood/lib:/.../lib
    Using commands from .../bin
    Starting pool of MyApp workers: beekeeper-myapp.

    1000 notifications   of   0 Kb  in ... each
    1000 notifications   of   1 Kb  in ... each
    1000 notifications   of   5 Kb  in ... each
    1000 notifications   of  10 Kb  in ... each

    1000 sync calls      of   0 Kb  in ... each
    1000 sync calls      of   1 Kb  in ... each
    1000 sync calls      of   5 Kb  in ... each
    1000 sync calls      of  10 Kb  in ... each

    1000 async calls     of   0 Kb  in ... each
    1000 async calls     of   1 Kb  in ... each
    1000 async calls     of   5 Kb  in ... each
    1000 async calls     of  10 Kb  in ... each

    1000 fire & forget   of   0 Kb  in ... each
    1000 fire & forget   of   1 Kb  in ... each
    1000 fire & forget   of   5 Kb  in ... each
    1000 fire & forget   of  10 Kb  in ... each

    Stopping pool of MyApp workers: beekeeper-myapp.
    };

    $expected =~ s/^\\\n//;
    $expected =~ s/\\\n/\\n\n/g;
    $expected =~ s/^(\\ )+/\\s*/mg;
    $expected =~ s/(\\\.){3}/.*?/g;

    like( $output, qr/$expected/x, "flood example output");
}

sub test_03_example_scraper : Test(1) {
    my ($self) =  @_;

    my $output = $self->run_cmd(
        'cd examples/scraper',
        'source setup.sh',
        './run.sh',
        'await 2',
        './client.pl --async  https://google.com  not-an-url',
        './run.sh stop',
    );

    my $expected = quotemeta qq{
    Using configs from  .../examples/scraper/config
    Using modules from  .../examples/scraper/lib:/.../lib
    Using commands from .../bin
    Starting pool of MyApp workers: beekeeper-myapp.

    not-an-url
    -32602 Invalid url

    https://google.com
    "..."
    Stopping pool of MyApp workers: beekeeper-myapp.
    };

    $expected =~ s/^\\\n//;
    $expected =~ s/\\\n/\\n\n/g;
    $expected =~ s/^(\\ )+/\\s*/mg;
    $expected =~ s/(\\\.){3}/.*?/g;

    like( $output, qr/$expected/x, "scraper example output");
}

sub test_04_example_websocket : Test(1) {
    my ($self) =  @_;

    my $output = $self->run_cmd(
        'cd examples/websocket',
        'source setup.sh',
        './run.sh',
        'await 2',
        './client.pl',
        'await 1',
        '2 + 2',
        'hello',
        '10 / 0',
        'quit',
        'await 1',
        './run.sh stop',
    );

    my $expected = quotemeta qq{
    Using configs from  .../examples/websocket/config
    Using modules from  .../examples/websocket/lib:/.../lib
    Using commands from .../bin
    Starting pool of MyApp workers: beekeeper-myapp.
    > = 4
    > ERR: Call to 'myapp.calculator.eval_expr' failed: -32603 Invalid expression at .../MyApp/Service/Calculator.pm line ...
    > ERR: Call to 'myapp.calculator.eval_expr' failed: -32000 Server error at .../MyApp/Service/Calculator.pm line ...
    > Stopping pool of MyApp workers: beekeeper-myapp.
    };

    $expected =~ s/^\\\n//;
    $expected =~ s/\\\n/\\n\n/g;
    $expected =~ s/^(\\ )+/\\s*/mg;
    $expected =~ s/(\\\.){3}/.*?/g;

    like( $output, qr/$expected/x, "websocket example output");
}

sub test_05_example_chat : Test(1) {
    my ($self) =  @_;

    my $output = $self->run_cmd(
        'cd examples/chat',
        'source setup.sh',
        './run.sh',
        'await 4',
        './chat.pl --test',
        'await 1',
        './run.sh stop',
    );

    my $expected = quotemeta qq{
    Using configs from  .../examples/chat/config
    Using modules from  .../examples/chat/lib:/.../lib
    Using commands from .../bin
    Starting ToyBroker: beekeeper-myapp-broker.
    Starting pool #1 of MyApp workers: beekeeper-myapp-A.
    Starting pool #2 of MyApp workers: beekeeper-myapp-B.
    Available commands:
      /login username pass   Login
      /pm username message   Send private message
      /logout                End user session
      /kick user             End another user session
      /ping                  Measure latency
      /quit                  Exit (or use Ctrl-C)
    > Welcome Dave
    > Dave: Public message
    > Dave: Private message
    > Bye!
    > Welcome Zoe
    > Zoe: Hello
    > Ping: ... ms
    > Sorry, you were kicked
    Stopping pool #1 of MyApp workers: beekeeper-myapp-A.
    Stopping pool #2 of MyApp workers: beekeeper-myapp-B.
    Stopping ToyBroker: beekeeper-myapp-broker.
    };

    $expected =~ s/^\\\n//;
    $expected =~ s/\\\n/\\n\n/g;
    $expected =~ s/^(\\ )+/\\s*/mg;
    $expected =~ s/(\\\.){3}/.*?/g;

    like( $output, qr/$expected/x, "chat example output");
}

1;
