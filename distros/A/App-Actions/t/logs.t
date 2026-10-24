use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();

use App::Actions::Logs;
use App::Actions::Schema ();

# Object::Configure reads the developer's own configuration files (~/.conf
# and the like), where a UNIVERSAL logger would take the messages these tests
# read off standard error.  An empty directory leaves the defaults in force.
local $ENV{CONFIG_DIR} = tempdir(CLEANUP => 1);

my $root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $lib  = File::Spec->catdir($root, 'lib');
my $script = File::Spec->catfile($root, 'bin', 'action-run');

# Windows writes CRLF when output is redirected to a file, and the matches
# below anchor on the end of a line.
sub useful_text {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/\r\n/\n/g;
    return $text;
}

sub run_cli {
    my (@args) = @_;

    my ($stdout, $stderr, $status) = capture {
        system($^X, '-I' . $lib, $script, @args);
    };

    return (useful_text($stdout), useful_text($stderr), $status >> 8);
}

sub write_file {
    my ($path, $text) = @_;

    open my $handle, '>', $path or die "Unable to write '$path': $!";
    binmode $handle;
    print {$handle} $text;
    close $handle or die "Unable to write '$path': $!";

    return;
}

is(App::Actions::Logs::format_age(0), 'just now', 'a log written now is just now');
is(App::Actions::Logs::format_age(59), 'just now', 'under a minute is just now');
is(App::Actions::Logs::format_age(60), '1 minute ago', 'a minute is a minute');
is(App::Actions::Logs::format_age(3599), '59 minutes ago', 'under an hour stays in minutes');
is(App::Actions::Logs::format_age(3600), '1 hour ago', 'an hour is an hour');
is(App::Actions::Logs::format_age(7200), '2 hours ago', 'two hours is two hours');
is(App::Actions::Logs::format_age(86400), '1 day ago', 'a day is a day');
is(App::Actions::Logs::format_age(30 * 86400), '1 month ago', 'thirty days is a month');
is(App::Actions::Logs::format_age(365 * 86400), '1 year ago', 'a year is a year');
is(App::Actions::Logs::format_age(undef), 'just now', 'a missing time is not a negative age');
is(App::Actions::Logs::format_age(-10), 'just now', 'a time ahead of the clock is just now');

is(
    App::Actions::Logs->default_directory,
    File::Spec->catdir(App::Actions::Cache::base_directory(), 'action-run', 'logs'),
    'the default log directory is the one a run writes to',
);

{
    local $ENV{ACTION_RUN_LOG_DIR} = File::Spec->catdir(
        tempdir(CLEANUP => 1), 'chosen',
    );

    is(App::Actions::Logs->new->directory, $ENV{ACTION_RUN_LOG_DIR},
        'ACTION_RUN_LOG_DIR names the directory the command reads');
}

my $scratch = tempdir(CLEANUP => 1);
my $logs_dir = File::Spec->catdir($scratch, 'logs');
my $new_run  = File::Spec->catdir($logs_dir, '20261021-120000-abc123');
my $old_run  = File::Spec->catdir($logs_dir, '20261020-090000-def456');
my $stray    = File::Spec->catdir($logs_dir, 'keep-me');

make_path($new_run, $old_run, $stray);

write_file(File::Spec->catfile($new_run, 'job-1-test_n_one.log'), 'a' x 2048);
write_file(File::Spec->catfile($new_run, 'job-2-test_n_two.log'), 'b' x 1024);
write_file(File::Spec->catfile($new_run, 'notes.txt'), 'not a log');
write_file(File::Spec->catfile($old_run, 'job-1-test_n_one.log'), 'c' x 4096);
write_file(File::Spec->catfile($stray, 'job-1-test.log'), 'd' x 128);

my $now = time;
my $two_hours = $now - 2 * 3600;
my $two_days  = $now - 2 * 86400;
utime($two_hours, $two_hours, File::Spec->catfile($new_run, $_))
    for qw(job-1-test_n_one.log job-2-test_n_two.log);
utime($two_days, $two_days, File::Spec->catfile($old_run, 'job-1-test_n_one.log'));

my $logs = App::Actions::Logs->new(directory => $logs_dir);

