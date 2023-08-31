# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 02-init.t".
#
# Without "Build" file it could be called with "perl -I../lib 02-init.t"
# or "perl -Ilib t/02-init.t".  This is also the command needed to find
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

use Test::More tests => 61;
use Test::Output;

#####################################
# prepare fixed environment:
use constant T_PATH => map { s|/[^/]+$||; $_ } Cwd::abs_path($0);
use constant TMP_PATH => T_PATH . '/tmp';

do(T_PATH . '/functions/call_with_stdin.pl');
do(T_PATH . '/functions/sub_perl.pl');
do(T_PATH . '/functions/files_directories.pl');

_setup_dir('');
use constant HOME_PATH => TMP_PATH . '/home';
_setup_dir('/home');

use constant FAIL_PATH => TMP_PATH . '/fail';
_setup_dir('/fail');

BEGIN {
    delete $ENV{DISPLAY};
    $ENV{UI} = 'PoorTerm';	# PoorTerm allows easy testing
    # no testing outside of t:
    $ENV{HOME} = HOME_PATH;
    $ENV{LXC_DEFAULT_CONF_DIR} = TMP_PATH;
}

use App::LXC::Container;
use App::LXC::Container::Data::common;

$App::LXC::Container::Data::_os_release =
    T_PATH . '/mockup-files/os-release-debian';
$App::LXC::Container::Data::common::_system_default =
    T_PATH . '/mockup-files/network-empty.conf';

