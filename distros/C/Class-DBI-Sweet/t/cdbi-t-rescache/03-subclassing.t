use strict;
use Test::More;
use Class::DBI::Sweet;
Class::DBI::Sweet->default_search_attributes({ use_resultset_cache => 1 });
Class::DBI::Sweet->cache(Cache::MemoryCache->new(
    { namespace => "SweetTest", default_expires_in => 60 } ) ); 

#----------------------------------------------------------------------
# Make sure subclasses can be themselves subclassed
#----------------------------------------------------------------------

BEGIN {
	eval "use Cache::MemoryCache";
	plan skip_all => "needs Cache::Cache for testing" if $@;
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 6);
}

use lib 't/cdbi-t/testlib';
use Film;

INIT { @Film::Threat::ISA = qw/Film/; }

ok(Film::Threat->db_Main->ping, 'subclass db_Main()');
is_deeply [ sort Film::Threat->columns ], [ sort Film->columns ],
	'has the same columns';

my $bt = Film->create_test_film;
ok my $btaste = Film::Threat->retrieve('Bad Taste'), "subclass retrieve";
isa_ok $btaste => "Film::Threat";
isa_ok $btaste => "Film";
is $btaste->Title, 'Bad Taste', 'subclass get()';
