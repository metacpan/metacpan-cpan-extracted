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
use POSIX qw/:signal_h/;

my $stress_nproc=10;
my $stress_reader=10;
my $stress_count=15;

plan $ENV{STRESS_BDB}
     ? (tests=>3)
     : (skip_all=>'set STRESS_BDB env variable to run this test');
#plan 'no_plan';

my $serverroot=Apache::Test::vars->{serverroot};
sub n {my @c=caller; $c[1].'('.$c[2].'): '.$_[0];}
my $bdbenv=$serverroot.'/bdbenv';

use Apache2::Translation::File;
use Apache2::Translation::BDB;

File::Path::rmtree( $bdbenv );
t_mkdir( $bdbenv );
t_write_file( t_catfile($bdbenv, 'DB_CONFIG'), <<'EOF' );
set_lk_max_locks   5000
set_lk_max_lockers 5000
set_lk_max_objects 5000
set_tx_max         200
set_flags          DB_LOG_INMEMORY
set_lg_regionmax   1048576
set_lg_bsize       10485760
EOF

my $fo=Apache2::Translation::File->new(ConfigFile=>\*DATA);
$fo->start;

######################################################################
## the real tests begin here                                        ##
######################################################################

pipe my($r, $w);
my $pid;
select undef, undef, undef, .1 while( !defined($pid=fork) );
if( $pid==0 ) {
  %Apache::TestUtil::CLEAN=();
  close $r;

  my $o=Apache2::Translation::BDB->new(BDBEnv=>$bdbenv);

  my $y;
  $o->start;
 RETRY: {
    eval {
      $o->begin;
      $y=$o->append($fo);
      $o->commit;
      $o->stop;
    };
    if( $@ ) {
      if( $@ eq "__RETRY__\n" ) {
        $o->rollback;
        redo RETRY;
      }
      die "$@";
    }
  }

  print $w "$y\n";
  exit;
}

cmp_deeply scalar(<$r>)+0, 6, 'init';

select( (select(STDERR), $|=1)[0] );
print STDERR "stress test -- please be patient ...\n";

pipe my($r2, $w2);
my @reader_pids;
for( my $i=0; $i<$stress_reader; $i++ ) {
  select undef, undef, undef, .1 while( !defined($pid=fork) );
  if( $pid==0 ) {
    %Apache::TestUtil::CLEAN=();
    close $r;
    close $w;
    close $r2;

    my $done;
    $SIG{TERM}=sub {$done++};

    my $o=Apache2::Translation::BDB->new(BDBEnv=>$bdbenv, ReadOnly=>1);

    my $block=POSIX::SigSet->new(SIGTERM);

    my ($x, $y)=(0,0);
    $o->start;
    while( !$done ) {
      sigprocmask( SIG_BLOCK, $block );
      my @l=$o->fetch('k1', 'u2');
      sigprocmask( SIG_UNBLOCK, $block );
      $y+=(@l!=3);
      $x++;
    }
    $o->stop;

    print $w2 "$y $x\n";
    exit;
  }
  push @reader_pids, $pid;
}

for( my $i=0; $i<$stress_nproc; $i++ ) {
  select undef, undef, undef, .1 while( !defined($pid=fork) );
  if( $pid==0 ) {
    %Apache::TestUtil::CLEAN=();
    close $r;
    close $r2;
    close $w2;

    my $o=Apache2::Translation::BDB->new(BDBEnv=>$bdbenv);

    my $x;
    my $y=0;
    my $retry=0;
    for( $x=0; $x<$stress_count; $x++ ) {
      $o->start;
    RETRY: {
        eval {
          $o->begin;
          $y+=($o->clear==6);
          $y+=($o->append($fo)==6);
          $o->commit;
          $o->stop;
        };
        if( $@ ) {
          if( $@ eq "__RETRY__\n" ) {
            $o->rollback;
            $retry++;
            redo RETRY;
          }
          die "$@";
        }
      }
    }
    #warn "#### $$: $x $y $retry\n";
    print $w ($x+$y)." $retry\n";
    exit;
  }
}

close $w;
close $w2;
my $sum=0;
my $resolved_deadlocks=0;
while( defined( my $l=<$r> ) ) {
  $l=~/(\d+) (\d+)/ and do {
    $sum+=$1;
    $resolved_deadlocks+=$2;
  };
}
print STDERR "                         $resolved_deadlocks deadlocks resolved\n";
cmp_deeply $sum, 3*$stress_count*$stress_nproc, n "stress count";

kill 'TERM', @reader_pids;
$sum=0;
my $retry_total=0;
while( defined( my $l=<$r2> ) ) {
  $l=~/(\d+) (\d+)/ and do {
    $sum+=$1;
    $retry_total+=$2;
  };
}
cmp_deeply $sum, 0, n "all $retry_total reads are okay";

__DATA__
>>> 1 k1 u1 0 0
a
>>> 2 k1 u1 1 1
c
>>> 3 k1 u1 0 1
b
>>> 4 k1 u2 0 0
d
>>> 5 k1 u2 1 1
f
>>> 6 k1 u2 1 0
e
