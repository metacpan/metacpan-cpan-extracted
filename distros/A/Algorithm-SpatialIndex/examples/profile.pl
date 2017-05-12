use strict;
use warnings;
use lib 'lib';
use Algorithm::SpatialIndex;

my $what = lc(shift(@ARGV)||'poll');
my $bucks = 50;
my $scale = 2;
my @limits = qw(-10 -10 10 10);

my $use_dbi = 1;
if ($use_dbi) {
  eval "use DBI; use DBD::SQLite;";
  unlink 't.sqlite';
  $use_dbi = DBI->connect("dbi:SQLite:dbname=t.sqlite", "", "");
}

my @si_opt = (
  strategy => 'QuadTree',
  storage  => $use_dbi ? 'DBI' : 'Memory',
  limit_x_low => $limits[0],
  limit_y_low => $limits[1],
  limit_x_up  => $limits[2],
  limit_y_up  => $limits[3],
  bucket_size => $bucks,
  dbh_rw => $use_dbi,
);

my $idx;

if ($what eq 'insert') {
  DB::enable_profile();
}
my $iter = 0;
do {
  $idx = Algorithm::SpatialIndex->new(@si_opt);
  my $i = 0;
  foreach my $x (map {$_/$scale} $limits[0]*$scale..$limits[2]*$scale) {
    foreach my $y (map {$_/$scale} $limits[1]*$scale..$limits[3]*$scale) {
      $idx->insert($i, $x, $y);
      $i++;
    }
  }
  warn $i;
  $iter++;
} while ($what eq 'insert' and $iter < 2);

if ($what eq 'insert') {
  DB::disable_profile();
}
else {
  DB::enable_profile();
}
if ($what eq 'poll') {
  my @rect_small = (-1.5, -1.4, -1.51, -1.41);
  foreach my $i (1..40000) {
    warn $i if $i%1000 == 0;
    my @o = $idx->get_items_in_rect(@rect_small);
  }
}
