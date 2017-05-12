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

plan tests=>19;
#plan 'no_plan';

my $data=<<'EOD';
#xkey	xuri		xblock	xorder	xaction	xnote
k1	u1		0	0	a	note1
k1	u1		1	1	c	note2
k1	u1		0	1	b
k1	u2		0	0	d	note3
k1	u2		1	1	f
k1	u2		1	0	e	note4
EOD

my $serverroot=Apache::Test::vars->{serverroot};
sub n {my @c=caller; $c[1].'('.$c[2].'): '.$_[0];}
my $conf=$serverroot.'/bdbenv.conf';
my $conf_notes=$serverroot.'/bdbenv.notes';
my $bdbenv=$serverroot.'/bdbenv';

{
  my @wlog;
  my $sw;

  sub start_warnlog {
    $sw=$SIG{__WARN__};
    @wlog=();
    $SIG{__WARN__}=sub {
      push @wlog, "@_";
    };
  }

  sub stop_warnlog {
    $SIG{__WARN__}=$sw;
    return @wlog;
  }
}

######################################################################
## the real tests begin here                                        ##
######################################################################

use Apache2::Translation::File;
use Apache2::Translation::BDB;

File::Path::rmtree( $bdbenv );
File::Path::rmtree( $conf_notes );
t_mkdir( $bdbenv );
t_mkdir( $conf_notes );
t_write_file( $conf, '' );
my $time=time;
utime $time, $time, $conf;

my $fo=Apache2::Translation::File->new
  (
   ConfigFile=>$conf,
   NotesDir=>$conf_notes,
  );

my $o=Apache2::Translation::BDB->new(BDBEnv=>$bdbenv);
my $ro=Apache2::Translation::BDB->new(BDBEnv=>$bdbenv, ReadOnly=>1);

ok $o, n 'provider object';
ok $ro, n 'readonly provider';

$fo->start;
$fo->begin;
foreach my $l (split /\n/, $data) {
  next if( $l=~/^#/ );
  chomp $l;
  $fo->insert([split /\t+/, $l]);
}
$fo->commit;
$fo->stop;

$o->start;
$o->begin;
$fo->start;
cmp_deeply $o->append($fo), 6, n 'append';
$fo->stop;
$o->commit;
$o->stop;

$ro->start;
$ro->begin;
$fo->start;
cmp_deeply $ro->append($fo), 0, n 'readonly append';
$fo->stop;
$ro->commit;
$ro->stop;

$o->start;
cmp_deeply [$ro->fetch('k1', 'u1')],
           [[0, 0, 'a', 1],
	    [0, 1, 'b', 2],
	    [1, 1, 'c', 3]],
           n 'fetch k1 u1';

cmp_deeply [$o->fetch('k1', 'u1', 1)],
           [[0, 0, 'a', 1, 'note1'],
	    [0, 1, 'b', 2, undef],
	    [1, 1, 'c', 3, 'note2']],
           n 'fetch k1 u1 with notes';

$o->begin;
$o->insert([qw/k1 u1 1 0 inserted_action inserted_note/]);
$o->commit;

cmp_deeply [$ro->fetch('k1', 'u1', 1)],
           [[0, 0, 'a', 1, 'note1'],
	    [0, 1, 'b', 2, undef],
	    [1, 0, 'inserted_action', 7, 'inserted_note'],
	    [1, 1, 'c', 3, 'note2']],
           n 'fetch k1 u1 after insert';

$o->begin;
$o->update([qw/k1 u1 1 0 7/],
	   [qw/k1 u1 1 3/, "updated\naction", "updated\nnote"]);
$o->commit;

cmp_deeply [$ro->fetch('k1', 'u1', 1)],
           [[0, 0, 'a', 1, 'note1'],
	    [0, 1, 'b', 2, undef],
	    [1, 1, 'c', 3, 'note2'],
	    [1, 3, "updated\naction", 7, "updated\nnote"]],
           n 'fetch k1 u1 after update';

$o->begin;
$o->delete([qw/k1 u1 1 1 3/]);
$o->commit;

cmp_deeply [$ro->fetch('k1', 'u1', 1)],
           [[0, 0, 'a', 1, 'note1'],
	    [0, 1, 'b', 2, undef],
	    [1, 3, "updated\naction", 7, "updated\nnote"]],
           n 'fetch k1 u1 after delete';

#$o->dump("%{KEY} / %{URI}\t%{BLOCK}/%{ORDER} %{ID}\n%{pa>> ;ACTION}\n%{pn>> ;NOTE}\n\n");

my @l=([qw/k1 u1 0 0 a note1 1/],
       [qw/k1 u1 0 1 b/, undef, 2],
       [qw/k1 u1 1 3/, "updated\naction", "updated\nnote", 7],
       [qw/k1 u2 0 0 d note3 4/],
       [qw/k1 u2 1 0 e note4 5/],
       [qw/k1 u2 1 1 f/, undef, 6]);
my $i=0;
for( my $iterator=$o->iterator; my $el=$iterator->(); $i++ ) {
  cmp_deeply($el, $l[$i], n "iterator $i");
}
cmp_deeply( $i, 6, n 'iteratorloop count' );

$o->begin;
$o->clear;
$o->commit;

cmp_deeply [$ro->fetch('k1', 'u1', 1)],
           [],
           n 'cleared';

$o->stop;

$o->begin;
cmp_deeply( $o->timestamp(123), 0, n 'set timestamp' );
$o->commit;

cmp_deeply( $o->timestamp(), 123, n 'get timestamp' );
