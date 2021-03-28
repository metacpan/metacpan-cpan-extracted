#!/usr/bin/env perl
use strict;

use Test::More tests => 31;

use File::Path qw(rmtree);
use File::Spec::Functions qw(abs2rel catdir catfile rel2abs splitdir);

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

$lib = catdir(@path, 't');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::FolderData;

my $test_dir = catdir(@path, 'test');
rmtree($test_dir)  if -e $test_dir;

mkdir $test_dir or die $!;
chmod 0755, $test_dir;

my $archive = catfile(@path, 'test', 'archive'); 
mkdir $archive or die $!;
chmod 0755, $archive;
chdir($test_dir) or die $!;

#----------------------------------------------------------------------
# Create object

my $site_url = 'http://www.example.com';
my $remote_url = 'http://www.cloud.com';

my %configuration = (directory => $test_dir,
                     top_directory => $test_dir,
                     base_directory => $test_dir,
                     author => 'Bernie Simon',
                     site_url => $site_url,
                     remote_url => $remote_url,
                    );

my $obj = App::Followme::FolderData->new(%configuration);
isa_ok($obj, "App::Followme::FolderData"); # test 1
can_ok($obj, qw(new build)); # test 2

#----------------------------------------------------------------------
# Test builders

do {
    my $obj = App::Followme::FolderData->new(%configuration);

    my $filename = catfile($test_dir, 'archive','one.txt');

    my $title = $obj->calculate_title($filename);
    my $title_ok = 'One';
    is($title, $title_ok, 'Calculate file title'); # test 3

    my $index_name = catfile($test_dir, 'archive','index.html');
    $title = $obj->calculate_title($index_name);
    $title_ok = 'Archive';
    is($title, $title_ok, 'Calculate directory title'); # test 4

    my $keywords = $obj->calculate_keywords($filename);
    my $keywords_ok = 'archive';
    is($keywords, $keywords_ok, 'Calculate file keywords'); # test 5

    my $is_index = $obj->get_is_index($filename);
    is($is_index, 0, 'Regular file in not index'); # test 6

    $is_index = $obj->get_is_index($index_name);
    is($is_index, 1, 'Index file is index'); # test 7

    my $url = $obj->get_url($filename);
    my $url_ok = 'archive/one.html';
    is($url, $url_ok, 'Build a relative file url'); # test 8

    $url = $obj->get_absolute_url($filename);
    $url_ok = $site_url . '/archive/one.html';
    is($url, $url_ok, 'Build an absolute file url'); # test 9

    $url = $obj->get_remote_url($filename);
    $url_ok = $remote_url . '/archive/one.html';
    is($url, $url_ok, 'Build a remote file url'); # test 10

    $url = $obj->get_index_url($filename);
    $url_ok = 'archive/index.html';
    is($url, $url_ok, 'Build the url 0f the index page'); # test 11

    my $url_base = $obj->get_url_base($filename);
    my $url_base_ok = 'archive/one';
    is($url_base, $url_base_ok, 'Build a file url base'); # test 12

    my $ext = $obj->get_extension($filename);
    is($ext, 'txt', 'Build the filename extension'); # test 13

    $url = $obj->get_url($test_dir);
    is($url, 'index.html', 'Build directory url'); #test 14

    my $date = $obj->calculate_date('two.html');
    ok($date > 1000000000, 'Calculate date'); # test 15

    $date = $obj->format_date(1, time());
    ok($date gt '1000000000', 'Format date in sort order'); # test 16

    $obj->{date_format} = 'dd/mm/yyyy';
    $date = $obj->format_date(0, time());
    like($date, qr(^\d\d/\d\d/\d\d\d\d$),
         'Format date with user supplied format'); # test 17

    my $size = $obj->format_size(0, 2500);
    is($size, '2kb', 'Format size'); # test 18

    $size = $obj->format_size(1, 2500);
    my $ok_size = sprintf("%012d", $size);
    is($size, $ok_size, 'Format size'); # test 19

    my $author = $obj->calculate_author($test_dir);
    is($author, $configuration{author}, "Get author"); # test 20

    my $site_url = $obj->get_site_url($test_dir);
    is($site_url, $configuration{site_url}, "Get site url"); # test 21
};

