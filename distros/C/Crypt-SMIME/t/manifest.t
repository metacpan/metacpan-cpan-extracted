#!perl
use strict;
use warnings;
use ExtUtils::Manifest qw(fullcheck);
use Test::More tests => 2;

my ($missing, $extra) = do {
    local $ExtUtils::Manifest::Quiet = 1;
    fullcheck();
};

# Check for missing files in every case.
ok !scalar @$missing, 'No missing files that are in MANIFEST'
  or do {
      diag "No such file: $_" foreach @$missing;
  };

# Check for additional files - but not on Windows.
# See https://rt.cpan.org/Public/Bug/Display.html?id=124130
subtest 'extra files' => sub {
    if ($^O eq 'MSWin32') {
        plan skip_all => 'Not supported on Windows';
    }
    else {
        plan tests => 1;
    }

    ok !scalar @$extra, 'No extra files that aren\'t in MANIFEST'
      or do {
          diag "Not in MANIFEST: $_" foreach @$extra;
      };
};
