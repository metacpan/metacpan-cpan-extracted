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

if ( AnyEvent::detect eq 'AnyEvent::Impl::Perl' ) {
    plan skip_all => "pipes are broken with AE's pure-perl implementation";
}
else {
    plan tests => 7;
}

my ( $proc, $out, $err );

SKIP: {
    my ($bin) = Env::Path->PATH->Whence('sh');
    skip "test, reason: executable 'sh' not available", 7 unless $bin;

    my $h1    = AnyEvent::Proc::reader();
    my $h1out = '';

    $proc = AnyEvent::Proc->new(
        bin    => $bin,
        args   => [ -c => "echo hi >/dev/fd/$h1" ],
        ttl    => 5,
        outstr => \$out,
        errstr => \$err,
        extras => [$h1]
    );
    $h1->pipe( \$h1out );

    $proc->finish;
    is $proc->wait() => 0, 'wait ok, status is 0';
    is $err          => '';
    is $out          => '';
    like $h1out      => qr{^hi\s+$};

    my $h2 = AnyEvent::Proc::writer();

    $proc = AnyEvent::Proc->new(
        bin    => $bin,
        args   => [ -c => "cat </dev/fd/$h2" ],
        ttl    => 5,
        outstr => \$out,
        errstr => \$err,
        extras => [$h2]
    );
    $h2->writeln('hi');
    $h2->finish;
    $proc->finish;
    is $proc->wait() => 0, 'wait ok, status is 0';
    is $err          => '';
    like $out        => qr{^hi\s+$};

}

done_testing;
