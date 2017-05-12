########################################
# regression test for isolated IdType
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

# make component objects and Babel
my $idtypes=<<IDTYPES
[GLOBAL]
sql_type=VARCHAR(255)
[abc]
[xyz]
[isolated1]
[isolated2]
IDTYPES
;
my $maptables=<<MAPTABLES
[abc_xyz]
idtypes=abc xyz
MAPTABLES
;
$idtypes=new Data::Babel::Config (file=>\$idtypes)->objects('IdType');
$maptables=new Data::Babel::Config (file=>\$maptables)->objects('MapTable');
eval {
  my $babel=new Data::Babel(name=>'test',idtypes=>$idtypes,maptables=>$maptables)
};
my $err=$@;
my $err_head='Some IdType\(s\) are \'isolated\', ie, not in any MapTable:';
like($err,qr/^$err_head/,'some isolated IdTypes detected');
my($bad)=$err=~/^$err_head (.*) at/;
my @bad=split(/, /,$bad);
cmp_set(\@bad,[qw(isolated1 isolated2)],'expected isolated IdTypes detected');

done_testing();
