#!perl -T

use strict;
use warnings;

#BEGIN {
#       eval "use DBD::SQLite";
#       plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 6);
#}

use Carp qw/croak/; 
use Test::More;
#use Test::More tests => 9;
#use Test::More qw/no_plan/;
use File::Basename qw/dirname/;
use DBI;
use File::Temp;
use File::Spec;

BEGIN {
    eval "use DBI";
    $@ and plan skip_all => 'DBI/mysql is required for this test';

    # have to set this to use remote database
    $ENV{ACME_QUOTEDB_REMOTE} =  'mysql';
    $ENV{ACME_QUOTEDB_DB}     =  'acme_quotedb';
    $ENV{ACME_QUOTEDB_HOST}   =  'localhost';
    $ENV{ACME_QUOTEDB_USER}   =  'acme_user';
    $ENV{ACME_QUOTEDB_PASS}   =  'acme';
}
my $database = $ENV{ACME_QUOTEDB_DB};
my $host     = $ENV{ACME_QUOTEDB_HOST};
my $user     = $ENV{ACME_QUOTEDB_USER};
my $pass     = $ENV{ACME_QUOTEDB_PASS};

# XXX these use's must happen after the BEGIN,...
use ACME::QuoteDB::LoadDB;
use ACME::QuoteDB;

eval {
  my $q = File::Spec->catfile((dirname(__FILE__),'data'), 
      'simpsons_quotes.csv'
  );

  my $load_db = ACME::QuoteDB::LoadDB->new({
                              file        => $q,
                              file_format => 'csv',
                              create_db   => 1,
                          });
};
$@ and plan skip_all => 'mysql not installed or not configured for test user';

# ok, still here? let's run some tests 
plan tests => 7;

{ # create it
  my $q = File::Spec->catfile((dirname(__FILE__),'data'), 
      'simpsons_quotes.csv'
  );

  my $load_db = ACME::QuoteDB::LoadDB->new({
                              file        => $q,
                              file_format => 'csv',
                              create_db   => 1,
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

my $dbh = DBI->connect("DBI:mysql:database=$database;host=$host",$user,$pass)
          || croak "can not connect to: $database $!";
my $count = $dbh->selectrow_hashref('SELECT COUNT(*) AS COUNT FROM quote');
is $count->{COUNT}, 29 ;

my $qc = $dbh->selectrow_hashref('SELECT COUNT(*) AS COUNT FROM quote_catg');
is $qc->{COUNT}, 29 ;




