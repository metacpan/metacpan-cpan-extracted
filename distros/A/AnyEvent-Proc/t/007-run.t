#!perl

#BEGIN { $ENV{LC_ALL} = 'C' }

use Test::Most;
use AnyEvent;
use AnyEvent::Proc qw(run run_cb);
use Env::Path;

BEGIN {
    delete @ENV{qw{ LANG LANGUAGE }};
    $ENV{LC_ALL} = 'C';
}

plan tests => 6;

my ( $out, $err );

SKIP: {
    my ($bin) = Env::Path->PATH->Whence('echo');
    skip "test, reason: executable 'echo' not available", 1 unless $bin;
    $out = run( $bin => $$ );
    like $out => qr{^$$\s*$}, 'stdout is my pid';
}

SKIP: {
    my ($bin) = Env::Path->PATH->Whence('cat');
    skip "test, reason: executable 'cat' not available", 2 unless $bin;
    ( $out, $err ) = run( $bin => 'THISFILEDOESNOTEXISTSATALL' );
    like $out => qr{^\s*$}, 'stdout is empty';
    like $err => qr{^.*no such file or directory\s*$}i,
      'stderr hat error message';
}

SKIP: {
    my ($bin) = Env::Path->PATH->Whence('false');
    skip "test, reason: executable 'false' not available", 1 unless $bin;
    run($bin);
    is $?>> 8 => 1,
      'exit code is properly saved in $?';
}

SKIP: {
    my ($bin) = Env::Path->PATH->Whence('echo');
    skip "test, reason: executable 'echo' not available", 1 unless $bin;
    my $cv = AE::cv;
    run_cb(
        $bin => $$,
        sub {
            is $?>> 8 => 0, 'exit code is properly saved in $?';
            $cv->send(@_);
        }
    );
    my ($out) = $cv->recv;
    like $out => qr{^$$\s*$}, 'run_cb works as expected';
}

done_testing;
