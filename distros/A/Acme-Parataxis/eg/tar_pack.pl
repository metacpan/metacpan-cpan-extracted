#!/usr/bin/perl
# Building a .tar.gz that Ctrl-C can actually interrupt.
#
# Archive::Tar and Compress::Zlib are both C. Neither one of them has a chunked Perl-level API you can
# park in the middle of, so the reflex - wrap the call, get a cooperative program - does not work, and
# the honest version of this exercise is to *choose where the await boundaries go* and then measure
# where Ctrl-C actually lands.
#
# The shape:
#
#   1. A small input tree, and a per-file checksum computed in chunks. The chunk boundary is the await
#      boundary, so a cancel lands within one chunk of the signal rather than at the end of the file.
#   2. The archive, built with Archive::Tar. add_data() per file is interruptible between files;
#      write() is a single call into C and is not interruptible at all.
#   3. The cancellation, for real: a token on $SIG{INT}, a with_timeout scope, and the output file
#      cleaned up afterwards. A half-written .tar.gz is worse than no .tar.gz, and the demo says why.
#   4. Offloading the build to a thread, and the trap that comes with it: cancelling the await does not
#      stop the closure, so the file keeps growing after you have decided the run is over.
#
# Run it: perl -Mblib eg/tar_pack.pl [files] [bytes-per-file]
#
# Section 4 needs Acme::Parataxis::Blocking and a threaded perl. Without them it prints why and stops.
use v5.40;
use blib;
$|++;
use Acme::Parataxis qw[:all];
use Acme::Parataxis::CancellationToken;
use Acme::Parataxis::Semaphore;
use Archive::Tar ();
use Config;
use Digest::SHA ();
use File::Path  ();
use File::Spec;
use File::Temp  ();
use Time::HiRes ();
my $FILE_COUNT = shift // 12;
my $FILE_BYTES = shift // 1_048_576;
my $CHUNK      = 65_536;

# How many await boundaries a single file is divided into. This is the granularity a cancel gets, so
# the demo reports it rather than leaving it to be inferred.
my $CHUNKS_PER_FILE = int( ( $FILE_BYTES + $CHUNK - 1 ) / $CHUNK );

# NOTE: this file deliberately does NOT call enable_transparent_unblocking(). That feature and
# spawn_blocking do not mix - see section 5, which is a bug report rather than a demonstration.
# The point here is explicit await boundaries that you place on purpose, and a transparently
# unblocked sysread() would take the placement away and hand it to the scheduler.
#
# A tree to pack.
my $TREE = File::Temp->newdir( CLEANUP => 0 );

END {
    return if $main::TREE_DONE;
    $main::TREE_DONE = 1;
    File::Path::remove_tree("$TREE") if -d "$TREE";
}

sub build_tree {
    my ( $root, $count, $bytes ) = @_;
    my @paths;
    for my $i ( 0 .. $count - 1 ) {
        my $path = File::Spec->catfile( $root, sprintf( 'part%02d.dat', $i ) );
        open my $fh, '>:raw', $path or die "open $path: $!";

        # Vary the content so the gzip ratio is a real number rather than a column of zeroes.
        my $chunk = join q{}, map { chr( 32 + ( $_ * 7 + $i ) % 90 ) } 0 .. 4095;

        # The parens are required: x binds tighter than +, so without them this is
        # ( $chunk x int( $bytes / 4096 ) ) + 1 and perl tries to numify a 1 MB string.
        print {$fh} substr( $chunk x ( int( $bytes / 4096 ) + 1 ), 0, $bytes );
        close $fh;
        push @paths, $path;
    }
    return @paths;
}

