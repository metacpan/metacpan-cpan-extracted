use strict;
no warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
require "$Bin/testutil.pl";

use Test::More tests => 1;

my $errs = "";
OQ::foreachdb(sub {

  my $s = OQ::schema(
    'select' => {
      'U_ID' => ['movie','movie.movie_id','Movie ID'],
      'NAME' => ['movie', 'movie.name', 'Name']
    },
    'joins' => {
      'movie' => [undef, "oqtest_movie movie"]
    }
  );

  $s->output();

  $errs .= "$OQ::DBTYPE failed" unless $OQ::BUF =~ /Return\ of\ the\ Jedi/s;
});
is($errs, '', 'simple usage');
