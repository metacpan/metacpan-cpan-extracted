#!/usr/bin/env perl
use strict;

use Cwd;
use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 1;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::CreateSitemap;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir  or die $!;
chmod 0755, $test_dir;

mkdir catfile(@path, 'test', "sub") or die $!;
chmod 0755, catfile($test_dir, "sub");

chdir $test_dir or die $!;
$test_dir = cwd();

#----------------------------------------------------------------------
# Create pages to list in sitemap

do {
   my $page = <<'EOQ';
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

<p>All about %%.</p>
<!-- endsection content -->
</body>
</html>
EOQ

    my %configuration = (
            remote_url => 'http://www.example.com',
            sitemap => 'sitemap.txt',
            web_extension => 'html',
            );

    my $map = App::Followme::CreateSitemap->new(%configuration);

    my @webpages;
    foreach my $count (qw(first second third)) {
        my $output = $page;
        $output =~ s/%%/$count/g;

        my $filename = "$count.html";
        fio_write_page($filename, $output);

        my $absolute_url = $map->{data}->build('absolute_url', $filename);
        my $webpage = $configuration{remote_url} . $$absolute_url;
        push(@webpages, $webpage);
    }

    @webpages = sort @webpages;
    my @urls = sort $map->list_urls($test_dir);
    is_deeply(\@urls, \@webpages, 'create sitemap'); # test 1
};