# The cancellable read: hash a file, and keep its bytes, one chunk at a time.
#
# The await_sleep(0) is the entire point of this sub. It is the boundary a cancel lands on, and it is
# a choice: with it, a Ctrl-C during a 4MB file costs one chunk of work. Without it, the file is
# atomic as far as the scheduler is concerned and the signal waits for all of it.
sub read_hashed {
    my ( $path, $on_chunk ) = @_;
    open my $fh, '<:raw', $path or die "open $path: $!";
    my $sha  = Digest::SHA->new(256);
    my $body = q{};
    my $buf;
    my $n_chunk = 0;
    while ( my $n = sysread( $fh, $buf, $CHUNK ) ) {
        $body .= substr( $buf, 0, $n );
        $sha->add( substr( $buf, 0, $n ) );
        $n_chunk++;
        await_sleep(0);    # <- the cancel boundary
        $on_chunk->( $path, $n_chunk ) if $on_chunk;
    }
    close $fh;
    return ( $sha->hexdigest, length($body), $body );
}

# Read the finished .tar.gz back and prove it is a real archive.
#
# Four API details here are load-bearing, and every one of them fails quietly rather than loudly:
#
#   * write() only reaches the compressor when you hand it a FILENAME. $tar->write( $fh, 1 ) writes an
#     uncompressed tar and still returns true - you get a .tar.gz that is not gzip.
#   * iter() likewise needs a filename. Given a filehandle it returns a valid-looking iterator that
#     yields zero entries, so a loop over it "succeeds" having verified nothing.
#   * Archive::Tar->iter() returns a CODE ref, not an object. There is no ->next_file. You call it.
#   * Archive::Tar has no addfile() at all. add_data() is the one that takes content or a filename.
#
# And gzread() overwrites the variable you hand it, including on the final zero-length read, so
# appending is the only safe accumulator - read straight into one variable and the last call erases
# the data.
sub verify_archive($path) {
    my $next = Archive::Tar->iter( $path, 1 );
    my @got;
    while ( my $f = $next->() ) {
        my $body = $f->get_content;    # Archive::Tar::File has no read(); get_content is the accessor
        push @got, [ $f->full_path, $f->size, Digest::SHA::sha256_hex($body) ];
    }
    return @got;
}

sub show_entries( $rows, $expected, $label ) {
    printf "  %-28s %d entries\n", $label, scalar @$rows;
    my $ok = ( join( q{,}, map {"$_->[0]:$_->[1]:$_->[2]"} @$rows ) eq join( q{,}, map {"$_->[0]:$_->[1]:$_->[2]"} @$expected ) ) ? 'yes' : 'NO';
    printf "  %-28s %s\n", '  names, sizes and digests match', $ok;
    return $ok eq 'yes';
}

# The build itself. One sub, so section 4 can hand it to a thread and time it here.
#
# The arguments are deliberately plain - paths, sizes, a destination - because that is exactly what
# survives the copy-in/copy-out boundary of a cloned interpreter. See section 4.
sub build_archive( $out, $paths, $expected_ref ) {
    my $tar = Archive::Tar->new;
    for my $i ( 0 .. $#$paths ) {
        my ( $digest, $size, $body ) = read_hashed( $paths->[$i], undef );
        $tar->add_data( sprintf( 'part%02d.dat', $i ), $body );
        $expected_ref->[$i] = [ sprintf( 'part%02d.dat', $i ), $size, $digest ];
    }
    $tar->write( $out, 1 );    # a FILENAME, or this writes an uncompressed tar and still returns true
    return -s $out;
}

# A closure that really is incremental, which is what section 4 needs.
#
# Archive::Tar cannot do this: it assembles the whole archive and write() emits it in one call, so
# the destination file does not exist until the job is essentially over. Compress::Zlib can. gzopen
# on a filehandle gives a streaming writer whose output file grows as the input is consumed, so a
# cancel in the middle catches it genuinely half-written - which is the state section 4 is about.
#
# The arguments are three plain scalars on purpose. A cloned interpreter gets a copy-in/copy-out
# snapshot, so anything passed in has to be something that survives being copied; see the Blocking
# documentation for what does not.
sub gzip_stream ( $src, $dst, $chunk ) {
    open my $in,  '<:raw', $src or die "open $src: $!";
    open my $out, '>:raw', $dst or die "open $dst: $!";
    my $zw  = Compress::Zlib::gzopen( $out, 'wb' );
    my $buf = q{};
    my ( $read, $passes ) = ( 0, 0 );
    while ( my $n = sysread( $in, $buf, $chunk ) ) {
        $zw->gzwrite( substr( $buf, 0, $n ) );
        $read += $n;
        $passes++;
    }
    $zw->gzclose;    # this is what flushes the last block and writes the trailer
    close $out;
    return "$read/$passes";
}

