package CPAN::Search::Lite::DBI::Query;
use base qw(CPAN::Search::Lite::DBI);
use CPAN::Search::Lite::DBI qw($tables $dbh);
our $VERSION = 0.77;

use strict;
use warnings;

package CPAN::Search::Lite::DBI::Query::reps;
use base qw(CPAN::Search::Lite::DBI::Query);
use CPAN::Search::Lite::DBI qw($dbh);

package CPAN::Search::Lite::DBI::Query::chapters;
use base qw(CPAN::Search::Lite::DBI::Query);
use CPAN::Search::Lite::DBI qw($dbh);

package CPAN::Search::Lite::DBI::Query::ppms;
use base qw(CPAN::Search::Lite::DBI::Query);
use CPAN::Search::Lite::DBI qw($dbh);

package CPAN::Search::Lite::DBI::Query::chaps;
use base qw(CPAN::Search::Lite::DBI::Query);
use CPAN::Search::Lite::DBI qw($dbh);

package CPAN::Search::Lite::DBI::Query::reqs;
use base qw(CPAN::Search::Lite::DBI::Query);
use CPAN::Search::Lite::DBI qw($dbh);

package CPAN::Search::Lite::DBI::Query::mods;
use base qw(CPAN::Search::Lite::DBI::Query);
use CPAN::Search::Lite::DBI qw($dbh);

package CPAN::Search::Lite::DBI::Query::dists;
use base qw(CPAN::Search::Lite::DBI::Query);
use CPAN::Search::Lite::DBI qw($dbh);

package CPAN::Search::Lite::DBI::Query::auths;
use base qw(CPAN::Search::Lite::DBI::Query);
use CPAN::Search::Lite::DBI qw($dbh);

package CPAN::Search::Lite::DBI::Query;

1;
