use strict;
use warnings;
use t::lib;
use t::utilBabel;
use Test::More;
use Data::Babel;

# Implicit split is deprecated and removed in 5.12.2
# old = sub id2name {shift; split(':',$_[0]); pop(@_);}
# new = sub id2name {shift; my @names = split(':',$_[0]); pop(@names);}

# create AutoDB database
my $autodb=new Class::AutoDB(database=>'test',create=>1);
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
cleanup_db($autodb);		# cleanup database from previous test
my $name='test';

my $babel=new Data::Babel(name=>$name);
isa_ok($babel,'Data::Babel','sanity test - $babel');

my @ids=
    (qw(idtype:type_001 idtype:type_002 idtype:type_003 idtype:type_004),
     qw(master:type_001_master master:type_002_master master:type_003_master master:type_004_master),
     qw(maptable:maptable_001 maptable:maptable_002 maptable:maptable_003));
my @names=
    (qw(type_001 type_002 type_003 type_004),
     qw(type_001_master type_002_master type_003_master type_004_master),
     qw(maptable_001 maptable_002 maptable_003));
my %id2name=map {$ids[$_]=>$names[$_]} (0..$#ids);
for my $id (@ids) {
  my $actual=$babel->id2name($id);
  unlike($actual, qr/:/, "Name split correctly for $id to $actual");
}

done_testing();
