# -*- mode: cperl; cperl-indent-level: 2; cperl-continued-statement-offset: 2; indent-tabs-mode: nil -*-
use strict;
use warnings FATAL => 'all';

use Apache::Test ();            # just load it to get the version
use version;
use Apache::Test (version->parse(Apache::Test->VERSION)>=version->parse('1.35')
                  ? '-withtestmore' : ':withtestmore');
use Apache::TestUtil;
use Apache::TestUtil qw(t_catfile);
use Test::Deep;
use File::Basename 'dirname';
use File::Path ();

plan tests=>24;
#plan 'no_plan';

my $data=<<'EOD';
#xkey	xuri		xblock	xorder	xaction
k1	u1		0	0	a
k1	u1		1	0	c
k1	u1		0	1	b
k1	u2		0	0	d
k1	u2		1	1	f
k1	u2		1	0	e
EOD

my $serverroot=Apache::Test::vars->{serverroot};
sub n {my @c=caller; $c[1].'('.$c[2].'): '.$_[0];}
my $conf=$serverroot.'/translation.conf';
my $conf_notes=$serverroot.'/translation.notes';

######################################################################
## the real tests begin here                                        ##
######################################################################

use Apache2::Translation::File;

File::Path::rmtree( $conf_notes );
t_mkdir( $conf_notes );
t_write_file( t_catfile($conf_notes, "3"), "note on 3" );
t_write_file( $conf, '' );
my $time=time;
utime $time, $time, $conf;

my $o=Apache2::Translation::File->new
  (
   ConfigFile=>$conf,
  );

ok $o, n 'provider object';