#########################################################################
# local helper functions:
sub fail_in_sub_perl($$$;$$)
{
    my ($home_dir, $conf_dir, $input, $call_new, $debug) = @_;
    defined $debug  or  $debug = 0;
    return _sub_perl('
		BEGIN {
		    $ENV{HOME} = "' . $home_dir . '";
		    $ENV{LXC_DEFAULT_CONF_DIR} = "' . $conf_dir . '";
		};
		use App::LXC::Container;
		do("' . T_PATH . '/functions/call_with_stdin.pl");
		my $dummy_obj = { MAIN_UI => UI::Various::Main->new() };
		$dummy_obj = bless $dummy_obj, "App::LXC::Container::Setup";
		UI::Various::logging("DEBUG_3") if ' . $debug . ';
		my @input = qw(' . $input . ');
		_call_with_stdin
		(\@input,
		 sub {
		     App::LXC::Container::Setup' .
		     ($call_new
		      ? '->new("dummy");'
		      : '::_init_config_dir($dummy_obj);') .
		'});');
}

sub check_config_file($$$&$)
{
    my ($name, $file, $size, $src_func, $re_content) = @_;
    ok(-f $file, $name . ' exist');
    ok(-s $file > $size, $name . ' is not empty');
    if ($src_func)
    {
	my @content = &$src_func();
	local $_ =
	    App::LXC::Container::Setup::_create_or_compare($file, @content);
	is($_, 0, $name . ' is deterministic');
	like(join("\n", @content), qr/^.*$re_content.*$/ms,
	     $name . ' has been created correctly');
    }
    else
    {
	open my $in, '<', $file  or  die "can't open $file: $!";
	local $_ = join("\n", <$in>);
	close $in;
	like($_, qr/^.*$re_content.*$/, $name . ' has been created correctly');
    }
}

#########################################################################
# regular expression parts for tests:
my $re_dialog_main =
    '^========== select or enter (configuration|LXC root) directory\n' .
    '^\s+select or enter (configuration|LXC root) directory\n' .
    '^<1>\s+\[ \.\. \][^<]+' .
    '^<2>[^<]+ \[ Quit \]\s+\[ OK \][^<]+' .
     '^<0> leave dialogue\s+^----- enter number to choose next step: [^<]+';
my $re_dialog_fs =
    '<1>\s+' .
    '^<\*> [^<]+' .
    '^<2>   [^<]+' .
    '^<3>[^<]+' .
    '^<0> leave box\s+^----- enter number to choose next step: [^<]+';
my $re_dialog_value =
    '^old value:\s+^new value\?[^<]+';
my $re_dialog_buttons =
    '^<1> \[ Quit \][^<]+'.
    '^<2> \[ OK \][^<]+' .
    '^<0> leave box\s+^----- enter number to choose next step: [^<]+';

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

#########################################################################
# failing and aborted tests of _init_config_dir:
chmod 0555, FAIL_PATH  or  die "can't chmod 0555 ", FAIL_PATH;
$_ = fail_in_sub_perl(HOME_PATH, FAIL_PATH, '2 2 2 2', 1);
like($_,
     qr{^aborting after the following error\(s\):\nPermission denied at }m,
     'bad configuration directory should fail');
# FIXME: additional diagnostic to try to find reason for deep recursion:
my $debug_ui = 0;
if (m/Deep recursion/)
{
    diag('HOME_PATH is ', HOME_PATH);
    diag('HOME_PATH really is ', Cwd::abs_path(HOME_PATH));
    diag('FAIL_PATH is ', FAIL_PATH);
    diag('FAIL_PATH really is ', Cwd::abs_path(FAIL_PATH));
    diag('activating UI::Various debugging');
    $debug_ui = 1;
}
$_ = fail_in_sub_perl(HOME_PATH, FAIL_PATH, '2 1 2 2', 0, $debug_ui);
diag("DEEP RECURSION:\n", $_)  if  $debug_ui  and  m/deep recursion/i;
like($_,
     qr{$re_dialog_main$re_dialog_buttons}ms,
     'aborting initialisation 1 looks correct');
ok(! -d HOME_PATH . '/conf', 'conf does not yet exist');
$_ = fail_in_sub_perl(HOME_PATH, FAIL_PATH, '2 2 2 1', 0, $debug_ui);
diag("DEEP RECURSION:\n", $_)  if  $debug_ui  and  m/deep recursion/i;
like($_,
     qr{$re_dialog_main$re_dialog_buttons}ms,
     'aborting initialisation 2 looks correct');
ok(! -d HOME_PATH . '/conf', 'conf still does not yet exist');
$_ = fail_in_sub_perl(FAIL_PATH, HOME_PATH, '2 2 2 2', 0, $debug_ui);
diag("DEEP RECURSION:\n", $_)  if  $debug_ui  and  m/deep recursion/i;
like($_,
     qr{^can't link '.*/t/tmp/fail/.lxc-configuration' to '.*/t/tmp/home': Permission denied at }m,
     'unwritable home directory should fail');
ok(-d HOME_PATH . '/conf', 'conf got created regardless of error');

eval {   App::LXC::Container::Setup::new('wrong-call', 'dummy');   };
like($@,
     qr{^bad call to App::LXC::Container::Setup->new.*$re_msg_tail},
     'bad call of App::LXC::Container::Setup->new fails');

#########################################################################
# tests of _init_config_dir:

# on smokers (no STDIN from TTY) we only use mockup (except for 'ls' and 'ldd'):
-t STDIN  and  $ENV{PATH} = T_PATH . '/mockup:' . $ENV{PATH};

my $re_dialog = join('',
		     $re_dialog_main,
		     $re_dialog_fs,
		     $re_dialog_value,
		     $re_dialog_fs,
		     $re_dialog_main,
		     $re_dialog_buttons,
		     $re_dialog_main,
		     $re_dialog_buttons
		    );

my @input = qw(1 3 lxc 0 2 2 2 2);
my $dummy_obj = { MAIN_UI => UI::Various::Main->new() };
$dummy_obj = bless $dummy_obj, "App::LXC::Container::Setup";
stdout_like
{   _call_with_stdin
	(\@input,
	 sub { App::LXC::Container::Setup::_init_config_dir($dummy_obj); });
}
    qr{$re_dialog}ms,
    'initialisation of configuration directory did not fail';

my $root_dir = TMP_PATH . '/lxc';
is(-d  $root_dir . '/conf', 1, 'configuration directories exist');
is(-l  HOME_PATH . '/.lxc-configuration', 1,
   'symbolic link to configuration directory exists');
check_config_file('network list',
		  $root_dir . '/.networks.lst',
		  70,
		  \&App::LXC::Container::Data::initial_network_list,
		  '1 is the LXC bridge');
check_config_file('LXC root file-system',
		  $root_dir . '/.root_fs',
		  12,
		  undef,
		  '^/var/lib/lxc\n$');
check_config_file('default network configuration',
		  $root_dir . '/conf/10-NET-default.conf',
		  200,
		  \&App::LXC::Container::Data::content_network_default,
		  '^lxc\.net\.0\.ipv4\.address = ');
check_config_file('default device configuration',
		  $root_dir . '/conf/20-DEV-default.conf',
		  120,
		  \&App::LXC::Container::Data::content_device_default,
		  '^lxc\.mount\.auto =( cgroup:ro| proc:mixed| sys:ro){3}$');
check_config_file('minimal default package configuration',
		  $root_dir . '/conf/30-PKG-default.packages',
		  160,
		  \&App::LXC::Container::Data::content_default_packages,
		  '^libc\b');
check_config_file('minimal network package configuration',
		  $root_dir . '/conf/31-PKG-network.packages',
		  100,
		  \&App::LXC::Container::Data::content_network_packages,
		  '^iproute2\b');
check_config_file('minimal default mount configuration',
		  $root_dir . '/conf/40-MNT-default.mounts',
		  300,
		  \&App::LXC::Container::Data::content_default_mounts,
		  '^/var/tmp\s+create=dir,rw\s+tmpfs$');
check_config_file('minimal network mount configuration',
		  $root_dir . '/conf/41-MNT-network.mounts',
		  120,
		  \&App::LXC::Container::Data::content_network_mounts,
		  '^/usr/share/ca-certificates\b');
check_config_file('minimal default filter configuration',
		  $root_dir . '/conf/50-NOT-default.filter',
		  600,
		  \&App::LXC::Container::Data::content_default_filter,
		  '^# common:$.*^/usr/lib\s+nomerge$.*'
		  . '^/var/backups\s+ignore$.*^/var/log\s+empty$');
check_config_file('minimal X11 package configuration',
		  $root_dir . '/conf/60-PKG-X11.packages',
		  100,
		  \&App::LXC::Container::Data::content_x11_packages,
		  '^fontconfig-config$');
check_config_file('minimal X11 mount configuration',
		  $root_dir . '/conf/61-MNT-X11.mounts',
		  200,
		  \&App::LXC::Container::Data::content_x11_mounts,
		  '^/usr/share/icons$');
check_config_file('minimal audio package configuration',
		  $root_dir . '/conf/70-PKG-audio.packages',
		  100,
		  \&App::LXC::Container::Data::content_audio_packages,
		  '^# list of mandatory packages needed for audio$');

#########################################################################
# re-runs:
stdout_like
{   _call_with_stdin
	(\@input,
	 sub { App::LXC::Container::Setup::_init_config_dir($dummy_obj); });
}
    qr{$re_dialog}ms,
    're-run with same directory did not fail';

$_ = fail_in_sub_perl(HOME_PATH, TMP_PATH, '1 3 home 0 2 2 2 2', 0, $debug_ui);
diag("DEEP RECURSION:\n", $_)  if  $debug_ui  and  m/deep recursion/i;
like($_,
     qr{^can't link '.*/t/tmp/home/.lxc-configuration' to '.*/t/tmp/home': File exists at }m,
     'existing link should fail');

#########################################################################
# missing branches run during initialisation:
stderr_like
{
    my @output = ('');
    App::LXC::Container::Setup::_create_or_compare
	    ($root_dir . '/conf/20-DEV-default.conf', @output);
}
    qr{/conf/20-DEV-default.conf differs from the standard configuration:\n\@\@},
    'differences from standard are reported as errors';
