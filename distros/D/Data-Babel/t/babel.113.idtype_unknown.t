########################################
# regression test for unknown IdTypes - all should be gathered and confessed together
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use Data::Babel;
use Data::Babel::Config;
use strict;

# create AutoDB database
my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
cleanup_db($autodb);		# cleanup database from previous test
Data::Babel->autodb($autodb);
my $dbh=$autodb->dbh;

# make component objects and Babel. note that $masters is for EXPLICIT masters only
my $idtypes=<<IDTYPES
[GLOBAL]
sql_type=VARCHAR(255)
[abc]
[xyz]
IDTYPES
;
my $maptables=<<MAPTABLES
[abc_xyz]
idtypes=abc xyz
[abc_bad1]
idtypes=abc bad1
[abc_bad2]
idtypes=abc bad2
[bad1_bad2]
idtypes=bad1 bad2
[bad3_bad4]
idtypes=bad3 bad4
MAPTABLES
;
my $abc_xyz=<<DATA
ABC XYZ
Abc Xyz
aBc xYz
DATA
;
$idtypes=new Data::Babel::Config (file=>\$idtypes)->objects('IdType');
$maptables=new Data::Babel::Config (file=>\$maptables)->objects('MapTable');
eval {
  my $babel=new Data::Babel(name=>'test',idtypes=>$idtypes,maptables=>$maptables)
};
my $err=$@;
my $err_head='Unknown IdType\(s\) appear in MapTables:';
like($err,qr/^$err_head/,'some unknown IdTypes detected');
my($bad)=$err=~/^$err_head (.*) at/;
my @bad=split(/, /,$bad);
cmp_set(\@bad,[qw(bad1 bad2 bad3 bad4)],'expected unknown IdTypes detected');

done_testing();