{
    my $runs = $logs->entries;
    is(scalar @$runs, 2, 'only directories that hold a job log are runs');
    is_deeply(
        [ map { $_->{name} } @$runs ],
        [ '20261021-120000-abc123', '20261020-090000-def456' ],
        'the newest run is listed first',
    );
    is_deeply(
        [ map { $_->{name} } @{ $runs->[0]{logs} } ],
        [ 'job-1-test_n_one.log', 'job-2-test_n_two.log' ],
        'the logs of a run are sorted by file name',
    );
    is($runs->[0]{logs}[1]{size}, 1024, 'a log reports its size');
    is($runs->[0]{logs}[1]{mtime}, $two_hours, 'a log reports when it was written');
}

{
    my $out = $logs->report(now => $now);

    like($out, qr/^Logs directory: \Q$logs_dir\E$/m, 'the listing names the directory');
    like($out, qr/^  RUN\s+LOG\s+SIZE\s+AGE$/m, 'the listing has a header');
    like(
        $out,
        qr/^  \Q20261021-120000-abc123\E\s+job-1-test_n_one\.log\s+2\.0 KB\s+2 hours ago$/m,
        'a log is listed with its run, size and age',
    );
    like(
        $out,
        qr/^  \Q20261020-090000-def456\E\s+job-1-test_n_one\.log\s+4\.0 KB\s+2 days ago$/m,
        'an older run is listed with a larger age',
    );
    like($out, qr/^3 logs, 7\.0 KB on disk\.$/m, 'the listing totals what it found');
    like($out, qr/^Remove them with "action-run logs --prune"\.$/m,
        'the listing says how to remove them');
    unlike($out, qr/notes\.txt/, 'a file that is not a job log is ignored');
    unlike($out, qr/keep-me/, 'a directory named another way is ignored');
}

{
    my $document = $logs->document(now => $now);
    is($document->{schema_version}, App::Actions::Logs->json_schema_version,
        'the document carries the version it was written for');
    is($document->{generated_at}, $now,
        'the document records the clock its ages are measured from');
    is($document->{logs_directory}, $logs_dir, 'the document names the directory it read');
    is(scalar @{ $document->{logs} }, 3, 'the document lists every kept log');
    is($document->{logs}[0]{run}, '20261021-120000-abc123', 'the newest run is first');
    is($document->{logs}[0]{name}, 'job-1-test_n_one.log', 'the log file is named');
    is($document->{logs}[0]{size}, 2048, 'the document carries the size in bytes');
    is($document->{logs}[0]{mtime}, $two_hours, 'the document carries when it was written');
    is($document->{logs}[0]{age}, 7200, 'the document carries the age in seconds');
    is($document->{logs}[0]{mtime} + $document->{logs}[0]{age},
        $document->{generated_at}, 'the age is measured from generated_at');
    is($document->{logs}[2]{age}, 2 * 86400, 'an older log carries a larger age');
    is($document->{totals}{runs}, 2, 'the document counts the runs');
    is($document->{totals}{logs}, 3, 'the document counts the logs');
    is($document->{totals}{size}, 7168, 'the document totals the bytes');
    is($document->{prune}, undef, 'a listing has no prune report');

    my $ahead = $logs->document(now => $two_hours - 30);
    is($ahead->{generated_at}, $two_hours - 30,
        'the document records the clock it was given');
    is($ahead->{logs}[0]{age}, 0,
        'a log ahead of the clock has an age of zero rather than a negative one');
}

{
    # The threshold selects logs individually, by their own modification time.
    # The old run's log is two days old and the newer run's two are two hours
    # old, so a one-day threshold takes one row rather than a whole run.
    my $out = $logs->report(now => $now, older_than => 86400);

    like($out, qr/^Only job logs older than 1 day\.$/m,
        'the filtered listing says what it selected');
    like($out, qr/^  \Q20261020-090000-def456\E\s+job-1-test_n_one\.log\s+4\.0 KB\s+2 days ago$/m,
        'the log older than the threshold is listed');
    unlike($out, qr/^  \Q20261021-120000-abc123\E\b/m,
        'a run whose logs are all newer is left out');
    like($out, qr/^1 log, 4\.0 KB on disk\.$/m,
        'the filtered listing totals only the selected logs');

    my $document = $logs->document(now => $now, older_than => 86400);
    is_deeply(
        [ map { [ $_->{run}, $_->{name} ] } @{ $document->{logs} } ],
        [ [ '20261020-090000-def456', 'job-1-test_n_one.log' ] ],
        'the filtered document holds only the logs older than the threshold',
    );
    is($document->{totals}{runs}, 1,
        'the filtered document counts the selected run');
    is($document->{totals}{logs}, 1,
        'the filtered document counts the selected logs');
    is($document->{totals}{size}, 4096,
        'the filtered document totals the selected bytes');

    $out = $logs->report(now => $now, older_than => 365 * 86400);
    like($out, qr/^No job logs are older than 1 year\.$/m,
        'a threshold no log reaches says why the listing is empty');
}

