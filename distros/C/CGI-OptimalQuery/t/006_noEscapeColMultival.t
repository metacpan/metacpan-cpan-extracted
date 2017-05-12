use strict;
no warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
require "$Bin/testutil.pl";

use Test::More tests => 1;

my $errs = "";
OQ::foreachdb(sub {
  my $oq = OQ::schema(
    'select' => {
      'U_ID' => ['movie','movie.movie_id','Movie ID'],
      'TEST' => ['moviecast', "'<a href=123456></a>'", 'TEST']
    },
    'options' => {
      'CGI::OptimalQuery::InteractiveQuery' => {
        noEscapeCol => ['TEST'],
      }
    },
    'joins' => {
      'movie' => [undef, "oqtest_movie movie"],
      'moviecast' => ['movie', 'JOIN oqtest_moviecast moviecast ON (movie.movie_id = moviecast.movie_id)', undef, { new_cursor => 1 }]
    }
  );


  $oq->output();

  $errs .= "$OQ::DBTYPE invalid; " if index($OQ::BUF, '<a href=123456></a> <a href=123456></a>') == -1;
});

is($errs, '', "noEscapeColMultival");
