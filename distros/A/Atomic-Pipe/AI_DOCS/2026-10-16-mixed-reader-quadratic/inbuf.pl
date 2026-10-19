use strict; use warnings; use lib '/home/exodist/projects/exodist/Atomic-Pipe/lib'; use Atomic::Pipe; use POSIX; use Time::HiRes 'time';
open my $fh, '<', 'events.jsonl' or die; my @EV = grep {length} map {chomp; $_} <$fh>;
for my $z (0,1) {
my ($r,$w) = Atomic::Pipe->pair(mixed_data_mode=>1, $z ? (compression=>'zstd') : ()); $w->resize(1<<20);
my $t=time; unless (fork) { $r->close; $w->write_message($_) for @EV; $w->close; POSIX::_exit(0) } $w->close;
my ($max,$fills,$n)=(0,0,0); { no warnings 'redefine'; my $o=\&Atomic::Pipe::fill_buffer; *Atomic::Pipe::fill_buffer=sub{ my $g=$o->(@_); $fills++ if $g; $max=$_[0]{in_buffer_size} if ($_[0]{in_buffer_size}//0)>$max; $g } }
while (1) { my %m=$r->get_line_burst_or_data; last if !%m && $r->eof; $n++ if defined $m{message} }
wait; printf "zstd=%d msgs=%d time=%.2fs successful_reads=%d max_in_buffer=%.1fMB\n",$z,$n,time-$t,$fills,$max/1e6;
}
