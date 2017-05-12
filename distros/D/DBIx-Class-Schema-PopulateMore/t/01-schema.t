use warnings;
use strict;

use Test::More tests => 43;
use DBIx::Class::Schema::PopulateMore::Test::Schema;

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

ok my $populate = [
    
    {Gender => {
        fields => 'label',
        data => {
            male => 'male',
            female => 'female',
        }}},
        
    {Person    => {
        fields => ['name', 'age', 'gender'],
        data => {
            john => ['john', 38, "!Index:Gender.male"],
            jane => ['jane', 40, '!Index:Gender.female'],
        }}},
        
    {Company => {
        fields => ['name', 'company_persons'],
        data => {
            bms => ['bristol meyers squibb', [
                {employee=>'!Index:Person.john'},
                {employee=>'!Index:Person.jane'},
            ]],
            takkle => ['takkle', [
                {
                    employee => '!Index:Person.john', 
                    employment_history => {
                        started=>'!Date:january 1, 2000',
                    }
                },
            ]],
        }}},
        
    {FriendList => {
        fields => ['befriender', 'friendee'],
        data => {
            john_jane => ['!Index:Person.john', '!Index:Person.jane'],
        }}},
        
    {Person    => {
        fields => ['name', 'age', 'gender', 'friendlist'],
        data => {
            mike => ['mike', 25, "!Index:Gender.male", [
                {friendee=>'!Index:Person.john'},
                {friendee=>'!Index:Person.jane'},                
            ]],
        }}},
        
    {CompanyPerson => {
        fields => ['employee', 'company', 'employment_history'],
        data => {
            mike_at_takkle => [
                '!Index:Person.mike', 
                '!Index:Company.takkle', 
                {started=>'!Date:yesterday'}
            ],
        }}},

] => 'Create structure to populate_more with';

ok my %index = $schema->populate_more($populate)
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
    
    ok my $john = $employees_rs->search({name=>'john'})->first
    => 'found john';
    
    is $john->age, 38
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

## Extra tests for alternative ->populate_more argument styles

ok my $extra = [
    {Person    => {
        fields => ['name', 'age', 'gender'],
        data => {
            joe => ['joe', 19, '!Find:Gender.[label=male]'],
        }}},
], 'Created extra';

ok my %index2 = $schema->populate_more($extra)
  => 'Successful populated again.';

ok my $joe = $schema->resultset('Person')->search({name=>'joe'})->first,
  => 'Got a Person';

is $joe->age, 19, 'Joe is 19';

ok $joe->delete, 'Delete Joe';

ok my %index2_again = $schema->populate_more($extra)
  => 'Successful populated same data again.';

ok my $joe_again = $schema->resultset('Person')->search({name=>'joe'})->first,
  => 'Got a Person again';

ok my %index3 = $schema->populate_more(
        Gender => {
            fields => 'label',
            data => {
                unknown => 'unknown',
            }
        },
            
        Person => {
            fields => ['name', 'age', 'gender'],
            data => {
                toad => ['toad', 38, '!Index:Gender.unknown'],
                bill => ['bill', 40, '!Find:Gender.[label=male]'],
                york => ['york', 45, '!Find:Gender.[label=female]'],
            }
        },
    ) => 'Successful populated.';

ok my ($bill,$toad,$york) = $schema->resultset('Person')->search({name=>[qw/bill toad york/]},{order_by=>\"name asc"})
  => 'Found bill, toad and york';

is $bill->age, 40, 'Got correct age for bill';
is $toad->age, 38, 'Got correct age for toad';
is $york->age, 45, 'Got correct age for york';

