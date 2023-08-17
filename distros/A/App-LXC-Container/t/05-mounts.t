# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 05-mounts.t".
#
# Without "Build" file it could be called with "perl -I../lib 05-mounts.t"
# or "perl -Ilib t/05-mounts.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Test::More tests => 234;
use Test::Output;

use App::LXC::Container::Mounts;

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

#########################################################################
# just 1 failing test:

eval {   App::LXC::Container::Mounts::new('wrong-call');   };
like($@,
     qr{^bad call to App::LXC::Container::Mounts->new$re_msg_tail},
     'bad call of App::LXC::Container::Mounts->new fails');

#########################################################################
# building tree and testing it:
my $obj = App::LXC::Container::Mounts->new();
is(ref($obj), 'App::LXC::Container::Mounts',
   'App::LXC::Container::Mounts object has been created correctly');
is($obj->mount_point('/'), NO_MERGE, 'got correct state for entry of /');

is($obj->mount_point('/usr/lib', NO_MERGE), NO_MERGE,
   'correct state could be set for /usr/lib');
is($obj->mount_point('/usr/lib'), NO_MERGE,
   'got correct state for entry of /usr/lib');
is($obj->mount_point('/usr'), NO_MERGE, 'got correct state for entry of /usr');

is($obj->mount_point('/tmp', EXPLICIT), EXPLICIT,
   'correct state could be set for /tmp');
is($obj->mount_point('/tmp'), EXPLICIT, 'got correct state for entry of /tmp');
is($obj->mount_point('/tmp/sub'), EXPLICIT,
   'got correct state for entry of /tmp/sub');

is($obj->mount_point('/var/log', EMPTY), EMPTY,
   'correct state could be set for /var/log');
is($obj->mount_point('/var/log'), EMPTY,
   'got correct state for entry of /var/log');
is($obj->mount_point('/var'), NO_MERGE, 'got correct state for entry of /var');

is($obj->mount_point('/var/spool', UNDEFINED), UNDEFINED,
   'correct state could be set for /var/log');
is($obj->mount_point('/var/spool'), UNDEFINED,
   'got correct state for entry of /var/log');

is($obj->mount_point('/var/cache', IGNORE), IGNORE,
   'correct state could be set for /var/cache');
is($obj->mount_point('/var/cache'), IGNORE,
   'got correct state for entry of /var/cache');

is($obj->mount_point('/usr/bin/chromium', IMPLICIT), IMPLICIT,
   'correct state could be set for /usr/bin/chromium');
is($obj->mount_point('/usr/bin/chromium'), IMPLICIT,
   'got correct state for entry of /usr/bin/chromium');
is($obj->mount_point('/usr/bin'), UNDEFINED,
   'got correct state for entry of /usr/bin');
is($obj->mount_point('/usr'), NO_MERGE, 'got correct state for entry of /usr');

is($obj->mount_point('/usr/bin/chromium', IMPLICIT), IMPLICIT,
   'setting state again returned correct value for /usr/bin/chromium');

is($obj->mount_point('/usr/lib/sub-directory/symbolic-link', IMPLICIT_LINK),
   IMPLICIT_LINK,
   'correct state could be set for /usr/lib/sub-directory/symbolic-link');
is($obj->mount_point('/usr/lib/sub-directory/symbolic-link'), IMPLICIT_LINK,
   'got correct state for /usr/lib/sub-directory/symbolic-link');
is($obj->mount_point('/usr/lib/sub-directory'), UNDEFINED,
   'got correct state for /usr/lib/sub-directory');
is($obj->mount_point('/usr/lib'), NO_MERGE,
   'still got correct state for entry of /usr/lib');

my @sizes =
    (8, 16, 22, 24, 32, 36, 42, 64, 72, 96, 128, 192, 256, 480, 512, 1024);
my @sub_dirs = ();
foreach (@sizes)
{
    $_ = '/usr/share/icons/hicolor/' . $_ . 'x' . $_;
    push @sub_dirs, $_;
    $_ = $_ . '/apps/some-icon.png';
    is($obj->mount_point($_, IMPLICIT), IMPLICIT,
       'correct state could be set for ' . $_);
}
is($obj->mount_point('/usr/share/icons/hicolor/8x8/apps/some-icon.png'),
   IMPLICIT,
   'got correct state for entry of /usr/share/icons/hicolor/.../some-icon.png');
is($obj->mount_point('/usr/share/icons/hicolor/8x8/apps'), UNDEFINED,
   'got correct state for entry of /usr/share/icons/hicolor/8x8/apps');
is($obj->mount_point('/usr/share/icons/hicolor/8x8'), UNDEFINED,
   'got correct state for entry of /usr/share/icons/hicolor/8x8');
