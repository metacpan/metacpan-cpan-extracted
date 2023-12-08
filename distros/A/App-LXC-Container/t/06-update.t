# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 05-update.t".
#
# Without "Build" file it could be called with "perl -I../lib 05-update.t"
# or "perl -Ilib t/05-update.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd;

use Test::More tests => 193;
use Test::Output;

#####################################
# prepare fixed environment:
use constant T_PATH => map { s|/[^/]+$||; $_ } Cwd::abs_path($0);
use constant TMP_PATH => T_PATH . '/tmp';

do(T_PATH . '/functions/call_with_stdin.pl');
do(T_PATH . '/functions/sub_perl.pl');
do(T_PATH . '/functions/files_directories.pl');

use constant HOME_PATH => TMP_PATH . '/home';
_setup_dir('/home');
use constant LXC_LINK => HOME_PATH . '/.lxc-configuration';
use constant BAD_CONF => HOME_PATH . '/not-existing';
use constant CONF_ROOT => TMP_PATH . '/lxc';
use constant CONF_PATH => LXC_LINK . '/conf';
use constant LOCAL_ROOT_FS => '/home/.lxc-configuration/.root_fs';

BEGIN {
    delete $ENV{DISPLAY};
    $ENV{UI} = 'PoorTerm';	# PoorTerm allows easy testing
    # no testing outside of t:
    $ENV{HOME} = HOME_PATH;
    $ENV{LXC_DEFAULT_CONF_DIR} = TMP_PATH;
}

-f TMP_PATH . '/lxc/conf/10-NET-default.conf'  and
    -f TMP_PATH . '/usr/bin/2something'  or
    die "$0 can only run after a successful invocation of t/02-init.t and "
    .   "t/03-setup.t\n";

use App::LXC::Container;

# directory of mockup commands:
$ENV{PATH} = T_PATH . '/mockup:' . $ENV{PATH};

use App::LXC::Container::Data;
use App::LXC::Container::Data::Debian;

$App::LXC::Container::Data::Debian::_dpkg_status =
    T_PATH . '/mockup-files/dpkg.status';
$App::LXC::Container::Data::_os_release =
    T_PATH . '/mockup-files/os-release-debian';

