use strict;

use lib 't/lib';
use test_01_actual_term;

use Test::More;

use CHI;
use CHI::Cascade;

plan skip_all => 'Not installed CHI::Driver::File'
  unless eval "use CHI::Driver::File; 1";

plan tests => 32;

$SIG{__DIE__} = sub {
    `{ rm -rf t/file_cache; } >/dev/null 2>&1`;
    $SIG{__DIE__} = 'IGNORE';
};

`{ rm -rf t/file_cache; } >/dev/null 2>&1`;

my $cascade = CHI::Cascade->new(
    chi => CHI->new(
	driver		=> 'File',
	root_dir	=> 't/file_cache'
    )
);

test_cascade($cascade);

$SIG{__DIE__} eq 'IGNORE' || $SIG{__DIE__}->();
