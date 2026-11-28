use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use File::Temp 'tempdir';
use IPC::Open3;
use JSON;
use Path::Tiny;
use App::LinkSite;

my $root = path($Bin)->parent;
my $work = path(tempdir(CLEANUP => 1));
my $runner = $work->child('run-cli.pl');
$runner->spew(q{
    use File::ShareDir ();
    my ($directory, $cli, $src) = splice @ARGV, 0, 3;
    chdir $directory or die "Cannot enter $directory: $!";
    # Exercise checkout templates even when a CPAN installation also exists.
    my $dist_dir = \&File::ShareDir::dist_dir;
    {
        no warnings 'redefine';
        *File::ShareDir::dist_dir = sub {
            return $src if $_[0] eq 'App-LinkSite';
            return $dist_dir->(@_);
        };
    }
    $0 = $cli;
    do $cli;
    die $@ if $@;
});

sub run_cli {
    my ($directory, @args) = @_;
    my $output;
    my $pid = open3(undef, $output, $output, $^X,
        '-I' . $root->child('lib'), "$runner", "$directory",
        $root->child('bin', 'linksite')->stringify,
        $root->child('src')->stringify, @args);
    my $text = do { local $/; <$output> };
    close $output;
    waitpid $pid, 0;
    return ($? >> 8, $text);
}

sub write_input {
    my ($file, $name) = @_;
    $file->parent->mkpath;
    $file->spew(JSON->new->canonical->encode({
        name => $name, handle => 'example', desc => 'CLI fixture',
        image => '', og_image => '', site_url => 'https://example.invalid/',
        social => [], links => [{ title => 'Website', link => 'https://example.invalid/' }],
    }));
}

for my $case (
    ['default input', 'links.json'],
    ['custom input path with spaces', 'content/my profile.json', '--file', 'content/my profile.json'],
    ['filename zero', '0', '--file', '0'],
) {
    my ($label, $filename, @args) = @$case;
    subtest $label => sub {
        my $directory = $work->child($label);
        $directory->mkpath;
        my $input = $directory->child($filename);
        write_input($input, $label);
        $directory->child('links.json')->spew('invalid default input')
            if $filename ne 'links.json';
        my ($status, $output) = run_cli($directory, @args);
        is($status, 0, 'CLI build succeeds') or diag $output;
        my $index = $directory->child('docs', 'index.html');
        ok($index->is_file, 'CLI generates index.html');
        SKIP: {
            skip 'no generated page', 3 unless $index->is_file;
            like($index->slurp, qr/\Q$label\E/, 'page uses the selected input');
            ok($directory->child('docs', 'css', 'style.css')->is_file, 'CSS is copied');
            my $published = $directory->child('docs', $input->basename);
            is($published->is_file ? $published->slurp_raw : undef,
                $input->slurp_raw, 'selected JSON is published under its basename');
        }
        done_testing;
    };
}

for my $case (
    ['help', ['--help'], [qr/Usage: linksite.*--file/]],
    ['version', ['--version'], [qr/^linksite \Q$App::LinkSite::VERSION\E\r?$/m]],
    ['combined info', ['--file', 'missing.json', '--help', '--version'],
        [qr/Usage: linksite.*--file/, qr/^linksite \Q$App::LinkSite::VERSION\E\r?$/m]],
) {
    my ($label, $args, $expected) = @$case;
    subtest $label => sub {
        my $directory = $work->child($label);
        $directory->mkpath;
        my ($status, $output) = run_cli($directory, @$args);
        is($status, 0, 'informational options succeed without an input file');
        like($output, $_, 'expected information is displayed') for @$expected;
        ok(!$directory->child('docs')->exists, 'informational options do not build');
        done_testing;
    };
}

for my $case (
    ['unknown option', ['--no-such-option'], qr/Unknown option/],
    ['missing filename', ['--file'], qr/requires an argument/],
) {
    my ($label, $args, $expected) = @$case;
    subtest $label => sub {
        my $directory = $work->child($label);
        write_input($directory->child('links.json'), 'Must not build');
        my ($status, $output) = run_cli($directory, @$args);
        is($status, 2, 'invalid options return a usage error');
        like($output, $expected, 'option error is displayed');
        ok(!$directory->child('docs')->exists, 'invalid options do not build');
        done_testing;
    };
}

done_testing;
