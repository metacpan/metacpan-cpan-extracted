use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);

use_ok('Chandra::Log');

my $TMPDIR = tempdir(CLEANUP => 1);

# Helper: capture output via file-based redirect
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

# ---- Constructor defaults ----
{
    my $log = Chandra::Log->new;
    isa_ok($log, 'Chandra::Log', 'new() returns blessed object');
    is($log->level, 'debug', 'default level is debug');
}

# ---- Constructor with level ----
{
    my $log = Chandra::Log->new(level => 'warn');
    is($log->level, 'warn', 'constructor respects level');
}

# ---- All log levels via callback ----
{
    my @captured;
    my $log = Chandra::Log->new(
        level  => 'debug',
        output => { callback => sub { push @captured, $_[0] } },
    );

    $log->debug('d msg');
    $log->info('i msg');
    $log->warn('w msg');
    $log->error('e msg');
    $log->fatal('f msg');

    is(scalar @captured, 5, 'all 5 levels logged');
    is($captured[0]{level}, 'debug', 'debug level');
    is($captured[0]{message}, 'd msg', 'debug message');
    is($captured[1]{level}, 'info', 'info level');
    is($captured[2]{level}, 'warn', 'warn level');
    is($captured[3]{level}, 'error', 'error level');
    is($captured[4]{level}, 'fatal', 'fatal level');
}

# ---- Level filtering ----
{
    my @captured;
    my $log = Chandra::Log->new(
        level  => 'warn',
        output => { callback => sub { push @captured, $_[0] } },
    );

    $log->debug('no');
    $log->info('no');
    $log->warn('yes');
    $log->error('yes');
    $log->fatal('yes');

    is(scalar @captured, 3, 'level filtering: only warn+ logged');
    is($captured[0]{level}, 'warn', 'first captured is warn');
}

# ---- set_level ----
{
    my @captured;
    my $log = Chandra::Log->new(
        level  => 'debug',
        output => { callback => sub { push @captured, $_[0] } },
    );

    $log->set_level('error');
    $log->info('filtered');
    $log->error('passed');

    is(scalar @captured, 1, 'set_level filters correctly');
    is($captured[0]{level}, 'error', 'set_level: error passes');
}

# ---- level() getter/setter ----
{
    my $log = Chandra::Log->new(level => 'info');
    is($log->level, 'info', 'level getter');
    $log->level('fatal');
    is($log->level, 'fatal', 'level setter via level()');
}

# ---- Structured data ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );

    $log->info('request', { method => 'GET', status => 200 });
    is($captured[0]{data}{method}, 'GET', 'structured data: method');
    is($captured[0]{data}{status}, 200, 'structured data: status');
}

# ---- Contextual logger (with) ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );

    my $child = $log->with(request_id => 'abc-123', user => 'alice');
    isa_ok($child, 'Chandra::Log', 'with() returns Chandra::Log');
    $child->info('processing');

    ok(exists $captured[0]{context}, 'child has context');
    is($captured[0]{context}{request_id}, 'abc-123', 'context: request_id');
    is($captured[0]{context}{user}, 'alice', 'context: user');
}

# ---- Nested with() merges context ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );

    my $c1 = $log->with(a => 1);
    my $c2 = $c1->with(b => 2);
    $c2->info('nested');

    is($captured[0]{context}{a}, 1, 'nested with: inherits parent context');
    is($captured[0]{context}{b}, 2, 'nested with: has own context');
}

# ---- with() doesn't affect parent ----
{
    my @parent_cap;
    my @child_cap;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @parent_cap, $_[0] } },
    );

    my $child = $log->with(extra => 'yes');
    # Override child output
    $log->info('parent msg');

    ok(!exists $parent_cap[0]{context} || !defined $parent_cap[0]{context},
       'parent has no context after with()');
}

# ---- Text formatter (default) ----
{
    my $log = Chandra::Log->new(output => 'stdout');
    my $output = capture_log(sub { $log->info('hello world') });
    like($output, qr/\[INFO\]/, 'text format has [INFO]');
    like($output, qr/hello world/, 'text format has message');
    like($output, qr/\d{4}-\d{2}-\d{2}/, 'text format has timestamp');
}

# ---- Text formatter with data ----
{
    my $log = Chandra::Log->new(output => 'stdout');
    my $output = capture_log(sub { $log->info('req', { method => 'GET' }) });
    like($output, qr/method/, 'text format includes data keys');
    like($output, qr/GET/, 'text format includes data values');
}