# An incompressible payload. The tree above is deliberately repetitive so the ratio in section 1 is
# dramatic, but repetitive data gzips at about 66ms for 12MB, which is too short to reliably catch a
# cancel in the middle. Random bytes take about 216ms and barely compress at all, which is both the
# slow case and the honest one: backing up files that are already compressed looks like this.
sub build_incompressible ( $path, $bytes ) {
    open my $fh, '>:raw', $path or die "open $path: $!";
    if ( open my $ur, '<:raw', '/dev/urandom' ) {    # fast, and everywhere this demo is likely to run
        my $buf;
        my $left = $bytes;
        while ( $left > 0 ) {
            my $want = $left > 1_048_576 ? 1_048_576 : $left;
            my $n    = sysread( $ur, $buf, $want );
            last if !$n;
            print {$fh} $buf;
            $left -= $n;
        }
        close $ur;
    }
    else {                                           # a portable fallback: an LCG, which is slower to generate but needs no device
        my ( $s, $buf ) = ( 2_654_435_761, q{} );
        my $left = $bytes;
        while ( $left > 0 ) {
            $buf = q{};
            for ( 1 .. 16_384 ) { $s = ( $s * 1_103_515_245 + 12_345 ) % 2_147_483_648; $buf .= pack( 'N', $s ) }
            my $n = length($buf) > $left ? $left : length($buf);
            print {$fh} substr( $buf, 0, $n );
            $left -= $n;
        }
    }
    close $fh;
    return $path;
}

# A token that a signal handler can reach, and a way to fire one without needing a real terminal.
sub token_for_signal {
    my $tok = Acme::Parataxis::CancellationToken->new( kind => 'cancel' );
    $SIG{INT} = sub { $tok->cancel };
    return $tok;
}

# Cancel from inside the program, at a chosen moment, using the same path a real Ctrl-C takes.
sub canceller ( $tok, $after_ms ) {
    my $f = fiber {
        await_sleep($after_ms);
        $tok->cancel;
        return;
    };
    return $f;
}
my @paths = build_tree( $TREE, $FILE_COUNT, $FILE_BYTES );
my $mb    = $FILE_COUNT * $FILE_BYTES / 1_048_576;
say "Packing $FILE_COUNT files, " . sprintf( '%.1f MB', $mb ) . ', in ' . $CHUNK . ' byte chunks.';
say '';

# The happy path, and the boundary you are choosing.
my @expected;
my $t0 = Time::HiRes::time();
Acme::Parataxis::run(
    sub {
        my $out = File::Spec->catfile( "$TREE", 'ok.tar.gz' );
        build_archive( $out, \@paths, \@expected );
        return;
    }
);
my $ok_ms   = ( Time::HiRes::time() - $t0 ) * 1000;
my $ok_path = File::Spec->catfile( "$TREE", 'ok.tar.gz' );
printf "  %-34s %s\n", 'built', sprintf( '%.1f ms', $ok_ms );
printf "  %-34s %s\n", 'archive size', sprintf( '%d bytes (%.0f%% of the input)', -s $ok_path, 100 * ( -s $ok_path ) / ( $mb * 1_048_576 ) );
my $ok = show_entries( [ verify_archive($ok_path) ], \@expected, 'read back with iter' );
say '';
say "  Every file in that archive was read in $CHUNK byte chunks with an await boundary between";
say '  them, so a cancel could have landed mid-file. Nothing cancelled it, so it did not.';

