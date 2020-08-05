#!/usr/bin/env perl
use strict;

use Cwd;
use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 7;

#----------------------------------------------------------------------
# Change the modification date of a file

sub age {
	my ($filename, $sec) = @_;
	return unless -e $filename;
	return if $sec <= 0;
	
    my @stats = stat($filename);
    my $date = $stats[9];
    $date -= $sec;
    utime($date, $date, $filename);
    
    return; 
}

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::CreateNews;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir or die $!;
chmod 0755, $test_dir;

my $archive_dir = catfile(@path, 'test', 'archive');
mkdir($archive_dir) or die $!;
chmod 0755, $archive_dir;

chdir $test_dir or die $!;
$test_dir = cwd();
    
my %configuration = (
                        base_directory => $test_dir,
                        template_directory => '.',
                        news_index_length => 3,
                        news_template_file => 'blog_template.htm',
                        index_template_file => 'news_index.htm',
                        date_format => 'mon d, yyyy',
                    );

my $idx = App::Followme::CreateNews->new(%configuration);

isa_ok($idx, "App::Followme::CreateNews"); # test 1
can_ok($idx, qw(new run)); # test 2

#----------------------------------------------------------------------
# Write templates

do {
    chdir($test_dir) or die $!;
    $test_dir = cwd();

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
<h1>Post %%</h1>

<p>All about %%.</p>
<!-- endsection primary -->
<!-- section secondary -->
<!-- endsection secondary -->
</body>
</html>
EOQ

   my $archive_template = <<'EOQ';
<html>
<head>
<meta name="robots" content="noarchive,follow">
<!-- section meta -->
<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<!-- section primary -->
<!-- endsection primary -->
<!-- section secondary -->
<h2>$title</h2>

<!-- for @top_files -->
<h2>$title</h2>

$body
<p>$date<a href="$url">Permalink</a></p>
<!-- endfor -->
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
<!-- section primary -->
<!-- endsection primary -->
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

    my $idx = App::Followme::CreateNews->new(%configuration);
    fio_write_page($idx->{news_template_file}, $archive_template);
    fio_write_page($idx->{index_template_file}, $index_template);

	my $sec = 40;
    foreach my $count (qw(four three two one)) {
        my $output = $page;
        $output =~ s/%%/$count/g;

        my $filename = catfile('archive',"$count.html");
        fio_write_page($filename, $output);
        age($filename, $sec);
        $sec -= 10;
    }
};

#----------------------------------------------------------------------
# Create index files

do {
    chdir($test_dir) or die $!;
    $test_dir = cwd();
    
    my $idx = App::Followme::CreateNews->new(%configuration);

    my $archive_dir = catfile($test_dir, 'archive');
    my $index_file = fio_to_file($archive_dir, $idx->{web_extension});

    $idx->update_folder($test_dir);
    my $page = fio_read_page($index_file);

    like($page, qr/>Post one<\/a><\/li>/, 'Archive index content'); # test 3
    like($page, qr/<a href="archive\/one.html">/, 'Archive index link'); # test 4
};

#----------------------------------------------------------------------
# Create news file

do {
    chdir($test_dir);
    my $idx = App::Followme::CreateNews->new(%configuration);
    my $news_file = fio_full_file_name($test_dir, 'index.html');

    $idx->update_folder($test_dir);
    my $page = fio_read_page($news_file);

    like($page, qr/All about two/, 'Archive news content'); # test 5
    like($page, qr/<h2>Post two/, 'Archive news title'); # test 6
    like($page, qr/<a href="archive\/one.html">/, 'Archive news link'); # test 7
};
