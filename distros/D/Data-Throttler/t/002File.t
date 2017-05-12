######################################################################
# Test suite for Throttler
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use Test::More;
use Data::Throttler;
use File::Temp qw(tempfile);

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

my $nof_tests = 12;

plan tests => $nof_tests;

SKIP: {
  eval 'require YAML';
  if($@) {
    skip "No YAML - skipping persistent data checks", $nof_tests;
    last;
  }

my($fh, $file) = tempfile();
unlink $file;
END { unlink $file if defined $file };

my $throttler = Data::Throttler->new(
    max_items => 2,
    interval  => 60,
    db_file   => $file,
);

is($throttler->try_push(), 1, "1st item in");
is($throttler->try_push(), 1, "2nd item in");
is($throttler->try_push(), 0, "3nd item blocked");

my $throttler2 = Data::Throttler->new(
    max_items => 999,
    interval  => 1235,
    db_file   => $file,
);

is($throttler2->try_push(), 1, "3nd item in");
is($throttler2->try_push(), 1, "4th item in");

# Reset test
my $throttler3 = Data::Throttler->new(
    max_items => 2,
    interval  => 60,
    db_file   => $file,
    reset     => 1,
);
is($throttler3->try_push(), 1, "1st item in");
is($throttler3->try_push(), 1, "2nd item in");
is($throttler3->try_push(), 0, "3rd item blocked");

# Reload test
my $throttler4 = Data::Throttler->new(
    max_items => 2,
    interval  => 60,
    db_file   => $file,
);
is($throttler4->try_push(), 0, "item blocked after reload");
is($throttler4->reset_key(), 2, "resetting key returned expected value");
is($throttler4->try_push(), 1, "item allowed after resetting key");
is($throttler4->reset_key(), 1, "resetting key returned expected value");

};
