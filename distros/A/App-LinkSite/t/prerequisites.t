use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use File::Temp 'tempdir';
use IPC::Open3;
use Path::Tiny;
use CPAN::Meta;

my $root = path($Bin)->parent;
my $work = path(tempdir(CLEANUP => 1));
$root->child('Makefile.PL')->copy($work->child('Makefile.PL'));
$work->child('lib', 'App')->mkpath;
$root->child('lib', 'App', 'LinkSite.pm')->copy(
    $work->child('lib', 'App', 'LinkSite.pm')
);
$work->child('src')->mkpath;

my $runner = $work->child('configure.pl');
$runner->spew(q{
    chdir $ARGV[0] or die "Cannot enter $ARGV[0]: $!";
    my $status = system {$^X} $^X, 'Makefile.PL';
    die "Cannot configure distribution: $!" if $status == -1;
    exit($status == 0 ? 0 : 1);
});
my $output;
my $pid = open3(undef, $output, $output, $^X, "$runner", "$work");
my $diagnostics = do { local $/; <$output> };
close $output;
waitpid $pid, 0;
is($?, 0, 'Makefile.PL configures successfully in a fresh directory')
    or diag $diagnostics;
unlike($diagnostics, qr/Undefined requirement|Warning: prerequisite\s/,
    'configuration has no malformed or unsatisfied prerequisite warnings')
    or diag $diagnostics;

my $metadata_file = $work->child('MYMETA.json');
ok($metadata_file->is_file, 'configuration writes MYMETA.json')
    or diag $diagnostics, explain([map { "$_" } $work->children]);
BAIL_OUT('Cannot check prerequisites without generated metadata')
    unless $metadata_file->is_file;

my $configured = CPAN::Meta->load_file("$metadata_file");
my $generated = $configured->effective_prereqs;
my $bootstrap = CPAN::Meta->load_file($root->child('META.json')->stringify);
is_deeply($bootstrap->effective_prereqs->as_string_hash,
    $generated->as_string_hash,
    'committed bootstrap metadata matches freshly configured prerequisites');
is($bootstrap->version, $configured->version,
    'committed metadata version matches the distribution');
is_deeply(
    $generated->requirements_for('configure', 'requires')->as_string_hash,
    {
        'File::ShareDir::Install' => '0',
        'ExtUtils::MakeMaker' => '7.70',
        'ExtUtils::CBuilder' => '0.280236',
        'CPAN::Meta' => '2.150010',
        'CPAN::Meta::YAML' => '0.018',
    },
    'generated metadata retains all configure prerequisites and minimum versions',
);

my $runtime = $generated->requirements_for('runtime', 'requires')->as_string_hash;
is($runtime->{'Path::Tiny'}, '0.125', 'Path::Tiny minimum version is advertised');
ok(exists $runtime->{'File::Basename'}, 'File::Basename is a runtime prerequisite');
ok(exists $runtime->{'URI'}, 'URI is a runtime prerequisite');
ok(exists $runtime->{'URI::Escape'}, 'URI::Escape is a runtime prerequisite');
is($runtime->{perl}, '5.026000', 'Perl 5.26 minimum version is advertised');
is($generated->requirements_for('test', 'requires')->as_string_hash->{'Test::More'},
    '0', 'Test::More is a test prerequisite');

done_testing;