is($obj->mount_point('/usr/share/icons/hicolor'), UNDEFINED,
   'got correct state for entry of /usr/share/icons/hicolor');
is($obj->mount_point('/usr/share/icons'), UNDEFINED,
   'got correct state for entry of /usr/share/icons');
is($obj->mount_point('/usr/share'), UNDEFINED,
   'got correct state for entry of /usr/share');
@sub_dirs = sort @sub_dirs;
is_deeply([$obj->sub_directories('/usr/share/icons/hicolor')], \@sub_dirs,
	  'got correct sub-directories for /usr/share/icons/hicolor');

is_deeply([$obj->sub_directories('/usr/share/icons/hicolor/16x16/apps')],
	  ['/usr/share/icons/hicolor/16x16/apps/some-icon.png'],
	  'child found for /usr/share/icons/hicolor/16x16/apps');
is($obj->mount_point('/usr/share/icons/hicolor/16x16/apps', IMPLICIT), IMPLICIT,
   'correct state could be set for /usr/share/icons/hicolor/16x16/apps');
is_deeply([$obj->sub_directories('/usr/share/icons/hicolor/16x16/apps')], [],
	  'I* state of parent correctly removed child for .../16x16/apps');
is($obj->mount_point('/usr/share/icons/hicolor/16x16/apps'), IMPLICIT,
   'got correct state for entry of /usr/share/icons/hicolor/16x16/apps');
is($obj->mount_point('/usr/share/icons/hicolor/16x16'), UNDEFINED,
   'got correct state for entry of /usr/share/icons/hicolor/16x16');
is($obj->mount_point('/usr/share/icons/hicolor'), UNDEFINED,
   'got correct state for entry of /usr/share/icons/hicolor');

is($obj->mount_point('/usr/share/doc', EXPLICIT), EXPLICIT,
   'correct state could be set for /usr/share/doc');
is($obj->mount_point('/usr/share/doc'), EXPLICIT,
   'got correct state for /usr/share/doc');
is($obj->mount_point('/usr/share'), NO_MERGE,
   'got correct new state for /usr/share');

is($obj->mount_point('/usr/share/info/libc.info-1.gz', IMPLICIT), IMPLICIT,
   'correct state could be set for /usr/share/info/libc.info-1.gz');
is($obj->mount_point('/usr/share/info/libc.info-2.gz', IMPLICIT), IMPLICIT,
   'correct state could be set for /usr/share/info/libc.info-2.gz');
is($obj->mount_point('/usr/share/info/libc.info-1.gz'), IMPLICIT,
   'got correct state for entry of /usr/share/info/libc.info-1.gz');
is($obj->mount_point('/usr/share/info/libc.info-2.gz'), IMPLICIT,
   'got correct state for entry of /usr/share/info/libc.info-2.gz');

is($obj->mount_point('/usr/share/not-set'), UNDEFINED,
   'got correct state for /usr/share/not-set');

#########################################################################
# testing a standard merge:
$obj->merge_mount_points(100, 30, 4, 3);
is_deeply([$obj->sub_directories('/usr/share/icons/hicolor')], [],
	  'merge worked for /usr/share/icons/hicolor');

is($obj->mount_point('/usr/share/icons/hicolor/8x8/apps/some-icon.png'),
   IMPLICIT,
   'got correct state for entry of /usr/share/icons/hicolor/.../some-icon.png');
is($obj->mount_point('/usr/share/icons/hicolor/8x8/apps'), IMPLICIT,
   'got correct new state for entry of /usr/share/icons/hicolor/8x8/apps');
is($obj->mount_point('/usr/share/icons/hicolor/8x8'), IMPLICIT,
   'got correct new state for entry of /usr/share/icons/hicolor/8x8');
is($obj->mount_point('/usr/share/icons/hicolor'), IMPLICIT,
   'got correct new state for entry of /usr/share/icons/hicolor');
is($obj->mount_point('/usr/share/icons'), UNDEFINED,
   'got correct state for entry of /usr/share/icons');
is($obj->mount_point('/usr/share'), NO_MERGE,
   'got correct state for entry of /usr/share');
is($obj->mount_point('/usr'), NO_MERGE, 'got correct state for entry of /usr');

is($obj->mount_point('/usr/share/info/libc.info-1.gz'), IMPLICIT,
   'still got correct state for entry of /usr/share/info/libc.info-1.gz');
is($obj->mount_point('/usr/share/info/libc.info-2.gz'), IMPLICIT,
   'still got correct state for entry of /usr/share/info/libc.info-2.gz');

