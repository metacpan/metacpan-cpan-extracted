use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();

use App::Actions;
use App::Actions::Cache;

my $root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $lib  = File::Spec->catdir($root, 'lib');
my $script = File::Spec->catfile($root, 'bin', 'action-run');
my $fake_docker = File::Spec->catfile($root, 't', 'bin', 'fake-docker');

my $scratch = tempdir(CLEANUP => 1);

# Object::Configure reads the developer's own configuration files (~/.conf
# and the like), where a UNIVERSAL logger would take the messages these tests
# read off standard error.  An empty directory leaves the defaults in force.
local $ENV{CONFIG_DIR} = tempdir(CLEANUP => 1);

# Every run in this file records its images in the cache, so the record and the
# fake daemon both live under one temporary directory.
local $ENV{ACTION_RUN_CACHE_FILE} = File::Spec->catfile($scratch, 'cache.json');
local $ENV{ACTION_RUN_LOG_DIR} = File::Spec->catdir($scratch, 'logs');
local $ENV{FAKE_DOCKER_STATE} = File::Spec->catfile($scratch, 'docker');
local $ENV{FAKE_DOCKER_LOG} = File::Spec->catfile($scratch, 'docker.log');

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

    # $? carries the POSIX-compatible status on Windows too.
    return (useful_text($stdout), useful_text($stderr), $status >> 8);
}

sub image_marker {
    my ($image) = @_;

    (my $name = $image) =~ s/[^A-Za-z0-9_.-]/_/g;
    return File::Spec->catfile($ENV{FAKE_DOCKER_STATE}, "image-$name");
}

sub mark_image {
    my ($image) = @_;

    open my $handle, '>', image_marker($image) or die $!;
    print {$handle} $image;
    close $handle;

    return;
}

sub write_cache_record {
    my (%entries) = @_;

    my %images = map {
        $_ => { pulls => 1, %{ $entries{$_} } }
    } keys %entries;

    open my $handle, '>', $ENV{ACTION_RUN_CACHE_FILE} or die $!;
    print {$handle} JSON::PP->new->canonical->encode({
        version => 1,
        images  => \%images,
    });
    close $handle or die $!;

    return;
}

is(App::Actions::Cache::format_size(0), '0 B', 'nothing is 0 B');
is(App::Actions::Cache::format_size(512), '512 B', 'a small size stays in bytes');
is(App::Actions::Cache::format_size(2048), '2.0 KB', 'a size over a kilobyte is reported in KB');
is(App::Actions::Cache::format_size(123_456_789), '117.7 MB',
    'the size the fake daemon reports is shown in MB');
is(App::Actions::Cache::format_size(undef), '0 B', 'an unknown size is 0 B');

is(App::Actions::Cache::parse_duration('30s'), 30,
    'a duration reads a second count');
is(App::Actions::Cache::parse_duration('15m'), 15 * 60,
    'm means minutes');
is(App::Actions::Cache::parse_duration('12h'), 12 * 60 * 60,
    'h means hours');
is(App::Actions::Cache::parse_duration('7d'), 7 * 24 * 60 * 60,
    'd means days');
is(App::Actions::Cache::parse_duration('2w'), 2 * 7 * 24 * 60 * 60,
    'w means weeks');
is(App::Actions::Cache::parse_duration('3mo'), 3 * 30 * 24 * 60 * 60,
    'mo means months, in the 30-day span an age uses');
is(App::Actions::Cache::parse_duration('1y'), 365 * 24 * 60 * 60,
    'y means years, in the 365-day span an age uses');
is(App::Actions::Cache::parse_duration('2 days'), 2 * 24 * 60 * 60,
    'a unit may be spelled out');
ok(!defined App::Actions::Cache::parse_duration('1 fortnight'),
    'an unknown unit is not a duration');
ok(!defined App::Actions::Cache::parse_duration('-1d'),
    'a negative duration is rejected');

