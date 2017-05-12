#!perl

use strict;
use warnings;

use FindBin;
use Test::More;
use File::Spec;
use JavaScript::Minifier::XS 'minify';
use HTTP::Request;
use HTTP::Headers;

use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp3';

my $h = HTTP::Headers->new;
$h->referrer('/station');

my $request = HTTP::Request->new(GET => '/test', $h);

my $served = get($request);

my $str = q{};
for my $t_file (qw{test.js station.js}) {
   my $path = File::Spec->catfile($FindBin::Bin, qw{lib TestApp3 root js}, $t_file);
   open my $file, '<', $path;

   while (<$file>) {
      $str .= $_;
   }
}
ok $served && minify($str) eq $served, 'server actually minifed the javascript';

done_testing;

