#!/usr/bin/env perl
use strict;

use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 4;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::UploadData;

my $test_dir = catdir(@path, 'test');
my $state_dir = catdir(@path, 'test', '_state');

rmtree($test_dir);
mkdir $test_dir or die $!;
chmod 0755, $test_dir;

mkdir $state_dir or die $!;
chmod 0755, $state_dir;
chdir $test_dir or die $!;

my %configuration = (
                     top_directory => $test_dir,
                   );

#----------------------------------------------------------------------
# Create test files

my $page = <<'EOQ';
<html>
<head>
<meta name="robots" content="archive">
<!-- section meta -->
<title>Post %%</title>
<!-- endsection meta -->
</head>
<body>
<!-- section content -->
<h1>Post %%</h1>

<p>All about !!.</p>
<!-- endsection content -->
</body>
</html>
EOQ

my @dirs = ('', 'sub');
my @folders_ok;
my @files_ok;

foreach my $dir (@dirs) {
    if ($dir) {
        mkdir $dir or die $!;
        chmod 0755, $dir;
        push(@folders_ok, catfile($test_dir, $dir));
    }

    foreach my $count (qw(one two three)) {
        my $output = $page;
        $output =~ s/!!/$dir/g;
        $output =~ s/%%/$count/g;

        my $filename = $dir ? catfile($dir, "$count.html") : "$count.html";
        fio_write_page($filename, $output);

        unless ($dir) {
            push(@files_ok, catfile($test_dir, $filename));
        }
    }
}

@folders_ok = sort(@folders_ok);
@files_ok = sort(@files_ok);

#----------------------------------------------------------------------
# Create object

my $obj = App::Followme::UploadData->new(%configuration);
isa_ok($obj, "App::Followme::UploadData"); # test 1
can_ok($obj, qw(new build)); # test 2

#----------------------------------------------------------------------
# Test list creation
do {
    my $index_file = fio_to_file($test_dir, 'html');
    my $files = $obj->build('files', $index_file);
    my @files = sort @$files;

    is_deeply(\@files, \@files_ok, "List of files"); # test 3

    my $folders = $obj->build('folders', $index_file);
    my @folders = sort @$folders;

    is_deeply(\@folders, \@folders_ok, "List of folders"); # test 3
};
