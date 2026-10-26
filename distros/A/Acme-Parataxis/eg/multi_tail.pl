use v5.40;
use blib;
$|++;
use Acme::Parataxis qw[:all];
use Acme::Parataxis::Channel;
use File::Spec;
use File::Temp 'tempdir';
use Time::HiRes qw[time];

# multi-tail: one parataxis fiber per log file, all tailing a growing set of
# rotated log files from a single OS thread. Every tail fiber is a plain
# synchronous loop - open, sysread to EOF, await_sleep(poll), repeat - the
# kind of code that would serialize trivially if the files were read one after
# another; run together they all advance within the same poll window.
#
#   writer (1 fiber)  simulates N loggers, appending patterned lines to each
#     file at staggered rates and parking between appends, so the scheduler
#     keeps the tails running. Halfway through it rotates err.log (renamed
#     aside and recreated, or truncated in place when the OS denies moving a
#     file another fiber has open - Windows does), so the tail fiber must
#     notice the shrink and fold to the fresh file.
#   tails (1 fiber per file)  sysread whatever appeared since the last poll,
#     push each complete line onto a bounded channel as {file,text}; a size
#     that shrank or a different inode at the same path is treated as
#     rotation and the fiber reopens the path and keeps going.
#   main (the run() body)  drains the channel - the filter/annotate stage -
#     and prefixes every line with a running count and the file it came from,
#     applying the optional --match filter. Bounded queues mean memory never
#     tracks the log volume.
#
# Usage:  perl eg/multi_tail.pl [--match PATTERN] [--lines N] [--poll MS]
#   self-generates its logs so it runs anywhere, prints the tailed stream,
#   then exits 0 once the writer is done and every tail has caught up.
my $POLL  = 120;    # ms between tail polls
my $LINES = 60;     # lines per file; 3 * $LINES streams in total
my $MATCH;
{
    my @a = @ARGV;
    while (@a) {
        my $arg = shift @a;
        if    ( $arg eq '--match' ) { $MATCH = shift @a }
        elsif ( $arg eq '--lines' ) { $LINES = int shift @a }
        elsif ( $arg eq '--poll' )  { $POLL = int shift @a }
        else                        { die "unknown option '$arg'\n" }
    }
}
$MATCH = $MATCH ? eval {qr/$MATCH/} // die "bad --match '$MATCH': $@" : undef;
my $dir   = tempdir( 'parataxis-mtail-XXXXXX', CLEANUP => 0, TMPDIR => 1 );
my @NAMES = qw[app.log web.log err.log];
my @paths = map { File::Spec->catfile( $dir, $_ ) } @NAMES;
for my $p (@paths) {    # loggers pre-exist: a tail must never race their creation
    open my $fh, '>', $p or die "cannot seed $p: $!\n";
    close $fh;
}
my @TAGS        = qw[conn http err];
my $out         = Acme::Parataxis::Channel->new( capacity => 1024 );
my $writer_done = 0;
my $start       = time();

sub writer_fiber {
    my @done    = ( 0, 0, 0 );
    my $rotated = 0;
    while ( $done[0] + $done[1] + $done[2] < 3 * $LINES ) {
        my $slot = int rand 3;
        next if $done[$slot] >= $LINES;
        $done[$slot]++;
        my $text = sprintf '%s.%d', $TAGS[$slot], $done[$slot];
        open my $fh, '>>', $paths[$slot] or die "cannot append $paths[$slot]: $!\n";
        print {$fh} scalar(localtime), " $text\n";
        close $fh;
        my $total = $done[0] + $done[1] + $done[2];

        if ( !$rotated && $total >= int( 3 * $LINES / 2 ) ) {
            my $bak = "$paths[2].old";
            unlink $bak if -e $bak;
            if ( rename $paths[2], $bak ) {
                open my $nf, '>>', $paths[2] or die "cannot recreate $paths[2]: $!\n";
                print {$nf} scalar(localtime), " notice err.log rotated away and recreated\n";
                close $nf;
                $out->put( { file => '---', text => "err.log was rotated away and recreated" } );
            }
            else {
                open my $nf, '>', $paths[2] or die "cannot rotate $paths[2]: $!\n";
                print {$nf} scalar(localtime), " notice err.log truncated in place (rename denied)\n";
                close $nf;
                $out->put( { file => '---', text => "err.log was truncated in place (rename denied)" } );
            }
            await_sleep( 3 * $POLL );    # settle: let the tail reopen before any new err.log writes
            $rotated = 1;
        }
        await_sleep( 4 + int rand 18 );    # park, don't block the shared thread
    }
    $writer_done = 1;
    1;
}

