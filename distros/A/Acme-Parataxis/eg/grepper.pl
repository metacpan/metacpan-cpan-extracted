use v5.40;
use blib;
$|++;
use Acme::Parataxis qw[:all];
use Acme::Parataxis::Channel;

# A bounded-memory concurrent grepper, in the spirit of ripgrep, built on
# fibers. This is the case fibers exist for: one process, shared state, and
# plain synchronous-looking code (open/opendir/sysread) that would otherwise
# trivially serialize -- now fanned out over a fixed pool of worker fibers.
#
# Architecture, all of it on the Parataxis scheduler:
#
#   dir_generator (1 fiber)   BFS the roots, lazily discovering subdirectories,
#     pushes each directory onto $work (bounded: capacity == CONCURRENCY) with
#     a non-blocking try_put + yield, so a huge tree cannot balloon memory.
#     When the frontier is exhausted it parks CONCURRENCY sentinels, one per
#     worker, then retires -- every real directory is FIFO-ahead of them.
#
#   workers (CONCURRENCY fibers) get a directory, scan only its direct files
#     in 64 KiB chunks (maybe_yield between chunks, NUL byte = binary, skip),
#     and put each {file,line,text} match onto $hits (bounded: 4096). A full
#     $hits channel parks the worker: the result channel is the backpressure.
#
#   reaper (1 fiber) awaits the generator and every worker, then $hits->shutdown.
#
#   main (the run() body) drains $hits as fast as they land and prints them
#     in grep format, so a 10 GB log tree costs memory proportional to the two
#     bounded queues, not to the tree or the match count.
#
# Ctrl-C sets $stop: the generator bails out (parking the sentinels anyway so
# workers can retire) and the run winds down gracefully.
#
# Usage:  perl eg/grepper.pl [PATTERN [DIR ...]]
#   defaults search this module's own tree (lib t inc eg) for 'parataxis'.
my $CONCURRENCY = 8;
my $CHUNK       = 64 * 1024;
my $CAP         = 250;         # printed matches cap; the full count still lands
my $work_hits   = [ 0, 0 ];    # [scanned files, scanned bytes] shared by workers

# Split remaining @ARGV after pattern/dirs; default to the module's own tree.
my ( $pattern, @roots ) = @ARGV;
$pattern = '(?i:parataxis)' if !defined $pattern;
if ( !@roots ) {
    @roots = grep {-d} qw[lib t inc eg];
}
@roots or die "no search roots given and no default tree present here\n";
my $re   = eval {qr/$pattern/} // die "bad pattern '$pattern': $@";
my $stop = 0;
my $done = 0;                                                         # set by the reaper once every producer has retired
$SIG{INT} = sub { $stop = 1 };
my $SENTINEL = { sentinel => 1 };                                     # ref, so it can never be a directory path

sub dir_generator ( $work, $workers ) {
    my @frontier = @roots;
    while ( @frontier && !$stop ) {
        my $dir    = shift @frontier;
        my $pushed = $work->try_put($dir);
        while ( !$pushed && !$stop ) {
            yield;
            $pushed = $work->try_put($dir);
        }
        next if $stop;
        opendir my $dh, $dir or next;
        my @kids = readdir $dh;
        closedir $dh;
        for my $kid (@kids) {
            next if $kid eq '.' || $kid eq '..';
            next if index( $kid, '.' ) == 0;       # skip dot dirs (.git, .github, ...)
            my $path = $dir eq '.' ? $kid : "$dir/$kid";
            push @frontier, $path if -d $path;
        }
    }
    $work->put($SENTINEL) for 1 .. $workers;    # one wake-up per worker, FIFO after all dirs
    1;
}

sub scan_dir ( $dir, $hits ) {
    opendir my $dh, $dir or return;
    my @files = readdir $dh;
    closedir $dh;
FILE: for my $name (@files) {
        next if $name eq '.' || $name eq '..';
        my $path = $dir eq '.' ? $name : "$dir/$name";
        next unless -f $path;
        $work_hits->[0]++;
        open my $fh, '<', $path or next;
        binmode $fh;
        my $buf    = '';
        my $line   = 0;
        my $pend   = '';
        my $binary = 0;
        my $first  = 1;

        while (1) {
            my $n = sysread( $fh, $buf, $CHUNK );
            last if !defined $n || $n == 0;
            if ($first) {
                $binary = index( $buf, "\0" ) >= 0 ? 1 : 0;
                $first  = 0;
                last if $binary;    # skip binary files after the check, not per chunk
            }
            $work_hits->[1] += $n;
            maybe_yield;            # let sibling workers interleave between chunks
            $pend .= $buf;
            while ( ( my $i = index $pend, "\n" ) >= 0 ) {
                $line++;
                my $text = substr $pend, 0, $i + 1, '';
                chop $text;
                next if $text !~ $re;
                my $out = $text;
                $out = substr( $out, 0, 120 ) . '...' if length $out > 120;
                $hits->put( { file => $path, line => $line, text => $out } );
            }
        }
        close $fh;
        next FILE if $binary;
        if ( length $pend ) {    # trailing line without newline
            $line++;
            $hits->put( { file => $path, line => $line, text => $pend } ) if $pend =~ $re;
        }
    }
    1;
}

sub worker ( $work, $hits ) {
    while (1) {
        my $dir = $work->get;
        last if ref $dir || $stop;    # sentinel or interrupt
        scan_dir( $dir, $hits );
    }
    1;
}
my ( $files_scanned, $bytes_scanned, $matches, $printed ) = ( 0, 0, 0, 0 );
run(
    sub {
        say "parataxis grepper: /$pattern/ over " . join( ', ', @roots ) . " with $CONCURRENCY worker fibers (Ctrl-C to stop early)";
        my $work    = Acme::Parataxis::Channel->new( capacity => $CONCURRENCY );
        my $hits    = Acme::Parataxis::Channel->new( capacity => 4096 );
        my @workers = map {
            spawn( sub { worker( $work, $hits ) } )
        } 1 .. $CONCURRENCY;
        my $gen    = spawn( sub { dir_generator( $work, $CONCURRENCY ) } );
        my $reaper = spawn(
            sub {
                $gen->await;
                $_->await for @workers;
                $hits->shutdown;
                $done = 1;
            }
        );

        # A progress ticker that also shows the bounded queues doing real work.
        spawn(
            sub {
                my $last = 0;
                while ( !$stop && !$done ) {
                    await_sleep(250);
                    next if $last == $work_hits->[0];
                    $last = $work_hits->[0];
                    say sprintf '  [%d scanned] %d bytes in; work queue %d, hits queue %d, %d matches so far', $last, $work_hits->[1], $work->size,
                        $hits->size, $matches;
                }
            }
        );
        while ( my $hit = $hits->get ) {
            $matches++;
            if ( $printed < $CAP ) {
                $printed++;
                say sprintf '%s:%d: %s', $hit->{file}, $hit->{line}, $hit->{text};
            }
            elsif ( $printed == $CAP ) {
                $printed++;    # so the "..." note prints exactly once
                say "  ... ($matches more)";
            }
        }
        $files_scanned = $work_hits->[0];
        $bytes_scanned = $work_hits->[1];
        say '';
        say "+$matches match(es) in $files_scanned file(s), $bytes_scanned bytes scanned, on $CONCURRENCY workers";
        say 'interrupted by user'                       if $stop;
        die "self-test failed: no files scanned\n"      if !$files_scanned && !$stop;
        die "self-test failed: pattern never matched\n" if !$matches       && !$stop;
        stop();
    }
);
say 'exit 0';
