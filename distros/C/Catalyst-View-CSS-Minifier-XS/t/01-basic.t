#!perl

use strict;
use warnings;

use FindBin;
use File::stat;
use Test::More;
use File::Spec;
use CSS::Minifier::XS 'minify';

use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp';

my $res = request('/test');
my $served = $res->content;

ok $served, q{served data isn't blank};
my $path = File::Spec->catfile($FindBin::Bin, qw{lib TestApp root css foo.css});
open my $file, '<', $path;

my $str = q{};
while (<$file>) {
   $str .= $_;
}

is minify($str), $served, 'server actually minifed the css';
is $res->headers->last_modified, stat($path)->mtime, 'right modtime header';

done_testing;