#----------------------------------------------------------------------
# Test filename variables

do {
   my $code = <<'EOQ';
<html>
<head>
<meta name="robots" content="archive">
<!-- section meta -->
<title>Page %%</title>
<!-- endsection meta -->
</head>
<body>
<!-- section content -->
<h1>Page %%</h1>
<!-- endsection content -->
<ul>
<!-- section nav -->
<li><a href="%%.html">%%</a></li>
<!-- endsection nav -->
</ul>
</body>
</html>
EOQ

	my $sec = 100;
    my @ok_files;
    my @ok_all_files;
    my @ok_breadcrumbs;
    my @dirs = ($test_dir);
    foreach my $dir (('', 'archive')) {
        push(@dirs, $dir) if $dir;
        my $index_name = catfile(@dirs, 'index.html');
        push(@ok_breadcrumbs, $index_name);

        foreach my $count (sort qw(four three two one index)) {
            my $output = $code;
            $output =~ s/%%/$count/g;

            my $filename = catfile(@dirs, "$count.html");
            my $xfilename = catfile(@dirs, "$count.xhtml");

            push(@ok_files, $filename) unless $dir;
            push(@ok_all_files, $filename);
            fio_write_page($filename, $output);
            fio_write_page($xfilename, $output);
			age($filename, $sec);
			$sec -= 10;
        }
    }

    my $obj = App::Followme::FolderData->new(%configuration);

    my $size = $obj->get_size(catfile($test_dir, 'three.html'));
    ok($size > 300, 'get file size'); # test 22

    my $index_file = catfile($test_dir,'index.html');
    my $files = $obj->get_files($index_file);
    is_deeply($files, \@ok_files, 'Build files'); # test 23

    my $all_files = $obj->get_all_files($index_file);
    is_deeply($all_files, \@ok_all_files, 'Build all files'); # test 24

    my $filename = catfile($test_dir, 'archive', 'two.html');
    my $breadcrumbs = $obj->get_breadcrumbs($filename);
    is_deeply($breadcrumbs, \@ok_breadcrumbs, 'Build breadcrumbs'); # test 25

    $filename = catdir($test_dir, 'archive');
    my $folders = $obj->get_folders($test_dir);
    is_deeply($folders, [$filename], 'Build folders'); # test 26

    my $related_files = $obj->get_related_files(catfile($test_dir, 'one.html'));
    my $related_ok = [catfile($test_dir, 'one.html'), catfile($test_dir, 'one.xhtml')];
    is_deeply($related_files, $related_ok, 'Build list of related files'); # test 27

    $obj->{list_length} = 2;

    my $top_files = $obj->get_top_files($index_file);
    my $top_files_ok = [catfile($test_dir, 'archive','two.html'),
                        catfile($test_dir, 'archive','three.html')];

    is_deeply($top_files, $top_files_ok, 'Build top files');  # test 28

    my $newest_file_ok = [$ok_all_files[-1]];
    my $newest_file = $obj->get_newest_file();
    is_deeply($newest_file, $newest_file_ok, 'Get newest file'); # test 29

    my (@urls, @next_urls, @previous_urls);
    for my $file (@ok_files) {
        push(@urls, $obj->get_url($file));
        push(@next_urls, $obj->get_url_next($file, \@ok_files));
        push(@previous_urls, $obj->get_url_previous($file, \@ok_files));
    }

    my @ok_next_urls = @urls;
    shift(@ok_next_urls);
    push(@ok_next_urls, '');
    is_deeply(\@next_urls, \@ok_next_urls, "Get next url"); # test 30

    my @ok_previous_urls = @urls;
    pop(@ok_previous_urls);
    unshift(@ok_previous_urls, '');
    is_deeply(\@previous_urls, \@ok_previous_urls, "Get previous url"); # test 31
};
