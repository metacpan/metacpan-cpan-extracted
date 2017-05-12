use warnings;
use strict;

use DBIx::Class::Schema::PopulateMore;
use Test::More tests => 16;

diag( "Testing DBIx::Class::Schema::PopulateMore $DBIx::Class::Schema::PopulateMore::VERSION, Perl $], $^X" );
use_ok( 'DBIx::Class::Schema::PopulateMore' );
use_ok( 'DBIx::Class::Schema::PopulateMore::Command' );    
use_ok( 'DBIx::Class::Schema::PopulateMore::Inflator' );
use_ok( 'DBIx::Class::Schema::PopulateMore::Visitor' );
use_ok( 'DBIx::Class::Schema::PopulateMore::Inflator::Index' );    
use_ok( 'DBIx::Class::Schema::PopulateMore::Inflator::Date' );
use_ok( 'DBIx::Class::Schema::PopulateMore::Inflator::Env' );
use_ok( 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result' );
use_ok( 'DBIx::Class::Schema::PopulateMore::Test::Schema::ResultSet' );
use_ok( 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Gender' );
use_ok( 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Person' );
use_ok( 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::FriendList' );
use_ok( 'DBIx::Class::Schema::PopulateMore::Test::Schema::ResultSet::Person' );    
use_ok( 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Company' );
use_ok( 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::CompanyPerson' );    
use_ok( 'DBIx::Class::Schema::PopulateMore::Test::Schema' );

