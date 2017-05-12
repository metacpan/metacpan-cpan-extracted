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
$|++;

my $TESTS = 60;
my ($testlib, $repos_uri);
eval {
    $testlib = TestLib->new();
    $repos_uri = $testlib->create_svn_repos();
};
plan skip_all => $@ if $@;
# Ok, setup done - we are good to go.
plan tests => $TESTS;

print "Starting real testing:\n";

throws_ok { Catalyst::Model::SVN->new() } qr/repository/, 'Throws with no config';
lives_ok {
    Catalyst::Model::SVN->config(
        repository => $repos_uri,
    );
} 'Setting repos config';

my $m;
lives_ok { $m = Catalyst::Model::SVN->new(); } 'Can construct';

{
    my $r = $m->revision;
    is($r, 5, 'Repository revision is 5 (5 commits)');
}

# Try a really simple ls in both scalar and list contexts..
my (@l, $l);
# Paths only.
lives_ok {$l = $m->ls('/', 5)} 'ls (scalar) path only with explicit revision, no exception';
lives_ok {@l = $m->ls()} 'ls (list + default args) path only , no exception';
my $l2 = \@l;
ok(scalar(@l) == 2, 'Have 2 top level items in ls path only');
is_deeply($l, $l2, 'Scalar and list context ls compare the same path only');

#URIs 
my $l3;
lives_ok {$l3 = $m->ls($repos_uri, 2)} 'ls (scalar) uri with explicit revision, no exception';
ok(scalar(@$l3) == 2, 'Have 2 top level items in ls uri');
is_deeply($l3, $l, 'Scalar and list context ls compare the same uri');

throws_ok {$m->ls('/bfgjghjfh', 2)} qr/File not found/, 'File which doesn not exist ls throws';
throws_ok {$m->ls($repos_uri . 'etgjhbhjjb', 2)} qr/File not found/, 'File which doesn not exist ls throws';

my $f = $l->[0];
# Tests for a single file f (from ls)
isa_ok($f, 'Catalyst::Model::SVN::Item', 'ls returns an array of Catalyst::Model::SVN::Item objects');
is($f->name, 'f1', 'Name of file as expected');
my $uri = $f->uri;
ok($f->uri, 'uri method returns something (' . $uri . ')');
ok($f->is_file, 'f is file');    
ok(!$f->is_directory, 'f is not directory');
{ 
    my ($c1, $c2) = ($f->contents, $f->contents);
    ok(length $c1, 'File has contents (1)');
    ok(length $c2, 'File has contents (2)');
    is($c1, $c2, 'Contents two times is the same');
    is($c1, "  File 1, rev 1\n  ", 'Contents as expected');
};

ok(!defined($f->author), 'Author is undef');
ok($f->size, 'Size has value');
ok($f->time, "Time has value");
isa_ok($f->time, 'DateTime', 'Is a DateTime object');
my $r = $f->revision();
ok($r, 'Revision has value');
ok($r =~ /^\d+$/, 'Revision number is decimal');
ok($r < 10, "Less than 10 revisions on item ($r)");
lives_ok {
    ok(length($f->log), 'item has log');
} 'log no exception';

lives_ok {
    is($f->propget('svn:mime-type'), 'text/plain', 'propget works (defined prop)');
    ok(!defined($f->propget('svn:foobar')), 'propget works (undefined prop)');
} 'propget no exception';

# Test path and uri methods (and that they all work the same on various URI formats)
is($f->path, '/f1', 'Path is /f1');
is($f->uri, 'svn://localhost/f1', ' URI is svn://localhost/f1');
foreach my $method (qw(path uri)) {
    no strict 'refs';
    my ($a1, $a2, $a3) = (grep { defined $_ && $_->$method } ($f, $l2->[0], $l3->[0]) );
    ok($a1, "$method works");
    is($a2, $a1, "$method on ls (list + path) is same as ls (scalar + path)");
    is($a3, $a2, "$method on ls (scalar + path) is same as ls (scalar + uri)")
}


# Try to get a file with cat, using both uri and local paths.
# URI
{
    my $f;
    lives_ok {$f = $m->cat($repos_uri . 'f1', 'HEAD')} 'cat top level file with whole URI';
    ok($f, 'cat method fetches f1 back (full uri)');
};

#Paths only.
{
    my $f;
    lives_ok {$f = $m->cat('/f1', 'HEAD')} 'cat top level file with just path';
    ok($f, 'cat method fetched f1 back (just path)'); 
    is($f, "  File 1, rev 1\n  ", 'Contents as expected');
};

# Try propget and propget_hr methods on a known path.
{
    my $p;
    lives_ok {$p = $m->properties_hr('/f1') } 'properties_hr on model direct lives';
    my $mime;
    lives_ok {$mime = $m->propget('/f1', 'svn:mime-type')} 'propget on model direct lives';
    is(ref($p), 'HASH', 'properties_hr returns hashref');
    is($mime, 'text/plain', 'mime type from propget as expected');
    my $expected = { 
        'svn:mime-type' => $mime,
        'svn:entry:committed-rev' => '3',
        'svn:entry:committed-date' => $p->{'svn:entry:committed-date'},
        'svn:entry:uuid' => $p->{'svn:entry:uuid'},
    }; 
    is_deeply($p, $expected, 'properties_hr returns expected hashref');
}

# Tests for the directory returned (/)
my $d = $l->[1]; # Get back /subdir (2nd item in list)
isa_ok($d, 'Catalyst::Model::SVN::Item', 'ls returns list of Catalyst::Model::SVN::Item objects');
is($d->name, 'subdir', 'Name of top level directory as expected');
#print STDERR "\n\n" . $d->is_file . "\n\n";
ok(!$d->is_file, 'd is not file');    
ok($d->is_directory, 'd is directory');
ok(!defined($d->contents()), 'Directory contents undef');

# test resolve_copy on moved file, older revision
lives_ok {
    ok($m->cat($repos_uri .'subdir/f2.moved', 3), 'resolve_copy in cat');
    my $olddir = $m->ls('subdir/', 3);
    my $oldfile = (grep { $_->name =~ /s3/ } @$olddir)[0];
    my $l = $oldfile->log;
    my $n = $oldfile->name;
    ok($l, 'resolve_copy in log');
} 'resolve_copy testing';

# FIXME - check coverage for resolve_copy testing.

# $testlib goes out of scope, and automatically cleans up.

