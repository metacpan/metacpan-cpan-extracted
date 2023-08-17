#!/usr/bin/env perl
use strict;

use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 9;

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

rmtree($test_dir, 0, 1) if -e $test_dir;
mkdir($test_dir) unless -e $test_dir;
 
chdir $test_dir or die $!;

my $archive_dir = catfile(@path, 'test', 'archive');
mkdir($archive_dir) unless -e $archive_dir;
  

#----------------------------------------------------------------------
# Create object

my $template_file = 'template.htm';

my %configuration = (
        top_directory => $test_dir,
        base_directory => $test_dir,
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

   my $index_page = <<'EOQ';
<html>
<head>
<meta name="robots" content="noarchive,follow">
<!-- section meta -->
<title>Stuff</title>
<meta name="date" content="2012-12-12T12:12:12" />
<meta name="description" content="All my thoughts about stuff." />
<meta name="keywords" content="stuff, thoughts" />
<meta name="author" content="Anna Blogger" />
<!-- endsection meta -->
</head>
<body>
<!-- section primary -->
<p>All my thoughts about stuff</p>
<!-- endsection primary -->
<!-- section secondary -->
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
<meta name="date" content="$date" />
<meta name="description" content="$description" />
<meta name="keywords" content="$keywords" />
<meta name="author" content="$author" />
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

   $template_file = catfile($test_dir, $template_file);
   fio_write_page($template_file, $index_template);

   chdir($archive_dir) or die $!;

   my ($index_name) = fio_to_file($archive_dir, $configuration{web_extension});
   fio_write_page($index_name, $index_page);

   foreach my $count (qw(four three two one)) {
      my $output = $page;
      $output =~ s/%%/$count/g;

      my $filename = catfile($archive_dir, "$count.html");
      fio_write_page($filename, $output);
   }

   chdir($archive_dir) or die $!;

   $configuration{base_directory} = $archive_dir;
   my $idx = App::Followme::CreateIndex->new(%configuration);
   $idx->run($archive_dir);

   $page = fio_read_page($index_name);
   ok($page, 'Write index page'); # test 3

   my $filled = $idx->sections_are_filled($index_name);
   ok($filled, 'Test if sections are filled'); # test 4

   like($page, qr/Post four/, 'Index first page title'); # test 5
   like($page, qr/Post two/, 'Index last page title'); # test 6

   like($page, qr/<title>Stuff<\/title>/, 'Write index title'); # test 7
   like($page, qr/<li><a href="archive\/two.html">Post two<\/a><\/li>/,
      'Write index link'); #test 8

   my $pos = index($page, $index_name);
   is($pos, -1, 'Exclude index file'); # test 9
};
