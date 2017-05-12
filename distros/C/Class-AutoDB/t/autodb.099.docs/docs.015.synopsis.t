use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbUtil;

# new features in verion 1.20
use Class::AutoDB;
use Person;
my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
my @males=$autodb->get(collection=>'Person',sex=>'M'); # just the boys  
is(scalar @males,2,'number of males - sanity test');

# delete objects
#
my %old_counts=norm_counts(actual_counts(qw(Person _AutoDB)));
$autodb->del(@males);                                  # delete the boys  
my %new_counts=norm_counts(actual_counts(qw(Person _AutoDB)));
my $actual_diffs=norm_counts(map {$_=>$new_counts{$_}-$old_counts{$_}} qw(Person _AutoDB));
my $correct_diffs={Person=>-2,_AutoDB=>-2};
cmp_deeply($actual_diffs,$correct_diffs,'deleted correct number of objects');

done_testing();