sub tail_fiber ( $id, $path ) {
    open my $fh, '<', $path or die "cannot open $path: $!\n";
    binmode $fh;
    seek $fh, 0, 2;                   # skip whatever pre-existed: tail only
    my $name     = $NAMES[$id];
    my $consumed = -s $path;          # bytes logically read (tell() is unreliable here)
    my $ino      = ( stat $fh )[1];
    my $carry    = '';
    while (1) {
        my $chunk = '';
        my $n     = sysread( $fh, $chunk, 65536 );
        if ( defined $n && $n > 0 ) {
            $consumed += $n;
            $carry .= $chunk;
            while ( ( my $i = index $carry, "\n" ) >= 0 ) {
                my $line = substr $carry, 0, $i + 1, '';
                chop $line;
                $out->put( { file => $name, text => $line } );
            }
        }
        my $size = -s $path;
        my $pino = ( stat $path )[1];
        if ( ( defined $size && $size < $consumed ) || ( defined $pino && $pino != $ino ) ) {
            close $fh;                            # truncated or replaced: fold to the fresh file
            my $opened = 0;
            for ( my $t = 0; $t < 10; $t++ ) {    # the path can briefly not exist mid-rotation
                if ( open $fh, '<', $path ) {
                    binmode $fh;
                    $ino      = ( stat $fh )[1];
                    $carry    = '';                # the fresh file is a new ledger
                    $consumed = 0;
                    $opened   = 1;
                    last;
                }
                await_sleep($POLL);
            }
            last if !$opened;    # the path vanished for good and the writer is gone
            $out->put( { file => '---', text => "$name was rotated; tailing the fresh file" } );
        }
        last if $writer_done && $carry eq '' && ( ( -s $path // -1 ) <= $consumed );
        await_sleep($POLL);
    }
    close $fh;
    1;
}
run(
    sub {
        spawn( \&writer_fiber );
        my @tails;
        for my $id ( 0 .. $#NAMES ) {
            my $path = $paths[$id];
            push @tails, spawn( sub { tail_fiber( $id, $path ) } );
        }
        spawn( sub { $_->await for @tails; $out->shutdown; 1 } );    # reaper: close the stream
        my $seen  = 0;                                               # lines on the channel = filter/annotate stage input
        my $shown = 0;
        while ( defined( my $ent = $out->get ) ) {
            $seen++;
            next if defined $MATCH && $ent->{text} !~ $MATCH;
            $shown++;
            printf "%-4d %-20s %s\n", $seen, $ent->{file}, $ent->{text};
        }
        $_->await for @tails;
        my $elapsed = time() - $start;
        say sprintf "\n%d line(s) streamed through %d tail fiber(s) in %.2fs", $seen, scalar @NAMES, $elapsed;
        say "$shown shown" if defined $MATCH;
        say "(scheduler: 1 OS thread, ", Acme::Parataxis::get_live_fiber_count(), " live fiber(s) at the end)";
        stop();
    }
);
for my $p ( @paths, map {"$_.old"} @paths ) {    # everything closed: clear the temp dir
    unlink $p;
}
rmdir $dir;
exit 0;
