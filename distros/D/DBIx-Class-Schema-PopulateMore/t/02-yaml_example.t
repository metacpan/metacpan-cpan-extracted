use warnings;
use strict;

use Test::More tests => 31;
use DBIx::Class::Schema::PopulateMore::Test::Schema;
use YAML::Tiny;

## This is just a quick example to show what this might look like if you
## loaded from an external file, like yaml.  It's evil cut 'n paste from
## the standard test.

ok my $schema = DBIx::Class::Schema::PopulateMore::Test::Schema->connect_and_setup
=> 'Got a schema';

diag "Created Datebase with @{$schema->storage->connect_info}[0]";

ok $schema->can('populate_more')
=> 'schema has required method';

ok my @sources = sort($schema->sources)
=> 'got some sources';

is_deeply \@sources, [qw/
    Company CompanyPerson
    EmploymentHistory FriendList 
    Gender Person/]
=> 'Got expected sources';

my $string = join('', <DATA>);

ok my $yaml = YAML::Tiny->read_string( $string )
=> 'loaded yaml config';

ok my %index = $schema->populate_more($yaml->[0])
=> 'Successful populated.';

## Find some Genders

GENDER: {

    ok my $gender_rs = $schema->resultset('Gender')
    => 'Got a resultset of genders';

    is $gender_rs->count, 2
    => 'Got expected number of genders';

    ok $gender_rs->find({label=>'male'})
    => 'Found male';

    ok $gender_rs->find({label=>'female'})
    => 'Found female';

    ok ! $gender_rs->find({label=>'transgender'})
    => 'Correctly didn not find transgender';

}


## Find some People

PERSON: {

    ok my $person_rs = $schema->resultset('Person')
    => 'Got a person resultset';

    is $person_rs->count, 3
    => 'Got expected number of person_rs';

    ok my $john = $person_rs->search({name=>'john'})->first
    => 'Found John';

    is $john->age, 38
    => 'Got correct age for john';

    ok my $jane = $person_rs->search({name=>'jane'})->first
    => 'Found John';

    is $jane->age, 40
    => 'Got correct age for jane';

}

## Find some companies

COMPANY: {

    ok my $company_rs = $schema->resultset('Company')
    => 'Got a person resultset';

    is $company_rs->count, 2
    => 'Got expected number of person_rs';

    ok my $takkle = $company_rs->search({name=>'takkle'})->first
    => 'Found takkle';

    ok my $company_persons_rs = $takkle->company_persons
    => 'got company_persons';

    is $company_persons_rs->count, 2
    => 'got right number of $company_persons_rs';
    
    ok my $employees_rs = $takkle->employees
    => 'got some employees';
    
    ok my $john1 = $employees_rs->search({name=>'john'})->first
    => 'found john';
    
    is $john1->age, 38
    => 'got correct age';
    
    ok my $bms = $company_rs->search({name=>'bristol meyers squibb'})->first
    => 'Found bristol meyers squibb';
    
    is $bms->employees->count, 2
    => 'got correct count for bms employees';
    
}

## Test Friendlist

FRIENDLIST: {

    ok my $friendlist_rs = $schema->resultset('FriendList')
    => 'Got a friendlist resultset';
    
    is $friendlist_rs->count, 3
    => 'Got expected number of friendlist_rs';
    
    ok my $mike = $schema->resultset('Person')->search({name=>'mike'})->first
    => 'found mike';
    
    is $mike->friends, 2
    => 'got correct number of friends for mike';
    
}
__DATA__
---
- Gender:
    data:
      female: female
      male: male
    fields: label
- Person:
    data:
      jane:
        - jane
        - 40
        - '!Index:Gender.female'
      john:
        - john
        - 38
        - '!Index:Gender.male'
    fields:
      - name
      - age
      - gender
- Company:
    data:
      bms:
        - bristol meyers squibb
        -
          - employee: '!Index:Person.john'
          - employee: '!Index:Person.jane'
      takkle:
        - takkle
        -
          - employee: '!Index:Person.john'
            employment_history:
              started: '!Date:january 1, 2000'
    fields:
      - name
      - company_persons
- FriendList:
    data:
      john_jane:
        - '!Index:Person.john'
        - '!Index:Person.jane'
    fields:
      - befriender
      - friendee
- Person:
    data:
      mike:
        - mike
        - 25
        - '!Index:Gender.male'
        -
          - friendee: '!Index:Person.john'
          - friendee: '!Index:Person.jane'
    fields:
      - name
      - age
      - gender
      - friendlist
- CompanyPerson:
    data:
      mike_at_takkle:
        - '!Index:Person.mike'
        - '!Index:Company.takkle'
        - started: '!Date:yesterday'
    fields:
      - employee
      - company
      - employment_history

