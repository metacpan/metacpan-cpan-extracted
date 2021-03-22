#!/usr/bin/env perl
use strict;

use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 11;

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
require App::Followme::EditSections;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir  or die $!;
chmod 0755, $test_dir;

my $sub_dir = catfile(@path, "test", "sub"); 
mkdir $sub_dir or die $!;
chmod 0755, $sub_dir;
chdir $test_dir or die $!;

my %configuration = (
                    top_directory => $test_dir,
                    base_directory => $test_dir,
                    remove_comments => 0,
                    data_pkg => 'App::Followme::WebData',
                    );

#----------------------------------------------------------------------
# Write test pages

do {
   my $page = <<'EOQ';
<html>
<head>
<meta name="robots" content="archive">
<!-- begin meta -->
<title>page %%</title>
<!-- end meta -->
</head>
<body>
<!-- begin content -->
<h1>page %%</h1>
<!-- end content -->
<ul>
<li><a href="">&& link</a></li>
<!-- begin nav -->
<li><a href="">link %%</a></li>
<!-- end nav -->
</ul>
</body>
</html>
EOQ

    my $es = App::Followme::EditSections->new(%configuration);

    foreach my $dir (('sub', '')) {
        foreach my $count (qw(four three two one)) {
            my $output = $page;
            $output =~ s/%%/$count/g;

            my $filename;
            if ($dir) {
                $filename = catfile($test_dir, $dir, $count);
            } else {
                $filename = catfile($test_dir, $count);
            }
            $filename .= '.html';

			my $sec;
            if ($count eq 'one' && $dir eq '') {
                $output =~ s/begin/section/g;
                $output =~ s/end/endsection/g;
                $sec = 0;
            } else {
				$sec = 10;
			}

            fio_write_page($filename, $output);
			age($filename, $sec);
        }
    }

#----------------------------------------------------------------------
};
# Test comment removal

do {
    my $es = App::Followme::EditSections->new(%configuration);

    my $filename = catfile($test_dir, 'one.html');
    my $output = $es->strip_comments($filename, 1);
    my $output_ok = fio_read_page($filename);
    is($output, $output_ok, 'strip comments, keep sections'); # test 1

    $output = $es->strip_comments($filename, 0);
    $output_ok =~ s/(<!--.*?-->)//g;
    is($output, $output_ok, 'strip comments and sections'); # test 2

    $filename = catfile($test_dir, 'two.html');
    $output = $es->strip_comments($filename, 0);
    $output_ok = fio_read_page($filename);
    is($output, $output_ok, 'don\'t strip comments'); # test 3

    $configuration{remove_comments} = 1;
    $es = App::Followme::EditSections->new(%configuration);
    $configuration{remove_comments} = 0;

    $output = $es->strip_comments($filename, 0);
    $output_ok =~ s/(<!--.*?-->)//g;
    is($output, $output_ok, 'strip comments'); # test 4
};

#----------------------------------------------------------------------
# Test update folder

do {
    my $es = App::Followme::EditSections->new(%configuration);

    my $filename = catfile($test_dir, 'one.html');
    my $prototype = $es->strip_comments($filename, 1);
    $es->update_folder($test_dir);

    my $output_template = <<EOQ;
<html>
<head>
<meta name="robots" content="archive">
<!-- section meta -->
<!-- begin meta -->
<title>page %%</title>
<!-- end meta -->
<!-- endsection meta -->
</head>
<body>
<!-- section content -->
<!-- begin content -->
<h1>page %%</h1>
<!-- end content -->
<!-- endsection content -->
<ul>
<li><a href="">&& link</a></li>
<!-- section nav -->
<!-- begin nav -->
<li><a href="">link %%</a></li>
<!-- end nav -->
<!-- endsection nav -->
</ul>
</body>
</html>
EOQ

    foreach my $dir (('sub', '')) {
        for my $count (qw(one two three four)) {
            next if $count eq 'one' && $dir eq '';

            my $filename;
            if ($dir) {
                $filename = catfile($test_dir, $dir, $count);
            } else {
                $filename = catfile($test_dir, $count);
            }
            $filename .= '.html';

            my $output = fio_read_page($filename);

            my $output_ok = $output_template;
            $output_ok =~ s/%%/$count/g;

            is($output, $output_ok, "update file $filename"); # test 5-11
        }
    }

};
