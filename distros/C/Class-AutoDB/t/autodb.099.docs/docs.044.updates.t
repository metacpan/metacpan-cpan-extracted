use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbUtil;

# test update methods documented in METHODS
use Person;
my @usual_tables=qw(_AutoDB Person);

# create database so we can start fresh
my $autodb=new Class::AutoDB(database=>testdb,create=>1);
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

########################################
# put
# make some objects
my $joe=new Person(name=>'Joe',sex=>'M',id=>id_next());
my $mary=new Person(name=>'Mary',sex=>'F',id=>id_next());
my $bill=new Person(name=>'Bill',sex=>'M',id=>id_next());
$joe->friends([$mary,$bill]);
$mary->friends([$joe,$bill]);
$bill->friends([$joe,$mary]);

$autodb->put;
my $count=0;			# number of objects put
my %actual_counts=actual_counts(@usual_tables);
cmp_deeply(\%actual_counts,{_AutoDB=>1,Person=>0},'put');

my @objects=($joe,$mary);
$autodb->put(@objects);
$count+=2;
my %actual_counts=actual_counts(@usual_tables);
cmp_deeply(\%actual_counts,{_AutoDB=>1+$count,Person=>$count},'put(@objects)');

########################################
# put_object
# make more objects
my $joe=new Person(name=>'Joe',sex=>'M',id=>id_next());
my $mary=new Person(name=>'Mary',sex=>'F',id=>id_next());
my $bill=new Person(name=>'Bill',sex=>'M',id=>id_next());
$joe->friends([$mary,$bill]);
$mary->friends([$joe,$bill]);
$bill->friends([$joe,$mary]);

$autodb->put_objects;
$count+=4;			# 3 made here, 1 leftover from 'put'
my %actual_counts=actual_counts(@usual_tables);
cmp_deeply(\%actual_counts,{_AutoDB=>1+$count,Person=>$count},'put_object');

# make even more objects
my $joe=new Person(name=>'Joe',sex=>'M',id=>id_next());
my $mary=new Person(name=>'Mary',sex=>'F',id=>id_next());
my $bill=new Person(name=>'Bill',sex=>'M',id=>id_next());
$joe->friends([$mary,$bill]);
$mary->friends([$joe,$bill]);
$bill->friends([$joe,$mary]);
my @objects=($mary,$bill);

$autodb->put_objects(@objects);
$count+=2;
my %actual_counts=actual_counts(@usual_tables);
cmp_deeply(\%actual_counts,{_AutoDB=>1+$count,Person=>$count},'put_objects(@objects)');

done_testing();

