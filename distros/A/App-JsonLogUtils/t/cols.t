use strict;
use warnings;
use Test2::V0;
use JSON::XS;
use App::JsonLogUtils qw(lines json_cols);

my @log = (
  {a => 1, b => 2, c => 3},
  {a => 1, b => 2, c => 3},
  {a => 1, b => 2, c => 3},
);

my $log = join "\n", map{ encode_json $_ } @log;

open my $fh, '<', \$log or die $!;

my $cols = json_cols 'a c', '|', lines $fh;

my @expected = (
  'a|c',
  '1|3',
  '1|3',
  '1|3',
);

foreach (@expected) {
  is <$cols>, $_, 'expected results';
}

is <$cols>, U, 'exhausted';

done_testing;
