use strict;
use warnings;
use Test2::V0;
use JSON::XS;
use App::JsonLogUtils qw(lines json_cut);

my @log = (
  {a => 1, b => 2, c => 3},
  {a => 1, b => 2, c => 3},
  {a => 1, b => 2, c => 3},
);

my $log = join "\n", map{ encode_json $_ } @log;

subtest basics => sub{
  open my $fh, '<', \$log or die $!;
  my $cut = json_cut 'a c', 0, lines $fh;

  my @expected = (
    {a => 1, c => 3},
    {a => 1, c => 3},
    {a => 1, c => 3},
  );

  foreach (@expected) {
    is <$cut>, $_, 'expected results';
  }

  is <$cut>, U, 'exhausted';
};

subtest inverse => sub{
  open my $fh, '<', \$log or die $!;
  my $cut = json_cut 'b', 1, lines $fh;

  my @expected = (
    {a => 1, c => 3},
    {a => 1, c => 3},
    {a => 1, c => 3},
  );

  foreach (@expected) {
    is <$cut>, $_, 'expected results';
  }

  is <$cut>, U, 'exhausted';
};

done_testing;
