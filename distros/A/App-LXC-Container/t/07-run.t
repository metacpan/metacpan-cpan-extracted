# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 07-run.t".
#
# Without "Build" file it could be called with "perl -I../lib 07-run.t"
# or "perl -Ilib t/07-run.t".  This is also the command needed to find
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

use Test::More tests => 212;
use Test::Output;

#####################################
# prepare fixed environment:
use constant T_PATH => map { s|/[^/]+$||; $_ } Cwd::abs_path($0);
use constant TMP_PATH => T_PATH . '/tmp';

do(T_PATH . '/functions/sub_perl.pl');
do(T_PATH . '/functions/files_directories.pl');

use constant HOME_PATH => TMP_PATH . '/home';
#_setup_dir('/home');
use constant LXC_LINK => HOME_PATH . '/.lxc-configuration';
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
    die "$0 can only run after a successful invocation of t/02-init.t "
    .   "and t/03-setup.t\n";

use App::LXC::Container;

# directory of mockup commands:
my $test_path = $ENV{PATH} = T_PATH . '/mockup:' . $ENV{PATH};

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
		App::LXC::Container::run("' . $_[1] . '");');
    }
    else
    {	die 'bad branch';   }
}
sub check_config_object($$$)
{
    my ($obj, $id, $ra_checks) = @_;
    local $_;

    is(ref($obj), 'App::LXC::Container::Run', $id . ' returned correct object');
    foreach (@$ra_checks)
    {
	if (ref($_->[1]) eq 'ARRAY')
	{
	    is_deeply($obj->{$_->[0]}, $_->[1],
		      $id . ' has correct ' . $_->[0] . ' ARRAY');
	}
	elsif (ref($_->[1]) eq 'HASH')
	{
	    is_deeply($obj->{$_->[0]}, $_->[1],
		      $id . ' has correct ' . $_->[0] . ' HASH');
	}
	elsif ($_->[1] =~ m/^\^/)
	{
	    like($obj->{$_->[0]}, qr{$_->[1]}, $id . ' has correct ' . $_->[0]);
	}
	else
	{   is($obj->{$_->[0]}, $_->[1], $id . ' has correct ' . $_->[0]);   }
    }
}
sub check_config_file($$)
{
    my ($file, $rh_checks) = @_;
    (my $short = $file) =~ s|^.*/||;
    ok(-f $file, $short . ' exists');
    open my $in, '<', $file  or  die "can't open $file: $!";
    my $content = join('', <$in>);
    local $_;
    foreach (sort keys %$rh_checks)
    {
	my $re = $rh_checks->{$_};
	if ($re =~ s/^!//)
	{
	    unlike($content, qr/^.*$re.*$/m,
		   $short . ': ' . $_ . ' is missing as expected');
	}
	else
	{   like($content, qr/^$re$/m, $short . ': found correct ' . $_);   }
    }
    close $in;
}

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;
my $re_eval = qr{ at \(eval \d+\)(\[t/\d+-[a-z]+\.t:\d+\])? line 1\.$};

#########################################################################
# initialise mockup scripts:
_remove_file('/.lxc-attach-counter');
_setup_file('/.lxc-attach-counter', 0);
_remove_file('/.lxc-execute-counter');
_setup_file('/.lxc-execute-counter', 0);
_remove_file('/.lxc-ls-counter');
_setup_file('/.lxc-ls-counter', 0);
_remove_file('/.nft-counter');
_setup_file('/.nft-counter', 0);
_remove_file('/.xauth-counter');
_setup_file('/.xauth-counter', 0);

#########################################################################
# general failing tests:

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
_setup_link(LXC_LINK, CONF_ROOT);

eval {   App::LXC::Container::Run::new('wrong-call', '', '', '');   };
like($@,
     qr{^bad call to App::LXC::Container::Run->new.*$re_msg_tail},
     'bad call of App::LXC::Container::Run->new fails');
eval {   $_ = App::LXC::Container::Run->new('non-existing', '', '');   };
like($@,
     qr{^can't open '/[^']+/.lxc-configuration/non-existing.conf':.*$re_msg_tail},
    'running non-existing configuration fails');

eval {   App::LXC::Container::run('-u', 'root', '-d', '/', 'bad-name!');   };
like($@,
     qr/^The name of the container may only contain word char.*!$re_msg_tail/,
     'bad container name fails');

#########################################################################
# tests with broken configuration:
_setup_dir('/lxc/run-test-broken');
_remove_file('/lxc/run-test-broken.conf');
_setup_file('/lxc/run-test-broken.conf', '#MASTER:G,-,-');
eval {
    $_ = App::LXC::Container::Run->new('run-test-broken', '', '');
};
like($@,
     qr{^bad MASTER value 'G,-,-'$re_msg_tail},
    'missing network ID in MASTER fails');

_remove_file('/lxc/run-test-broken.conf');
_setup_file('/lxc/run-test-broken.conf', '#MASTER:G0,-,-');
eval {
    $_ = App::LXC::Container::Run->new('run-test-broken', '', '');
};
like($@,
     qr{^bad MASTER value 'G0'$re_msg_tail},
    'wrong network ID in MASTER fails');

_remove_file('/lxc/run-test-broken.conf');
_setup_file('/lxc/run-test-broken.conf',
	    'lxc.rootfs.path=' . CONF_ROOT . '/run-test-broken.conf');
eval {
    $_ = App::LXC::Container::Run->new('run-test-broken', '', '');
};
like($@,
     qr{^directory /[^']+/lxc/run-test-broken.conf is missing$re_msg_tail},
    'wrong rootfs entry in master configuration fails');

_remove_file('/lxc/run-test-broken.conf');
_setup_file('/lxc/run-test-broken.conf', 'lxc.rootfs.path=/tmp');
eval {
    $_ = App::LXC::Container::Run->new('run-test-broken', '', '');
};
like($@,
     qr{^bad directory '/tmp'$re_msg_tail},
    'bad rootfs entry in master configuration fails');

_remove_file('/lxc/run-test-broken.conf');
_setup_file('/lxc/run-test-broken.conf',
	    '#MASTER:G42,-,-', 'lxc.net.0.ipv4.address = 10.0.3.47/24');
eval {
    $_ = App::LXC::Container::Run->new('run-test-broken', '', '');
};
like($@,
     qr{^bad MASTER value '10.0.3.47 \(!~ 42\$\)'$re_msg_tail},
    'inconsistent network entry in master configuration fails');

_remove_file('/lxc/run-test-broken.conf');
_setup_file('/lxc/run-test-broken.conf');
eval {
    $_ = App::LXC::Container::Run->new('run-test-broken', '', '');
};
like($@,
     qr{^bad MASTER value '\?\?\?'$re_msg_tail},
    'empty master configuration fails');

_remove_file('/lxc/run-test-broken.conf');
_setup_file('/lxc/run-test-broken.conf',
	    '#MASTER:L42,-,-',
	    'lxc.rootfs.path=' . CONF_ROOT . '/run-test-broken',
	    'lxc.net.0.ipv4.address = 10.0.3.42/24');
$ENV{ALC_DEBUG} = 0;		# cover branch in App::LXC::Container::run

_setup_file('/lxc-ls', '#!/bin/sh', 'exit 0');	# lxc-ls runs before nft!
_chmod(0755, '/lxc-ls');
$ENV{PATH} = TMP_PATH . ':/bin:/usr/bin';	# open will fail
stderr_like
{   eval "App::LXC::Container::run('run-test-broken');";   }
    qr{^.*"nft": [^:]+App/LXC/Container/Run\.pm line \d+\.$},
    '1st (mocked) nft list for local network fails with correct output';
like($@,
     qr{^error running 'nft list ruleset inet' [^:]+: 0$re_eval},
    '1st (mocked) nft list for local network fails with correct message');
$ENV{ALC_DEBUG} = 'x';
$ENV{PATH} = $test_path;			# close will fail
eval {   App::LXC::Container::run('run-test-broken');   };
like($@,
     qr{^error running 'nft list ruleset inet' [^:]+: 256$re_msg_tail},
    '2nd (mocked) nft list for local network fails');
delete $ENV{ALC_DEBUG};

#########################################################################
# tests with 1st (simple) valid configuration:
_setup_dir('/lxc/run-test-1');
_remove_file('/lxc/run-test-1.conf');
_setup_file('/lxc/run-test-1.conf',
	    '#MASTER:N,-,-',
	    'lxc.rootfs.path=' . CONF_ROOT . '/run-test-1',
	    'lxc.idmap = u 0 0 1',
	    'lxc.idmap = u 1 1 1',
	    'lxc.idmap = u 2 100002 65534',
	    'lxc.idmap = g 0 0 1',
	    'lxc.idmap = g 1 1 1',
	    'lxc.idmap = g 2 100002 65534',
	    'lxc.mount.entry = tmpfs dev/shm tmpfs create=dir,rw 0 0',
	    'lxc.mount.entry = /tmp tmp none create=dir,rw,bind 0 0',
	    '');
$_ = App::LXC::Container::Run->new('run-test-1', 'root', '/', 'do', 'it');
check_config_object($_,
		    'valid configuration 1',
		    [[audio => '-'],
		     [command => ['do', 'it']],
		     [dir => '/'],
		     [gateway => '^$'],
		     [gids => [1]],
		     [init => CONF_ROOT . '/run-test-1/lxc-run.sh'],
		     [ip => '^$'],
		     [mounts => {'/tmp' => 1}],
		     [name => 'run-test-1'],
		     [network => 0],
		     [network_type => 'N'],
		     [rc => LXC_LINK . '/run-test-1.conf'],
		     [root => CONF_ROOT . '/run-test-1'],
		     [running => 0],
		     [uids => [1]],
		     [user => 'root'],
		     [x11 => '-']]);

# using container to test some _check_running errors:
$ENV{PATH} = '';		# sub-program will fail
stderr_like
{   eval '$_->_check_running();';   }
    qr{^.*"lxc-ls": [^:]+App/LXC/Container/Run\.pm line \d+\.$},
    'failing lxc-ls has correct output';
like($@,
     qr{^call to 'lxc-ls' failed: 256$re_eval},
    'lxc-ls fails with empty PATH');
$ENV{PATH} = $test_path;	# back to normal
eval {   $_->_check_running();   };
like($@,
     qr{^call to 'lxc-ls' failed: 512$re_msg_tail},
     'lxc-ls fails in 2nd mockup');
is($_->{running}, 0, 'failed test did not affect running flag');
$_->_check_running();
is($_->{running}, 1, '3rd mockup of lxc-ls correctly set running flag');

#########################################################################
# using (modified!) container to test local network restrictions:
$_->{ip} = '10\.0\.3\.234';
output_like			# 1 - not yet restricted
{   $_->_local_net();   }
    qr{^$},
    qr{^$},
    '1st test with mocked local net OK';
output_like			# 2 - everything has been already set-up
{   $_->_local_net();   }
    qr{^$},
    qr{^$},
    '2nd test with mocked local net OK';
output_like			# 3 - 1st add fails
{   eval '$_->_local_net();';   }
    qr{^$},
    qr{^nft: add chain inet lxc localfilter: mockup failed$},
    '3rd test with mocked local net OK';
output_like			# 4 - insert fails
{   eval '$_->_local_net();';   }
    qr{^$},
    qr{^nft: insert rule inet lxc forward jump localfilter: mockup failed$},
    '4th test with mocked local net OK';
output_like			# 5 - 2nd add fails
{   eval '$_->_local_net();';   }
    qr{^$},
    qr{^nft: add rule inet lxc localfilter ip saddr .+ reject: mockup failed$},
    '5th test with mocked local net OK';

#########################################################################
# testing set-up of user accounts in (modified!) container:
_setup_dir('/etc');
_setup_file('/etc/passwd',
	    'root:x:0:0:root:/root:/bin/sh',
	    'daemon:x:1:1:daemon:/bin:/usr/sbin/nologin');
_setup_file('/etc/shadow',
	    'root:!:19191:0:99999:99:::',
	    'daemon:*:19191:0:99999:99:::');
_setup_file('/etc/group',
	    'root:x:0:',
	    'daemon:x:1:',
	    'other:x:42:some,root,one',
	    'dummy:x:12345:dummy');
_setup_file('/etc/gshadow',
	    'root:*::',
	    'daemon:*::');
$App::LXC::Container::Run::_root_etc = TMP_PATH . '/etc/';

_remove_file('/lxc/run-test-1/etc/group');
_remove_file('/lxc/run-test-1/etc/gshadow');
_remove_file('/lxc/run-test-1/etc/passwd');
_remove_file('/lxc/run-test-1/etc/shadow');
_remove_dir(TMP_PATH . '/lxc/run-test-1/etc');
eval '$_->_prepare_user();';
like($@,
     qr{^can't open .+/run-test-1/etc/group': No such file or directory$re_eval},
    'non-existing target /etc has correct output (for /etc/group)');

_setup_dir('/lxc/run-test-1/etc');
_setup_file('/lxc/run-test-1/etc/gshadow'); # for successful unlink of it
_chmod(0, '/etc/shadow');
eval '$_->_prepare_user();';
like($@,
     qr{can't open .+tmp/etc/shadow': Permission denied$re_eval},
    'failing read-access to mocked /etc/shadow has correct output');
_chmod(0644, '/etc/shadow');
_chmod(0555, '/lxc/run-test-1/etc');
eval '$_->_prepare_user();';
like($@,
     qr{can't remove .+tmp/lxc/run-test-1/etc/group': Permission denied$re_eval},
    'failing write-access to target /etc has correct output');
_chmod(0755, '/lxc/run-test-1/etc');

$_->{mounts}{'/etc'} = 1;
output_like
{ $_->_prepare_user(); }
    qr{^$}, qr{^$},
    '_prepare_user for mapped /etc looks correct';
delete $_->{mounts}{'/etc'};

$_->{mounts}{'/etc/group'} = 1;
$_->{mounts}{'/etc/gshadow'} = 1;
$_->{mounts}{'/etc/passwd'} = 1;
my $re_account_files = 'group gshadow passwd shadow';
output_like
{ $_->_prepare_user(); }
    qr{^$},
    qr{^broken user mapping - check mounting of $re_account_files$re_msg_tail},
    '_prepare_user for only 3 mapped account files looks correct';
$_->{mounts}{'/etc/shadow'} = 1;
output_like
{ $_->_prepare_user(); }
    qr{^$}, qr{^$},
    '_prepare_user for all 4 mapped account files looks correct';

#########################################################################
# check writing of startup script for 1st configuration:

_remove_file('/lxc/run-test-1/lxc-run.sh');
_setup_file('/lxc/run-test-1/lxc-run.sh');
_chmod(0444, '/lxc/run-test-1/lxc-run.sh');
eval '$_->_write_init_sh();';
like($@,
     qr{can't open .+tmp/lxc/run-test-1/lxc-run.sh': Permission denied$re_eval},
    'failing write-access to startup script lxc-run.sh has correct output');
_remove_file('/lxc/run-test-1/lxc-run.sh');

$_->{running} = 0;
eval '$_->_write_init_sh();';
is($@, '', 'creating minimal startup script run without problems');
check_config_file(TMP_PATH . '/lxc/run-test-1/lxc-run.sh',
		  {DISPLAY => '!DISPLAY',
		   PULSE => '!PULSE_SERVER',
		   XAUTHORITY => '!XAUTHORITY',
		   cd => 'cd "/"',
		   dns => '!nameserver',
		   exec => "exec 'do' 'it'",
		   gateway => '!gateway',
		   route => '!route',
		   shebang => '#!/bin/sh'});

$_->{running} = 1;
eval '$_->_write_init_sh();';
is($@, '', 'creating 2nd minimal startup script run without problems');
check_config_file(TMP_PATH . '/lxc/run-test-1/lxc-run.sh',
		  {DISPLAY => '!DISPLAY',
		   PULSE => '!PULSE_SERVER',
		   XAUTHORITY => '!XAUTHORITY',
		   cd => 'cd "/"',
		   dns => '!nameserver',
		   exec => "exec 'do' 'it'",
		   gateway => '!gateway',
		   route => '!route',
		   shebang => '#!/bin/sh'});

$_->{user} = 'bin';
eval '$_->_write_init_sh();';
is($@, '', 'creating variant 1 for other user run without problems');
check_config_file(TMP_PATH . '/lxc/run-test-1/lxc-run.sh',
		  {DISPLAY => '!DISPLAY',
		   PULSE => '!PULSE_SERVER',
		   XAUTHORITY => '!XAUTHORITY',
		   cd => 'cd "/"',
		   dns => '!nameserver',
		   exec =>
		   "exec su bin -s /bin/sh -c 'do \"\\\$@\"' -- dummy_argv0 'it'",
		   gateway => '!gateway',
		   route => '!route',
		   shebang => '#!/bin/sh'});

$_->{command} = ['do'];
eval '$_->_write_init_sh();';
is($@, '', 'creating variant 2 for other user run without problems');
check_config_file(TMP_PATH . '/lxc/run-test-1/lxc-run.sh',
		  {DISPLAY => '!DISPLAY',
		   PULSE => '!PULSE_SERVER',
		   XAUTHORITY => '!XAUTHORITY',
		   cd => 'cd "/"',
		   dns => '!nameserver',
		   exec => "exec su bin -s /bin/sh -c 'do'",
		   gateway => '!gateway',
		   route => '!route',
		   shebang => '#!/bin/sh'});

$_->{command} = [];
eval '$_->_write_init_sh();';
is($@, '', 'creating variant 3 for other user run without problems');
check_config_file(TMP_PATH . '/lxc/run-test-1/lxc-run.sh',
		  {DISPLAY => '!DISPLAY',
		   PULSE => '!PULSE_SERVER',
		   XAUTHORITY => '!XAUTHORITY',
		   cd => 'cd "/"',
		   dns => '!nameserver',
		   exec => "exec su bin -s /bin/sh",
		   gateway => '!gateway',
		   route => '!route',
		   shebang => '#!/bin/sh'});

$_->{user} = 'root';
$_->{command} = ["in'valid"];
eval '$_->_write_init_sh();';
like($@, qr{^can't run command with <in'valid> containing <'>$re_eval},
     'invalid command fails correctly');

$_->{command} = ['do', "in'val\"id"];
eval '$_->_write_init_sh();';
like($@, qr{^can't run command with <in'val"id> containing <'">$re_eval},
     'invalid command arguments fail correctly');

$_->{command} = ['do', 'mixed', 'q"uot"ed', "par'ameters"];
eval '$_->_write_init_sh();';
is($@, '', 'creating startup script with quoted parameters run without problems');
check_config_file(TMP_PATH . '/lxc/run-test-1/lxc-run.sh',
		  {DISPLAY => '!DISPLAY',
		   PULSE => '!PULSE_SERVER',
		   XAUTHORITY => '!XAUTHORITY',
		   cd => 'cd "/"',
		   dns => '!nameserver',
		   exec => "exec 'do' 'mixed' 'q\"uot\"ed' \"par'ameters\"",
		   gateway => '!gateway',
		   route => '!route',
		   shebang => '#!/bin/sh'});

#########################################################################
# testing mocked runs (even the failing ones must run in subprocesses,
# otherwise Devel::Cover gets confused):
$ENV{PATH} = '';		# lxc-execute and lxc-attach will fail

my $re_output =
    "using 'PoorTerm' as UI\n" .
    '.+"lxc-execute": [^:]+App/LXC/Container/Run\.pm line \d+\.' . "\n" .
    "call to 'lxc-execute' failed: No such file or directory at -e line \\d\\.";
$_ = _sub_perl('use App::LXC::Container;
		$_ = App::LXC::Container::Run->new
		("run-test-1", "root", "/", "command");
		$_->_run();');
like($_, qr{^$re_output$}, 'lxc-execute fails with empty PATH');

$re_output =
    "using 'PoorTerm' as UI\n" .
    '.+"lxc-attach": [^:]+App/LXC/Container/Run\.pm line \d+\.' . "\n" .
    "call to 'lxc-attach' failed: No such file or directory at -e line \\d\\.";
$_ = _sub_perl('use App::LXC::Container;
		$_ = App::LXC::Container::Run->new
		("run-test-1", "root", "/", "command");
		$_->{running} = 1;
		$_->_run();');
like($_, qr{^$re_output$}, 'lxc-attach fails with empty PATH');

$ENV{PATH} = $test_path;	# back to normal

$_ = _sub_perl('use App::LXC::Container;
		$_ = App::LXC::Container::Run->new
		("run-test-1", "root", "/", "command");
		$_->_run();');
like($_, qr{^using 'PoorTerm' as UI$},
     '_run in 1st mockup test (lxc-execute) seems correct');

$_ = _sub_perl('use App::LXC::Container;
		$_ = App::LXC::Container::Run->new
		("run-test-1", "root", "/", "command");
		$_->{running} = 1;
		$_->_run();');
like($_, qr{^using 'PoorTerm' as UI$},
     '_run in 2nd mockup test (lxc-attach) seems correct');

_setup_dir('/lxc/run-test-1/.xauth-dir');
_setup_file('/lxc/run-test-1/.xauth-dir/.Xauthority', 42);
_chmod(0555, '/lxc/run-test-1/.xauth-dir');
$_ = _sub_perl('use App::LXC::Container;
		$_ = App::LXC::Container::Run->new
		("run-test-1", "root", "/", "command");
		$_->_run();');
$re_output =
    "using 'PoorTerm' as UI\n" .
    "can't remove .+tmp/lxc/run-test-1/.xauth-dir/.Xauthority': " .
    'Permission denied at -e line \d\.';
like($_, qr{^$re_output$},
     '_run in 3rd mockup test (lxc-execute protected .Xauthority) fails correct');
_chmod(0755, '/lxc/run-test-1/.xauth-dir');
_remove_file('/lxc/run-test-1/.xauth-dir/.Xauthority');
_remove_dir('/lxc/run-test-1/.xauth-dir');

#########################################################################
# tests with 2nd valid configuration:
_setup_dir('/lxc/run-test-2');
_remove_file('/lxc/run-test-2.conf');
_setup_file('/lxc/run-test-2.conf',
	    '#MASTER:G42,X,A',
	    'lxc.rootfs.path=' . CONF_ROOT . '/run-test-2',
	    'lxc.net.0.ipv4.address = 10.0.3.42/24',
	    'lxc.idmap = u 0 100000 65536',
	    'lxc.idmap = g 0 100000 65536',
	    'lxc.mount.entry = tmpfs dev/shm tmpfs create=dir,rw 0 0',
	    'lxc.mount.entry = /tmp tmp none create=dir,rw,bind 0 0',
	    '');
_setup_dir('/lxc/run-test-2/etc');
$_ = App::LXC::Container::Run->new('run-test-2', 'root', '/', 'do', 'it');
check_config_object($_,
		    'valid configuration 2',
		    [[audio => 'A'],
		     [command => ['do', 'it']],
		     [dir => '/'],
		     [gateway => '^10\.0\.3\.1$'],
		     [gids => []],
		     [init => CONF_ROOT . '/run-test-2/lxc-run.sh'],
		     [ip => '^10\.0\.3\.42$'],
		     [mounts => {'/tmp' => 1}],
		     [name => 'run-test-2'],
		     [network => 42],
		     [network_type => 'G'],
		     [rc => LXC_LINK . '/run-test-2.conf'],
		     [root => CONF_ROOT . '/run-test-2'],
		     [running => 0],
		     [uids => []],
		     [user => 'root'],
		     [x11 => 'X']]);

#########################################################################
# check writing of startup script for 2nd configuration:

_remove_file('/lxc/run-test-2/lxc-run.sh');

_remove_file('/home/.Xauthority');
_setup_file('/home/.Xauthority');
_chmod(0600, '/home/.Xauthority');
system('cp', '-a',
       T_PATH . '/mockup-files/.Xauthority',
       HOME_PATH . '/.Xauthority') == 0
    or  die "can't cp mockup '.Xauthority: $!\n";
$ENV{DISPLAY} = ':0';
$ENV{XAUTHORITY} = HOME_PATH . '/.Xauthority';

_remove_file('/lxc/run-test-2/.xauth-root/.Xauthority');
_remove_dir(TMP_PATH . '/lxc/run-test-2/.xauth-root');
_chmod(0555, '/lxc/run-test-2');
eval '$_->_write_init_sh();';	# 1 - creating .xauth directory fails
like($@,
    qr{^can't create .+/lxc/run-test-2/.xauth-root': Permission denied$re_eval},
    'failing write-access for .xauth directory has correct output');
_chmod(0755, '/lxc/run-test-2');

eval '$_->_write_init_sh();';	# 2 - "empty original" .Xauthority fails
like($@,
    qr{^call to 'xauth list' failed: no :0$re_eval},
    'missing .Xauthority entry fails correctly');

eval '$_->_write_init_sh();';	# 3 - writing .Xauthority fails
like($@,
    qr{^call to 'xauth -b -f [^']+/\.Xauthority add [^']+' failed: \d+$re_eval},
    'failing write-access for .Xauthority has correct output');

eval '$_->_write_init_sh();';	# 4 - run without error (D+XA)
is($@, '', 'creating startup script with full X11 access run without problems');
check_config_file(TMP_PATH . '/lxc/run-test-2/lxc-run.sh',
		  {DISPLAY => 'export DISPLAY=:0',
		   PULSE => 'export PULSE_SERVER=10\.0\.3\.1',
		   XAUTHORITY => 'export XAUTHORITY=/\.xauth-root/\.Xauthority',
		   cd => 'cd "/"',
		   dns => 'echo "nameserver \$gateway" >/etc/resolv\.conf',
		   exec => "exec 'do' 'it'",
		   gateway => 'gateway=10\.0\.3\.1',
		   route => 'ip route add default via "\$gateway"',
		   shebang => '#!/bin/sh'});
ok(-f TMP_PATH . '/lxc/run-test-2/.xauth-root/.Xauthority',
   '1st .Xauthority file has been created in correct location');

$_->{running} = 1;
eval '$_->_write_init_sh();';	# 5 - run without error (D+XA, 2nd)
is($@, '', 'creating startup script for 2nd X11 access run without problems');
check_config_file(TMP_PATH . '/lxc/run-test-2/lxc-run.sh',
		  {DISPLAY => 'export DISPLAY=:0',
		   PULSE => 'export PULSE_SERVER=10\.0\.3\.1',
		   XAUTHORITY => 'export XAUTHORITY=/\.xauth-root/\.Xauthority',
		   cd => 'cd "/"',
		   dns => '!gateway',
		   exec => "exec 'do' 'it'",
		   gateway => '!gateway',
		   route => '!route',
		   shebang => '#!/bin/sh'});

my $user = defined $ENV{USER} ? $ENV{USER} : 'root' ;
$_->{user} = $user;
eval '$_->_write_init_sh();';	# 6 - run without error (D+XA, 2nd user)
is($@, '',
   "creating startup script for 2nd user's X11 access run without problems");
check_config_file(TMP_PATH . '/lxc/run-test-2/lxc-run.sh',
		  {DISPLAY => 'export DISPLAY=:0',
		   PULSE => 'export PULSE_SERVER=10\.0\.3\.1',
		   XAUTHORITY => "export XAUTHORITY=/\.xauth-$user/\.Xauthority",
		   cd => 'cd "/"',
		   dns => '!gateway',
		   exec =>
		   "exec su $user -s /bin/sh -c 'do \"..\"' -- dummy_argv0 'it'",
		   gateway => '!gateway',
		   route => '!route',
		   shebang => '#!/bin/sh'});
ok(-f TMP_PATH . '/lxc/run-test-2/.xauth-' . $user . '/.Xauthority',
   '2nd .Xauthority file has been created in correct location');
$_->{user} = 'root' ;
$_->{running} = 0;

delete $ENV{XAUTHORITY};
$_->{command} = [];		# trying default command aka shell
eval '$_->_write_init_sh();';	# 7 - run without error (D-XA)
is($@, '',
   'creating startup script with simple X11 access run without problems');
check_config_file(TMP_PATH . '/lxc/run-test-2/lxc-run.sh',
		  {DISPLAY => 'export DISPLAY=:0',
		   PULSE => 'export PULSE_SERVER=10\.0\.3\.1',
		   XAUTHORITY => '!XAUTHORITY',
		   cd => 'cd "/"',
		   dns => 'echo "nameserver \$gateway" >/etc/resolv\.conf',
		   exec => "exec '/bin/sh'",
		   gateway => 'gateway=10\.0\.3\.1',
		   route => 'ip route add default via "\$gateway"',
		   shebang => '#!/bin/sh'});

$_->{running} = 1;
eval '$_->_write_init_sh();';	# 8 - run without error (D-XA, 2nd)
is($@, '',
   'creating startup script for 2nd simple X11 access run without problems');
check_config_file(TMP_PATH . '/lxc/run-test-2/lxc-run.sh',
		  {DISPLAY => 'export DISPLAY=:0',
		   PULSE => 'export PULSE_SERVER=10\.0\.3\.1',
		   XAUTHORITY => '!XAUTHORITY',
		   cd => 'cd "/"',
		   dns => '!gateway',
		   exec => "exec '/bin/sh'",
		   gateway => '!gateway',
		   route => '!route',
		   shebang => '#!/bin/sh'});

delete $ENV{DISPLAY};
eval '$_->_write_init_sh();';	# 9 - run without error (-D-XA, 2nd)
is($@, '',
   'creating startup script for 2nd no-X11 variant run without problems');
check_config_file(TMP_PATH . '/lxc/run-test-2/lxc-run.sh',
		  {DISPLAY => '!DISPLAY',
		   PULSE => 'export PULSE_SERVER=10\.0\.3\.1',
		   XAUTHORITY => '!XAUTHORITY',
		   cd => 'cd "/"',
		   dns => '!gateway',
		   exec => "exec '/bin/sh'",
		   gateway => '!gateway',
		   route => '!route',
		   shebang => '#!/bin/sh'});

#########################################################################
# final test of a full run with above 2nd configuration:
$_ = _sub_perl('use App::LXC::Container;
		$App::LXC::Container::Run::_root_etc = "' . TMP_PATH . '/etc/";
		App::LXC::Container::run("run-test-2", "do", "it");');
like($_, qr{^using 'PoorTerm' as UI$}, 'full run produced correct output');
