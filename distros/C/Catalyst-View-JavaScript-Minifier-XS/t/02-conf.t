#!perl

use strict;
use warnings;

use FindBin;
use Test::More;
use File::Spec;
use JavaScript::Minifier::XS 'minify';

use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp2';

my $served = get('/test');

my $path = File::Spec->catfile($FindBin::Bin, qw{lib TestApp2 different_root sj foo.js});
open my $file, '<', $path;

my $str = q{};
while (<$file>) {
   $str .= $_;
}

ok $served && minify($str) eq $served,
   'server actually minifed the javascript, so changing the stash variable and path worked';

done_testing;

