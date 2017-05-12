#!perl
use strict;
use warnings;

# Copied and modified from the CPAN-Mini-Webserver-0.51 distribution

use FindBin;
use lib "$FindBin::Bin";

use Test::More;
use Compress::Zlib;
use CPAN::Mini::Webserver::PSGI;
use File::Slurp qw( read_file write_file );
use File::Path 'remove_tree';
use Plack::Test;
use WebserverTester;

chdir "$FindBin::Bin/..";
$ENV{CPAN_MINI_CONFIG} = 't/mini/.minicpanrc';
for my $file ( qw( t/mini/authors/01mailrc.txt t/mini/modules/02packages.details.txt ) ) {
    my $gz_file = "$file.gz";
    unlink $gz_file if -e $gz_file;
    my $gz = Compress::Zlib::memGzip( read_file( $file, binmode => ':raw' ) ) or die "Cannot compress $file: $gzerrno\n";
    write_file( $gz_file, { binmode => ':raw' }, $gz );
}

plan tests => 47;

my $server = CPAN::Mini::Webserver::PSGI->new;
my $app    = $server->to_app;
set_app($app);

my $name =
  ( $server->author_type eq 'Whois' )
  ? "Andreas CpanTest K"
  : "Andreas CpanTest K";    # TODO : figure out how to deal with umlaute
my $dist          = "CPAN-Test-Dummy-Perl5-Make-1.05";
my $cpan_id       = "andk";
my $cpan_id_upper = uc $cpan_id;
my $cpan_id_path  = "A/AN";
my $module        = "Bundle/CpanTestDummies.pm";
my $desc          = "A bundle only for testing CPAN.pm";

my $html;

# index
$html = html_page_ok( '/' );
like( $html, qr/Index/ );
like( $html, qr/Welcome to CPAN::Mini::Webserver/ );

# search for nothing
$html = html_page_ok( '/search/', q => '' );
like( $html, qr/No results found./ );

# search for buffy
$html = html_page_ok( '/search/', q => "dummy" );
like( $html, qr/Search for .dummy./ );
like( $html, qr/$dist/ );
like( $html, qr/$name/ );

# show Leon
$ENV{BREAK_NOW} = 1;
$html = html_page_ok( "~$cpan_id/", 'q' => undef );
like( $html, qr/$name/ );
like( $html, qr/$dist/ );
like( $html, qr/CPAN-Test-Dummy-Perl5-Build-1.03/ );

# Show $dist
$html = html_page_ok( "~$cpan_id/$dist/" );
like( $html, qr/$name.* &gt; $dist/ );
like( $html, qr/Changes/ );
like( $html, qr/00_load\.t/ );

# Show $dist Changes
$html = html_page_ok( "~$cpan_id/$dist/$dist/Changes" );
like( $html, qr{$name.* &gt; $dist &gt; $dist/Changes} );
like( $html, qr/Revision history for CPAN-Test-Dummy-Perl5-Make/ );

# Show $dist Buffy.pm
$html = html_page_ok( "~$cpan_id/$dist/$dist/lib/$module" );
like( $html, qr{$name.* &gt; $dist &gt; $dist/lib/$module} );
like( $html, qr{$desc} );
like( $html, qr{See raw file} );

# Show $dist Buffy.pm
$html = html_page_ok( "/raw/~$cpan_id/$dist/$dist/lib/$module" );
like( $html, qr{$name.* &gt; $dist &gt; $dist/lib/$module} );
like( $html, qr{$desc} );

# Show package Acme::Buffy.pm
redirect_ok( "/~$cpan_id/$dist/$dist/lib/$module", "/package/$cpan_id/$dist/Bundle::CpanTestDummies/" );

# 'static' files
css_ok( '/static/css/screen.css' );
css_ok( '/static/css/print.css' );
css_ok( '/static/css/ie.css' );
png_ok( '/static/images/logo.png' );
png_ok( '/static/images/favicon.png' );
png_ok( 'favicon.ico' );
opensearch_ok( '/static/xml/opensearch.xml' );

# 404
error404_ok( '/this/doesnt/exist' );

# downloads
$html = download_ok( "/download/~$cpan_id_upper/$dist/$dist/README" );
like( $html, qr{This CPAN distribution file is designed for testing purposes only.} );

redirect_ok( "/authors/id/$cpan_id_path/$cpan_id_upper/$dist.tar.gz", "/download/~$cpan_id_upper/$dist", );

# be like a CPAN mirror
$html = download_gzip_ok( "/authors/id/$cpan_id_path/$cpan_id_upper/$dist.tar.gz" );

$html = download_gzip_ok( '/modules/02packages.details.txt.gz' );
like( $html, qr{^\037\213} );

$html = download_gzip_ok( '/authors/01mailrc.txt.gz' );
like( $html, qr{^\037\213} );

$html = download_ok( "/authors/id/$cpan_id_path/$cpan_id_upper/CHECKSUMS" );
like( $html, qr{this PGP-signed message is also valid perl} );

error404_ok( "/authors/id/$cpan_id_path/$cpan_id_upper/CHECKSUMZ" );