$o->start;
cmp_deeply $o->timestamp, $time, n 'cache timestamp';
$o->begin;
foreach my $l (split /\n/, $data) {
  next if( $l=~/^#/ );
  chomp $l;
  $o->insert([split /\t+/, $l]);
}
$o->commit;
$o->stop;

cmp_deeply $o->_cache, {
			"k1\0u2" => [
				     [0, 0, "d", 4, "k1", "u2"],
				     [1, 0, "e", 6, "k1", "u2"],
				     [1, 1, "f", 5, "k1", "u2"]
				    ],
			"k1\0u1" => [
				     [0, 0, "a", 1, "k1", "u1"],
				     [0, 1, "b", 3, "k1", "u1"],
				     [1, 0, "c", 2, "k1", "u1"]
				    ]
		       }, n 'cache status';

cmp_deeply do {local $/; local @ARGV=($conf); <>}, <<'EOF', n 'written config';
#>>> id key uri blk ord
# action
##################################################################
>>>   1 k1  u1    0   0
a
##################################################################
>>>   3 k1  u1    0   1
b
##################################################################
>>>   2 k1  u1    1   0
c
##################################################################
>>>   4 k1  u2    0   0
d
##################################################################
>>>   6 k1  u2    1   0
e
##################################################################
>>>   5 k1  u2    1   1
f
EOF

{
  my $tm=(stat $conf)[9];
  open my $f, ">>$conf";
  print $f ">>> 100 k2 u1 0 0\na\na\n";
  close $f;
  utime( $tm+1, $tm+1, $conf );
}

$o->start;
cmp_deeply $o->_cache, {
			"k1\0u2" => [
				     [0, 0, "d", 4, "k1", "u2"],
				     [1, 0, "e", 6, "k1", "u2"],
				     [1, 1, "f", 5, "k1", "u2"]
				    ],
			"k1\0u1" => [
				     [0, 0, "a", 1, "k1", "u1"],
				     [0, 1, "b", 3, "k1", "u1"],
				     [1, 0, "c", 2, "k1", "u1"]
				    ],
			"k2\0u1" => [
				     [0, 0, "a\na", 100, "k2", "u1"]
				    ]
		       }, n 'cache reloaded';

cmp_deeply [$o->fetch('k1', 'u1')],
           [['0', '0', 'a', '1'], ['0', '1', 'b', '3'], ['1', '0', 'c', '2']],
           n 'fetch k1 u1';

$o->begin;
$o->update( ["k2", "u1", 0, 0, 100], ["k2", "u1", 1, 2, "b\nccc"] );
$o->commit;

cmp_deeply do {local $/; local @ARGV=($conf); <>}, <<'EOF', n 'config after update';
#>>> id key uri blk ord
# action
##################################################################
>>>   1 k1  u1    0   0
a
##################################################################
>>>   3 k1  u1    0   1
b
##################################################################
>>>   2 k1  u1    1   0
c
##################################################################
>>>   4 k1  u2    0   0
d
##################################################################
>>>   6 k1  u2    1   0
e
##################################################################
>>>   5 k1  u2    1   1
f
##################################################################
>>> 100 k2  u1    1   2
b
ccc
EOF

cmp_deeply [$o->fetch('k2', 'u1')],
           [['1', '2', "b\nccc", '100']],
           n 'fetch k2 u1';

$o->begin;
$o->update( ["k2", "u1", 1, 2, 100], ["k1", "u1", 1, 2, "b\nccc"] );
$o->commit;
$o->stop;

cmp_deeply do {local $/; local @ARGV=($conf); <>}, <<'EOF', n 'config after update';
#>>> id key uri blk ord
# action
##################################################################
>>>   1 k1  u1    0   0
a
##################################################################
>>>   3 k1  u1    0   1
b
##################################################################
>>>   2 k1  u1    1   0
c
##################################################################
>>> 100 k1  u1    1   2
b
ccc
##################################################################
>>>   4 k1  u2    0   0
d
##################################################################
>>>   6 k1  u2    1   0
e
##################################################################
>>>   5 k1  u2    1   1
f
EOF

cmp_deeply [$o->fetch('k1', 'u1')],
           [[0, 0, "a", 1],
	    [0, 1, "b", 3],
	    [1, 0, "c", 2],
	    [1, 2, "b\nccc", 100]],
           n 'fetch k1 u1';


{
  my $tm=(stat $conf)[9];
  open my $f, ">>$conf";
  print $f ">>>90 k1 u1 1 1\nc\n";
  close $f;
  utime( $tm+1, $tm+1, $conf );
}

$o->start;
cmp_deeply $o->_cache, {
			"k1\0u2" => [
				     [0, 0, "d", 4, "k1", "u2"],
				     [1, 0, "e", 6, "k1", "u2"],
				     [1, 1, "f", 5, "k1", "u2"]
				    ],
			"k1\0u1" => [
				     [0, 0, "a", 1, "k1", "u1"],
				     [0, 1, "b", 3, "k1", "u1"],
				     [1, 0, "c", 2, "k1", "u1"],
				     [1, 1, "c", 90, "k1", "u1"],
				     [1, 2, "b\nccc", 100, "k1", "u1"]
				    ]
		       }, n 'cache reloaded';
$o->begin;
$o->delete(["k1", "u1", 1, 2, 100]);
$o->commit;
cmp_deeply [$o->fetch('k1', 'u1')],
           [[0, 0, "a", 1],
	    [0, 1, "b", 3],
	    [1, 0, "c", 2],
	    [1, 1, "c", 90]],
           n 'fetch k1 u1';
$o->stop;

$o->start;
$o->begin;
$o->delete(["k1", "u2", 0, 0, 4]);
$o->delete(["k1", "u2", 1, 0, 6]);
$o->delete(["k1", "u2", 1, 1, 5]);
$o->commit;

cmp_deeply $o->_cache, {
			"k1\0u1" => [
				     [0, 0, "a", 1, "k1", "u1"],
				     [0, 1, "b", 3, "k1", "u1"],
				     [1, 0, "c", 2, "k1", "u1"],
				     [1, 1, "c", 90, "k1", "u1"]
				    ]
		       }, n 'after delete (3x)';
$o->stop;

$o=Apache2::Translation::File->new
  (
   ConfigFile=>$conf,
   NotesDir=>$conf_notes,
  );

$o->start;
cmp_deeply $o->_cache, {
			"k1\0u1" => [
				     [0, 0, "a", 1, "k1", "u1"],
				     [0, 1, "b", 3, "k1", "u1"],
				     [1, 0, "c", 2, "k1", "u1"],
				     [1, 1, "c", 90, "k1", "u1"]
				    ]
		       }, n 'reread with notes';
cmp_deeply [$o->fetch( qw/k1 u1 1/ )], [
					[0, 0, "a", 1, undef],
					[0, 1, "b", 3, 'note on 3'],
					[1, 0, "c", 2, undef],
					[1, 1, "c", 90, undef]
				       ], n 'fetch with_notes';
$o->begin;
$o->update( ["k1", "u1", 1, 1, 90], ["k2", "u1", 1, 2, "bccc", 'note on 90'] );
$o->commit;

cmp_deeply do{local $/; local @ARGV=(t_catfile($conf_notes, '90')); <>.''},
           'note on 90', n 'note on id=90';

my @l=(['k1', 'u1', 0, 0, 'a', undef, 1],
       ['k1', 'u1', 0, 1, 'b', 'note on 3', 3],
       ['k1', 'u1', 1, 0, 'c', undef, 2],
       ['k2', 'u1', 1, 2, 'bccc', 'note on 90', 90]);
my $i=0;
for( my $iterator=$o->iterator; my $el=$iterator->(); $i++ ) {
  cmp_deeply($el, $l[$i], n "iterator $i");
}
cmp_deeply( $i, 4, n 'iteratorloop count' );

$o->begin;
$o->clear;
$o->commit;

cmp_deeply [$o->fetch('k1', 'u1', 1)],
           [],
           n 'cleared';

$o->stop;

$o=Apache2::Translation::File->new(ConfigFile=>\*DATA);

$o->start;
cmp_deeply [$o->fetch( qw/key uri/ )],
           [
            [0, 1, "action1\naction1\n", 1],
            [0, 2, "action3\naction3", 3],
           ], n '__DATA__ as provider input 1';

cmp_deeply [$o->fetch( qw/key2 uri2/ )],
           [
            [1, 2, "action2\naction2\n", 2],
           ], n '__DATA__ as provider input 2';
$o->stop;

__DATA__

>>> 1 key uri 0 1
action1
action1

>>> 2 key2 uri2 1 2
action2
action2

>>> 3 key uri 0 2
action3
action3
