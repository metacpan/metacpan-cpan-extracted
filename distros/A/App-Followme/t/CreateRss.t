#!/usr/bin/env perl
use strict;

use Cwd;
use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 19;

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
eval "use App::Followme::NestedText";
require App::Followme::CreateRss;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir  or die $!;
chmod 0755, $test_dir;
chdir $test_dir or die $!;
	
#----------------------------------------------------------------------
# Create object

my $site_url = 'http://www.example.com';
my $remote_url = 'http://cloudhost.com';

my %configuration = (
        author => 'Bernie Simon',
        site_url => $site_url,
        remote_url => $remote_url,
        list_length => 3,
        web_extension => 'html',
        );

my $idx = App::Followme::CreateRss->new(%configuration);

isa_ok($idx, "App::Followme::CreateRss"); # test 1
can_ok($idx, qw(new run)); # test 2

#----------------------------------------------------------------------
# Create rss file

do {
   my $page = <<'EOQ';
<html>
<head>
<meta name="robots" content="archive">
<!-- section meta -->
<title>Post %%</title>
<meta name="description" content="This is a page about %%" />
<meta name="keywords" content="%%" />
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

   my $index = <<'EOQ';
<html>
<head>
<!-- section meta -->
<title>All the Numbers</title>
<meta name="description" content="A blog about numbers" />
<meta name="keywords" content="math" />
<!-- endsection meta -->
</head>
<body>
<!-- section secondary -->
<h1>All the numbers</h1>

<ul>
<li><a href="one.html">One</a></li>
<li><a href="two.html">Two</a></li>
<li><a href="three.html">Three</a></li>
<li><a href="four.html">Four</a></li>
</ul>
<!-- endsection secondary -->
</body>
</html>
EOQ

    # Create underlying files

    my $filename = catfile($test_dir, 'index.html');
    fio_write_page($filename, $index);

	my $sec = 50;
    foreach my $count (qw(four three two one)) {
        my $output = $page;
        $output =~ s/%%/$count/g;

        my $filename = catfile($test_dir, "$count.html");
        fio_write_page($filename, $output);
        age($filename, $sec);
        $sec -= 10;
    }

    # Create and test rss file

    $idx->run($test_dir);
    my %rss = nt_parse_almost_xml_file('test.rss');
    
    my $channel = $rss{rss}{channel};
    ok(ref $channel eq 'HASH', "rss tag exists"); # test 3

    my @keys = sort keys %$channel;
    my @keywords = qw(author description item link pubDate title);
    is_deeply(\@keys, \@keywords, "channel has keywords"); # test 4

    for my $key (@keywords) {
        ok(length $channel->{$key}, "channel $key has a value"); # test 5-9
    }

    my $items = $channel->{item};
    is(@$items, 3, "rss has three items"); # test 10

    my @item_titles = map {$_->{title}} @$items;
    my @fourth = grep {/four/} @item_titles;
    is(@fourth, 0, "no fourth post"); # test 11

    my $item = $items->[0];
    my @keys = sort keys %$item;
    @keywords = qw(author description guid link pubDate title);
    is_deeply(\@keys, \@keywords, "item has keywords"); # test 12

    for my $key (@keywords) {
        ok(length $item->{$key}, "item $key has a value"); # test 13-17
    }    
};