{
    # A removal that fails is reported and leaves the logs for a second try.
    no warnings 'redefine';
    local *App::Actions::Logs::_unlink = sub {
        $! = 13;    # EACCES, so the report has a reason to print
        return 0;
    };

    my ($out, $exit, $data) = $logs->prune;
    is($exit, 1, 'a prune that could not remove a run exits 1');
    like($out, qr/^Could not remove 2 runs:$/m, 'the prune counts the runs it left');
    like($out, qr/^  \Q20261021-120000-abc123\E: .*permission denied$/im,
        'the prune names the run and the reason');
    is($data->{removed}, 0, 'a failed prune removed no logs');
    is($data->{freed}, 0, 'a failed prune freed nothing');
    is_deeply(
        [ map { $_->{run} } @{ $data->{failed} } ],
        [ '20261021-120000-abc123', '20261020-090000-def456' ],
        'the document data names every run that stayed',
    );
    like($data->{failed}[0]{error}, qr/permission denied/i,
        'the document data carries the reason');
    ok(-f File::Spec->catfile($new_run, 'job-1-test_n_one.log'),
        'a failed prune leaves the log in place');
}

{
    my ($out, $exit, $data) = $logs->prune;
    is($exit, 0, 'pruning kept logs exits 0');
    like($out, qr/^Removed 3 logs, 7\.0 KB freed\.$/m,
        'the prune says how many logs it removed and what that freed');
    is($data->{removed}, 3, 'the document data counts the removed logs');
    is($data->{freed}, 7168, 'the document data totals the bytes freed');
    is_deeply($data->{failed}, [], 'the document data has no failed runs');
    ok(!-e File::Spec->catfile($new_run, 'job-1-test_n_one.log'),
        'the newest run no longer holds its logs');
    ok(-f File::Spec->catfile($new_run, 'notes.txt'),
        'a file that is not a job log is left where it was');
    ok(-d $new_run, 'a run directory that still holds something is kept');
    ok(!-e $old_run, 'a run directory that held only logs is removed');
    ok(-f File::Spec->catfile($stray, 'job-1-test.log'),
        'a directory named another way is not removed');
}

{
    my $out = $logs->report(now => $now);
    like($out, qr/^No job logs have been kept yet\.$/m, 'an empty log directory says so');

    my ($text, $exit, $data) = $logs->prune;
    is($exit, 0, 'pruning an empty log directory exits 0');
    like($text, qr/^No job logs have been kept yet\.$/m, 'an empty prune says there is nothing to do');
    is($data->{removed}, 0, 'an empty prune removes nothing');
    is($data->{freed}, 0, 'an empty prune frees nothing');
    is_deeply($data->{failed}, [], 'an empty prune has no failed runs');
}

{
    my $missing = App::Actions::Logs->new(
        directory => File::Spec->catdir($scratch, 'not-created'),
    );
    like($missing->report, qr/^No job logs have been kept yet\.$/m,
        'a log directory that does not exist yet is empty');
}

{
    local $ENV{ACTION_RUN_LOG_DIR} = File::Spec->catdir(
        tempdir(CLEANUP => 1), 'logs',
    );
    my $run = File::Spec->catdir($ENV{ACTION_RUN_LOG_DIR}, '20261021-120000-abc123');
    make_path($run);
    write_file(File::Spec->catfile($run, 'job-1-test.log'), 'a' x 512);

    my ($out, $err, $exit) = run_cli('logs');
    is($exit, 0, 'logs exits 0');
    is($err, '', 'logs writes nothing to standard error');
    like($out, qr/^Logs directory: \Q$ENV{ACTION_RUN_LOG_DIR}\E$/m,
        'the command reads ACTION_RUN_LOG_DIR');
    like($out, qr/job-1-test\.log\s+512 B/, 'the command lists the kept log');

    ($out, $err, $exit) = run_cli('logs', '--prune');
    is($exit, 0, 'logs --prune exits 0');
    is($err, '', 'logs --prune writes nothing to standard error');
    like($out, qr/^Removed 1 log, 512 B freed\.$/m, 'the command says what it removed');
    ok(!-e $run, 'the command removed the run directory');
}

