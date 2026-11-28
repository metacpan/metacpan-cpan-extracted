use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use Cwd 'getcwd';
use File::Copy;
use File::Temp 'tempdir';
use App::LinkSite;

# Test that we can pass a custom file parameter
my $fixture = "$Bin/links.json";
my $linksite = App::LinkSite->new(file => $fixture);
isa_ok($linksite, 'App::LinkSite', 'Created an App::LinkSite object with file parameter');

# Test that the file parameter is correctly stored
is($linksite->file, $fixture, 'file parameter is correctly set');

# Test default file parameter
my $original_dir = getcwd;
my $content_dir = tempdir(CLEANUP => 1);
copy $fixture, "$content_dir/links.json" or die "Cannot copy fixture: $!";

my $completed = eval {
    chdir $content_dir or die "Cannot enter $content_dir: $!";
    my $linksite_default = App::LinkSite->new();
    is($linksite_default->file, 'links.json', 'default file parameter is "links.json"');
    1;
};
my $error = $@;
chdir $original_dir or die "Cannot restore $original_dir: $!";
die $error unless $completed;
is(getcwd, $original_dir, 'working directory is restored after the default-file test');

done_testing;
