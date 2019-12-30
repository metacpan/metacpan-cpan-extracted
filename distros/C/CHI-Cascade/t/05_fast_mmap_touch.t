use strict;

use lib 't/lib';
use test_02_touch;

use Test::More;

use CHI;
use CHI::Cascade;

plan skip_all => 'Not installed CHI::Driver::FastMmap'
  unless eval "use CHI::Driver::FastMmap; 1";

$SIG{__DIE__} = sub {
    `{ rm -rf t/fast_mmap; } >/dev/null 2>&1`;
    $SIG{__DIE__} = 'IGNORE';
};

$SIG{TERM} = $SIG{INT} = $SIG{HUP} = sub { die "Terminated by signal " . shift };

`{ rm -rf t/fast_mmap; } >/dev/null 2>&1`;

my $cascade = CHI::Cascade->new(
    chi => CHI->new(
        driver          => 'FastMmap',
        root_dir        => 't/fast_mmap'
    )
);

test_cascade($cascade);

done_testing;

$SIG{__DIE__} eq 'IGNORE' || $SIG{__DIE__}->();