{
    local $ENV{ACTION_RUN_LOG_DIR} = File::Spec->catdir(
        tempdir(CLEANUP => 1), 'logs',
    );
    my $new_run = File::Spec->catdir(
        $ENV{ACTION_RUN_LOG_DIR}, '20261021-140000-abc123',
    );
    my $old_run = File::Spec->catdir(
        $ENV{ACTION_RUN_LOG_DIR}, '20261018-090000-def456',
    );
    make_path($new_run, $old_run);

    my $new_log = File::Spec->catfile($new_run, 'job-1-test.log');
    my $old_log = File::Spec->catfile($old_run, 'job-1-test.log');
    write_file($new_log, 'a' x 1024);
    write_file($old_log, 'b' x 4096);

    my $now = time;
    utime($now - 3600, $now - 3600, $new_log);
    utime($now - 3 * 86400, $now - 3 * 86400, $old_log);

    my ($out, $err, $exit) = run_cli('logs', '--older-than', '1d');
    is($exit, 0, 'logs --older-than exits 0');
    is($err, '', 'logs --older-than writes nothing to standard error');
    like($out, qr/^Only job logs older than 1 day\.$/m,
        'the command says what it filtered');
    like($out, qr/\Q20261018-090000-def456\E\s+job-1-test\.log\s+4\.0 KB/,
        'the command lists the old log');
    unlike($out, qr/\Q20261021-140000-abc123\E/,
        'the command leaves out the newer log');
    like($out, qr/^1 log, 4\.0 KB on disk\.$/m,
        'the command totals only the logs it selected');

    ($out, $err, $exit) = run_cli('logs', '--json', '--older-than', '1d');
    is($exit, 0, 'logs --json --older-than exits 0');
    my $document = eval { JSON::PP->new->decode($out) };
    ok($document, 'the filtered document decodes') or diag "stderr: $err";
    is_deeply(
        [ map { $_->{name} } @{ $document->{logs} } ],
        ['job-1-test.log'],
        'the document holds only the old log',
    );
    is($document->{totals}{logs}, 1,
        'the document totals only the selected log');
    is($document->{totals}{size}, 4096,
        'the document totals only the selected bytes');

    ($out, $err, $exit) = run_cli('logs', '--prune', '--older-than', '1d');
    is($exit, 0, 'logs --prune --older-than exits 0');
    is($err, '', 'logs --prune --older-than writes nothing to standard error');
    like($out, qr/^Removed 1 log, 4\.0 KB freed\.$/m,
        'the filtered prune removes only the old log');
    ok(!-e $old_log, 'the old log is gone');
    ok(!-e $old_run, 'the run directory that held only the old log is gone');
    ok(-e $new_log, 'the newer log is still there');
    ok(-d $new_run, 'the run directory holding the newer log is still there');

    # As with the cache, a filtered prune document shows the whole record that
    # remains, not just the filter's empty selection the second time.
    ($out, $err, $exit) = run_cli(
        'logs', '--prune', '--json', '--older-than', '1d',
    );
    is($exit, 0, 'a filtered prune with nothing left to remove exits 0');
    my $prune_document = eval { JSON::PP->new->decode($out) };
    ok($prune_document, 'the filtered prune document decodes')
        or diag "stderr: $err";
    is($prune_document->{prune}{removed}, 0,
        'the filtered prune removed nothing the second time');
    is_deeply(
        [ map { $_->{name} } @{ $prune_document->{logs} } ],
        ['job-1-test.log'],
        'the prune document lists the newer log it kept',
    );
}

