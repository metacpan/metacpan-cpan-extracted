use strict; use warnings;
use lib $ENV{APLIB};
use Atomic::Pipe;
use Storable qw/freeze/;
use POSIX ();
# usage: prof.pl event|frame mixed(0|1)
my ($shape, $mixed) = @ARGV;
open my $fh, '<', 'events.jsonl' or die; my @EV = grep {length} map {chomp; $_} <$fh>;
my @M = $shape eq 'event' ? @EV : map { freeze([@EV[$_*1000 .. ($_*1000+999 > $#EV ? $#EV : $_*1000+999)]]) } 0 .. int($#EV/1000);
my ($r, $w) = Atomic::Pipe->pair($mixed ? (mixed_data_mode => 1) : ());
$w->resize(1 << 20);
my $pid = fork // die;
unless ($pid) { DB::disable_profile() if defined &DB::disable_profile; $r->close; $w->write_message($_) for (@M) x 3; $w->close; POSIX::_exit(0) }
$w->close;
my $n = 0;
if ($mixed) { while (1) { my %m = $r->get_line_burst_or_data; last if !%m && $r->eof; $n++ if defined $m{message} } }
else { $n++ while defined $r->read_message }
waitpid $pid, 0;
print "msgs=$n\n";