# ---- JSON formatter ----
{
    my $log = Chandra::Log->new(
        output    => 'stdout',
        formatter => 'json',
    );
    my $output = capture_log(sub { $log->info('test json', { x => 42 }) });
    like($output, qr/"level"\s*:\s*"info"/, 'json format has level');
    like($output, qr/"msg"\s*:\s*"test json"/, 'json format has msg');
}

# ---- Minimal formatter ----
{
    my $log = Chandra::Log->new(
        output    => 'stdout',
        formatter => 'minimal',
    );
    my $output = capture_log(sub { $log->warn('watch out') });
    like($output, qr/^WARN: watch out\n$/, 'minimal format correct');
}

# ---- Custom formatter ----
{
    my $log = Chandra::Log->new(
        output    => 'stdout',
        formatter => sub {
            my ($entry) = @_;
            return "CUSTOM:$entry->{message}\n";
        },
    );
    my $output = capture_log(sub { $log->info('hello') });
    is($output, "CUSTOM:hello\n", 'custom formatter works');
}

# ---- Change formatter at runtime ----
{
    my $log = Chandra::Log->new(output => 'stdout');
    $log->formatter('minimal');
    my $output = capture_log(sub { $log->error('boom') });
    like($output, qr/^ERROR: boom\n$/, 'formatter changed at runtime');
}

# ---- File output ----
{
    my $dir = tempdir(CLEANUP => 1);
    my $file = "$dir/test.log";

    my $log = Chandra::Log->new(
        output => { file => $file },
        formatter => 'minimal',
    );

    $log->info('line one');
    $log->warn('line two');

    ok(-f $file, 'log file created');
    open my $fh, '<', $file or die "Cannot read $file: $!";
    my @lines = <$fh>;
    close $fh;

    is(scalar @lines, 2, 'two lines in log file');
    like($lines[0], qr/^INFO: line one\n$/, 'file line 1');
    like($lines[1], qr/^WARN: line two\n$/, 'file line 2');
}

# ---- Multiple outputs ----
{
    my @cb_captured;
    my $dir  = tempdir(CLEANUP => 1);
    my $file = "$dir/multi.log";

    my $log = Chandra::Log->new(
        output => [
            { file => $file },
            { callback => sub { push @cb_captured, $_[0] } },
        ],
        formatter => 'minimal',
    );

    $log->info('multi');

    is(scalar @cb_captured, 1, 'callback received entry');
    ok(-f $file, 'file created');
    open my $fh, '<', $file;
    my $line = <$fh>;
    close $fh;
    like($line, qr/INFO: multi/, 'file has entry');
}

# ---- Per-output level filter ----
{
    my @cb_all;
    my @cb_error;

    my $log = Chandra::Log->new(
        level  => 'debug',
        output => [
            { callback => sub { push @cb_all, $_[0] } },
            { callback => sub { push @cb_error, $_[0] }, level => 'error' },
        ],
    );

    $log->info('info msg');
    $log->error('error msg');

    is(scalar @cb_all, 2, 'all-levels output gets both');
    is(scalar @cb_error, 1, 'error-only output gets one');
    is($cb_error[0]{level}, 'error', 'error-only output has error');
}

# ---- File rotation ----
{
    my $dir = tempdir(CLEANUP => 1);
    my $file = "$dir/rot.log";

    my $log = Chandra::Log->new(
        output    => { file => $file },
        formatter => 'minimal',
        rotate    => { max_size => 50, keep => 3 },
    );

    # Write enough to trigger rotation
    for my $i (1..10) {
        $log->info("message number $i which is long enough");
    }

    # Check that rotated files exist
    ok(-f $file, 'current log exists');
    ok(-f "$file.1", 'rotated file .1 exists');
}

# ---- Timestamp format ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );
    $log->info('ts test');

    like($captured[0]{timestamp},
         qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}$/,
         'timestamp format YYYY-MM-DD HH:MM:SS.mmm');
}

# ---- Entry structure ----
{
    my @captured;
    my $log = Chandra::Log->new(
        output => { callback => sub { push @captured, $_[0] } },
    );
    $log->info('structure check', { key => 'val' });

    my $e = $captured[0];
    ok(exists $e->{timestamp}, 'entry has timestamp');
    ok(exists $e->{level}, 'entry has level');
    ok(exists $e->{message}, 'entry has message');
    ok(exists $e->{data}, 'entry has data');
    is(ref $e->{data}, 'HASH', 'data is hashref');
}

done_testing();
