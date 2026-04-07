use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('Chandra::Log');

my $TMPDIR = tempdir(CLEANUP => 1);

sub capture_log {
    my ($log_sub) = @_;
    my $file = "$TMPDIR/cap_$$.txt";
    open my $save, '>&', \*STDOUT or die "dup: $!";
    open STDOUT, '>', $file or die "redirect: $!";
    $log_sub->();
    STDOUT->flush();
    open STDOUT, '>&', $save or die "restore: $!";
    open my $fh, '<', $file or die "read: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    unlink $file;
    return $content;
}

# ---- undef message ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );
    $log->info(undef);
    is($captured[0]{message}, '', 'undef message becomes empty string');
}

# ---- No data argument ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );
    $log->info('no data');
    ok(!exists $captured[0]{data} || !defined $captured[0]{data},
       'no data when not provided');
}

# ---- Empty string message ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );
    $log->info('');
    is($captured[0]{message}, '', 'empty string message preserved');
}

# ---- Unicode message ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );
    $log->info("Hello \x{263A} world");
    like($captured[0]{message}, qr/Hello.*world/, 'unicode message logged');
}

# ---- Very long message ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );
    my $long = 'x' x 100_000;
    $log->info($long);
    is(length($captured[0]{message}), 100_000, 'long message preserved');
}

# ---- Numeric message ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );
    $log->info(42);
    is($captured[0]{message}, '42', 'numeric message stringified');
}

# ---- Deep nested data ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );
    my $deep = { a => { b => { c => { d => [1, 2, 3] } } } };
    $log->info('deep', $deep);
    is($captured[0]{data}{a}{b}{c}{d}[1], 2, 'deep nested data preserved');
}

# ---- Data as arrayref ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );
    $log->info('arr data', [1, 2, 3]);
    is(ref $captured[0]{data}, 'ARRAY', 'arrayref data preserved');
    is($captured[0]{data}[1], 2, 'arrayref data values');
}

# ---- Rapid logging ----
{
    my $count = 0;
    my $log = Chandra::Log->new(
        output => { callback => sub { $count++ } },
    );
    $log->info("msg $_") for 1..1000;
    is($count, 1000, 'rapid logging: 1000 messages');
}

# ---- Multiple file writes don't corrupt ----
{
    my $dir  = tempdir(CLEANUP => 1);
    my $file = "$dir/rapid.log";

    my $log = Chandra::Log->new(
        output    => { file => $file },
        formatter => 'minimal',
    );

    $log->info("line $_") for 1..50;

    open my $fh, '<', $file or die $!;
    my @lines = <$fh>;
    close $fh;
    is(scalar @lines, 50, 'file has all 50 lines');
}

# ---- File rotation keeps correct count ----
{
    my $dir  = tempdir(CLEANUP => 1);
    my $file = "$dir/rot.log";

    my $log = Chandra::Log->new(
        output    => { file => $file },
        formatter => 'minimal',
        rotate    => { max_size => 30, keep => 2 },
    );

    for my $i (1..20) {
        $log->warn("rotation test message number $i");
    }

    ok(-f $file, 'current log exists after rotation');
    ok(-f "$file.1", 'rotated .1 exists');
    ok(-f "$file.2", 'rotated .2 exists');
    ok(! -f "$file.3", 'rotated .3 does not exist (keep=2)');
}

# ---- DESTROY cleans up ----
{
    my $log = Chandra::Log->new;
    isa_ok($log, 'Chandra::Log');
    undef $log;
    pass('DESTROY did not crash');
}

# ---- Multiple DESTROY is safe ----
{
    my $log = Chandra::Log->new;
    undef $log;
    undef $log;
    pass('double undef is safe');
}

# ---- with() preserves level ----
{
    my @captured;
    my $log = Chandra::Log->new(
        level  => 'error',
        output => { callback => sub { push @captured, $_[0] } },
    );
    my $child = $log->with(ctx => 'val');
    $child->info('filtered');
    $child->error('passed');
    is(scalar @captured, 1, 'with() child inherits level filter');
}

# ---- with() preserves formatter ----
{
    my $log = Chandra::Log->new(
        output    => 'stdout',
        formatter => 'minimal',
    );
    my $child = $log->with(x => 1);
    my $output = capture_log(sub { $child->info('child msg') });
    like($output, qr/^INFO: child msg\n$/, 'child inherits minimal formatter');
}

# ---- Callback that dies doesn't crash logger ----
{
    my $log = Chandra::Log->new(
        output => { callback => sub { die "boom" } },
    );

    eval { $log->info('should not crash') };
    # If we get here without a hard crash, we're fine
    pass('callback die does not crash process');
}

# ---- stdout output ----
{
    my $log = Chandra::Log->new(output => 'stdout', formatter => 'minimal');
    my $output = capture_log(sub { $log->info('stdout test') });
    like($output, qr/INFO: stdout test/, 'stdout output works');
}

# ---- stderr output (capture via redirect) ----
{
    my $dir  = tempdir(CLEANUP => 1);
    my $file = "$dir/stderr.txt";

    # Redirect STDERR
    open my $save_err, '>&', \*STDERR;
    open STDERR, '>', $file;

    my $log = Chandra::Log->new(output => 'stderr', formatter => 'minimal');
    $log->info('stderr test');

    # Restore
    open STDERR, '>&', $save_err;

    open my $fh, '<', $file;
    my $content = do { local $/; <$fh> };
    close $fh;
    like($content, qr/INFO: stderr test/, 'stderr output works');
}

# ---- JSON format with context ----
{
    my $log = Chandra::Log->new(
        output    => 'stdout',
        formatter => 'json',
    );
    my $child = $log->with(req => 'abc');
    my $output = capture_log(sub { $child->info('json ctx') });
    like($output, qr/"context"/, 'json output includes context');
    like($output, qr/"req"/, 'json context has key');
}

done_testing();