#########################################################################
# testing an aggressive merges:
@sub_dirs = (qw(/usr/share/doc /usr/share/icons /usr/share/info));
foreach (1..9)
{
    $_ = '/usr/share/sub' . $_;
    push @sub_dirs, $_;
    is($obj->mount_point($_, IMPLICIT), IMPLICIT,
       'correct state could be set for ' . $_);
}
$obj->merge_mount_points(2,2,2,2);
is_deeply([$obj->sub_directories('/usr/share')], \@sub_dirs,
	  'merge ignored for /usr/share');

is($obj->mount_point('/usr/share/icons/hicolor'), IMPLICIT,
   'got correct new state for entry of /usr/share/icons/hicolor');
is($obj->mount_point('/usr/share/icons'), UNDEFINED,
   'got correct state for entry of /usr/share/icons');
is($obj->mount_point('/usr/share'), NO_MERGE,
   'got correct state for entry of /usr/share');
is($obj->mount_point('/usr'), NO_MERGE, 'got correct state for entry of /usr');

is($obj->mount_point('/usr/share', COPY), COPY,
   'correct new state could be set for /usr/share');
$obj->merge_mount_points(2);
is_deeply([$obj->sub_directories('/usr/share')], \@sub_dirs,
	  'merge still ignored for /usr/share');
is($obj->mount_point('/usr/share/icons/hicolor'), IMPLICIT,
   'got correct state for entry of /usr/share/icons/hicolor');
is($obj->mount_point('/usr/share/icons'), UNDEFINED,
   'got correct state for entry of /usr/share/icons');
is($obj->mount_point('/usr/share'), COPY,
   'got correct new state for entry of /usr/share');
is($obj->mount_point('/usr'), NO_MERGE, 'got correct state for entry of /usr');

#########################################################################
# testing invalid modifications:

output_like
{   $_ = $obj->mount_point('/var/log', IMPLICIT);   }
    qr{^$}s,
     qr{^/var/log already has incompatible state .* /var/log$re_msg_tail},
    'bad call for /var/log fails';
is($_, EMPTY, 'bad call for /var/log returned correct old state');
is($obj->mount_point('/var/log'), EMPTY,
   'got correct state for entry of /var/log');

output_like
{   $_ = $obj->mount_point('/var/log/cups', EXPLICIT);   }
    qr{^$}s,
     qr{^/var/log already has incompatible state .* /var/log/cups$re_msg_tail},
    'bad call for /var/log/cups fails';
is($_, IGNORE, 'bad call for /var/log/cups returned correct state');

is($obj->mount_point('/var/log/cups'), EMPTY,
   'got correct state for entry of /var/log/cups');
is($obj->mount_point('/var/log'), EMPTY,
   'got correct modified state for entry of /var/log');

#########################################################################
# testing merges in artificial tree:
my $obj2 = App::LXC::Container::Mounts->new();

sub build_tree($$);
sub build_tree($$)
{
    my ($down, $root) = @_;
    if ($down-- > 0)
    {
	is($obj2->mount_point($root . '/sub1', UNDEFINED), UNDEFINED,
	   'correct state could be set for ' . $root . '/sub1');
	is($obj2->mount_point($root . '/sub2', UNDEFINED), UNDEFINED,
	   'correct state could be set for ' . $root . '/sub2');
	build_tree($down, $root . '/sub1');
	build_tree($down, $root . '/sub2');
    }
    else
    {
	is($obj2->mount_point($root . '/sub1', IMPLICIT), IMPLICIT,
	   'correct state could be set for ' . $root . '/sub1');
	is($obj2->mount_point($root . '/sub2', IMPLICIT), IMPLICIT,
	   'correct state could be set for ' . $root . '/sub2');
    }
}
build_tree(5, '');
is(scalar(keys %{$obj2}), 127, 'artificial tree has correct size of 127');

$obj2->merge_mount_points(2,2,2,2);

is($obj2->mount_point('/'), NO_MERGE,
   'got correct state for entry of /');
is($obj2->mount_point('/sub1'), UNDEFINED,
   'got correct state for entry of /sub1');
is($obj2->mount_point('/sub2'), UNDEFINED,
   'got correct state for entry of /sub2');
is($obj2->mount_point('/sub1/sub1'), IMPLICIT,
   'got correct state for entry of /sub1/sub1');
is($obj2->mount_point('/sub1/sub2'), IMPLICIT,
   'got correct state for entry of /sub1/sub2');
is($obj2->mount_point('/sub2/sub1'), IMPLICIT,
   'got correct state for entry of /sub2/sub1');
is($obj2->mount_point('/sub2/sub2'), IMPLICIT,
   'got correct state for entry of /sub2/sub2');

is(scalar(keys %{$obj2}), 7, 'artificial tree has been correctly reduced to 7');
