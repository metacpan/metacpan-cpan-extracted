# Test by creating a small local svn repos, committing some stuff into it...
use strict;
use warnings;
use Test::More;
use FindBin qw( $Bin );
use lib ("$Bin/lib", "$Bin/../lib");
use TestLib;
use Catalyst::Model::SVN;
use Test::More;
use Test::Exception; 

my $TESTS = 10;
my ($testlib, $repos_uri);
eval {
    $testlib = TestLib->new();
    $repos_uri = $testlib->create_svn_repos();
};
plan skip_all => $@ if $@;
# Ok, setup done - we are good to go.
plan tests => $TESTS;

print "Starting real testing:\n";

# This is the key bit for this test
$repos_uri .= 'subdir/';

lives_ok {
    Catalyst::Model::SVN->config(
        repository => $repos_uri,
    );
} 'Setting repos config';

my $m;
lives_ok { $m = Catalyst::Model::SVN->new(); } 'Can construct';

my (@l, @l2);
lives_ok {@l = $m->ls('/')} 'ls /, no exception';
lives_ok {@l2 = $m->ls($repos_uri)} 'ls repos uri, no excpetion';
ok(scalar(@l), '@l has contents');
is_deeply(\@l, \@l2, 'Lists compare the same');

my ($f1, $f2);
lives_ok {$f1 = $m->cat('/f2.moved')} '$f1 = cat /f2.moved, no exception';
lives_ok {$f2 = $m->cat($repos_uri . 'f2.moved')} '$f2 = cat ' . $repos_uri . 'f2.moved, no excpetion';
ok(length $f1, '$f1 has length');
is($f1, $f2, '$f1 and $f2 the same');

# $testlib goes out of scope, and automatically cleans up.
