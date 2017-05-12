#!perl

use Test::Most;
use AnyEvent;
use AnyEvent::Proc;
use IO::Pipe;
use Env::Path;

BEGIN {
    delete @ENV{qw{ LANG LANGUAGE }};
    $ENV{LC_ALL} = 'C';
}

sub sync_read {
    my $h   = shift;
    my $buf = \( my $str = '' );
    my $cv  = AE::cv;
    $h->on_eof(
        sub {
            $cv->send($$buf);
        }
    );
    $h->on_error(
        sub {
            diag "error $h: $_[2]";
            $cv->send($$buf);
        }
    );
    $h->on_read(
        sub {
            $$buf .= $_[0]->rbuf;
            $_[0]->rbuf = '';
        }
    );
    $cv;
}

if ( AnyEvent::detect eq 'AnyEvent::Impl::Perl' ) {
    plan skip_all => "pipes are broken with AE's pure-perl implementation";
}
else {
    plan tests => 6;
}

my ( $proc, $R, $W, $cv );

SKIP: {
    my ($bin) = Env::Path->PATH->Whence('cat');
    skip "test, reason: executable 'cat' not available", 6 unless $bin;

    ( $R, $W ) = AnyEvent::Proc::_wpipe;
    $cv = sync_read($R);

    $proc = AnyEvent::Proc->new( bin => $bin, ttl => 5 );
    $proc->pipe($W);
    $proc->writeln($$);
    $proc->finish;
    is $proc->wait() => 0, 'wait ok, status is 0';
    close $W;
    like $cv->recv => qr{^$$\s*$}, 'rbuf contains my pid';

    ( $R, $W ) = AnyEvent::Proc::_rpipe;

    $proc = AnyEvent::Proc->new( bin => $bin, ttl => 5 );
    $proc->pipe($W);
    $proc->writeln($$);
    $proc->finish;
    is $proc->wait() => 0, 'wait ok, status is 0';
    $W->destroy;
    like <$R> => qr{^$$\s*$}, 'buf contains my pid';

    ( $R, $W ) = @{ *{ IO::Pipe->new } };

    $proc = AnyEvent::Proc->new( bin => $bin, ttl => 5 );
    $proc->pipe($W);
    $proc->writeln($$);
    $proc->finish;
    is $proc->wait() => 0, 'wait ok, status is 0';
    close $W;
    like <$R> => qr{^$$\s*$}, 'buf contains my pid';
}

done_testing;