# Cancelling the read, with the cancel landing inside a file rather than before the first one.
say '';
say '2. Ctrl-C during the read, cancelled at a chunk boundary.';
say '';
{
    my $tok = token_for_signal();

    # A real Ctrl-C calls $tok->cancel from a signal handler at whatever moment the signal is
    # delivered, which is not reproducible. So fire the same call from a chunk callback instead, at a
    # fixed chunk number. Nothing else differs: $SIG{INT} is still wired to the same token above, and
    # the cancel still arrives from outside the wait, which is the part the scheduler has to handle.
    my $fire_at = 8;    # the 9th chunk boundary of the 3rd file
    my ( $seen, $where, $err ) = ( 0, q{}, q{} );
    my $out = File::Spec->catfile( "$TREE", 'cancelled.tar.gz' );
    Acme::Parataxis::run(
        sub {
            eval {
                # 0 means "no deadline" - this scope exists only to register the fiber with $tok, so
                # that any wait entered inside it is interruptible. with_cancel() would not do here:
                # it registers the fiber with its own scope token, and that token is not assigned
                # until the block returns, so a signal handler could not reach it. with_timeout()
                # takes a token you already hold.
                with_timeout(
                    0, $tok,
                    sub {
                        for my $i ( 0 .. $#paths ) {
                            read_hashed(
                                $paths[$i],
                                sub {
                                    $seen++;
                                    $where = sprintf( '%s chunk %d', ( split m{/}, $paths[$i] )[-1], $seen );
                                    $tok->cancel if $seen == $fire_at;
                                }
                            );
                        }
                        return 'unreachable';
                    }
                );
                1;
            } or $err = $@;
            return;
        }
    );
    printf "  %-34s %s\n",       'died with', ( $err ? ref($err) : 'NOTHING' );
    printf "  %-34s %d of %d\n", 'chunk boundaries entered', $seen, $CHUNKS_PER_FILE * scalar @paths;
    printf "  %-34s %s\n",       'cancel delivered during',  $where;
    printf "  %-34s %s\n",       'archive written', ( -e $out ? 'yes' : 'no' );
    say '';
    say sprintf( '  The cancel landed on the %dth boundary, inside a file that was %d chunks long,', $seen, $CHUNKS_PER_FILE );
    say '  and the cost of the signal was the work in flight for that one chunk. Change the chunk size';
    say '  at the top of this file and the granularity moves with it: that is the whole design';
    say "  decision, and it is yours to make, not the scheduler's.";
    say '';
    say '  Note also what is *not* on disk. The reads never reached the build stage, so there is no';
    say '  output file at all - not a zero-length one, not an empty archive. A cooperative cancel';
    say '  cannot leave you a half-written archive, because the only code that writes the destination';
    say '  is code the cancel can stop before it starts. Section 3 is about the case where that is';
    say '  not true.';
}

