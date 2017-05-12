# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Biblio-Thesaurus-SQLite.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 8;

####################  1 #########################
BEGIN { use_ok('Biblio::Thesaurus::SQLite') };
#################################################

####################  2 #########################
use Biblio::Thesaurus::SQLite;

ok(Biblio::Thesaurus::SQLite::TheSql2ISOthe('t/db_simple', 't/out'));
##################################################

####################  3 #########################
ok(Biblio::Thesaurus::SQLite::ISOthe2TheSql('t/out', 't/out_db'));
##################################################

####################  4 #########################
ok(Biblio::Thesaurus::SQLite::getTermAsXHTML('ovo', 't/out_db'));
##################################################

####################  5 #########################
ok(Biblio::Thesaurus::SQLite::getTermAsPerl('ovo', 't/out_db'));
##################################################

####################  6 #########################
ok(Biblio::Thesaurus::SQLite::setTerm('ovo', 'BT', 'galinha', 't/out_db'));
##################################################

####################  7 #########################
ok(Biblio::Thesaurus::SQLite::changeTerm(
	'ovo', 'BT', 'galinha', 'NT', 'pito', 't/out_db'));
##################################################

####################  8 #########################
ok(Biblio::Thesaurus::SQLite::deleteTerm('ovo', 'BT', 'galinha', 't/out_db'));
##################################################

