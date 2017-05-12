#!perl

use strict;
use warnings;

use FindBin;
use Test::More;
use File::Spec;
use CSS::Minifier::XS 'minify';

use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp2';

my $served = get('/test');

my $path = File::Spec->catfile($FindBin::Bin, qw{lib TestApp2 different_root ssc foo.css});
open my $file, '<', $path;

my $str = q{};
while (<$file>) {
   $str .= $_;
}
ok $served && minify($str) eq $served,
   'server actually minifed the css, so changing the stash and path varaible worked';

done_testing;