{
    local $ENV{ACTION_RUN_CACHE_FILE}
        = File::Spec->catfile(tempdir(CLEANUP => 1), 'nested', 'cache.json');

    my $cache = App::Actions::Cache->new;
    is($cache->file, $ENV{ACTION_RUN_CACHE_FILE}, 'the record path is the one it was given');
    is_deeply($cache->entries, [], 'a record that does not exist has no images');

    is($cache->remember('alpine:3.20', 'perl:5.38'), 2, 'remember reports what it recorded');
    ok(-f $cache->file, 'recording an image creates the record, and its directory');

    my $reloaded = App::Actions::Cache->new(file => $cache->file);
    is_deeply(
        [ map { $_->{image} } @{ $reloaded->entries } ],
        [ 'alpine:3.20', 'perl:5.38' ],
        'the record survives a reload, sorted by image',
    );

    $reloaded->remember('alpine:3.20');
    my ($alpine) = grep { $_->{image} eq 'alpine:3.20' } @{ App::Actions::Cache->new(
        file => $cache->file,
    )->entries };
    is($alpine->{pulls}, 2, 'pulling an image again counts as another use');
    like($alpine->{last_used}, qr/\A\d+\z/, 'the record keeps when the image was last used');

    is($reloaded->forget('perl:5.38'), 1, 'forget reports the image it dropped');
    is(scalar @{ App::Actions::Cache->new(file => $cache->file)->entries }, 1,
        'the forgotten image stays forgotten');
    is($reloaded->forget('perl:5.38'), 0, 'forgetting an image twice is not an error');

    $reloaded->forget('alpine:3.20');
    ok(!-e $cache->file, 'the record goes away when its last image does');
}

{
    my $damaged = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
    open my $handle, '>', $damaged or die $!;
    print {$handle} "{ this is not a cache\n";
    close $handle;

    is_deeply(
        App::Actions::Cache->new(file => $damaged)->entries,
        [],
        'a damaged record is treated as empty rather than failing a run',
    );
}

{
    # The document carries the clock it was made against, not just the times an
    # image was last used, so an age can be computed without the reader's
    # clock or the record having to be read at the same moment.
    my $cache = App::Actions::Cache->new(
        file => File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json'),
    );
    $cache->remember('alpine:3.20');

    my $last_used = $cache->entries->[0]{last_used};
    my $now = $last_used + 120;
    my $document = $cache->document(now => $now);

    is($document->{generated_at}, $now,
        'the document records the clock it was given');
    is($document->{images}[0]{age}, 120,
        'the image carries its age in seconds');
    is(
        $document->{generated_at} - $document->{images}[0]{last_used},
        120,
        'an image age is generated_at minus last_used',
    );

    my $ahead = $cache->document(now => $last_used - 30);
    is($ahead->{images}[0]{age}, 0,
        'an image last used after the document clock has age 0');

    my $report = $cache->report(now => $now);
    like($report, qr/^  IMAGE\s+SIZE\s+LAST USED\s+AGE$/m,
        'the text listing has an age column');
    like(
        $report,
        qr/^  alpine:3\.20\s+unknown\s+\d{4}-\d{2}-\d{2} \d{2}:\d{2}\s+2 minutes ago$/m,
        'the text listing shows the same age as the document',
    );
}

{
    # A record written before last_used was stored still has an entry, but
    # there is no clock to measure it from, so its age is null rather than
    # zero or a number invented from the document's own clock.
    my $path = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
    open my $handle, '>', $path or die $!;
    print {$handle} '{"version":1,"images":{"legacy:1":{"pulls":1}}}';
    close $handle;

    my $legacy = App::Actions::Cache->new(file => $path);
    my $document = $legacy->document(now => 1000);
    is($document->{images}[0]{last_used}, undef, 'a record without last_used stays unknown');
    is($document->{images}[0]{age}, undef, 'an unknown last use has an unknown age');
    like(
        $legacy->report(now => 1000),
        qr/^  legacy:1\s+unknown\s+-\s+unknown$/m,
        'the text listing shows an unknown age without inventing one',
    );
}

my $project = tempdir(CLEANUP => 1);
make_path(File::Spec->catdir($project, '.github', 'workflows'));
my $workflow = File::Spec->catfile($project, '.github', 'workflows', 'test.yml');
open my $workflow_handle, '>', $workflow or die $!;
print {$workflow_handle} <<'YAML';
name: Cache test
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo hello
YAML
close $workflow_handle;

