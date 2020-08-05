#!/usr/bin/env perl
use strict;

use Cwd;
use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 8;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::CreateIndex;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir  or die $!;
chmod 0755, $test_dir;

my $archive_dir = catfile(@path, 'test', 'archive');
mkdir($archive_dir)  or die $!;
chmod 0755, $archive_dir;

chdir $test_dir or die $!;
$test_dir = cwd();

#----------------------------------------------------------------------
# Create object

my $template_file = 'template.htm';
my $prototype_file = 'index.html';

my %configuration = (
        template_directory => $test_dir,
        template_file => $template_file,
        web_extension => 'html',
        );

my $idx = App::Followme::CreateIndex->new(%configuration);

isa_ok($idx, "App::Followme::CreateIndex"); # test 1
can_ok($idx, qw(new run)); # test 2

#----------------------------------------------------------------------
# Create indexes

do {
   my $page = <<'EOQ';
<html>
<head>
<meta name="robots" content="archive">
<!-- section meta -->
<title>Post %%</title>
<!-- endsection meta -->
</head>
<body>
<!-- section primary -->
<p>My latest posts.</p>
<!-- endsection primary -->
<!-- section secondary -->
<h1>Post %%</h1>

<p>All about %%.</p>
<!-- endsection secondary -->
</body>
</html>
EOQ

   my $index_template = <<'EOQ';
<html>
<head>
<meta name="robots" content="noarchive,follow">
<!-- section meta -->
<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<!-- section secondary -->
<h1>$title</h1>

<ul>
<!-- for @files -->
<li><a href="$url">$title</a></li>
<!-- endfor -->
</ul>
<!-- endsection secondary -->
</body>
</html>
EOQ

my $body_ok = <<'EOQ';

<h1>Post three</h1>

<p>All about three.</p>
EOQ

    fio_write_page($template_file, $index_template);

    chdir($archive_dir) or die $!;
    $archive_dir = cwd();
    my @archived_files;

    foreach my $count (qw(four three two one)) {
        my $output = $page;
        $output =~ s/%%/$count/g;

        my $filename = "$count.html";
        fio_write_page($filename, $output);
        push(@archived_files, $filename);
    }

    chdir($test_dir) or die $!;

    $idx->run($archive_dir);
    my ($index_name) = fio_to_file($archive_dir, $configuration{web_extension});

    $page = fio_read_page($index_name);
    ok($page, 'Write index page'); # test 3

    like($page, qr/Post four/, 'Index first page title'); # test 4
    like($page, qr/Post two/, 'Index last page title'); # test 5

    like($page, qr/<title>Archive<\/title>/, 'Write index title'); # test 6
    like($page, qr/<li><a href="archive\/two.html">Post two<\/a><\/li>/,
       'Write index link'); #test 7

    my $pos = index($page, $index_name);
    is($pos, -1, 'Exclude index file'); # test 8
};
