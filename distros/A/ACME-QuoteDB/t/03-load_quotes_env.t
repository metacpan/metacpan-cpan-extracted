#!perl -T

use strict;
use warnings;

use Carp qw/croak/;
use File::Temp;

BEGIN {
    eval "use DBD::SQLite";
    $@ and croak 'DBD::SQLite is a required dependancy';

    # give alternate path to the DB
    $ENV{ACME_QUOTEDB_PATH} = 
          File::Temp->new( UNLINK => 0,
                           EXLOCK => 0,
                           SUFFIX => '.dat',
                     );
}

use Test::More tests => 9;
use File::Basename qw/dirname/;
use File::Spec;
use DBI;
use ACME::QuoteDB;
use ACME::QuoteDB::LoadDB;

{ # prove it's not using the provided db path
  my $def_db = File::Spec->catfile( (dirname(__FILE__), '..', 'lib', 'ACME',
                            'QuoteDB', 'DB'), 'quotes.db'
               );
  if ( -e $def_db ) { 
    ok unlink $def_db;
  } 
  else {
    ok 'already gone';
  }
}

ok -z $ENV{ACME_QUOTEDB_PATH};
 
{
  my $q = File::Spec->catfile((dirname(__FILE__),'data'), 
      'simpsons_quotes.tsv.csv'
  );

  my $load_db = ACME::QuoteDB::LoadDB->new({
                              file        => $q,
                              file_format => 'tsv',
                              create_db   => 1,
                              delimiter   => "\t",
                              attribution => 'The Simpsons',
                              category    => 'Humor',
                              rating      => 6,
                              #verbose     =>1
                          });
  
  isa_ok $load_db, 'ACME::QuoteDB::LoadDB';
  $load_db->data_to_db;
  ok $load_db->success;
  is $load_db->success, 1;

   
  my $sq = ACME::QuoteDB->new;
  isa_ok $sq, 'ACME::QuoteDB';
  
  # expected attribution list from our data
  my @expected_attribution_list = (
           'Apu Nahasapemapetilon',
           'Chief Wiggum',
           'Comic Book Guy',
           'Grandpa Simpson',
           'Ralph Wiggum',
          );
  
  is( $sq->list_attr_names, join "\n", sort @expected_attribution_list);

  $load_db = undef;
}
ok ! -z $ENV{ACME_QUOTEDB_PATH};

my $dbh = DBI->connect('dbi:SQLite:dbname='.$ENV{ACME_QUOTEDB_PATH},'','');
my $count = $dbh->selectrow_hashref('SELECT COUNT(*) AS COUNT FROM quote');
is $count->{COUNT}, 29 ;




