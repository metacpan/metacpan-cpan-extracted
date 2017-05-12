use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbUtil;

# test methods in METHODS/Manage database schema

# create AutoDB database and SBDM files so we start clean
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# exists
ok($autodb->exists,'exists');

# register
package Person;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends name_prefix sex_word);
%AUTODB=1;

package main;
$autodb->register(class=>'Person',collection=>'Person', 
		  keys=>qq(name string, sex string, id integer),
		  transients=>qq(name_prefix sex_word));

my @actual_tables=actual_tables(qw(Person));
cmp_bag(\@actual_tables,[qw(Person)],'collection tables exist after register');
test_single('Person',qw(Person));

# create
$autodb->create;
my @actual_tables=actual_tables(qw(_AutoDB Person));
cmp_bag(\@actual_tables,[qw(_AutoDB Person)],'tables after create');
my %actual_counts=actual_counts(qw(_AutoDB Person));
cmp_deeply(\%actual_counts,{_AutoDB=>1,Person=>0},'counts after create');

# alter
$autodb->alter;
my @actual_tables=actual_tables(qw(_AutoDB Person));
cmp_bag(\@actual_tables,[qw(_AutoDB Person)],'tables after alter');
my %actual_counts=actual_counts(qw(_AutoDB Person));
cmp_deeply(\%actual_counts,{_AutoDB=>1,Person=>0},'counts after alter');

# drop
$autodb->drop;
my @actual_tables=actual_tables(qw(_AutoDB Person));
cmp_bag(\@actual_tables,[qw(_AutoDB)],'tables after drop');
my %actual_counts=actual_counts(qw(_AutoDB Person));
cmp_deeply(\%actual_counts,{_AutoDB=>1,Person=>0},'counts after drop');

done_testing();