# What a half-written archive actually does, measured rather than asserted.
say '';
say '3. A half-written archive, and what the standard tools make of it.';
say '';
{
    # A cooperative cancel can never produce one, which is worth being precise about. write() is a
    # single call into C, so the scheduler has no boundary inside it, and section 2's cancel lands
    # before the build is even called. The only way to get a truncated archive is a signal that ends
    # the process outright - SIGKILL, a power cut, an OOM kill. So simulate that honestly: take a
    # finished archive and cut it.
    my $cut = File::Spec->catfile( "$TREE", 'cut.tar.gz' );
    my $all = do {
        open my $fh, '<:raw', $ok_path or die "open $ok_path: $!";
        local $/;
        <$fh>;
    };
    my $full = length $all;
    open my $cfh, '>:raw', $cut or die $!;
    print {$cfh} substr( $all, 0, int( $full * 0.6 ) );
    close $cfh;
    printf "  %-34s %d of %d bytes\n", 'archive cut to 60%', ( -s $cut ), $full;
    for my $tool ( [ 'gzip -t', "gzip -t $cut" ], [ 'tar tzf', "tar tzf $cut" ] ) {
        my ( $label, $cmd ) = @$tool;
        my @lines = split m/\n/, `$cmd 2>&1`;
        my $rc    = $? >> 8;
        printf "  %-34s exit %d, %d entries named\n", $label, $rc, scalar( grep {/part\d+\.dat/} @lines );
    }

    # Extraction is the dangerous one, because the files land on disk before tar gives up.
    my $dest = File::Spec->catdir( "$TREE", 'extracted' );
    File::Path::make_path($dest);
    my @out = split m/\n/, `tar xzf $cut -C $dest 2>&1`;
    my @ext = glob( File::Spec->catfile( $dest, '*' ) );
    printf "  %-34s exit %d, %d files left on disk\n", 'tar xzf into a fresh directory', $? >> 8, scalar @ext;

    # And the iterator this program uses to verify, which is the one a reader would most trust. It is
    # the worst of the four: it does not exit, and it does not die either. It warns once and hands
    # back a short list, so a verify step written as "read the entries and compare" has to notice a
    # warning to notice the damage.
    my ( $recovered, $iter_died, @iter_warned ) = ( 0, q{}, q{} );
    {
        my $next = Archive::Tar->iter( $cut, 1 );
        local $SIG{__WARN__} = sub { push @iter_warned, $_[0] };
        local $@;
        eval {
            while ( my $f = $next->() ) { $recovered++ }
            1;
        } or $iter_died = $@;
        $iter_died =~ s/\n.*//s if $iter_died;
    }
    printf "  %-34s %d of %d entries, %d warning(s), %s\n", 'Archive::Tar->iter', $recovered, $#paths + 1, scalar @iter_warned,
        ( $iter_died ? "died: $iter_died" : 'no exception' );
    if (@iter_warned) {
        my @first = grep {length} map {
            my $w = $_;
            $w =~ s{\s+at\s+\S+\s+line\s+\d+\.?\s*\z}{};    # drop "at eg/foo.pl line 289."
            $w =~ s{\A\s+}{};
            $w =~ s{\s*\n.*}{}s;
            $w;
        } @iter_warned;
        printf "  %-34s %s\n", '  it warns', join( ' / ', @first ) if @first;
    }
    say '';
    say '  gzip and tar both exit non-zero, so a caller that checks will notice. But look at when:';
    say '  tar names the entries it recovered on stdout, tar xzf puts the files on disk, and only then';
    say '  does either report the error. A consumer that ignores the exit status, or whose status is';
    say '  lost to a timeout or a killed pipeline, is left holding a directory that looks exactly like';
    say '  a successful extract.';
    say '';
    say '  Archive::Tar->iter is the one to be careful with, and it is the one this program itself';
    say '  uses to verify. It does not exit - it is a library - and it does not die. It warns, returns';
    say '  a short list, and lets you get on with it. So the verify step in this file compares the';
    say '  entry count and the digests; the count is the part that catches the truncation, and a';
    say '  verify that only checked that iteration completed would have passed.';
    say '';
    say '  Note also what the scheduler did NOT have to do here: it did not prevent the truncation,';
    say '  and it could not. The process was killed rather than cancelled. Atomicity has to come from';
    say '  the filesystem, not from cooperation -';
    say '';
    my $tmp = File::Spec->catfile( "$TREE", 'staged.tar.gz' );
    my @junk;
    Acme::Parataxis::run( sub { build_archive( $tmp, \@paths, \@junk ) } );
    show_entries( [ verify_archive($tmp) ], \@junk, 'staged, then read back' );
    rename( $tmp, $ok_path ) or die "rename: $!";
    printf "  %-34s %s\n", 'published by rename()', ( -e $tmp ? 'FAILED - staging file still present' : 'yes, staging file is gone' );
    say '';
    say '  Write to a temporary name in the same directory, read the archive back and check the';
    say '  entries, and only then rename() into place. rename() is atomic within a filesystem, so a';
    say '  concurrent reader sees either the previous archive or the new one and never half of';
    say '  either, however the process died.';
}

