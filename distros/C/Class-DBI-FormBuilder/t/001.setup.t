#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 1;

BEGIN { unlink 'test.db' };

use Class::DBI::FormBuilder::DBI::Test;

Class::DBI::FormBuilder::DBI::Test->db_Main->do("CREATE TABLE person (
    id integer not null primary key,
    name varchar(255),
    town integer,
    street varchar(255)        
);");

Class::DBI::FormBuilder::DBI::Test->db_Main->do("CREATE TABLE town (
    id integer not null primary key,
    name varchar,
    pop integer,
    lat numeric,
    long numeric,
    country text
);");

Class::DBI::FormBuilder::DBI::Test->db_Main->do("CREATE TABLE toy (
    id integer not null primary key,
    name varchar,
    person integer,
    descr text
);");

# id person jobtitle employer salary
Class::DBI::FormBuilder::DBI::Test->db_Main->do("CREATE TABLE job (
    id integer not null primary key,
    person integer,
    jobtitle text,
    employer text,
    salary integer
);");

# 
Class::DBI::FormBuilder::DBI::Test->db_Main->do("CREATE TABLE wackypk (
    wooble integer not null primary key,
    flooble integer,
    flump text,
    poo text
);");

Class::DBI::FormBuilder::DBI::Test->db_Main->do("CREATE TABLE alias (
    id integer not null primary key,
    colour text,
    fruit text,
    town integer
);");

Class::DBI::FormBuilder::DBI::Test->db_Main->do("CREATE TABLE alias_has_many (
    id integer not null primary key,
    alias integer,
    foo text
);");


my @towns = ( [ qw( Trumpton 250 150.7 160.8 PlayLand ) ],      # 1
              [ qw( Uglyton  1000000 10.2 8.3 Yuckland ) ],     # 2
              [ qw( Toonton  500 100.5 200.9 Cartoonland ) ],   # 3
              [ qw( London   6000000 310.4 431 2 England ) ],   # 4
              );

foreach my $town ( @towns )
{
    my %data;
    @data{ qw( name pop lat long country ) } = @$town;
    #use Data::Dumper;
    #warn Dumper( \%data );
    Town->create( \%data );
}

CDBIFB::Alias->create( { colour => 'green', 
                 fruit  => 'apple',
                 town   => 1,
                 } ); 
CDBIFB::Alias->create( { colour => 'yellow', 
                 fruit  => 'banana',
                 town   => 2,
                 } ); 
                 
AliasHasMany->create( { foo => 'bar',
                        alias => 1,
                        } );

AliasHasMany->create( { foo => 'boor',
                        alias => 1,
                        } );

ok(1);


# ----------------------------------------------------------------------------------

__END__

$VAR1 = {
          'might_have' => {
                            'job' => bless( {
                                              'foreign_class' => 'Job',
                                              'name' => 'might_have',
                                              'args' => {
                                                          'import' => [
                                                                        'jobtitle',
                                                                        'employer',
                                                                        'salary'
                                                                      ]
                                                        },
                                              'class' => 'Person',
                                              'accessor' => 'job'
                                            }, 'Class::DBI::Relationship::MightHave' )
                          },
          'has_a' => {
                       'town' => bless( {
                                          'foreign_class' => 'Town',
                                          'name' => 'has_a',
                                          'args' => {},
                                          'class' => 'Person',
                                          'accessor' => bless( {
                                                                 '_groups' => {
                                                                                'All' => 1
                                                                              },
                                                                 'name' => 'town',
                                                                 'mutator' => 'town',
                                                                 'placeholder' => '?',
                                                                 'accessor' => 'town'
                                                               }, 'Class::DBI::Column' )
                                        }, 'Class::DBI::Relationship::HasA' )
                     },
          'has_many' => {
                          'toys' => bless( {
                                             'foreign_class' => 'CDBIFB::Toy',
                                             'name' => 'has_many',
                                             'args' => {
                                                         'mapping' => [],
                                                         'foreign_key' => 'person',
                                                         'order_by' => undef
                                                       },
                                             'class' => 'Person',
                                             'accessor' => 'toys'
                                           }, 'Class::DBI::Relationship::HasMany' )
                        }
        };
