use strict; use warnings; use lib $ENV{APLIB}; use Atomic::Pipe; use POSIX; use Time::HiRes 'time';
my $L = ('x' x 100) . "\n"; my $N = 150_000; # 15MB of 101B lines
my ($r,$w)=Atomic::Pipe->pair(mixed_data_mode=>1); $w->resize(1<<20);
my $t=time; unless (fork) { $r->close; my $wh=$w->wh; syswrite($wh, $L x 1000) for 1..$N/1000; $w->close; POSIX::_exit(0) } $w->close;
my $n=0; while (1) { my %m=$r->get_line_burst_or_data; last if !%m && $r->eof; $n++ if defined $m{line} }
wait; printf "lines=%d %.2fs %.1f MB/s\n",$n,time-$t,$N*101/1e6/(time-$t);