{
    my (undef, $err, $exit) = run_cli('--docker', $fake_docker, $workflow, $project);
    is($exit, 0, 'the workflow run succeeds');
    is($err, '', 'the run writes nothing to standard error');

    ok(-f $ENV{ACTION_RUN_CACHE_FILE}, 'the run recorded the image it pulled');

    open my $handle, '<', $ENV{ACTION_RUN_CACHE_FILE} or die $!;
    my $text = do { local $/; <$handle> };
    close $handle;
    my $document = JSON::PP->new->decode($text);
    is_deeply(
        [ sort keys %{ $document->{images} } ],
        ['ubuntu:latest'],
        'the record names the image the run kept',
    );
}

{
    # The threshold is compared with the age of each image, and an image with
    # no recorded last use is not guessed to be old enough.  A separate
    # scratch record keeps the ages fixed without touching the record below.
    my $aging = tempdir(CLEANUP => 1);
    local $ENV{ACTION_RUN_CACHE_FILE}
        = File::Spec->catfile($aging, 'cache.json');
    local $ENV{FAKE_DOCKER_STATE} = File::Spec->catdir($aging, 'docker');
    local $ENV{FAKE_DOCKER_LOG} = File::Spec->catfile($aging, 'docker.log');
    make_path($ENV{FAKE_DOCKER_STATE});

    my $now = time;
    write_cache_record(
        'old:1'     => { last_used => $now - 3 * 86400 },
        'new:1'     => { last_used => $now - 3600 },
        'unknown:1' => {},
    );
    mark_image($_) for qw(old:1 new:1 unknown:1);

    my ($out, $err, $exit) = run_cli(
        'cache', '--older-than', '2d', '--docker', $fake_docker,
    );
    is($exit, 0, 'cache --older-than exits 0');
    is($err, '', 'cache --older-than writes nothing to standard error');
    like($out, qr/^Only images older than 2 days\.$/m,
        'the listing says what it filtered');
    like($out, qr/^  old:1\s+117\.7 MB\s+/m,
        'the old image is listed');
    unlike($out, qr/^  new:1\b/m, 'a newer image is left out');
    unlike($out, qr/^  unknown:1\b/m,
        'an image without a last use is left out');
    like($out, qr/^1 image, 117\.7 MB on disk\.$/m,
        'the totals count only the images shown');

    ($out, $err, $exit) = run_cli(
        'cache', '--json', '--older-than', '2d', '--docker', $fake_docker,
    );
    is($exit, 0, 'cache --json --older-than exits 0');
    my $document = eval { JSON::PP->new->decode($out) };
    ok($document, 'the filtered document decodes') or diag "stderr: $err";
    is_deeply(
        [ map { $_->{image} } @{ $document->{images} } ],
        ['old:1'],
        'the document holds only the images older than the threshold',
    );
    is($document->{totals}{images}, 1,
        'the document totals only the images shown');

    ($out, $err, $exit) = run_cli(
        'cache', '--older-than', '1y', '--docker', $fake_docker,
    );
    is($exit, 0, 'a threshold no image reaches still exits 0');
    like($out, qr/^No cached images are older than 1 year\.$/m,
        'the empty filtered listing says why it is empty');

    ($out, $err, $exit) = run_cli(
        'cache', '--prune', '--older-than', '2d', '--docker', $fake_docker,
    );
    is($exit, 0, 'prune --older-than exits 0');
    is($err, '', 'prune --older-than writes nothing to standard error');
    like($out, qr/^Removed 1 image, 117\.7 MB freed\.$/m,
        'prune removes only the image older than the threshold');
    ok(!-e image_marker('old:1'),
        'the old image is gone from the daemon');
    ok(-e image_marker('new:1'),
        'the newer image is still on the daemon');
    ok(-e image_marker('unknown:1'),
        'an image with no last use is still on the daemon');

    my $cache = App::Actions::Cache->new;
    is_deeply(
        [ map { $_->{image} } @{ $cache->entries } ],
        [ 'new:1', 'unknown:1' ],
        'the prune leaves the newer and unknown images in the record',
    );

    # A prune document lists the whole record that remains, not just what the
    # filter selected, so a caller can see the newer images the prune kept.
    ($out, $err, $exit) = run_cli(
        'cache', '--prune', '--older-than', '2d', '--json',
        '--docker', $fake_docker,
    );
    is($exit, 0, 'a filtered prune with nothing left to remove exits 0');
    my $prune_document = eval { JSON::PP->new->decode($out) };
    ok($prune_document, 'the filtered prune document decodes')
        or diag "stderr: $err";
    is($prune_document->{prune}{removed}, 0,
        'the filtered prune removed nothing the second time');
    is_deeply(
        [ map { $_->{image} } @{ $prune_document->{images} } ],
        [ 'new:1', 'unknown:1' ],
        'the prune document lists the newer and unknown images it kept',
    );
}