#########################################################################
# local helper functions:
sub fail_in_sub_perl($$)
{
    if ($_[0] == 1)
    {
	return _sub_perl('
		use App::LXC::Container;
		App::LXC::Container::update("' . $_[1] . '");');
    }
    elsif ($_[0] == 2)
    {
	return _sub_perl('
		use App::LXC::Container;
		$_ = App::LXC::Container::Update->new("' . $_[1] . '");
		$_->network_number();');
    }
}

my $update_object;
sub obj_keys_in_range($$$$)
{
    my ($key, $from, $to, $text) = @_;
    local $_ = scalar(keys(%{$update_object->{$key}}));
    ok($from <= $_  &&  $_  <= $to,
       $text . "\t(" . $from . ' <= ' . $_ . ' <= ' . $to . ')');
}

sub patch_config($@)
{
    my $file = shift;
    my $fh;
    open $fh, '<', $file  or  die "can't open ", $file, ': ', $!;
    my @content = <$fh>;
    close $fh;
    local $_;
    while (@_)
    {
	if ($_[0] eq 'd')
	{   delete $content[$_[1]];   }
	else
	{   die 'bad patch: ', join(',', @_);   }
	shift @_;
	shift @_;
    }
    open $fh, '>', $file  or  die "can't open ", $file, ': ', $!;
    print $fh @content;
    close $fh;
}

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/m;
my $re_eval = qr{ at \(eval \d+\)(\[t/\d+-[a-z]+\.t:\d+\])? line 1\.$}m;

#########################################################################
# failing tests:

_remove_link(LXC_LINK);
$_ = fail_in_sub_perl(1, 'no-network');
like($_,
     qr{\$HOME/.lxc-configuration link is missing at -e line \d\.$}m,
     'missing configuration link should fail');
_setup_dir('/home/.lxc-configuration');
$_ = fail_in_sub_perl(1, 'no-network');
like($_,
     qr{t/tmp/home/.lxc-configuration is not a symbolic link at -e line \d\.$}m,
     'bad configuration link should fail');
_remove_dir(LXC_LINK);

_setup_link(LXC_LINK, HOME_PATH);
my $re = "^can't open '" . LXC_LINK . '/.networks.lst' . "'"
    . ': .* at -e line 3\.' . "\n\\Z";
$_ = fail_in_sub_perl(1, 'no-network');
like($_, qr{$re}m, 'missing network configuration should fail');

_remove_file(LOCAL_ROOT_FS);
_setup_file('/home/.networks.lst', 'x');
$_ = fail_in_sub_perl(1, 'no-network');
$re = "^ignoring unknown configuration item in '" . LXC_LINK . '/\.networks.lst'
    . "'" . ', line 1 at -e line 3\.$';
like($_, qr{$re}m, 'bad network configuration should print error');
$re = "^can't open '" . LXC_LINK . '/.root_fs' . "'"
    . ': .* at -e line 3\.' . "\n\\Z";
like($_, qr{$re}m, 'missing configuration of root file-system should fail');

_setup_file(LOCAL_ROOT_FS, 'x');
$_ = fail_in_sub_perl(1, 'no-network');
$re = "^ignoring unknown configuration item in '" . LXC_LINK . '/\.root_fs'
    . "'" . ', line 1 at -e line 3\.$';
like($_, qr{$re}m, 'bad configuration of root file-system should print error');
_remove_file('/home/.networks.lst');

_remove_link(LXC_LINK);
_setup_link(LXC_LINK, CONF_ROOT);

eval {   App::LXC::Container::Update::new('wrong-call', 'dummy');   };
like($@,
     qr{^bad call to App::LXC::Container::Update->new.*$re_msg_tail},
     'bad call of App::LXC::Container::Update->new fails');

eval {   App::LXC::Container::update('bad-name!');   };
like($@,
     qr/^The name of the container may only contain word char.*!$re_msg_tail/,
     'bad container name fails');

_chmod(0444, '/lxc/.networks.lst');
$_ = fail_in_sub_perl(2, 'good-name');
$re = "^can't open '" . LXC_LINK . '/\.networks\.lst' . "'"
    . ': .* at -e line 4\.' . '$';
like($_, qr{$re}m,
     'new network number fails for protected global network file');
_chmod(0644, '/lxc/.networks.lst');

$_ = App::LXC::Container::Update->new('bad-paths');
$_->{root_fs} = BAD_CONF;
eval {   $_->_make_lxc_path('unused_dummy');   };
like($@,
     qr{^can't create '/.[^']+/bad-paths': .*$re_msg_tail},
    'inaccessible LXC root directory fails');

$_->{root_fs} = CONF_ROOT;
eval {   $_->_make_lxc_path('/non-existing');   };
like($@,
     qr{^/non-existing doesn't exist!$re_msg_tail},
    'non-existing real directory fails');

_setup_dir('/lxc/bad-paths/var');
_chmod(0444, '/lxc/bad-paths/var');
eval {   $_->_make_lxc_path('/var/tmp');   };
like($@,
     qr{^can't create '/.[^']+/bad-paths/var/tmp': .*$re_msg_tail},
    'protected LXC sub-directory fails for directory');

_setup_dir('/lxc/bad-paths/etc');
_chmod(0444, '/lxc/bad-paths/etc');
eval {   $_->_make_lxc_path('/etc/profile');   };
like($@,
     qr{^can't create '/.[^']+/bad-paths/etc/profile': .*$re_msg_tail},
    'protected LXC sub-directory fails for file');

_remove_file('/lxc/bad-paths.conf');
_chmod(0555, '/lxc');
eval {   $_->_write_lxc_configuration();   };
like($@,
     qr{^can't open '/.[^']+/.lxc-configuration/bad-paths.conf': .*$re_msg_tail},
    'writing LXC configuration file into protected directory fails');
_chmod(0755, '/lxc');

$_->{network} = 1;
foreach my $conf (qw(10-NET-default.conf 20-DEV-default.conf))
{
    _chmod(   0, '/lxc/conf/' . $conf);
    eval {   $_->_write_lxc_configuration();   };
    like($@,
	 qr{^can't open '/.[^']+/.lxc-configuration/conf/$conf': .*$re_msg_tail},
	 'writing LXC configuration file fails without access to ' . $conf);
    _chmod(0644, '/lxc/conf/' . $conf);
}

eval {   App::LXC::Container::update('no-network', 'other');   };
like($@,
     qr/^special container no-network may not be mixed with others$re_msg_tail/,
     'no-network with additional name fails');

_remove_file(LOCAL_ROOT_FS);
_setup_file(LOCAL_ROOT_FS, CONF_ROOT);		# create tree below t/tmp/lxc

my $os = App::LXC::Container::Data::_singleton()->{OS};
SKIP:{
    if (-l '/lib')
    {
	my $bad = App::LXC::Container::Update->new('bad-paths');
	_setup_dir('/lxc/bad-paths/usr');
	_chmod(0444, '/lxc/bad-paths/usr');
	output_like
	{   $bad->_make_lxc_path('/lib');   }
	qr{^$},
	qr{^can't create '/.[^']+/bad-paths/usr/lib': .*$re_msg_tail},
	'protected LXC sub-directory fails for linked directory';
	_remove_dir(TMP_PATH . '/lxc/bad-paths/usr');
    }
    else
    {	skip "/lib not symbolic link on $os", 1;   }
}

#########################################################################
# preparation for different distributions:
-f '/etc/debian_version'
    or  patch_config(CONF_PATH . '/40-MNT-default.mounts', 'd' => -1);

#########################################################################
# tests breaking internals:

# some of the next tests need a restricted "others" access to the path:
_chmod(0750, '/');

_setup_file('/lxc/conf/un-CNF-update-test-broken.master');
_setup_file('/lxc/conf/un-NOT-update-test-broken.filter');
_setup_file('/lxc/conf/un-MNT-update-test-broken.mounts');
_setup_file('/lxc/conf/un-PKG-update-test-broken.packages');
_setup_file('/lxc/conf/un-SPC-update-test-broken.special');
_chmod(0,   '/lxc/conf/un-SPC-update-test-broken.special');
my $broken = App::LXC::Container::Update->new('update-test-broken');
$broken->_parse_master();
$broken->_parse_packages();
$broken->{packages} = [ grep { ! m{^dash$} } @{$broken->{packages}}];
$broken->_parse_mounts();
$broken->_parse_filter();
$broken->{filter}{'/var/log'} = 'copy';
stderr_like
{   eval '$broken->_write_lxc_configuration();';   }
    qr{\A(?:.*may be inaccessible for LXC container's root account$re_eval\n)*\Z},
    'invalid copy directory filter causes correct error message';
like($@,
     qr{^INTERNAL ERROR .+: /var/log is directory in COPY$re_eval},
     'invalid copy directory filter fails');
$broken->{filter}{'/var/opt'} = 'invalid_value';
eval {   $broken->_write_lxc_configuration();   };
like($@,
     qr{^INTERNAL ERROR .+: bad filter value: invalid_value.*$re_msg_tail},
    'invalid internal value for filter fails');
eval {   $broken->_parse_specials();   };
like($@,
     qr{^can't open '/.[^']+/un-SPC-update-test-broken.special': .*$re_msg_tail},
    'inaccessible special configuration fails');

#########################################################################
# basic tests for minimal container:
$_ = App::LXC::Container::Update->new('no-network');
is(ref($_), 'App::LXC::Container::Update',
   'App::LXC::Container::Update->new returned correct object');
is($_->{networks}{'local-network'}, 2,
   'local-network container has network ID 2');
is($_->{networks}{network}, 3, 'network container has network ID 3');
ok($_->{next_network} > 3, 'next network > 3');
is(@{$_->{containers}}, 1, 'test used 1 container configuration');
is($_->{containers}[0], 'no-network', 'test used "no-network" configuration');
$_->{name} = 'network';
$_ = $_->network_number();
is($_, 3, 'network number of "network" configuration is correct');

#########################################################################
# test for bad configuration files:
_setup_file('/lxc/conf/ud-CNF-update-test-bad.master', 'invalid entry');
_setup_file('/lxc/conf/ud-NOT-update-test-bad.filter',
	    'invalid entry', '/home/some.file copy');
_setup_file('/lxc/conf/ud-MNT-update-test-bad.mounts', 'invalid entry');
_setup_file('/lxc/conf/ud-PKG-update-test-bad.packages', 'invalid entry');
_setup_dir('/lxc/update-test-bad');
_setup_file('/lxc/update-test-bad/dummy', 'dummy');

my $re_err1 =
    "^ignoring unknown configuration item in '" . CONF_PATH . '/ud-' .
    '(CNF|MNT|NOT|PKG)-update-test-bad\.(filter|master|mounts|packages)' .
    "', line 1" . $re_msg_tail . "\n";
my $re_err2 = "/.*/usr/bin/missing doesn't exist!" . $re_msg_tail . "\n";
my $re_err3 =
    "(/.* may be inaccessible for LXC container's root account" .
    $re_msg_tail . "\n){0,2}";
my $re_err4 = "/.*/lib/somelink doesn't exist!" . $re_msg_tail . "\n";
my $re_err5 = "cp:.*\ncan't copy '/home/some.file': 256" . $re_msg_tail . "\n";
my $re_err_o1 = "(.*/lib/ld-linux.so.2 doesn't exist!" . $re_msg_tail . "\n)?";
$ENV{ALC_DEBUG} = 0;		# cover branch in App::LXC::Container::update
output_like
{   App::LXC::Container::update('update-test-bad');   }
    qr{^$},
    qr{\A($re_err1){4}($re_err2)?($re_err3$re_err5|$re_err5$re_err3)}m,
    'reading bad configuration files update-test-bad print errors';

_setup_file('/lxc/update-test-bad/home/some.file');
_chmod(0555, '/lxc/update-test-bad/home', '/lxc/update-test-bad', '/lxc');
my $re_err6 =
    "can't remove '/.*/tmp/lxc/update-test-bad': .*" . $re_msg_tail . "\n";
$ENV{ALC_DEBUG} = 'x';
output_like
{   App::LXC::Container::update('update-test-bad');   }
    qr{^$},
    qr{\A($re_err1){4}($re_err2)?$re_err6$re_err3\Z}m,
    'protected LXC directory prints error';
_chmod(0755, '/lxc', '/lxc/update-test-bad', '/lxc/update-test-bad/home');
delete $ENV{ALC_DEBUG};

_remove_file('/lxc/conf/ud-NOT-update-test-bad.filter');
$re = "^can't open '" . CONF_PATH . '/ud-NOT-update-test-bad.filter' . "'"
    . ': .* at -e line 3\.' . "\n\\Z";
$_ = fail_in_sub_perl(1, 'update-test-bad');
like($_, qr{$re}m, 'missing filter configuration fails');

_remove_file('/lxc/conf/ud-MNT-update-test-bad.mounts');
$re = "^can't open '" . CONF_PATH . '/ud-MNT-update-test-bad.mounts' . "'"
    . ': .* at -e line 3\.' . "\n\\Z";
$_ = fail_in_sub_perl(1, 'update-test-bad');
like($_, qr{$re}m, 'missing mounts configuration fails');

_remove_file('/lxc/conf/ud-PKG-update-test-bad.packages');
$re = "^can't open '" . CONF_PATH . '/ud-PKG-update-test-bad.packages' . "'"
    . ': .* at -e line 3\.' . "\n\\Z";
$_ = fail_in_sub_perl(1, 'update-test-bad');
like($_, qr{$re}m, 'missing packages configuration fails');

_remove_file('/lxc/conf/ud-CNF-update-test-bad.master');
$re = "^can't open '" . CONF_PATH . '/ud-CNF-update-test-bad.master' . "'"
    . ': .* at -e line 3\.' . "\n\\Z";
$_ = fail_in_sub_perl(1, 'update-test-bad');
like($_, qr{$re}m, 'missing master configuration fails');

#########################################################################
# test for master files:
_setup_file('/lxc/conf/u0-CNF-update-test-0.master',
	    '# minimal', 'network=0', 'x11=0', 'audio=0', 'users=');
_setup_file('/lxc/conf/u1-CNF-update-test-1.master',
	    'network=1', 'x11=0', 'audio=1', 'users=1001:u1,1002:u2');
_setup_file('/lxc/conf/u2-CNF-update-test-2.master',
	    'network=2', 'x11=1', 'audio=0', 'users=1002:u2,1003:u3');
_setup_file('/lxc/conf/u3-CNF-update-test-3.master',
	    'network=0', 'x11=1', 'audio=1', 'users=1003:u3,1004:u4');
_setup_file('/lxc/conf/u4-CNF-update-test-4.master',
	    '# minimal', 'network=0', 'x11=0', 'audio=0', 'users=0:root');

$_ = App::LXC::Container::Update->new('update-test-0');
$_->_parse_master();
is($_->{audio}, 0, 'master test 1 audio is correct');
is($_->{network}, 0, 'master test 1 network is correct');
is_deeply([sort keys %{$_->{users}}], [], 'master test 1 users are correct');
is_deeply($_->{users_from}, [], 'master test 1 users have correct origin');
is($_->{x11}, 0, 'master test 1 X11 is correct');

$_ = App::LXC::Container::Update->new('update-test-1');
$_->_parse_master();
is($_->{audio}, 1, 'master test 2 audio is correct');
is($_->{network}, 1, 'master test 2 network is correct');
is($_->{network_from}, 'update-test-1',
   'master test 2 network has correct origin');
is_deeply([sort keys %{$_->{users}}], [1001, 1002],
	  'master test 2 user ids are correct');
is_deeply([sort values %{$_->{users}}], ['u1', 'u2'],
	  'master test 2 users are correct');
is_deeply($_->{users_from}, ['update-test-1'],
	  'master test 2 users have correct origin');
is($_->{x11}, 0, 'master test 2 X11 is correct');

$_ = App::LXC::Container::Update->new('update-test-2');
$_->_parse_master();
is($_->{audio}, 0, 'master test 3 audio is correct');
is($_->{network}, 2, 'master test 3 network is correct');
is($_->{network_from}, 'update-test-2',
   'master test 3 network has correct origin');
is_deeply([sort keys %{$_->{users}}], [1002, 1003],
	  'master test 3 user ids are correct');
is_deeply([sort values %{$_->{users}}], ['u2', 'u3'],
	  'master test 3 users are correct');
is_deeply($_->{users_from}, ['update-test-2'],
	  'master test 3 users have correct origin');
is($_->{x11}, 1, 'master test 3 X11 is correct');

$_ = App::LXC::Container::Update->new('update-test-1', 'update-test-0');
$_->_parse_master();
is($_->{audio}, 1, 'master test 4 audio is correct');
is($_->{network}, 1, 'master test 4 network is correct');
is($_->{network_from}, 'update-test-1',
   'master test 4 network has correct origin');
is_deeply([sort keys %{$_->{users}}], [1001, 1002],
	  'master test 4 user ids are correct');
is_deeply([sort values %{$_->{users}}], ['u1', 'u2'],
	  'master test 4 users are correct');
is_deeply($_->{users_from}, ['update-test-1'],
	  'master test 4 users have correct origin');
is($_->{x11}, 0, 'master test 4 X11 is correct');

$_ = App::LXC::Container::Update->new('update-test-1', 'update-test-2');
$_->_parse_master();
is($_->{audio}, 1, 'master test 5 audio is correct');
is($_->{network}, 2, 'master test 5 network is correct');
is($_->{network_from}, 'update-test-2',
   'master test 5 network has correct origin');
is_deeply([sort keys %{$_->{users}}], [1001, 1002, 1003],
	  'master test 5 user ids are correct');
is_deeply([sort values %{$_->{users}}], ['u1', 'u2', 'u3'],
	  'master test 5 users are correct');
is_deeply($_->{users_from}, ['update-test-1', 'update-test-2'],
	  'master test 5 users have correct origin');
is($_->{x11}, 1, 'master test 5 X11 is correct');

$_ = App::LXC::Container::Update->new('update-test-1', 'update-test-2');
$_->_parse_master();
is($_->{audio}, 1, 'master test 6 audio is correct');
is($_->{network}, 2, 'master test 6 network is correct');
is($_->{network_from}, 'update-test-2',
   'master test 6 network has correct origin');
is_deeply([sort keys %{$_->{users}}], [1001, 1002, 1003],
	  'master test 6 user ids are correct');
is_deeply([sort values %{$_->{users}}], ['u1', 'u2', 'u3'],
	  'master test 6 users are correct');
is_deeply($_->{users_from}, ['update-test-1', 'update-test-2'],
	  'master test 6 users have correct origin');
is($_->{x11}, 1, 'master test 6 X11 is correct');

$_ = App::LXC::Container::Update->new('update-test-3');
output_like
{   $_->_parse_master();   }
    qr{^$},
    qr{^audio will not work without local or global network$re_msg_tail\Z},
    'audio without network prints warning';
is($_->{audio}, 1, 'master test 7 audio is correct');
is($_->{network}, 0, 'master test 7 network is correct');
is($_->{network_from}, '???',
   'master test 7 network has correct origin');
is_deeply([sort keys %{$_->{users}}], [1003, 1004],
	  'master test 7 user ids are correct');
is_deeply([sort values %{$_->{users}}], ['u3', 'u4'],
	  'master test 7 users are correct');
is_deeply($_->{users_from}, ['update-test-3'],
	  'master test 7 users have correct origin');
is($_->{x11}, 1, 'master test 7 X11 is correct');

$_ = App::LXC::Container::Update->new('update-test-4');
$_->_parse_master();
is($_->{audio}, 0, 'master test 8 audio is correct');
is($_->{network}, 0, 'master test 8 network is correct');
is_deeply([sort keys %{$_->{users}}], [0],
	  'master test 8 users are correct');
is_deeply([sort values %{$_->{users}}], ['root'],
	  'master test 8 users are correct');
is_deeply($_->{users_from}, ['update-test-4'],
	  'master test 8 users have correct origin');
is($_->{x11}, 0, 'master test 8 X11 is correct');
$_->_parse_users();
like($_->{mount_entry}{'/root'}, qr{^/root\s+root\s+none create=dir,rw,bind$},
     'user test 8 created correct mount entry');
is($_->{mount_source}{'/root'}, 'container users',
   'user test 8 created correct mount source');
is($_->{mounts_of_source}{'container users'}[0], '/root',
   'user test 8 created correct mount source list');

#########################################################################
# test for packages files:
_setup_file('/lxc/conf/u1-PKG-update-test-1.packages',
	    '# 2 identical', '', 'chromium', 'chromium');
_setup_file('/lxc/conf/u2-PKG-update-test-2.packages',
	    '# 2 different', '', 'chromium', 'evince');

$_ = App::LXC::Container::Update->new('update-test-1');
$_->_parse_packages();
is_deeply($_->{package_sources},
	  ['30-PKG-default.packages', 'u1-PKG-update-test-1.packages'],
	  'packages test 1 has correct source list');
# some Smokers don't have a dash, so it's not part of the default package list:
if (5 == @{$_->{packages}})
{
    is_deeply($_->{packages},
	      [qw(coreutils dash libc-bin util-linux chromium)],
	      'packages test 1 has correct content');
}
else
{
    diag(join(' ', 'PACKAGES:', @{$_->{packages}}));
    is_deeply($_->{packages},
	      [qw(coreutils libc-bin util-linux chromium)],
	      'packages test 1a has correct content');
}
is($_->{package_source}{chromium}, 'u1-PKG-update-test-1.packages',
   'packages test 1 chromium entry is correct');

$_ = App::LXC::Container::Update->new('update-test-2');
$_->_parse_packages();
is_deeply($_->{package_sources},
	  ['30-PKG-default.packages', 'u2-PKG-update-test-2.packages'],
	  'packages test 2 has correct source list');
if (6 == @{$_->{packages}})
{
    is_deeply($_->{packages},
	      [qw(coreutils dash libc-bin util-linux chromium evince)],
	      'packages test 2 has correct content');
}
else
{
    is_deeply($_->{packages},
	      [qw(coreutils libc-bin util-linux chromium evince)],
	      'packages test 2a has correct content');
}
is($_->{package_source}{chromium}, 'u2-PKG-update-test-2.packages',
   'packages test 2 chromium entry is correct');
is($_->{package_source}{evince}, 'u2-PKG-update-test-2.packages',
   'packages test 2 evince entry is correct');

$_ = App::LXC::Container::Update->new('update-test-1', 'update-test-2');
$_->_parse_packages();
is_deeply($_->{package_sources},
	  ['30-PKG-default.packages',
	   'u1-PKG-update-test-1.packages',
	   'u2-PKG-update-test-2.packages'],
	  'packages test 3 has correct source list');
if (6 == @{$_->{packages}})
{
    is_deeply($_->{packages},
	      [qw(coreutils dash libc-bin util-linux chromium evince)],
	      'packages test 3 has correct content');
}
else
{
    is_deeply($_->{packages},
	      [qw(coreutils libc-bin util-linux chromium evince)],
	      'packages test 3a has correct content');
}
is($_->{package_source}{chromium}, 'u1-PKG-update-test-1.packages',
   'packages test 3 chromium entry is correct');
is($_->{package_source}{evince}, 'u2-PKG-update-test-2.packages',
   'packages test 3 evince entry is correct');

$_ = App::LXC::Container::Update->new('update-test-2', 'update-test-1');
$_->_parse_master();		# now with audio packages!
$_->_parse_packages();
is_deeply($_->{package_sources},
	  ['30-PKG-default.packages',
	   '31-PKG-network.packages',
	   '60-PKG-X11.packages',
	   '70-PKG-audio.packages',
	   'u2-PKG-update-test-2.packages',
	   'u1-PKG-update-test-1.packages'],
	  'packages test 4 has correct source list');
if (9 == @{$_->{packages}})
{
    is_deeply($_->{packages},
	      [qw(coreutils dash libc-bin util-linux iproute2
		  fontconfig-config pulseaudio-utils chromium evince)],
	      'packages test 4 has correct content');
}
else
{
    diag(join(' ', 'PACKAGES:', @{$_->{packages}}));
    is_deeply($_->{packages},
	      [qw(coreutils libc-bin util-linux iproute2
		  fontconfig-config pulseaudio-utils chromium evince)],
	      'packages test 4a has correct content');
}
is($_->{package_source}{evince}, 'u2-PKG-update-test-2.packages',
   'packages test 4 evince entry is correct');
is($_->{package_source}{'pulseaudio-utils'}, '70-PKG-audio.packages',
   'packages test 4 evince entry is correct');

#########################################################################
# test for mounts files:
my $path2something = TMP_PATH . '/usr/bin/2something';
_setup_file('/lxc/conf/u1-MNT-update-test-1.mounts',
	    '# 1st gets overwritten by 2nd',
	    '',
	    TMP_PATH . '/usr/bin/2something create=unused tmpfs',
	    $path2something);
_setup_file('/lxc/conf/u2-MNT-update-test-2.mounts',
	    '# same as in u1...',
	    '',
	    $path2something);
_setup_file('/lxc/conf/u1-SPC-update-test-1.special',
	    '# special test entry:',
	    '',
	    'lxc.namespace.keep=ipc');

$update_object = App::LXC::Container::Update->new('update-test-1');
$update_object->_parse_mounts();
obj_keys_in_range('mount_entry', 8, 12,
		  'mounts test 1 has correct entry count');
obj_keys_in_range('mount_source', 8, 12,
		  'mounts test 1 has correct source count');
is($update_object->{mount_entry}{$path2something},
   $path2something . ' ' . substr($path2something, 1)
   . ' none create=file,ro,bind 0 0',
   'mounts test 1 source entry is correct');
is($update_object->{mount_source}{$path2something}, 'u1-MNT-update-test-1.mounts',
   'mounts test 1 source entry is correct');

$update_object = App::LXC::Container::Update->new('update-test-2');
$update_object->_parse_master();		# now with X11 mounts!
$update_object->_parse_mounts();
obj_keys_in_range('mount_entry', 18, 22,
		  'mounts test 2 has correct entry count');
obj_keys_in_range('mount_source', 18, 22,
		  'mounts test 2 has correct source count');
is($update_object->{mount_entry}{$path2something},
   $path2something . ' ' . substr($path2something, 1)
   . ' none create=file,ro,bind 0 0',
   'mounts test 2 source entry is correct');
is($update_object->{mount_source}{$path2something}, 'u2-MNT-update-test-2.mounts',
   'mounts test 2 source entry is correct');
is($update_object->{mount_entry}{'/usr/share/icons'},
   '/usr/share/icons usr/share/icons none create=dir,ro,bind 0 0',
   'mounts test 2 source entry for X11 is correct');
is($update_object->{mount_source}{'/usr/share/icons'}, '61-MNT-X11.mounts',
   'mounts test 2 source entry for X11 is correct');

$update_object = App::LXC::Container::Update->new('update-test-1', 'update-test-2');
$update_object->_parse_mounts();
obj_keys_in_range('mount_entry', 8, 12,
		  'mounts test 3 has correct entry count');
obj_keys_in_range('mount_source', 8, 12,
		  'mounts test 3 has correct source count');
is($update_object->{mount_entry}{$path2something},
   $path2something . ' ' . substr($path2something, 1)
   . ' none create=file,ro,bind 0 0',
   'mounts test 3 source entry is correct');
is($update_object->{mount_source}{$path2something}, 'u2-MNT-update-test-2.mounts',
   'mounts test 3 source entry is correct');

$update_object = App::LXC::Container::Update->new('update-test-2', 'update-test-1');
$update_object->_parse_mounts();
obj_keys_in_range('mount_entry', 8, 12,
		  'mounts test 4 has correct entry count');
obj_keys_in_range('mount_source', 8, 12,
		  'mounts test 4 has correct source count');
is($update_object->{mount_entry}{$path2something},
   $path2something . ' ' . substr($path2something, 1)
   . ' none create=file,ro,bind 0 0',
   'mounts test 4 source entry is correct');
is($update_object->{mount_source}{$path2something}, 'u1-MNT-update-test-1.mounts',
   'mounts test 4 source entry is correct');

#########################################################################
# test for filter files:
_setup_file('/lxc/conf/u1-NOT-update-test-1.filter',
	    '# 2nd overwrites 1st',
	    TMP_PATH . '/usr/lib nomerge',
	    TMP_PATH . '/var/log empty',
	    TMP_PATH . '/.Xdummy empty');
_setup_file('/lxc/conf/u2-NOT-update-test-2.filter',
	    '# 2nd overwrites 1st',
	    TMP_PATH . '/var/log copy');

$update_object = App::LXC::Container::Update->new('update-test-1');
$update_object->_parse_filter();
is($update_object->{filter}{TMP_PATH . '/usr/lib'}, 'nomerge',
   'filter test 1 /usr/lib entry is correct');
is($update_object->{filter}{TMP_PATH . '/var/log'}, 'empty',
   'filter test 1 /var/log entry is correct');
my $count1 = scalar(keys %{$update_object->{filter}});

$update_object = App::LXC::Container::Update->new('update-test-2');
$update_object->_parse_filter();
is(scalar(keys %{$update_object->{filter}}), $count1 - 2,
   'filter test 2 has correct count');
is($update_object->{filter}{TMP_PATH . '/var/log'}, 'copy',
   'filter test 2 /var/log entry is correct');

$update_object =
    App::LXC::Container::Update->new('update-test-1', 'update-test-2');
$update_object->_parse_filter();
is($update_object->{filter}{TMP_PATH . '/var/log'}, 'copy',
   'filter test 3 /var/log entry is correct');

$update_object =
    App::LXC::Container::Update->new('update-test-2', 'update-test-1');
$update_object->_parse_filter();
is($update_object->{filter}{TMP_PATH . '/var/log'}, 'empty',
   'filter test 4 /var/log entry is correct');

#########################################################################
# full test:

SKIP:{
    # Some smokers don't have the needed directory /usr/share/ssl-cert, so
    # hopefully we can create it:
    unless (-d '/usr/share/ssl-cert')
    {
	$< == 0
	    or  skip 'rest of tests not possible without /usr/share/ssl-cert', 62;
	mkdir '/usr/share/ssl-cert'
	    or  warn 'failed to mkdir /usr/share/ssl-cert';
    }
    # Running these tests in a sub-directory below /tmp cause
    # inconsistencies as that is one of our special directories:
    TMP_PATH =~ m|^/tmp/|  and  skip 'rest of tests not working below /tmp', 62;

    _setup_link(TMP_PATH . '/usr/bin/3link', '2something');
    _setup_dir('/usr/lib');
    _setup_dir('/usr/lib/some');
    _setup_dir('/usr/lib/some/directory');
    _setup_dir('/usr/lib/some/directory/with');
    foreach (1..9)
    {	_setup_file('/usr/lib/some/directory/with/file-' . $_ . '.txt');   }
    _setup_link(TMP_PATH . '/usr/lib/somelink',
		'/usr/lib/some/directory/with/file-1.txt');

    output_like			# last name becomes container name!
    {   App::LXC::Container::update('update-test-2', 'update-test-1');   }
    qr{^$},
    qr{\A$re_err2$re_err4$re_err_o1$re_err3\Z},
    'full test run with expected output';

    ok(-f CONF_ROOT . '/update-test-1.conf',
       'LXC configuration file has been created');
    $re = join
	("\n",
	 '^# container description created by App::LXC::Container::Update',
	 '# MASTER: G5,X,A',
	 'lxc\.uts\.name = update-test-1',
	 'lxc\.rootfs\.path = /.+/tmp/lxc/update-test-1',
	 'lxc\.rootfs\.options = idmap=container',
	 '',
	 '#+ update-test-2, 10-NET-default\.conf #+',
	 'lxc\.net\.0\.type = veth',
	 'lxc\.net\.0\.flags = up',
	 'lxc\.net\.0\.link = lxcbr0',
	 'lxc\.net\.0\.name = eth0',
	 'lxc\.net\.0\.ipv4\.address = 10\.0\.3\.5/24',
	 'lxc\.net\.0\.hwaddr = 00:16:3e:xx:xx:xx',
	 '',
	 '#+ 20-DEV-default\.conf #+',
	 'lxc\.pty\.max = 8',
	 'lxc\.mount\.auto = cgroup:ro proc:mixed sys:ro',
	 '',
	 '#+ update-test-2, update-test-1 #+',
	 '# root:',
	 'lxc\.idmap = u 0 0 1',
	 'lxc\.idmap = u 1 100001 1000',
	 '# u1:',
	 'lxc\.idmap = u 1001 1001 1',
	 '# u2:',
	 'lxc\.idmap = u 1002 1002 1',
	 '# u3:',
	 'lxc\.idmap = u 1003 1003 1',
	 'lxc\.idmap = u 1004 101004 64532',
	 '# root:',
	 'lxc\.idmap = g 0 0 1',
	 'lxc\.idmap = g 1 100001 1000',
	 '# u1:',
	 'lxc\.idmap = g 1001 1001 1',
	 '# u2:',
	 'lxc\.idmap = g 1002 1002 1',
	 '# u3:',
	 'lxc\.idmap = g 1003 1003 1',
	 'lxc\.idmap = g 1004 101004 64532',
	 '',
	 '#+ special configuration #+',
	 'lxc.namespace.keep=ipc',
	 '',
	 '#+ container users #+',
	 '',
	 '#+ 40-MNT-default\.mounts #+',
	 # distributions may have additional non-symlink directories here,
	 # some are missing /dev/shm:
	 '.*(lxc\.mount\.entry = tmpfs dev/shm tmpfs create=dir,rw 0 0',
	 ')?lxc\.mount\.entry = /etc/login.defs etc/login.defs none create=file,ro,bind 0 0',
	 'lxc\.mount\.entry = /etc/pam.d etc/pam.d none create=dir,ro,bind 0 0',
	 'lxc\.mount\.entry = /etc/security etc/security none create=dir,ro,bind 0 0',
	 '.*lxc\.mount\.entry = tmpfs root tmpfs create=dir,rw,mode=700 0 0',
	 '.*lxc\.mount\.entry = /tmp tmp none create=dir,rw,bind 0 0',
	 'lxc\.mount\.entry = tmpfs var/tmp tmpfs create=dir,rw 0 0',
	 '(lxc\.mount\.entry = /etc/debian_version etc/debian_version none create=file,ro,bind 0 0',
	 ')?',
	 '#+ 41-MNT-network\.mounts #+',
	 'lxc\.mount\.entry = /etc/ssl/certs etc/ssl/certs none create=dir,ro,bind 0 0',
	 'lxc\.mount\.entry = /usr/lib/ssl usr/lib/ssl none create=dir,ro,bind 0 0',
	 'lxc\.mount\.entry = /usr/share/ca-certificates usr/share/ca-certificates none create=dir,ro,bind 0 0',
	 'lxc\.mount\.entry = /usr/share/ssl-cert usr/share/ssl-cert none create=dir,ro,bind 0 0',
	 '',
	 '#+ 61-MNT-X11\.mounts #+',
	 '[^#]+#+ u2-MNT-update-test-2\.mounts #+',
	 '',
	 '#+ u1-MNT-update-test-1\.mounts #+',
	 'lxc\.mount\.entry = /.+/bin/2something none create=file,ro,bind 0 0',
	 'lxc\.mount\.entry = /.+/bin/2something none create=file,ro,bind 0 0',
	 '',
	 '#+ 30-PKG-default\.packages #+',
	 '# coreutils',
	 '# dash',
	 '# libc-bin',
	 '# util-linux',
	 '#+ 31-PKG-network.packages #+',
	 '# iproute2',
	 '#+ 60-PKG-X11.packages #+',
	 '# fontconfig-config',
	 '#+ 70-PKG-audio\.packages #+',
	 '# pulseaudio-utils',
	 '#+ u2-PKG-update-test-2\.packages #+',
	 '# chromium',
	 '# evince',
	 '#+ u1-PKG-update-test-1\.packages #+',
	 '',
	 '#+ empty filters #+',
	 'lxc\.mount\.entry = tmpfs .+/tmp/var/log tmpfs create=dir,rw 0 0',
	 'lxc\.mount\.entry = tmpfs var/log tmpfs create=dir,rw 0 0',
	 '',
	 '#+ mounts derived from above packages #+',
	 'lxc\.mount\.entry = /.+/tmp/usr/bin/1chromium .+/tmp/usr/bin/1chromium none create=file,ro,bind 0 0',
	 'lxc\.mount\.entry = /.+/tmp/usr/lib/some/directory/with .+/tmp/usr/lib/some/directory/with none create=dir,ro,bind 0 0'
# helper expression to update test after modifying Data/*.pm (move up/down):
#(1?():(
##))
	);
    my $conf = '';
    if (-f CONF_ROOT . '/update-test-1.conf')
    {
	open my $in, '<', CONF_ROOT . '/update-test-1.conf'
	    or  die "can't open ", CONF_ROOT, '/update-test-1.conf: ', $!;
	$conf = join('', <$in>);
	close $in;
    }
    like($conf, qr{^$re}s, 'LXC configuration file looks correct');

    foreach (qw(bin lib lib32 lib64 libx32 sbin))
    {
    SKIP:{
	    -l '/' . $_  or  skip "/$_ not symbolic link on $os", 1;
	    ok(-l CONF_ROOT . '/update-test-1/' . $_,  'got link: /' . $_);
	}
    }
    my $tmp_sub = substr(TMP_PATH, 1);
    foreach (qw(root tmp var var/log),
	     map { $tmp_sub . '/' . $_ }
	     qw(usr usr/bin usr/lib usr/lib/some/directory/with var var/log))
    {
	ok(-d CONF_ROOT . '/update-test-1/' . $_,  'got directory: /' . $_);
    }
    ok(! -e  CONF_ROOT . '/update-test-1/usr/lib/some/directory/with/file-1.txt',
       'no file-1.txt in /update-test-1/usr/lib/some/directory/with');
    foreach my $bin (qw(1chromium 2something 3link))
    {
	$_ = $tmp_sub . '/usr/bin/' . $bin;
	ok(-f CONF_ROOT . '/update-test-1/' . $_,  'got file: /' . $_);
    }
    $_ = $tmp_sub . '/usr/bin/3link';
    ok(-l CONF_ROOT . '/update-test-1/' . $_,  'got link: /' . $_);
    is((stat(CONF_ROOT . '/update-test-1/root'))[2] & 07777, 0700,
       '/root has correct permission');
    is((stat(CONF_ROOT . '/update-test-1/tmp'))[2] & 07777, 01777,
       '/tmp has correct permission');

    #####################################################################
    # tests of local-network and network container:
    foreach my $network ('local-network', 'network')
    {
	output_like		# last name becomes container name!
	{   App::LXC::Container::update($network);   }
	qr{^$},
	qr{\A$re_err2$re_err3\Z},
	'test run for container "' . $network . '" had expected output';

	my $conf_file = CONF_ROOT . '/' . $network . '.conf';
	ok(-f $conf_file,
	   'LXC configuration file has been created - ' . $network);
	my $net_key = $network eq 'network' ? 'G' : 'L';
	my $net_id = $network eq 'network' ? 3 : 2;
	$re = join
	    ("\n",
	     '^# container description created by App::LXC::Container::Update',
	     '# MASTER: ' . $net_key . $net_id . ',-,-',
	     'lxc\.uts\.name = ' . $network,
	     'lxc\.rootfs\.path = /.+/tmp/lxc/' . $network,
	     'lxc\.rootfs\.options = idmap=container',
	     '',
	     '#+ ' . $network . ', 10-NET-default\.conf #+',
	     'lxc\.net\.0\.type = veth',
	     'lxc\.net\.0\.flags = up',
	     'lxc\.net\.0\.link = lxcbr0',
	     'lxc\.net\.0\.name = eth0',
	     'lxc\.net\.0\.ipv4\.address = 10\.0\.3\.' . $net_id . '/24',
	     'lxc\.net\.0\.hwaddr = 00:16:3e:xx:xx:xx',
	     '',
	     '#+ 20-DEV-default\.conf #+',
	     'lxc\.pty\.max = 8',
	     'lxc\.mount\.auto = cgroup:ro proc:mixed sys:ro',
	     '',
	     '#+ -no privileged users- #+',
	     'lxc\.idmap = u 0 100000 65536',
	     'lxc\.idmap = g 0 100000 65536',
	     '',
	     '#+ 40-MNT-default\.mounts #+',
	     # distributions may have additional non-symlink directories here,
	     # some are missing /dev/shm:
	     '.*(lxc\.mount\.entry = tmpfs dev/shm tmpfs create=dir,rw 0 0',
	     ')?lxc\.mount\.entry = /etc/login.defs etc/login.defs none create=file,ro,bind 0 0',
	     'lxc\.mount\.entry = /etc/pam.d etc/pam.d none create=dir,ro,bind 0 0',
	     'lxc\.mount\.entry = /etc/security etc/security none create=dir,ro,bind 0 0',
	     '.*lxc\.mount\.entry = tmpfs root tmpfs create=dir,rw,mode=700 0 0',
	     '.*lxc\.mount\.entry = /tmp tmp none create=dir,rw,bind 0 0',
	     'lxc\.mount\.entry = tmpfs var/tmp tmpfs create=dir,rw 0 0',
	     '(lxc\.mount\.entry = /etc/debian_version etc/debian_version none create=file,ro,bind 0 0',
	     ')?',
	     '#+ 41-MNT-network\.mounts #+',
	     'lxc\.mount\.entry = /etc/ssl/certs etc/ssl/certs none create=dir,ro,bind 0 0',
	     'lxc\.mount\.entry = /usr/lib/ssl usr/lib/ssl none create=dir,ro,bind 0 0',
	     'lxc\.mount\.entry = /usr/share/ca-certificates usr/share/ca-certificates none create=dir,ro,bind 0 0',
	     'lxc\.mount\.entry = /usr/share/ssl-cert usr/share/ssl-cert none create=dir,ro,bind 0 0',
	     '',
	     '#+ 30-PKG-default\.packages #+',
	     '# coreutils',
	     '# dash',
	     '# libc-bin',
	     '# util-linux',
	     '#+ 31-PKG-network.packages #+',
	     '# iproute2',
	     '',
	     '#+ empty filters #+',
	     'lxc.mount.entry = tmpfs var/log tmpfs create=dir,rw 0 0',
	     '',
	     '#+ mounts derived from above packages #+',
	     'lxc\.mount\.entry = /.+/tmp/usr/bin/2something .+/tmp/usr/bin/2something none create=file,ro,bind 0 0'
# helper expression to update test after modifying Data/*.pm (move up/down):
#(1?():(
#))
	    );
	if (-f $conf_file)
	{
	    open my $in, '<', $conf_file
		or  die "can't open ", $conf_file . ': ', $!;
	    $conf = join('', <$in>);
	    close $in;
	}
	like($conf, qr{^$re}s,
	     'LXC configuration file looks correct - ' . $network);

	my $conf_dir = CONF_ROOT . '/' . $network . '/';
	foreach (qw(bin lib lib32 lib64 libx32 sbin))
	{
	SKIP:{
		-l '/' . $_  or  skip "/$_ not symbolic link on $os", 1;
		ok(-l $conf_dir . $_,  'got link /' . $_ . ' in ' . $network);
	    }
	}
	foreach (qw(root tmp var var/log),
		 map { $tmp_sub . '/' . $_ } qw(usr usr/bin))
	{
	    ok(-d $conf_dir . $_,  'got directory /' . $_ . ' in ' . $network);
	}
	$_ = $tmp_sub . '/usr/bin/2something';
	ok(-f $conf_dir . $_,  'got file /' . $_ . ' in ' . $network);
	is((stat(CONF_ROOT . '/' . $network . '/root'))[2] & 07777, 0700,
	   '/root has correct permission in ' . $network);
	is((stat(CONF_ROOT . '/' . $network . '/tmp'))[2] & 07777, 01777,
	   '/tmp has correct permission in ' . $network);
    }

} # end of big SKIP block
