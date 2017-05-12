#!perl -T

use strict;
use warnings;
use Test::More tests => 5;

use Config::Apt::SourceEntry;
my $src = Config::Apt::SourceEntry->new("deb http://example.com/debian testing main contrib");
my ($type,$uri,$dist,@components);
$type = $src->get_type();
$uri  = $src->get_uri();
$dist = $src->get_dist();
@components = $src->get_components();

ok($type eq "deb" && $uri eq "http://example.com/debian" && $dist eq "testing", 'source line parsed correctly');
ok($components[0] eq "main" && $components[1] eq "contrib", 'parsed components correctly');

$src->set_type("deb-src");
$src->set_uri("ftp://example.net/ubuntu/");
$src->set_dist("edgy");
$src->set_components(("main"));

my $line = $src->to_string();

ok($line eq "deb-src ftp://example.net/ubuntu/ edgy main", 'set and constructed new line correctly');

my $nocomponents = "deb http://example.com/debian-custom ./";

$src = Config::Apt::SourceEntry->new();
$src->from_string($nocomponents);
ok(defined $src && $src->to_string eq $nocomponents, 'entry with no components created');

$src = Config::Apt::SourceEntry->new(" deb   http://example.com/debian	testing main");
$type = $src->get_type();
$uri  = $src->get_uri();
$dist = $src->get_dist();
ok($type eq "deb" && $uri eq "http://example.com/debian" && $dist eq "testing", 'source line with extra whitespace parsed correctly');