{
    # The machine-readable form is the same listing with raw sizes and times,
    # and with the prune report the text only summarises.
    local $ENV{ACTION_RUN_LOG_DIR} = File::Spec->catdir(
        tempdir(CLEANUP => 1), 'logs',
    );
    my $json_run = File::Spec->catdir(
        $ENV{ACTION_RUN_LOG_DIR}, '20261021-130000-abc123',
    );
    make_path($json_run);
    write_file(File::Spec->catfile($json_run, 'job-1-test.log'), 'a' x 512);

    my ($out, $err, $exit) = run_cli('logs', '--json');
    is($exit, 0, 'logs --json exits 0');
    is($err, '', 'logs --json writes nothing to standard error');

    my $document = eval { JSON::PP->new->decode($out) };
    ok($document, 'logs --json prints one JSON object') or diag "stderr: $err";
    is($document->{schema_version}, App::Actions::Logs->json_schema_version,
        'the document carries the version it was written for');
    is($document->{logs_directory}, $ENV{ACTION_RUN_LOG_DIR},
        'the document names the directory it read');
    cmp_ok($document->{generated_at}, '>', 0,
        'the document records when it was made');
    is($document->{logs}[0]{run}, '20261021-130000-abc123', 'the run is named');
    is($document->{logs}[0]{name}, 'job-1-test.log', 'the log is named');
    is($document->{logs}[0]{size}, 512, 'the size is bytes rather than text');
    ok(defined $document->{logs}[0]{age}, 'the age is in seconds in the document');
    cmp_ok($document->{logs}[0]{age}, '>=', 0, 'the age is not negative');
    is($document->{logs}[0]{mtime} + $document->{logs}[0]{age},
        $document->{generated_at}, 'the age is measured from generated_at');
    is($document->{totals}{runs}, 1, 'the document counts the runs');
    is($document->{totals}{logs}, 1, 'the document counts the logs');
    is($document->{totals}{size}, 512, 'the document totals the bytes');
    is($document->{prune}, undef, 'a listing has no prune report');

    ($out, $err, $exit) = run_cli('logs', '--prune', '--json');
    is($exit, 0, 'logs --prune --json exits 0');
    is($err, '', 'logs --prune --json writes nothing to standard error');

    $document = eval { JSON::PP->new->decode($out) };
    ok($document, 'the prune document decodes') or diag "stderr: $err";
    ok(defined $document->{generated_at}, 'the prune document records when it was made');
    is($document->{prune}{removed}, 1, 'the document says what the prune removed');
    is($document->{prune}{freed}, 512, 'the document says what the prune freed');
    is_deeply($document->{prune}{failed}, [], 'the document says every removal worked');
    is_deeply($document->{logs}, [], 'the prune left no logs in the document');
    ok(!-e $json_run, 'the command removed the run directory');
}

{
    # A document that does not match the schema is not returned, even though
    # the listing itself succeeded.
    my $shipped = \&App::Actions::Logs::json_schema;
    no warnings 'redefine';
    local *App::Actions::Logs::json_schema = sub {
        my ($class) = @_;
        my $schema = $shipped->($class);
        delete $schema->{properties}{logs_directory};
        return $schema;
    };

    my $built = eval { App::Actions::Logs->new(directory => $logs_dir)->document; 1 };
    my $error = $@;
    ok(!$built, 'a document that does not match the schema is not returned');
    ok(ref $error && $error->isa('App::Actions::Schema::Invalid'),
        'the failure is the schema exception');
    like(
        "$error",
        qr/does not match App::Actions::Logs->json_schema: \$\.logs_directory: unexpected key/,
        'the error names the document, the schema and the key at fault',
    );
}

{
    my ($out, $err, $exit) = run_cli('logs', 'extra');
    is($exit, 2, 'logs takes no arguments');
    like(
        $err,
        qr/Usage: action-run \[options\] logs \[--prune\] \[--older-than DURATION\] \[--json\]/,
        'the usage line says how to invoke logs',
    );
}

{
    my (undef, $err, $exit) = run_cli('logs', '--older-than', 'fortnight');
    is($exit, 2, 'an unknown duration is a usage error for logs');
    like(
        $err,
        qr/--older-than must be a duration such as 30d, 12h or 90m, not 'fortnight'/,
        'the logs error says what a duration looks like',
    );
}

{
    my (undef, $err, $exit) = run_cli('--prune', 'workflow.yml', 'project');
    is($exit, 2, '--prune without cache or logs is a usage error');
    like($err, qr/--prune is only used by the cache and logs commands/,
        'the error says where --prune belongs');
}

done_testing;
