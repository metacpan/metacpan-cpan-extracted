# -*- mode: cperl; cperl-indent-level: 2; cperl-continued-statement-offset: 2; indent-tabs-mode: nil -*-
use strict;
use warnings FATAL => 'all';

use Apache::Test ();            # just load it to get the version
use version;
use Apache::Test (version->parse(Apache::Test->VERSION)>=version->parse('1.35')
                  ? '-withtestmore' : ':withtestmore');
use Apache::TestUtil;
use Test::Deep;
use DBI;
use File::Basename 'dirname';

plan tests=>23;
#plan 'no_plan';

my $data=<<'EOD';
#id	xkey	xuri		xblock	xorder	xaction
0	k1	u1		0	0	a
1	k1	u1		0	1	b
2	k1	u1		1	0	c
3	k1	u2		0	0	d
4	k1	u2		1	0	e
5	k1	u2		1	1	f
EOD

my $serverroot=Apache::Test::vars->{serverroot};
my ($db,$user,$pw)=@ENV{qw/DB USER PW/};
$user='' unless defined $user;
$pw='' unless defined $pw;
my $dbinit='';
unless( defined $db and length $db ) {
  ($db,$user,$pw)=("dbi:SQLite:dbname=$serverroot/test.sqlite", '', '');
  $dbinit="PRAGMA synchronous = OFF";
}
t_debug "Using DB=$db USER=$user";
my $dbh;
my $cache_value;
sub prepare_db {
  $dbh=DBI->connect( $db, $user, $pw,
		     {AutoCommit=>1, PrintError=>0, RaiseError=>1} )
    or die "ERROR: Cannot connect to $db: $DBI::errstr\n";

  $dbh->do($dbinit) if( length $dbinit );
  $dbh->do('DELETE FROM sequences');
  $dbh->do('DELETE FROM trans');
  my $stmt=$dbh->prepare('SELECT MAX(v) FROM cache');
  $stmt->execute;
  ($cache_value)=$stmt->fetchrow_array;
  $stmt->finish;

  $stmt=$dbh->prepare( <<'SQL' );
INSERT INTO trans (id, xkey, xuri, xblock, xorder, xaction) VALUES (?,?,?,?,?,?)
SQL

  foreach my $l (grep !/^\s*#/, split /\n/, $data) {
    $stmt->execute(split /\t+/, $l);
  }

}

prepare_db;
sub n {my @c=caller; $c[1].'('.$c[2].'): '.$_[0];}

######################################################################
## the real tests begin here                                        ##
######################################################################

use Apache2::Translation::DB;

my $o=Apache2::Translation::DB->new
  (
   Database=>$db, User=>$user, Passwd=>$pw,
   Table=>'trans', Key=>'xkey', Uri=>'xuri', Block=>'xblock',
   Order=>'xorder', Action=>'xaction', Id=>'id',
   CacheSize=>1000, CacheTbl=>'cache', CacheCol=>'v',
   DBInit=>"$dbinit",
  );

ok $o, n 'provider object';

ok tied(%{$o->_cache}), n 'tied cache';

$o->start;
cmp_deeply $o->_cache_version, $cache_value, n 'cache version is 1';
$o->stop;

$dbh->do('UPDATE cache SET v=v+1');

$o->start;
cmp_deeply $o->_cache_version, $cache_value+1, n 'cache version is 2';
cmp_deeply [$o->fetch('k1', 'u1')],
           [['0', '0', 'a', '0'], ['0', '1', 'b', '1'], ['1', '0', 'c', '2']],
           n 'fetch uri u1';
$dbh->do('DELETE FROM trans WHERE id=0');
$dbh->do('UPDATE cache SET v=v+1');
cmp_deeply [$o->fetch('k1', 'u1')],
           [['0', '0', 'a', '0'], ['0', '1', 'b', '1'], ['1', '0', 'c', '2']],
           n 'same result after update';
$o->stop;

$o->id=undef;	       	# check that no id is delivered if this is unset
$o->start;
cmp_deeply $o->_cache_version, $cache_value+2, n 'cache version is 3 after another $o->start';
cmp_deeply [$o->fetch('k1', 'u1')],
           [['0', '1', 'b'], ['1', '0', 'c']],
           n 'fetch uri u1 after another $o->start';
cmp_deeply [$o->fetch('unknown', 'unknown')], [],
           n 'fetch unknown key/uri pair';
cmp_deeply exists( $o->_cache->{"unknown\0unknown"} )||0, 0,
           n 'cache state after fetching unknown key/uri pair';
$o->stop;

$o=Apache2::Translation::DB->new
  (
   Database=>$db, User=>$user, Passwd=>$pw,
   Table=>'trans', Key=>'xkey', Uri=>'xuri', Block=>'xblock',
   Order=>'xorder', Action=>'xaction', Id=>'id', Notes=>'xnotes',
   CacheSize=>1000, CacheTbl=>'cache', CacheCol=>'v',
   SeqTbl=>'sequences', SeqNameCol=>'xname', SeqValCol=>'xvalue',
   IdSeqName=>'id',
   DBInit=>"$dbinit",
  );

$o->start;
cmp_deeply [$o->fetch('k1', 'u1', 1)],
           [['0', '1', 'b', '1', ''], ['1', '0', 'c', '2', '']],
           n 'fetch with notes';

$o->begin;
$o->update( ["k1", "u1", 1, 0, 2],
	    ["k1", "u1", 1, 2, "new action", 'note on 2'] );
$o->commit;

cmp_deeply [$o->fetch('k1', 'u1', 1)],
           [['0', '1', 'b', '1', ''], ['1', '2', 'new action', '2', 'note on 2']],
           n 'fetch changed notes';

eval {
  $o->begin;
  $o->insert([qw/k2 u1 1 2 inserted_action a_note/]);
  $o->commit;
} or $o->rollback;
cmp_deeply $@, "ERROR: sequences table not set up: missing row with xname=id\n",
           n 'sequences table not set up';

$dbh->do( <<'SQL' );
INSERT INTO sequences (xname, xvalue) VALUES ('id', 10)
SQL

eval {
  $o->begin;
  $o->insert([qw/k2 u1 1 2 inserted_action a_note/]);
  $o->commit;
};
cmp_deeply $@, '', n 'sequences table set up';

cmp_deeply [$o->fetch('k2', 'u1', 1)],
           [['1', '2', 'inserted_action', '10', 'a_note']],
           n 'fetch with notes';

my @l=(['k1', 'u1', 0, 1, 'b', undef, 1],
       ['k1', 'u1', 1, 2, 'new action', 'note on 2', 2],
       ['k1', 'u2', 0, 0, 'd', undef, 3],
       ['k1', 'u2', 1, 0, 'e', undef, 4],
       ['k1', 'u2', 1, 1, 'f', undef, 5],
       ['k2', 'u1', 1, 2, 'inserted_action', 'a_note', 10]);
my $i=0;
for( my $iterator=$o->iterator; my $el=$iterator->(); $i++ ) {
  cmp_deeply($el, $l[$i], n "iterator $i");
}
cmp_deeply( $i, 6, n 'iteratorloop count' );

$o->begin;
$o->clear;
$o->commit;

cmp_deeply [$o->fetch('k1', 'u1', 1)],
           [],
           n 'cleared';

$o->stop;

undef $o;

$dbh->disconnect;
