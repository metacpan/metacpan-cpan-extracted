
BEGIN {
	print "1..7\n";
}

use DBIx::FullTextSearch;

BEGIN { print "ok 1\n"; }

use DBIx::FullTextSearch::Blob;

BEGIN { print "ok 2\n"; }

use DBIx::FullTextSearch::Column;

BEGIN { print "ok 3\n"; }

use DBIx::FullTextSearch::String;

BEGIN { print "ok 4\n"; }

use DBIx::FullTextSearch::File;

BEGIN { print "ok 5\n"; }

use DBIx::FullTextSearch::URL;

BEGIN { print "ok 6\n"; }

use DBIx::FullTextSearch::Phrase;

BEGIN { print "ok 7\n"; }

