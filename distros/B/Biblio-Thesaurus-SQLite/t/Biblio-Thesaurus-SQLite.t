# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Biblio-Thesaurus-SQLite.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 2;

####################  1 #########################
BEGIN { use_ok('Biblio::Thesaurus::SQLite') };
#################################################

####################  2 #########################
use Biblio::Thesaurus::SQLite;

Biblio::Thesaurus::SQLite::TheSql2ISOthe('t/db_simple', 't/out');
open(F, '<t/out') or die;
my $data = join('', <F>);
close(F);

is($data, "\n\n12 direito\nNT 1211 direito civil\n\n\n1211 direito civil\nBT 12 direito\n", '  TheSQL2ISOthe\n');
##################################################
