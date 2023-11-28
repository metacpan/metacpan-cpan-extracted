# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 03-setup.t".
#
# Without "Build" file it could be called with "perl -I../lib 03-setup.t"
# or "perl -Ilib t/03-setup.t".  This is also the command needed to find
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

use Test::More tests => 49;
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

BEGIN {
    delete $ENV{DISPLAY};
    $ENV{UI} = 'PoorTerm';	# PoorTerm allows easy testing
    # no testing outside of t:
    $ENV{HOME} = HOME_PATH;
    $ENV{LXC_DEFAULT_CONF_DIR} = TMP_PATH;
}

-f TMP_PATH . '/lxc/conf/10-NET-default.conf'
    or  die "$0 can only run after a successful invocation of t/02-init.t\n";

use App::LXC::Container;

# directory of mockup commands:
$ENV{PATH} = T_PATH . '/mockup:' . $ENV{PATH};

$App::LXC::Container::Data::_os_release =
    T_PATH . '/mockup-files/os-release-debian';

#########################################################################
# local helper functions:
sub fail_in_sub_perl($)
{
    my ($variant) = @_;
    if ($variant == 1)
    {
	return _sub_perl('
		BEGIN {   $ENV{LXC_DEFAULT_CONF_DIR} = "' . BAD_CONF . '";   };
		use App::LXC::Container;
		App::LXC::Container::setup("test");');
    }
    return _sub_perl('
		BEGIN {   $ENV{LXC_DEFAULT_CONF_DIR} = "' . BAD_CONF . '";   };
		use App::LXC::Container;
		App::LXC::Container::Setup::_save_configuration(undef);');
}

sub check_config_against_regexp($$$)
{
    my ($name, $nr, $re_content) = @_;
    my $file = CONF_ROOT . '/conf/' . $name;
    ok(-f $file, $name . ' exists after ' . $nr . ' run');
    if (-f $file)
    {
	open my $content, '<', $file;
	local $_ = join('', <$content>);
	close $content;
    SKIP:{
	    $re_content =~ m/\\A/  and  $^V < v5.20  and
		skip 'regexp \A seems to be broken in Perl < 5.18', 1;
	    like($_, $re_content,
		 $name . ' has correct content after ' . $nr . ' run');
	}
    }
    else
    {	fail($name . ' has correct content after ' . $nr . ' run');   }
}

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;
my $re_msg_tail_m = qr/ at $0 line \d{2,}\.?$/m;
my $re_msg_tail_eval = qr/ at \(eval \d+\)(?:\[$0:\d{2,}\])? line \d+\.?$/;

# initial clean-up, only needed for re-run:
_remove_file('/lxc/conf/' . $_) foreach('tt-CNF-test.master',
					'tt-MNT-test.mounts',
					'tt-NOT-test.filter',
					'tt-PKG-test.packages');

#########################################################################
# failing tests:

_remove_link(LXC_LINK);
_setup_dir('/home/.lxc-configuration');
$_ = fail_in_sub_perl(1);
like($_,
     qr{t/tmp/home/.lxc-configuration is not a symbolic link at -e line \d\.$}m,
     'bad configuration link should fail');
$_ = fail_in_sub_perl(2);
my $re = 'INTERNAL ERROR [^:]+: directory missing '
    . 'in _save_configuration at -e line \d\.';
like($_, qr/^$re$/m,
     'missing configuration directory should fail on save');
_remove_dir(LXC_LINK);
_setup_link(LXC_LINK, CONF_ROOT);

eval {   App::LXC::Container::setup('bad-name!');   };
like($@,
     qr/^The name of the container may only contain word char.*!$re_msg_tail/,
     'bad container name fails');
App::LXC::Container::Texts::debug(0);			# manual reset!

eval {
    App::LXC::Container::Setup::_write_to('t/tmp/not-existing-dir/file', '');
};
like($@,
     qr{^can't open 't/tmp/not-existing-dir/file': .*$re_msg_tail},
     'bad file name fails');

#########################################################################
# simple writing tests:

my $abs_test_file = HOME_PATH . '/write.tst';
my $test_file = '/home/write.tst';
output_like
{   App::LXC::Container::Setup::_write_to($abs_test_file, '42');   }
    qr{^$}, qr{^$},
    '1st writing test did not fail';
output_like
{   App::LXC::Container::Setup::_write_to($abs_test_file, '47');   }
    qr{^$}, qr{^$},
    '2nd writing test did not fail';
_chmod(0444, $test_file);
output_like
{   App::LXC::Container::Setup::_write_to($abs_test_file, '0');   }
    qr{^$}, qr{^using existing protected .*/t/tmp/home/write.tst$re_msg_tail},
    '3rd writing test produced warning';
my $output = '';
if (-f $abs_test_file)
{
    open my $in, '<', $abs_test_file
	or  die "can't open ", $abs_test_file, ': ', $!;
    $output = join('', <$in>);
    close $in;
}
is($output, "47\n", 'writing test produced expected output');
_remove_file($test_file);

#########################################################################
# regular expression parts for tests (hangs without possessive matching):
my $re_div = '----------\s++';
my $re_buttons_mp = '\[ - \]\s++\[ \+ \]\s++';
my $re_buttons_map = '\[ - \]\s++\[ \* \]\s++\[ \+ \]\s++';
my $re_buttons_mapp = '\[ - \]\s++\[ \* \]\s++\[ \+ \]\s++\[ \+\+ \]\s++';
my $re_listbox_head = '(?:<1> ++)?(?:0|[1-9][0-9]*-[1-9][0-9]*)/\d+\s++';
my $re_list_buttons_mp = $re_listbox_head . '[^[]*+' . $re_buttons_mp;
my $re_list_buttons_map = $re_listbox_head . '[^[]*+' . $re_buttons_map;
my $re_list_buttons_mapp = $re_listbox_head . '[^[]*+' . $re_buttons_mapp;
my $re_list_packages = 'packages\s++' . $re_list_buttons_mapp;
my $re_list_files = 'files\s++' . $re_list_buttons_map;
my $re_list_filter = 'filter\s++' . $re_list_buttons_map;
my $re_radio = '(?:<[1*]>\s++)?\([o ]\) ';
my $re_network =
    'network\s++' .
    $re_radio . 'none\s++' .
    $re_radio . 'local\s++' .
    $re_radio . 'full\s++' .
    $re_div;
my $re_features =
    'features\s++' .
    '\[[ X]\] X11\s++' .
    '\[[ X]\] audio\s++' .
    $re_div;
my $re_list_users = 'users\s++' . $re_list_buttons_mp;
my $re_main_buttons =
    '(?:<7> )?\[ Quit \]\s++' .
    '(?:<8> )?\[ Help \]\s++' .
    '(?:<9> )?\[ OK \]\s++';
my $re_select =
    '^<0> leave (box|dialogue|window)\s++' .
    '^----- enter number to choose next step: \d++\s++';
my $re_select_mp = '<1> \[ - \]\s++<2> \[ \+ \]\s++';
my $re_select_map = '<1> \[ - \]\s++<2> \[ \* \]\s++<3> \[ \+ \]\s++';
my $re_select_mapp =
    '<1> \[ - \]\s++<2> \[ \* \]\s++<3> \[ \+ \]\s++<4> \[ \+\+ \]\s++';
my $re_select_listbox =
    '^< ?0> ++leave listbox\s++' .
    '^enter selection(?: \(\+/- scrolls\))?: \d++\s++';
my $re_select_radio =
    '^enter selection \(0 to cancel\): \d++\s++';

my $re_window_content =
    '<1>\s++' .
    $re_div . $re_list_packages . $re_div .
    $re_div . $re_list_files . $re_div .
    $re_div . $re_list_filter . $re_div .
    $re_div . $re_network .
    $re_div . $re_features .
    $re_div . $re_list_users . $re_div .
    $re_main_buttons .
    $re_select;

my $re_main_window =
    '^========== test\s++' . $re_window_content;

my $re_main_box =
    '^<1> ' . $re_div . $re_list_packages . $re_div .
    '^<2> ' . $re_div . $re_list_files . $re_div .
    '^<3> ' . $re_div . $re_list_filter . $re_div .
    '^<4> ' . $re_div . $re_network .
    '^<5> ' . $re_div . $re_features .
    '^<6> ' . $re_div . $re_list_users . $re_div .
    $re_main_buttons .
    $re_select;

my $re_help =
    "^========== Help\n" .
    "    The first column .* on the host\\.\n" .
    '<1> \[ OK \]\s++' .
    $re_select;

my $re_2nd_cancel_ok = '^<2>\s++\[ Cancel \]\s++\[ OK \]\s++';
my $re_select_file_dialogue_inside =
    '^<1>\s++\[ \.\. \]\s++[^<]++' .
    $re_2nd_cancel_ok;
my $re_select_file_dialogue_package =
    '^========== (?:select files for packages\s++){2}' .
    $re_select_file_dialogue_inside;
my $re_select_file_dialogue_libraries =
    '^========== (?:select files for needed library packages\s++){2}' .
    $re_select_file_dialogue_inside;
my $re_select_file_dialogue_files =
    '^========== (?:select files and/or directory\s++){2}' .
    $re_select_file_dialogue_inside;
my $re_select_file_dialogue_filter =
    '^========== (?:select files and/or directory for filters\s++){2}' .
    $re_select_file_dialogue_inside;
my $re_select_file_box =
    '^<1>\s++<\*> \[ \.\. \]\s++[^<]++' .
    '^<2> [^<]++';
my $re_select_file_list =
    '(?:<\+/-> ++)?' . $re_listbox_head .
    '^(< ?[1-9]\d*>[ *]{3}\S++\s++)++' .
    $re_select_listbox;
my $re_select_cancel_ok_buttons = '<1> \[ Cancel \]\s++<2> \[ OK \]\s++';

my $re_modify_package_dialogue =
    '========== (?:modify chromium\s++){2}' .
    '^<1> (?:chromium|VI)\s++' .
    $re_2nd_cancel_ok . $re_select;

my $re_select_in_files_list =
    '(?:^<\+/-> ++)?' . $re_listbox_head .
    '(?:^< ?[1-9]\d*>[ *]{3}(  |OV|RW) /(?-s:.++)\s++){3,4}' .
    $re_select_listbox;
my $re_modify_perm_dialogue =
    '^========== (?:modify file permissions\s++){2}' .
    '^' .
    $re_radio . ' ++read-only access\s++' .
    $re_radio . 'OV overlay file-system \(hide original\)\s++' .
    $re_radio . 'RW read/write access\s++' .
    $re_2nd_cancel_ok;
my $re_perm_radio_select =
    '^<1>    read-only access\s++' .
    '^<2> OV overlay file-system \(hide original\)\s++' .
    '^<3> RW read/write access\s++' .
    $re_select_radio;

my $re_select_in_filter_list =
    '(?:^<\+/-> ++)?' . $re_listbox_head .
    '(?:^< ?[1-9]\d*>[ *]{3}(IG|CP|EM|NM) /(?-s:.++)\s++){3,6}' .
    $re_select_listbox;
my $re_modify_filter_dialogue =
    '^========== (?:modify type of filter\s++){2}' .
    '^' .
    $re_radio . 'IG ignore directory\s++' .
    $re_radio . 'CP copy from original \(at time of LXC update!\)\s++' .
    $re_radio . 'EM create empty\s++' .
    $re_radio . 'NM don.t merge sub-directories into directory\s++' .
    $re_2nd_cancel_ok;
my $re_filter_radio_select =
    '^<1> IG ignore directory\s++' .
    '^<2> CP copy from original \(at time of LXC update!\)\s++' .
    '^<3> EM create empty\s++' .
    '^<4> NM don.t merge sub-directories into directory\s++' .
    $re_select_radio;

my $re_modify_network =
    '<1> none\s++' .
    '<2> local\s++' .
    '<3> full\s++' .
    $re_select_radio;

my $re_modify_features =
    'features\s++' .
    '<1> \[[ X]\] X11\s++' .
    '<2> \[[ X]\] audio\s++' .
    $re_select;

my $re_user = '\d++:[-a-z_A-Z.0-9]++';	# user names as in sub regular_users
my $re_select_user_dialogue =
    '^========== (?:select users\s++){2}' .
    '^' . $re_listbox_head .
    '(?:(?:\* )?' . $re_user . '\s++)*+' .
    $re_2nd_cancel_ok;
my $re_select_user_list =
    $re_listbox_head .
    '(?:^< ?[1-9]\d*> [ *] ' . $re_user . '\s++)++' .
    $re_select_listbox;

$_=    '
';

my $re_error_to_small = '^screen [0-9x]+ to small for window, ' .
    'need >= [0-9x]+ for all UI variants' . $re_msg_tail_m;
my $re_bad_interpreter = "bad interpreter '.*/usr/bin/1chromium' doesn't" .
    ' use ld-linux.so for dynamic linkage at ';

# PS:	Yes, I have a little helper script to analyse the error output of a
#	running Perl test script (to see where a regular expression fails to
#	match ;-).

#########################################################################
# 1st round: run help and quit

my @input = qw(1 8 1 7);
my $re_output =
    $re_main_window .
    $re_main_box .
    $re_help .
    $re_main_box .
    '$';
$ENV{ALC_DEBUG} = 0;		# cover branch in App::LXC::Container::setup
output_like
{   _call_with_stdin(\@input, sub { App::LXC::Container::setup("test"); });   }
    qr{$re_output}ms,
    qr{$re_error_to_small},
    'help and quit printed expected output';
$ENV{ALC_DEBUG} = 'x';

#########################################################################
# 2nd round: run and save defaults without any modifications:

@input = qw(1 9);
$re_output =
    $re_main_window .
    $re_main_box .
    '$';
output_like
{   _call_with_stdin(\@input, sub { App::LXC::Container::setup("test"); });   }
    qr{$re_output}ms,
    qr{$re_error_to_small},
    'saving unmodified initial configuration printed expected output';
delete $ENV{ALC_DEBUG};
check_config_against_regexp('tt-CNF-test.master', '2nd',
			    qr{^network=0\nx11=0\naudio=0\nusers=$}m);
check_config_against_regexp('tt-MNT-test.mounts', '2nd',
			    qr{\A# mounts for container test$}m);
check_config_against_regexp('tt-NOT-test.filter', '2nd',
			    qr{^\n/var/log\s+empty$}m);
check_config_against_regexp('tt-PKG-test.packages', '2nd',
			    qr{\A# package list for container test$}m);

#########################################################################
# 3rd round:
# run (read previous), modify several items, save with modifications:

# create dummy file-system:
_setup_dir('/usr');
_setup_dir('/usr/bin');
_setup_file('/usr/bin/1chromium');
_setup_file('/usr/bin/2something');
_setup_dir('/var');
_setup_dir('/var/log');

$App::LXC::Container::Setup::_initial_pkg_dir = TMP_PATH . '/usr/bin';
$App::LXC::Container::Setup::_initial_file_dir = TMP_PATH . '/usr/bin';

# And now follows one huge sequence of selections and an even huger regular
# expression checking the output of this! (Warning for the fainthearted ;-):

@input = (qw(1 1));		# -> packages box
$re_output =
    $re_main_window .					# 1
    $re_main_box;					# 1

push @input,
    qw(2 3 1 2 1 0 0 2 2 0),	# add a binary (mock: package chromium)
    qw(2 3 1 2 1 0 0 2 2 0),	# same again
    qw(2 3 1 2 1 0 0 2 1 0),	# same again, but cancel
    qw(2 3 1 2 2 0 0 2 2 0);	# try missing package (2something)
$re_output .=
    '(?:' .
    $re_list_packages . $re_select .			# 2
    $re_select_mapp . $re_select .			# 3
    $re_select_file_dialogue_package . $re_select .	# 1
    $re_select_file_box . $re_select .			# 2
    '(?:' . $re_select_file_list . '){2}' .		# 1 (or 2), 0
    $re_select_file_box . $re_select .			# 0
    $re_select_file_dialogue_package . $re_select .	# 2
    $re_select_cancel_ok_buttons . $re_select .		# 2 (or 1)
    $re_select_mapp . $re_select .			# 0
    '){4}';						# same/similar again
push @input,
    qw(2 3 1 2 0 0 2 2 0);	# try adding directory
$re_output .=
    $re_list_packages . $re_select .			# 2
    $re_select_mapp . $re_select .			# 3
    $re_select_file_dialogue_package . $re_select .	# 1
    $re_select_file_box . $re_select .			# 2
    $re_select_file_list .				# 0
    $re_select_file_box . $re_select .			# 0
    $re_select_file_dialogue_package . $re_select .	# 2
    $re_select_cancel_ok_buttons . $re_select .		# 2
    $re_select_mapp . $re_select;			# 0

push @input,
    qw(2 2 0),			# try modifying without selection
    qw(1 1 0 2 2 1 VI 2 1 0),	# modify (not) 1st of the 2
    qw(2 2 1 VI 2 2 0),		# modify 1st of the 2
    qw(1 1 0);			# remove selection for next test!
$re_output .=
    $re_list_packages . $re_select .			# 2
    '(?:' . $re_select_mapp . $re_select . '){2}' .	# 2, 0
    $re_list_packages . $re_select .			# 1
    '1-2/2\s++' . '(?:<[12]>   chromium\s++){2}' .
    $re_select_listbox .				# 1
    '1-2/2\s++' . '(?:<[12]> [ *] chromium\s++){2}' .
    $re_select_listbox .				# 0
    $re_list_packages . $re_select .			# 2
    $re_select_mapp . $re_select .			# 2
    $re_modify_package_dialogue .			# 1
    'old value: chromium\s++new value\?\s++' .		# VI
    $re_modify_package_dialogue .			# 2
    $re_select_cancel_ok_buttons . $re_select .		# 1
    $re_select_mapp . $re_select .			# 0
    $re_list_packages . $re_select .			# 2
    $re_select_mapp . $re_select .			# 2
    $re_modify_package_dialogue .			# 1
    'old value: chromium\s++new value\?\s++' .		# VI
    $re_modify_package_dialogue .			# 2
    $re_select_cancel_ok_buttons . $re_select .		# 2
    $re_select_mapp . $re_select .			# 0
    $re_list_packages . $re_select .			# 1
    '1-2/2\s++' . '(?:<[12]> [ *] (?:chromium|VI)\s++){2}' .
    $re_select_listbox .				# 1
    '1-2/2\s++' . '(?:<[12]>   (?:chromium|VI)\s++){2}' .
    $re_select_listbox;					# 0

push @input,
    qw(2 1 0),			# try removing without selection
    qw(1 1 0 2 1 0);		# remove 1st of the 2
$re_output .=
    $re_list_packages . $re_select .			# 2
    '(?:' . $re_select_mapp . $re_select . '){2}' .	# 1, 0
    $re_list_packages . $re_select .			# 1
    '1-2/2\s++' . '(?:<[12]>   (?:chromium|VI)\s++){2}' .
    $re_select_listbox .				# 1
    '1-2/2\s++' . '(?:<[12]> [ *] (?:chromium|VI)\s++){2}' .
    $re_select_listbox .				# 0
    $re_list_packages . $re_select .			# 2
    '(?:' . $re_select_mapp . $re_select . '){2}';	# 1, 0

push @input,
    qw(2 4 1 2 1 0 0 2 2 0);	# try adding ldd dependency (and fail)
$re_output .=
    $re_list_packages . $re_select .			# 2
    $re_select_mapp . $re_select .			# 4
    $re_select_file_dialogue_libraries . $re_select .	# 1
    $re_select_file_box . $re_select .			# 2
    '(?:' . $re_select_file_list . '){2}' .		# 1, 0
    $re_select_file_box . $re_select .			# 0
    $re_select_file_dialogue_libraries . $re_select .	# 2
    $re_select_cancel_ok_buttons . $re_select .		# 2
    $re_select_mapp . $re_select;			# 0

push @input, qw(0 2);		# .. -> files box
$re_output .=
    $re_list_packages . $re_select .			# 0
    $re_main_box;					# 2

push @input,
    qw(2 3 1 2 2 0 0 2 2 0),	# add a file (2something)
    qw(2 3 1 2 2 0 0 2 2 0),	# same again
    qw(2 3 1 2 2 0 0 2 2 0),	# same again
    qw(2 3 1 2 2 0 0 2 2 0),	# same again
    qw(2 3 1 2 2 0 0 2 1 0);	# same again, but cancel
$re_output .=
    '(?:' .
    $re_list_files . $re_select .			# 2
    $re_select_map . $re_select .			# 3
    $re_select_file_dialogue_files . $re_select .	# 1
    $re_select_file_box . $re_select .			# 2
    '(?:' . $re_select_file_list . '){2}' .		# 2,0
    $re_select_file_box . $re_select .			# 0
    $re_select_file_dialogue_files . $re_select .	# 2
    $re_select_cancel_ok_buttons . $re_select .		# 2 (or 1)
    $re_select_map . $re_select .			# 0
    '){5}';						# same/similar again

push @input, qw(1 1 0 2 1 0);	# remove 1st of the 4
$re_output .=
    $re_list_files . $re_select .			# 1
    '(?:' . $re_select_in_files_list . '){2}' .		# 1, 0
    $re_list_files . $re_select .			# 2
    '(?:' . $re_select_map . $re_select . '){2}';	# 1, 0

push @input,
    qw(2 2 0),			# try modifying without selection
    qw(1 2 0 2 2 1 2 2 2 0),	# modify 2nd as OV
    qw(1 3 0 2 2 1 3 2 2 0),	# modify 3rd as RW
    qw(1 2 0 2 2 1 1 2 1 0);	# modify 2nd as '  ', but cancel
$re_output .=
    $re_list_files . $re_select .			# 2
    '(?:' . $re_select_map . $re_select . '){2}' .	# 2, 0
    '(?:' .
    $re_list_files . $re_select .			# 1
    '(?:' . $re_select_in_files_list . '){2}' .		# 2 or 3, 0
    $re_list_files . $re_select .			# 2
    $re_select_map . $re_select .			# 2
    $re_modify_perm_dialogue . $re_select .		# 1
    $re_perm_radio_select .				# 2 or 3
    $re_modify_perm_dialogue . $re_select .		# 2
    $re_select_cancel_ok_buttons . $re_select .		# 2
    $re_select_map . $re_select .			# 0
    '){3}';						# similar again

push @input, qw(0 3);		# .. -> filter box
$re_output .=
    $re_list_files . $re_select .			# 0
    $re_main_box;					# 3

push @input,
    qw(2 3 1 2 2 0 0 2 2 0),	# add a file (2something)
    qw(2 3 1 2 2 0 0 2 2 0),	# same again
    qw(2 3 1 2 2 0 0 2 2 0);	# same again
$re_output .=
    '(?:' .
    $re_list_filter . $re_select .			# 2
    $re_select_map . $re_select .			# 3
    $re_select_file_dialogue_filter . $re_select .	# 1
    $re_select_file_box . $re_select .			# 2
    '(?:' . $re_select_file_list . '){2}' .		# 2,0
    $re_select_file_box . $re_select .			# 0
    $re_select_file_dialogue_filter . $re_select .	# 2
    $re_select_cancel_ok_buttons . $re_select .		# 2
    $re_select_map . $re_select .			# 0
    '){3}';						# same again

push @input,
    qw(1 2 0 2 2 1 2 2 2 0),	# modify 2nd new as CP
    qw(1 3 0 2 2 1 4 2 2 0);	# modify 3rd new as NM
$re_output .=
    '(?:' .
    $re_list_filter . $re_select .			# 1
    '(?:' . $re_select_in_filter_list . '){2}' .	# 2 or 3, 0
    $re_list_filter . $re_select .			# 2
    $re_select_map . $re_select .			# 2
    $re_modify_filter_dialogue . $re_select .		# 1
    $re_filter_radio_select .				# 2 or 4
    $re_modify_filter_dialogue . $re_select .		# 2
    $re_select_cancel_ok_buttons . $re_select .		# 2
    $re_select_map . $re_select .			# 0
    '){2}';						# similar again

push @input, qw(0 4 2);		# .. -> network box, local network
$re_output .=
    $re_list_filter . $re_select .			# 0
    $re_main_box .					# 4
    $re_modify_network;					# 2

push @input, qw(5 1 2);		# features box, X11, audio
$re_output .=
    $re_main_box .					# 5
    '(?:' . $re_modify_features . '){2}';		# 1, 2

push @input, qw(0 6);		# .. -> user box
$re_output .=
    $re_modify_features .				# 0
    $re_main_box;					# 6

push @input,
    qw(2 2 1 1 0 2 2 0),	# add 1st user found
    qw(2 2 1 1 0 2 2 0),	# same again
    qw(2 2 1 1 0 2 1 0);	# same again, but cancel
$re_output .=
    '(?:' .
    $re_list_users . $re_select .			# 2
    $re_select_mp . $re_select .			# 2
    $re_select_user_dialogue . $re_select .		# 1
    '(?:' . $re_select_user_list . '){2}' .		# 1, 0
    $re_select_user_dialogue . $re_select .		# 2
    $re_select_cancel_ok_buttons . $re_select .		# 2
    $re_select_mp . $re_select .			# 0
    '){3}';						# same again
push @input,
    qw(2 1 0),			# try removing without selection
    qw(1 1 0 2 1 0);		# remove 2nd of the 2
$re_output .=
    $re_list_users . $re_select .			# 2
    '(?:' . $re_select_mp . $re_select . '){2}' .	# 1, 0
    $re_list_users . $re_select .			# 1
    '1-2/2\s++' . '(?:<[12]>   ' . $re_user . '\s++){2}' .
    $re_select_listbox .				# 1
    '1-2/2\s++' . '(?:<[12]> [ *] ' . $re_user . '\s++){2}' .
    $re_select_listbox .				# 0
    $re_list_users . $re_select .			# 2
    '(?:' . $re_select_mp . $re_select . '){2}';	# 1, 0

push @input, qw(0 9);		# leave user box, save and quit
$re_output .=
    $re_list_users . $re_select .			# 0
    $re_main_box . '$';					# 9

output_like
{   _call_with_stdin(\@input, sub { App::LXC::Container::setup("test"); });   }
    qr{$re_output}ms,
    qr{$re_error_to_small\s+$re_bad_interpreter},
    'modifying everything printed expected output';

my @big_stat = (scalar(@input), length($re_output));

#########################################################################
# now check configuration created by above monster-test:
check_config_against_regexp
    ('tt-CNF-test.master', '3rd',
     qr{^network=1\nx11=1\naudio=1\nusers=$re_user$}m);
check_config_against_regexp
    ('tt-MNT-test.mounts', '3rd',
     qr{\A\#\ mounts\ for\ container\ test$
	.*/t/tmp/usr/bin/2something$
	.*/t/tmp/usr/bin/2something\s+create=file,rw\s+tmpfs$
	.*/t/tmp/usr/bin/2something\s+create=file,rw,bind$}msx);
check_config_against_regexp
    ('tt-NOT-test.filter', '3rd',
     qr{^/var/log\s+empty\n
	.*/t/tmp/usr/bin/2something\s+copy\n
	.*/t/tmp/usr/bin/2something\s+nomerge\n
	.*/t/tmp/usr/bin/2something\s+ignore\n}mx);
check_config_against_regexp
    ('tt-PKG-test.packages', '3rd',
     qr{\A# package list for container test\n.*^chromium\n\Z}ms);

#########################################################################
# 4th round: read modified configuration again:

@input = qw(1 7);
$re_output =
    $re_main_window .
    $re_main_box .
    '$';
output_like
{   _call_with_stdin(\@input, sub { App::LXC::Container::setup("test"); });   }
    qr{$re_output}ms,
    qr{$re_error_to_small},
    'reading modified configuration again did not cause any errors';

#########################################################################
# simulate invalid configuration entries and other fatal errors:
eval {   App::LXC::Container::Setup::_mark2filter('XX /bad-entry');   };
like($@,
     qr/^INTERNAL ERROR [^:]+: bad mark 'XX' in _mark2filter$re_msg_tail/,
     'bad filter entry fails');

eval {   App::LXC::Container::Setup::_mark2mount('YY /bad-entry');   };
like($@,
     qr/^INTERNAL ERROR [^:]+: bad mark 'YY' in _mark2mount$re_msg_tail/,
     'bad mount entry fails');

eval {   App::LXC::Container::Setup::_modify_entry(1,2,3, 1,2);   };
like($@,
     qr/^INTERNAL ERROR [^:]+: uneven list in _modify_entry$re_msg_tail/,
     'short parameter list for _modify_entry fails');
eval {   App::LXC::Container::Setup::_modify_entry(1,2,3, 1,2,3,4,5);   };
like($@,
     qr/^INTERNAL ERROR [^:]+: uneven list in _modify_entry$re_msg_tail/,
     'uneven parameter list for _modify_entry fails');

my $dummy_obj = {name => 'not-accessible'};
sub test_not_accessible($)
{
    my ($file) = @_;
    my $short_path = '/lxc/conf/' . $file;
    _remove_file($short_path);
    _setup_file($short_path);
    _chmod(0, $short_path);
    my $re = "can't open '" . LXC_LINK . '/conf/' . $file . "'" . ': .*'
	. $re_msg_tail_eval;
    (my $func = $file) =~ s/^.*\.//;
    $func = 'App::LXC::Container::Setup::_parse_' . $func . '($dummy_obj);';
    eval "$func";
    like($@, qr/^$re$/,
	 'reading non-accessible configuration file ' . $file . ' fails');
}
test_not_accessible('ne-NOT-not-accessible.filter');
test_not_accessible('ne-CNF-not-accessible.master');
test_not_accessible('ne-MNT-not-accessible.mounts');
test_not_accessible('ne-PKG-not-accessible.packages');

$dummy_obj = {name => 'bad'};
sub test_bad_config($@)
{
    my $file = shift;
    my $short_path = '/lxc/conf/' . $file;
    _remove_file($short_path);
    _setup_file($short_path, @_);
    my $re = "ignoring unknown configuration item in '" . LXC_LINK .
	'/conf/' . $file . "'" . ', line 1' . $re_msg_tail_eval;
    (my $func = $file) =~ s/^.*\.//;
    $func = 'App::LXC::Container::Setup::_parse_' . $func . '($dummy_obj);';
    output_like
    {	eval "$func";   }
    qr{^$}, qr/^$re$/,
    'reading bad configuration file ' . $file . ' fails';
}
test_bad_config('bd-NOT-bad.filter', 'bad entry');
test_bad_config('bd-CNF-bad.master', 'bad entry');
test_bad_config('bd-MNT-bad.mounts', 'bad-entry ');
test_bad_config('bd-PKG-bad.packages', 'bad entry');

#########################################################################
# simulate some more valid configuration entries:
like(App::LXC::Container::Setup::_mark2mount('RW /dev/disk'),
     qr{^/dev/disk\s+create=dir,rw,bind,optional$},
     'valid optional device directory');
like(App::LXC::Container::Setup::_mark2mount('RW /dev/somedevice'),
     qr{^/dev/somedevice\s+create=file,rw,bind,optional$},
     'valid optional device file');
like(App::LXC::Container::Setup::_mark2mount('OV /'),
     qr{^/\s+create=dir,rw\s+tmpfs$},
     'valid temporary directory');

#########################################################################
# run tests with other maximum screen sizes:
sub test_other_screen_size($$)
{
    my ($w, $h) = @_;
    my %dummy_obj = (MAIN_UI => UI::Various::Main->new(),
		     name => 'x', packages => [], mounts => [], filter => [],
		     network => 0, x11 => 0, audio => 0, users => []);
    # Unfortunately we need to access UI::Various internal structure here to
    # modify the maximum size of the virtual screen:
    $dummy_obj{MAIN_UI}{max_width} = $w;
    $dummy_obj{MAIN_UI}{max_height} = $h;
    return bless \%dummy_obj, 'App::LXC::Container::Setup';
};
output_like
{
    my $dummy_obj = test_other_screen_size(12, 99);
    App::LXC::Container::Setup::_create_main_window($dummy_obj);
}
    qr{^$}, qr{^$re_error_to_small},
    'narrow window causes error';
output_like
{
    my $dummy_obj = test_other_screen_size(99, 24);
    App::LXC::Container::Setup::_create_main_window($dummy_obj);
}
    qr{^$}, qr{^$re_error_to_small},
    'low window causes error';
output_like
{
    my $dummy_obj = test_other_screen_size(99, 99);
    App::LXC::Container::Setup::_create_main_window($dummy_obj);
}
    qr{^$}, qr{^$},
    'large enough window removed error';

#########################################################################
# special tests for library dependencies (ldd):
package Dummy::UI
{
    require Exporter;
    our @ISA = qw(Exporter);
    sub new($) { my $self = {}; bless $self, 'Dummy::UI'; }
    sub add($@) { shift; print "ADD2UI\t", join(',', @_), "\n"; }
};
sub test_ldd_dummy_object(@)
{
    my $dummy_ui = Dummy::UI->new();
    App::LXC::Container::Setup::__add_library_packages_internal_code
	    ($dummy_ui, @_);
}
if (-f '/bin/ls')
{
    diag(`echo \$PATH`, `ls -l t/mockup`, `file /bin/ls`, `ldd /bin/ls`);
    my @libs = App::LXC::Container::Data::libraries_used('/bin/ls');
    diag('LU:', join('|', @libs));
    foreach (@libs)
    { diag('PKG("',$_,'"):',App::LXC::Container::Data::package_of($_),'.'); }
}
else
{   diag('/bin/ls is missing!');   }
stdout_like
{   test_ldd_dummy_object('/bin/ls');   }
    qr{^ADD2UI\s+libc6(?::amd64|:i386)?$},
    'test for existing library dependencies';

_setup_file('/usr/bin/3ls');
_setup_link(TMP_PATH . '/usr/libbad.so.0', '/usr/non-existing-dir/libbad.so');
chmod 0755, T_PATH . '/mockup/ldd'
    or  die "can't chmod 0755 ", T_PATH . '/mockup/ldd';

stdout_like
{   test_ldd_dummy_object(TMP_PATH . '/usr/bin/3ls');   }
    qr{^$},
    'ldd test with bad symbolic link';

stdout_like
{   test_ldd_dummy_object('/nowhere/to/be/found');   }
    qr{^$},
    'test for non-existing library dependencies';
_remove_link(TMP_PATH . '/usr/libbad.so.0');

chmod 0644, T_PATH . '/mockup/ldd'
    or  die "can't chmod 0644 ", T_PATH . '/mockup/ldd';

#########################################################################
# final statistics:
diag('big test statistic: ', $big_stat[0],
     ' inputs checked against a regular expression of size ', $big_stat[1]);
