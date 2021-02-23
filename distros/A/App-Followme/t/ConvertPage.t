#!/usr/bin/env perl
use strict;

use Cwd;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::Requires 'Text::Markdown';
use Test::More tests => 7;

use lib '../..';

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
require App::Followme::ConvertPage;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir or die $!;
chmod 0755, $test_dir;

my $sub = catfile(@path, 'test', 'sub');
mkdir $sub  or die $!;
chmod 0755, $sub;

my $template_directory = $sub;
mkdir($template_directory) unless -e $template_directory;
chmod 0755, $template_directory;
chdir $template_directory or die $!;
$template_directory = cwd();
	
chdir $test_dir or die $!;
$test_dir = cwd();

#----------------------------------------------------------------------
# Create object

my $template_file = catfile($template_directory, 'template.htm');
my $prototype_file = catfile($test_dir, 'index.html');

my $cvt = App::Followme::ConvertPage->new(template_directory => $template_directory,
                                          template_file => $template_file);

isa_ok($cvt, "App::Followme::ConvertPage"); # test 1
can_ok($cvt, qw(new run)); # test 2

#----------------------------------------------------------------------
# Write test data

do {
   my $index = <<'EOQ';
<html>
<head>
<meta name="robots" content="archive">
<!-- section meta -->
<title>Home</title>
<!-- endsection meta -->
</head>
<body>
<!-- section primary -->
<h1>Home</h1>
<!-- endsection primary -->

<ul>
<li><a href="index.html">Home</a></li>
</ul>
</body>
</html>
EOQ

   my $template = <<'EOQ';
<html>
<head>
<meta name="robots" content="archive">
<!-- section meta -->
<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<!-- section primary -->
<h1>$title</h1>

$body
<!-- endsection primary -->
</body>
</html>
EOQ

   my $text = <<'EOQ';
Page %%
--------

This is a paragraph


    This is preformatted text.

* first %%
* second %%
* third %%
EOQ

    my %configuration = (template_file => 'template.htm');
    my $cvt = App::Followme::ConvertPage->new(%configuration);

    fio_write_page($prototype_file, $index);
    fio_write_page($template_file, $template);

	my $sec = 40;
    foreach my $count (qw(four three two one)) {
        my $output = $text;
        $output =~ s/%%/$count/g;

        my $filename = catfile($test_dir, "$count.md");
        fio_write_page($filename, $output);
        age($filename, $sec);
        $sec -= 10;
    }
};

#----------------------------------------------------------------------
# Get filename from title

do {
   my $filename = catfile($test_dir, 'one.html');
   my $new_filename = $cvt->title_to_filename($filename);
   is($new_filename, $filename, "Title to filename"); #test 3
};

#----------------------------------------------------------------------
# Test update file and folder
do {
    $cvt->update_file($test_dir, $prototype_file, 'four.md');

    my $file = catfile($test_dir, 'four.html');
    my $page = fio_read_page($file);
    like($page, qr/<h1>Four<\/h1>/, 'Update file four'); # test 4

    $cvt->update_folder($test_dir);
    foreach my $count (qw(three two one)) {
        $file = catfile($test_dir, "$count.html");
        $page = fio_read_page($file);
        my $kount = ucfirst($count);

        like($page, qr/<h1>$kount<\/h1>/,
             "Update folder file $count"); # test 5-7
    }
};