{
    my ($out, $err, $exit) = run_cli('cache', '--docker', $fake_docker);
    is($exit, 0, 'cache exits 0');
    is($err, '', 'cache writes nothing to standard error');
    like($out, qr/^Cache file: \Q$ENV{ACTION_RUN_CACHE_FILE}\E$/m, 'cache names the record it read');
    like($out, qr/^  IMAGE\s+SIZE\s+LAST USED\s+AGE$/m, 'cache has a header');
    like($out, qr/^  ubuntu:latest\s+117\.7 MB\s+\d{4}-\d{2}-\d{2} \d{2}:\d{2}\s+just now$/m,
        'cache lists the image with its size, last use and age');
    like($out, qr/^1 image, 117\.7 MB on disk\.$/m, 'cache totals what the record holds');
}

{
    my ($out, $err, $exit) = run_cli('cache', '--prune', '--docker', $fake_docker);
    is($exit, 0, 'prune exits 0');
    is($err, '', 'prune writes nothing to standard error');
    like($out, qr/^Removed 1 image, 117\.7 MB freed\.$/m, 'prune says what it removed and freed');
    ok(!-e image_marker('ubuntu:latest'), 'prune removed the image from the daemon');
    ok(!-e $ENV{ACTION_RUN_CACHE_FILE}, 'prune forgot the image');

    open my $log, '<', $ENV{FAKE_DOCKER_LOG} or die $!;
    my $commands = do { local $/; <$log> };
    close $log;
    like($commands, qr/^image\trm\t-f\tubuntu:latest$/m,
        'prune asks Docker to remove the image rather than doing it itself');
}

{
    my ($out, $err, $exit) = run_cli('cache', '--docker', $fake_docker);
    is($exit, 0, 'an empty cache exits 0');
    like($out, qr/^No images have been cached yet\.$/m, 'an empty cache says so');
}

{
    # A record entry whose image has gone is shown, then forgotten without
    # asking Docker to remove what is not there.
    App::Actions::Cache->new->remember('alpine:3.20');

    my ($out, $err, $exit) = run_cli('cache', '--docker', $fake_docker);
    is($exit, 0, 'cache lists an image that is no longer there');
    like($out, qr/^  alpine:3\.20\s+missing\s+/m, 'a missing image is reported as missing');
    like($out, qr/^1 image is no longer on the daemon\.$/m, 'cache counts the missing images');

    ($out, $err, $exit) = run_cli('cache', '--prune', '--docker', $fake_docker);
    is($exit, 0, 'prune exits 0 when the image has already gone');
    like($out, qr/^Forgot 1 image no longer on the daemon\.$/m,
        'prune forgets an image it did not have to remove');
    ok(!-e $ENV{ACTION_RUN_CACHE_FILE}, 'the record is gone once it has nothing left');
}