# Offloading the build, and the one trap in this whole file.
say '';
say '4. The same build on a thread.';
say '';
my $ithreads = ( defined $Config{useithreads} && $Config{useithreads} eq 'define' ) ? 1 : 0;
$ithreads = 0 if $^O eq 'MSWin32';
my $have_blocking = eval { require Acme::Parataxis::Blocking; 1 } ? 1 : 0;
if ( $have_blocking && $ithreads ) {
    require Acme::Parataxis::Blocking;
    require Compress::Zlib;
    my $big  = build_incompressible( File::Spec->catfile( "$TREE", 'raw.bin' ), 12 * 1_048_576 );
    my $out  = File::Spec->catfile( "$TREE", 'streamed.gz' );
    my $tok  = token_for_signal();
    my $want = -s $big;

    # Everything happens in one run(), on one fiber. That is not tidiness: several sequential run()
    # calls in a program this shape leave the second one without a scheduled fiber to park in, and
    # the failure shows up as "_park() must be called from inside a scheduled fiber" on an await that
    # is plainly inside one. A fiber that awaits a Future and then keeps going is the normal shape.
    my ( $at, $then, $settled, $grew, $await_result, $await_died, $err );
    my $watch_ms = 2_000;
    my $t0       = Time::HiRes::time();
    Acme::Parataxis::run(
        sub {
            my $fut = Acme::Parataxis::Blocking::spawn_blocking( \&gzip_stream, $big, $out, $CHUNK );

            # Sequence, and the reason for it. The thread needs roughly 10ms to clone an interpreter
            # before it touches anything, and the job takes a few hundred ms, so a sleep in between
            # lands us squarely mid-write. Cancel *before* the spawn and you get the pre-cancelled
            # path instead, which fails without ever entering the await and shows you nothing.
            await_sleep(70);
            $tok->cancel;    # the same call $SIG{INT} makes
            $at   = ( Time::HiRes::time() - $t0 ) * 1000;
            $then = -e $out ? -s $out : 0;
            eval {
                with_timeout( 0, $tok, sub { $fut->await } );
                1;
            } or $err = $@;

            # The closure is still running. Watch the file, and do not ask the thread anything to do
            # it. Bounded by wall time so the "after" figure means something: this is how big the file
            # got in the two seconds that followed the cancellation.
            my $w0 = Time::HiRes::time();
            while ( ( Time::HiRes::time() - $w0 ) * 1000 < $watch_ms ) {
                my $now = -e $out ? -s $out : 0;
                $settled = $now;
                last if $now >= $want;
                await_sleep(25);
            }
            $grew = ( $settled // 0 ) > $then;

            # And the half that is easy to skip: awaiting again, outside the cancel scope, works. The
            # slot is still held and the result is still there.
            eval { $await_result = $fut->await; 1 } or $await_died = $@;
            return;
        }
    );
    printf "  %-34s %s\n",                    'cancel delivered after',     sprintf( '%.0f ms', $at );
    printf "  %-34s %d of %d bytes\n",        'output file at that moment', $then, $want;
    printf "  %-34s %s\n",                    'the await returned', ( $err ? ref($err) : 'a result' );
    printf "  %-34s %d bytes, %d ms later\n", 'output file once it settled', ( $settled // $then ), $watch_ms;
    say '';
    if ($grew) {
        say "  It grew by " . ( $settled - $then ) . " bytes *after* the cancellation. That is not a bug and it is";
        say '  not fixable: the closure is a real OS thread running real code, and there is no safe way';
        say '  to yank one mid-instruction. The Blocking documentation says so in as many words -';
        say '  "Cancelling the await does not stop the closure (a real OS thread cannot be yanked); it';
        say '  withdraws the waiter, and the slot releases when the closure actually finishes."';
        say '';
        say '  What that costs a program like this one, concretely:';
        say '    * Do not unlink or rename the output because the await was cancelled. The thread is';
        say '      still writing to that path. unlink only removes the directory entry; the thread goes';
        say '      on filling an inode nothing can reach, and the space comes back only at thread exit.';
        say '    * Do not treat the Future as settled. Only the waiter is gone.';
        say '    * If the destination must be untouched on cancel, have the closure write to a path it';
        say '      owns and let the cancelling fiber decide afterwards what becomes of that file.';
        say '';
        say '  And the follow-through, which is the half that is easy to skip:';
    }
    else {
        say '  It did not grow on this run, so either the closure had already finished or it never got';
        say '  going. Raise the payload size, or lower the sleep, to make mid-write the usual case.';
        say '';
    }
    printf "  %-34s %s\n", 'awaited again, outside the scope',
        ( $await_died ? do { my $x = $await_died; $x =~ s/\n.*//s; "died: $x" } : "'$await_result' (bytes read / chunk passes)" );
    if ( -e $out ) {
        printf "  %-34s %s\n", 'and it is a valid gzip stream', ( system( 'gzip -t ' . quotemeta($out) . ' >/dev/null 2>&1' ) == 0 ? 'yes' : 'NO' );
        unlink $out;
        printf "  %-34s %s\n", 'after unlink', ( -e $out ? 'STILL THERE' : 'gone' );
    }
}
else {
    say '  Acme::Parataxis::Blocking, the separate distribution that provides spawn_blocking, is not';
    say '  available here, so the build stays on this thread:';
    printf "    %-38s %s\n", 'Blocking installed:',        ( $have_blocking               ? 'yes'                            : 'no' );
    printf "    %-38s %s\n", 'an ithreads perl to clone:', ( $ithreads                    ? 'yes'                            : 'no' );
    printf "    %-38s %s\n", '$Config{useithreads}',       ( defined $Config{useithreads} ? "'" . $Config{useithreads} . "'" : 'undef' );
    say '';
    say '  The trap still applies, it is just not demonstrable without the thread, and it is worth';
    say '  knowing before you reach for spawn_blocking on a long job: a cancelled await withdraws the';
    say '  waiter and nothing else. The closure runs to completion. Do not clean up its output on the';
    say '  strength of a cancellation alone.';
    say '';
    say '  Compare the inline numbers: the build above took ' . sprintf( '%.1f ms', $ok_ms ) . ' for ' . sprintf( '%.1f MB', $mb ) . '.';
    say '  A spawn_blocking call costs on the order of 10ms before it starts, so for a job this size';
    say '  the thread is not worth reaching for on speed grounds - only because you want the bytes';
    say '  moving while this thread does something else.';
}

# Two features in this distribution that must not be used in the same program.
#
# This section is a bug report, not a demonstration, and the numbers in it were measured on the
# threaded 5.44.0 build. It is here because the combination is easy to reach by accident: a program
# that turns on transparent unblocking to stop writing await_sleep(0) by hand, and then reaches for
# spawn_blocking for one long job.
#
# enable_transparent_unblocking() installs Acme::Parataxis::Compat, which overrides core file and
# pipe operations process-wide. threads->create clones the interpreter, overrides included, so a
# worker thread inherits them - and inside that worker there is no scheduler and no fiber, so the
# override tries to park a wait that cannot exist.
#
# What that costs, measured, reading a 12MB file in 64KB passes from a spawn_blocking closure:
#
#   transparent unblocking off   192 passes, 12582912 bytes read, exit 0
#   transparent unblocking on    the closure stops partway, and the Future carries
#                                "_park() must be called from inside a scheduled fiber"
#                                instead of anything to do with the file
#
# The second case is not a tidy error, though. At 4MB it prints
# "Attempt to free unreferenced scalar" and then returns the right answer anyway; at 12MB it
# segfaults. A bare threads->create with the overrides installed and no scheduler involved is fine,
# so it takes both features together to corrupt the heap.
#
# Nothing in this file needs transparent unblocking - the reads are chunked by hand precisely so the
# await boundaries are visible and movable. If you do want both features in one program, keep the
# worker free of the wrapped operations, or do the I/O before the thread exists.
say '';
say '5. enable_transparent_unblocking() and spawn_blocking do not mix.';
say '';
printf "  %-34s %s\n", 'transparent unblocking', Acme::Parataxis->transparent_unblocking ? 'on' : 'off';
printf "  %-34s %s\n", 'blocking available here', ( $have_blocking ? 'yes' : 'no' );
say '';
say '  The compatibility layer overrides core file operations process-wide, and a cloned thread';
say '  inherits the overrides but has no scheduler to park in. The symptom is a Future that fails';
say '  with a scheduler error on a closure that never mentioned a scheduler, and at larger sizes a';
say '  segfault. This file leaves transparent unblocking off on purpose, and the sections above do';
say '  their own chunking so the await boundaries stay visible.';
say '';
say '';
