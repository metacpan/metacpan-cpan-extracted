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
use Data::Dumper; $Data::Dumper::Useqq=1;

plan tests=>23;
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
my $db=$serverroot.'/mmapdb';

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
use Apache2::Translation::MMapDB;

unlink $db, $db.'.lock';
File::Path::rmtree( $conf_notes );
t_mkdir( $conf_notes );
t_write_file( $conf, '' );

my $fo=Apache2::Translation::File->new
  (
   ConfigFile=>$conf,
   NotesDir=>$conf_notes,
  );

my $o=Apache2::Translation::MMapDB->new(FileName=>$db,
                                        BaseKey=>'[qw/trans db/]');
my $ro=Apache2::Translation::MMapDB->new(FileName=>$db,
                                         BaseKey=>'["trans","db"]',
                                         ReadOnly=>1);

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
eval {$o->clear};
cmp_deeply $@, '', n 'newly created db successfully cleared';
$fo->start;
cmp_deeply $o->append($fo), 6, n 'append';
$fo->stop;
$o->commit;
$o->stop;

$ro->start;
$@='';
eval {$ro->begin};
is $@, "ERROR: read-only mode\n", n 'readonly append';
$ro->stop;

$o->start;
$ro->start;

cmp_deeply [$ro->fetch('k1', 'u1')],
           [[0, 0, 'a', re(qr/^\d+$/)],
	    [0, 1, 'b', re(qr/^\d+$/)],
	    [1, 1, 'c', re(qr/^\d+$/)]],
           n 'fetch k1 u1';

cmp_deeply [$o->fetch('k1', 'u1', 1)],
           [[0, 0, 'a', re(qr/^\d+$/), 'note1'],
	    [0, 1, 'b', re(qr/^\d+$/), undef],
	    [1, 1, 'c', re(qr/^\d+$/), 'note2']],
           n 'fetch k1 u1 with notes';

$o->begin;
$o->insert([qw/k1 u1 1 0 inserted_action inserted_note/]);
$o->commit;

$ro->start;
cmp_deeply [$ro->fetch('k1', 'u1', 1)],
           [[0, 0, 'a', re(qr/^\d+$/), 'note1'],
	    [0, 1, 'b', re(qr/^\d+$/), undef],
	    [1, 0, 'inserted_action', re(qr/^\d+$/), 'inserted_note'],
	    [1, 1, 'c', re(qr/^\d+$/), 'note2']],
           n 'fetch k1 u1 after insert';

$o->begin;
$o->update([qw/k1 u1 1 0/, $o->_db->main_index->{trans}->{db}
                             ->{actn}->{k1}->{u1}->[2]->[3]],
	   [qw/k1 u1 1 3/, "updated\naction", "updated\nnote"]);
$o->commit;

SKIP: {
  eval 'use JSON::XS; use Algorithm::Diff';
  $@ and skip 'JSON::XS or Algorithm::Diff not installed', 4;

  cmp_deeply [$ro->diff($o)],
             [
              [["-", 2,
                ["k1", "u1", 1, 0, "inserted_action", "inserted_note"]]],
              [["+", 3,
                ["k1", "u1", 1, 3, "updated\naction", "updated\nnote"]]],
             ],
             n 'diff after update';

  cmp_deeply [$ro->diff($o, qw/key k1 uri u1/)],
             [
              [["-", 2,
                ["k1", "u1", 1, 0, "inserted_action", "inserted_note"]]],
              [["+", 3,
                ["k1", "u1", 1, 3, "updated\naction", "updated\nnote"]]],
             ],
             n 'diff2 after update';

  cmp_deeply [$ro->diff($o, qw/key k1 uri u2/)],
             [],
             n 'diff3 after update';

  cmp_deeply [$ro->diff($o, qw/key hugo uri erna/)],
             [],
             n 'diff4 after update';
}

$ro->start;
cmp_deeply [$ro->fetch('k1', 'u1', 1)],
           [[0, 0, 'a', re(qr/^\d+$/), 'note1'],
	    [0, 1, 'b', re(qr/^\d+$/), undef],
	    [1, 1, 'c', re(qr/^\d+$/), 'note2'],
	    [1, 3, "updated\naction", re(qr/^\d+$/), "updated\nnote"]],
           n 'fetch k1 u1 after update';

$o->begin;
$o->delete([qw/k1 u1 1 1/, $o->_db->main_index->{trans}->{db}
                             ->{actn}->{k1}->{u1}->[2]->[3]]);
$o->commit;

$ro->start;
cmp_deeply [$ro->fetch('k1', 'u1', 1)],
           [[0, 0, 'a', re(qr/^\d+$/), 'note1'],
	    [0, 1, 'b', re(qr/^\d+$/), undef],
	    [1, 3, "updated\naction", re(qr/^\d+$/), "updated\nnote"]],
           n 'fetch k1 u1 after delete';

#$o->dump("%{KEY} / %{URI}\t%{BLOCK}/%{ORDER} %{ID}\n%{pa>> ;ACTION}\n%{pn>> ;NOTE}\n\n");

my @l=([qw/k1 u1 0 0 a note1/, re(qr/^\d+$/)],
       [qw/k1 u1 0 1 b/, undef, re(qr/^\d+$/)],
       [qw/k1 u1 1 3/, "updated\naction", "updated\nnote", re(qr/^\d+$/)],
       [qw/k1 u2 0 0 d note3/, re(qr/^\d+$/)],
       [qw/k1 u2 1 0 e note4/, re(qr/^\d+$/)],
       [qw/k1 u2 1 1 f/, undef, re(qr/^\d+$/)]);
my $i=0;
for( my $iterator=$o->iterator; my $el=$iterator->(); $i++ ) {
  cmp_deeply($el, $l[$i], n "iterator $i");
}
cmp_deeply( $i, 6, n 'iteratorloop count' );

$o->begin;
$o->clear;
$o->commit;

$ro->start;
cmp_deeply [$ro->fetch('k1', 'u1', 1)],
           [],
           n 'cleared';

$o->begin;
eval {$o->clear};
cmp_deeply $@, '', n 'clear an already cleared db'.($@?": $@":'');
$o->commit;

$o->stop;