{
    # The JSON document is the same record as the text report, with the values
    # a caller asserts on rather than padded columns and a date.
    App::Actions::Cache->new->remember('alpine:3.20');
    open my $marker, '>', image_marker('alpine:3.20') or die $!;
    print {$marker} 'alpine:3.20';
    close $marker;

    my ($out, $err, $exit) = run_cli('cache', '--json', '--docker', $fake_docker);
    is($exit, 0, 'cache --json exits 0');
    is($err, '', 'cache --json writes nothing to standard error');

    my $document = eval { JSON::PP->new->decode($out) };
    ok($document, 'cache --json prints one JSON object') or diag "stderr: $err";
    is($document->{schema_version}, App::Actions::Cache->json_schema_version,
        'the document carries the version it was written for');
    is($document->{cache_file}, $ENV{ACTION_RUN_CACHE_FILE},
        'the document names the record it read');
    cmp_ok($document->{generated_at}, '>', 0,
        'the document records when it was made');
    cmp_ok($document->{generated_at}, '>=', $document->{images}[0]{last_used},
        'the image age is measured from generated_at');
    is($document->{docker}{bin}, $fake_docker, 'the document names the Docker command');
    ok($document->{docker}{reachable}, 'a working daemon is reported as reachable');
    is($document->{images}[0]{image}, 'alpine:3.20', 'the recorded image is listed');
    is($document->{images}[0]{pulls}, 1, 'the document counts the pulls');
    is(
        $document->{images}[0]{age},
        $document->{generated_at} - $document->{images}[0]{last_used},
        'the document carries the age derived from its clock',
    );
    is($document->{images}[0]{size}, 123_456_789,
        'the document carries the size rather than formatted text');
    ok($document->{images}[0]{present}, 'an image the daemon has is marked present');
    is($document->{totals}{images}, 1, 'the document counts the images');
    is($document->{totals}{size}, 123_456_789, 'the document totals the size');
    is($document->{totals}{present}, 1, 'the document counts the present images');
    is($document->{totals}{missing}, 0, 'the document counts the missing images');
    is($document->{prune}, undef, 'a listing reports no prune');

    ($out, $err, $exit) = run_cli('cache', '--prune', '--json', '--docker', $fake_docker);
    is($exit, 0, 'cache --prune --json exits 0');
    is($err, '', 'cache --prune --json writes nothing to standard error');

    $document = eval { JSON::PP->new->decode($out) };
    ok($document, 'the prune document decodes') or diag "stderr: $err";
    cmp_ok($document->{generated_at}, '>', 0,
        'the prune document records when it was made');
    is($document->{prune}{removed}, 1, 'the document says what the prune removed');
    is($document->{prune}{freed}, 123_456_789, 'the document says what the prune freed');
    is($document->{prune}{forgotten}, 0, 'the document says nothing was merely forgotten');
    is_deeply($document->{prune}{failed}, [], 'the document says every removal worked');
    is_deeply($document->{images}, [], 'the prune left no images in the document');
    is($document->{totals}{images}, 0, 'the prune left nothing to total');
}

{
    # A removal the daemon refuses is still reported in the document, and the
    # image it kept stays in the record rather than disappearing from it.
    App::Actions::Cache->new->remember('alpine:3.20', 'postgres:15');
    for my $image (qw(alpine:3.20 postgres:15)) {
        open my $marker, '>', image_marker($image) or die $!;
        print {$marker} $image;
        close $marker;
    }

    local $ENV{FAKE_IMAGE_REMOVE_FAILURE} = 'postgres:15';

    my ($out, $err, $exit) = run_cli(
        'cache', '--prune', '--json', '--docker', $fake_docker,
    );
    is($exit, 1, 'a prune that could not remove an image exits 1');
    is($err, '', 'the failure is reported in the document, not on standard error');

    my $document = eval { JSON::PP->new->decode($out) };
    ok($document, 'the failed-prune document decodes') or diag "stderr: $err";
    is($document->{prune}{removed}, 1, 'the document counts the image it removed');
    is_deeply($document->{prune}{failed}, ['postgres:15'],
        'the document names the image it could not remove');
    is_deeply(
        [ map { $_->{image} } @{ $document->{images} } ],
        ['postgres:15'],
        'the image that stayed in the record is still listed',
    );

    my $cache = App::Actions::Cache->new;
    is_deeply(
        [ map { $_->{image} } @{ $cache->entries } ],
        ['postgres:15'],
        'a failed removal leaves the image in the record for a second attempt',
    );

    $cache->forget('postgres:15');
    unlink image_marker('postgres:15');
}

