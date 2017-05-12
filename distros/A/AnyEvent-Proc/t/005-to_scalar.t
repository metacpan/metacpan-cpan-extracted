#!perl

use Test::Most;
use AnyEvent::Proc;
use Env::Path;

BEGIN {
    delete @ENV{qw{ LANG LANGUAGE }};
    $ENV{LC_ALL} = 'C';
}

plan tests => 6;

SKIP: {
    my ($bin) = Env::Path->PATH->Whence('cat');
    skip "test, reason: executable 'cat' not available", 6 unless $bin;

    my ( $proc, $out, $err );

    $out = '';
    $err = '';

    $proc = AnyEvent::Proc->new(
        bin    => $bin,
        ttl    => 5,
        outstr => \$out,
        errstr => \$err
    );
    $proc->writeln($$);
    $proc->finish;
    is $proc->wait() => 0,           'wait ok, status is 0';
    like $out        => qr{^$$\s*$}, 'stdout is my pid';
    like $err        => qr{^\s*$},   'stderr is empty';

    $out = '';
    $err = '';

    $proc = AnyEvent::Proc->new(
        bin    => $bin,
        args   => [qw[ THISFILEDOESNOTEXISTSATALL ]],
        ttl    => 5,
        outstr => \$out,
        errstr => \$err
    );
    $proc->finish;
    isnt $proc->wait() => 0,         'wait ok, status isnt 0';
    like $out          => qr{^\s*$}, 'stdout is empty';
    like $err => qr{^.*no such file or directory\s*$}i,
      'stderr hat error message';
}

done_testing;
