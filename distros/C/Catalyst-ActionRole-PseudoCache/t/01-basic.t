#!perl

use strict;
use warnings;
use autodie;

use FindBin;
use Test::More;
use Test::WWW::Mechanize::Catalyst;
use File::Spec;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
my $root = File::Spec->catfile($FindBin::Bin,qw{lib TestApp root});
mkdir $root unless -e $root;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp');
$mech->get_ok('/test', 'get works when uncached');
$mech->content_is('big fat output', '... and the output is correct');
ok stat File::Spec->catfile($root, 'foo.txt'), '... and the file is cached as expected';
$mech->get_ok('/test', 'get works when cached');
$mech->content_is('big fat output', '... and the output is still correct');
use Catalyst::Test 'TestApp';
{
   action_redirect('/test', '... and it is done with a redirect');
   content_like('/test', qr{href="/foo\.txt"}, '... and it redirects to the right place');
   get('/test2'); #prime the pump
   content_like('/test2', qr{href="/static/foo\.txt"}, 'action redirects to the right place with a more complex config');
   ok stat File::Spec->catfile($root, 'bar.txt'), '... and the file is cached as expected, in the configured location';
};
done_testing;

END {
   # for some reason unlinking doesn't work for tmp files in windows
   unless ($^O eq 'Win32') {
      my ($f1, $f2) = map File::Spec->catfile($root, "$_.txt"), qw(foo bar);
      unlink $f1 if -e $f1;
      unlink $f2 if -e $f2;
      rmdir $root if -e $root;
   }
}