{
    my $shipped = \&App::Actions::Cache::json_schema;
    no warnings 'redefine';
    local *App::Actions::Cache::json_schema = sub {
        my ($class) = @_;
        my $schema = $shipped->($class);
        delete $schema->{properties}{cache_file};
        return $schema;
    };

    my $built = eval { App::Actions::Cache->new->document; 1 };
    my $error = $@;
    ok(!$built, 'a document that does not match the schema is not returned');
    ok(ref $error && $error->isa('App::Actions::Schema::Invalid'),
        'the failure is the schema exception');
    like(
        "$error",
        qr/does not match App::Actions::Cache->json_schema: \$\.cache_file: unexpected key/,
        'the error names the document, the schema and the key at fault',
    );
}

{
    my (undef, undef, $exit) = run_cli('--docker', $fake_docker, $workflow, $project);
    is($exit, 0, 'the workflow runs again to rebuild the cache');

    local $ENV{FAKE_NO_DAEMON} = 1;

    my ($out, $err);
    ($out, $err, $exit) = run_cli('cache', '--docker', $fake_docker);
    is($exit, 0, 'listing works with the daemon stopped');
    like($out, qr/^  ubuntu:latest\s+unknown\s+/m,
        'the names are shown even when the sizes cannot be');
    like($out, qr/^The Docker daemon is not reachable, so the sizes are unknown\.$/m,
        'the listing says why the sizes are unknown');

    my ($json_out, $json_err, $json_exit) = run_cli(
        'cache', '--json', '--docker', $fake_docker,
    );
    is($json_exit, 0, 'cache --json still exits 0 with the daemon stopped');
    is($json_err, '', 'cache --json says nothing on standard error without a daemon');

    my $document = eval { JSON::PP->new->decode($json_out) };
    ok($document, 'the document decodes without a daemon') or diag "stderr: $json_err";
    ok(!$document->{docker}{reachable}, 'the document says the daemon was not reached');
    cmp_ok($document->{generated_at}, '>', 0,
        'the document still records when it was made without a daemon');
    is(
        $document->{images}[0]{age},
        $document->{generated_at} - $document->{images}[0]{last_used},
        'the age is still known when the daemon is not',
    );
    is($document->{images}[0]{size}, undef,
        'a size that could not be discovered is null');
    is($document->{images}[0]{present}, undef,
        'presence that could not be discovered is null');
    is($document->{totals}{size}, undef, 'the total size is null');
    is($document->{totals}{present}, undef, 'the present count is null');
    is($document->{totals}{missing}, undef, 'the missing count is null');

    ($out, $err, $exit) = run_cli('cache', '--prune', '--docker', $fake_docker);
    is($exit, 2, 'prune without a daemon exits 2');
    like($err, qr/cannot prune the image cache/, 'the error says what could not be done');
    ok(-f $ENV{ACTION_RUN_CACHE_FILE}, 'a failed prune leaves the record alone');
    ok(-e image_marker('ubuntu:latest'), 'a failed prune leaves the image alone');
}

{
    my ($out, $err, $exit) = run_cli(
        '--prune', '--dry-run', $workflow, $project,
    );
    is($exit, 2, '--prune without the cache or logs command is a usage error');
    like($err, qr/--prune is only used by the cache and logs commands/,
        'the error says where --prune belongs');
}

{
    my (undef, $err, $exit) = run_cli(
        'cache', '--older-than', 'fortnight',
    );
    is($exit, 2, 'an unknown duration is a usage error');
    like(
        $err,
        qr/--older-than must be a duration such as 30d, 12h or 90m, not 'fortnight'/,
        'the error says what a duration looks like',
    );
}

{
    my (undef, $err, $exit) = run_cli('--older-than', '2d', 'check');
    is($exit, 2, '--older-than with another command is a usage error');
    like($err, qr/--older-than is only used by the cache and logs commands/,
        'the error says where --older-than belongs');
}

{
    my (undef, $err, $exit) = run_cli('cache', 'extra');
    is($exit, 2, 'cache takes no arguments');
    like(
        $err,
        qr/Usage: action-run \[options\] cache \[--prune\] \[--older-than DURATION\] \[--json\]/,
        'the usage line says how to invoke cache',
    );
}

done_testing;
