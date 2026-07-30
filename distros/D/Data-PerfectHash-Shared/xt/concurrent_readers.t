use strict; use warnings; use Test::More; use Config; use POSIX (); use File::Temp 'tempdir';
use Data::PerfectHash::Shared;
plan skip_all=>'fork required' unless $Config{d_fork};

my $dir=tempdir(CLEANUP=>1); my $p="$dir/c.phs";
my @ids = map { $_*3+1 } 0..9999;      # 10000 members: 1,4,7,...,29998
my @non = map { $_*3+2 } 0..99;        # 100 guaranteed non-members (residue 2 mod 3; members are residue 1)
Data::PerfectHash::Shared->build_int($p,\@ids);

# Start barrier: each child blocks on a read that returns only at EOF, which
# happens once EVERY write-end of the pipe is closed -- i.e. after all 8 have
# forked and closed their copy, and the parent closes its copy below. This
# makes the 8 lookup loops genuinely overlap (maximizing the chance of exposing
# any latent shared/static state in load()/has()). Deadlock-safe: no child ever
# waits on another child, and the parent's close always fires.
pipe(my $rgate, my $wgate) or die "pipe: $!";
my @pid;
for my $c (1..8){
  my $pid = fork // die "fork: $!";
  unless ($pid) {                                   # child
    close $wgate;                                   # child only reads the gate
    my $set = Data::PerfectHash::Shared->load($p);  # independent mmap per child
    sysread($rgate, my $b, 1);                      # block until parent releases (EOF)
    my $hit=0; for my $r (1..50) { $hit += $set->has($_) for @ids; }   # 500k member lookups
    my $fp=0; for my $k (@non) { $fp++ if $set->has($k); }             # must find zero
    POSIX::_exit( ($hit == 50*@ids && $fp == 0) ? 0 : 1 );
  }
  push @pid, $pid;
}
close $rgate;                                        # parent does not read
close $wgate;                                        # release all children simultaneously (EOF)
my $bad=0; for (@pid){ waitpid $_,0; $bad++ if $? & 127 or $?>>8; }
is $bad, 0, '8 concurrent readers: all members hit, zero false positives, no crash (lock-free)';
done_testing;
