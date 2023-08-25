# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 08-data.t".
#
# Without "Build" file it could be called with "perl -I../lib 08-data.t"
# or "perl -Ilib t/08-data.t".  This is also the command needed to find
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

use Test::More tests => 39;
use Test::Output;

#####################################
# prepare fixed environment:
use constant T_PATH => map { s|/[^/]+$||; $_ } Cwd::abs_path($0);
use constant TMP_PATH => T_PATH . '/tmp';

do(T_PATH . '/functions/sub_perl.pl');

BEGIN {
    delete $ENV{DISPLAY};
    $ENV{UI} = 'PoorTerm';	# PoorTerm allows easy testing
}

use App::LXC::Container::Data;

$App::LXC::Container::Data::_os_release =
    T_PATH . '/mockup-files/os-release-debian';

#########################################################################
# local helper functions:
sub check_singleton($$)
{
    my ($mockup, $expected) = @_;
    $mockup = T_PATH . '/mockup-files/' . $mockup;
    $_ = _sub_perl('
		use App::LXC::Container::Data;
		$App::LXC::Container::Data::_os_release = "' . $mockup . '";
		$_ = App::LXC::Container::Data::_singleton();
		defined $_  and  print $_->{OS};');
    if ($expected =~ m/^(\(\?\^u:)?\^/)
    {
	like($_, qr/^$expected$/,
	     'singleton output matched m/' . substr($expected, 5, 19) . '/...');
    }
    else
    {   is($_, $expected, "singleton returned expected '$expected'");   }
}

# reset _dpkg_status and depends_on for use with new (mocked) dpkg status file:
sub reset_dpkg_status($)
{
    App::LXC::Container::Data::_singleton->{STATUS} = undef;
    $App::LXC::Container::Data::Debian::_dpkg_status = $_[0];
}

sub check_comment_only_output($$@)
{
    my $function = shift;
    my $n = shift;
    local $_ = @_;
    is($_, $n, $function . ' returned correct number of output lines: ' . $_);
    $n = 0;
    like($_, qr{^#}, $function . ' returned a comment as line ' . ++$n)
	foreach @_;
}

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;
my $re_eval = qr{ at \(eval \d+\)(\[t/\d+-[a-z]+\.t:\d+\])? line 1\.$};
my $re__e = qr{ at -e line \d\.};
my $re_data_tail = qr{ at .+/Data\.pm line \d+\.$};

#########################################################################
# All tests here trigger code paths in Data.pm not triggered by the other
# tests:
my $path = $ENV{PATH};
$ENV{PATH} = '';
output_like
{   eval 'App::LXC::Container::Data::groups_of("root");';   }
    qr{^$},
    qr{^Can't exec "id": No such file or directory$re_data_tail},
    'id with empty PATH fails (STDERR)';
like($@,
     qr{^can't open 'id --groups root': No such file or directory$re_eval},
     'id with empty PATH fails ($@)');

eval {   App::LXC::Container::Data::find_executable('a/b');   };
like($@,
     qr{^INTERNAL ERROR .*: a/b may not contain directory$re_msg_tail},
     'executable with directory fails');

$ENV{PATH} = '.:/non-existent:/etc:' . $path;
$_ = App::LXC::Container::Data::find_executable('fstab');
is($_, undef, 'non-executable files are not found in PATH');
$ENV{PATH} = $path;

check_singleton('os-release-like', 'Debian');

check_singleton('os-release-not-found',
		qr{^can't open '.*/os-release-not-found': .+$re__e});

check_singleton('os-release-no-id',
		qr{^Can't determine OS \(distribution\)!  .+$re__e});

my $re1a = qr{aborting after the following error\(s\):\n};
my $re1b = qr{Can't locate App/LXC/Container/Data/Nonexistingdistribution.+\n};
my $re1c = qr{$re__e\n};
my $re2 = qr{unknown OS: Non-existing-distribution - .+$re__e};
check_singleton('os-release-unknown', qr{^$re1a$re1b$re1c$re2$});

# FIXME: remove when Smokers are OK: tests for distributions using unusual paths:
diag($_, ' is ', App::LXC::Container::Data::find_executable($_))
    foreach qw(ldd ls sh su);

#########################################################################
# All tests here trigger code paths in Data/Debian.pm not triggered by the
# other tests:
$ENV{PATH} = T_PATH . '/mockup:' . $ENV{PATH};
reset_dpkg_status(T_PATH . '/mockup-files/dpkg.status');
my $singleton = App::LXC::Container::Data::_singleton;
defined $singleton->{STATUS}  and  die '$singleton->{STATUS} already set';

my @list =
    App::LXC::Container::Data::depends_on('non-existing-package', 0);
$_ = @list;
is($_, 0, 'non-existing package has no dependencies');

@list = App::LXC::Container::Data::depends_on('libasound2-data', 0);
$_ = @list;
is($_, 0, 'libasound2-data package has no mandatory dependencies');
@list = App::LXC::Container::Data::depends_on('libasound2-data', 1);
is_deeply(\@list, [qw(alsa-ucm-conf alsa-topology-conf)],
	  'libasound2-data package recommends 2 packages');
@list = App::LXC::Container::Data::depends_on('libasound2-data', 2);
is_deeply(\@list, [qw(alsa-ucm-conf alsa-topology-conf alsa-utils)],
	  'libasound2-data package suggests 1 additional package');

# mockup-1 test depends on 06-update.t (+ indirectly 02-init.t & 03-setup.t):
@list = App::LXC::Container::Data::paths_of('mockup-1');
like(join(' ', '', @list), qr{^( [^ ]+/usr/bin/1chromium){3}$},
     'paths_of mockup-1 returns 3 identical entries');
eval {   App::LXC::Container::Data::paths_of('mockup-2');   };
like($@,
     qr{^INTERNAL ERROR .* dpkg-query --listfiles mockup-2: bad entry: fatal},
     'paths_of fails correctly for bad entry');
eval {   App::LXC::Container::Data::paths_of('mockup-3');   };
like($@,
     qr{^INTERNAL ERROR .* --listfiles failed to find anything for mockup-3},
     'paths_of fails correctly for empty package');

reset_dpkg_status(T_PATH . '/mockup-files/dpkg.status.missing');
eval {   App::LXC::Container::Data::depends_on('dummy', 0);   };
like($@,
     qr{^can't open '.*/mockup-files/dpkg\.status\.missing': No such file or},
     'non-existing dpkg.status fails correctly');
reset_dpkg_status(T_PATH . '/mockup-files/dpkg.status.bad-arch');
eval {   App::LXC::Container::Data::depends_on('dummy', 0);   };
like($@,
     qr{^can't determine package in .*/mockup-files/dpkg\.status\.bad-arch. },
     'Architecture entry without package fails correctly');
reset_dpkg_status(T_PATH . '/mockup-files/dpkg.status.bad-dep');
eval {   App::LXC::Container::Data::depends_on('dummy', 0);   };
like($@,
     qr{^can't determine package in .*/mockup-files/dpkg\.status\.bad-dep. },
     'Dependency entry without package fails correctly');

#########################################################################
# All tests here trigger code paths in Data/common.pm not triggered by the
# other tests:

$_ = App::LXC::Container::Data::common::new();
is($_, $singleton, 'call to common::new returned correct singleton');

$ENV{ALC_MINIMAL_SEARCH}='on';
@list = App::LXC::Container::Data::content_audio_packages();
check_comment_only_output('content_audio_packages (no package)', 2, @list);

$ENV{PATH} = '';
@list = App::LXC::Container::Data::content_audio_packages();
check_comment_only_output('content_audio_packages (not in path)', 2, @list);

eval {   App::LXC::Container::Data::content_default_packages();   };
like($@, qr{^mandatory package for ldd is missing$re_data_tail},
     'missing mandatory executable causes fatal error');

@list = App::LXC::Container::Data::content_network_packages();
check_comment_only_output('content_network_packages (not in path)', 2, @list);
$ENV{PATH} = T_PATH . '/mockup:' . $path;

@list = App::LXC::Container::Data::content_network_packages();
check_comment_only_output('content_network_packages (no package)', 2, @list);

@list = App::LXC::Container::Data::content_default_packages();
$_ = join("\n", @list);
unlike($_, qr{su},
       'content_default_packages did not add mocked su');
like($_, qr{^(#.*\n){5}coreutils\nlibc-bin$},
     'content_default_packages did add only coreutils and libc-bin');
# FIXME: remove when Smokers are OK:
unless (m/^coreutils$/m)
{
    diag('OS release: "', $App::LXC::Container::Data::_os_release, '"');
    diag('OS 1: "', $singleton->{OS}, '"');
    diag('OS 2: "', App::LXC::Container::Data::common::new()->{OS}, '"');
}

$singleton->{SYSTEM_DEFAULT} = '/non-existing';
eval {   App::LXC::Container::Data::content_network_default();   };
like($@,
     qr{^can't open '/non-existing': No such file or directory$re_data_tail},
     'non-existing network defaults file causes fatal error');

my $re_net =
    '# initial configuration derived from /.*:\n\n' .
    'lxc\.net\.0\.type\s*=\s*veth\n' .
    'lxc\.net\.0\.flags\s*=\s*up\n' .
    'lxc\.net\.0\.link\s*=\s*lxcbr0\n' .
    'lxc\.net\.0\.name\s*=\s*eth0\n' .
    'lxc\.net\.0\.ipv4\.address\s*=\s*10\.0\.3\.\$N/24\n' .
    'lxc\.net\.0\.hwaddr\s*=\s*00:16:3e:xx:xx:xx';
$singleton->{SYSTEM_DEFAULT} = T_PATH . '/mockup-files/network-named.conf';
@list = App::LXC::Container::Data::content_network_default();
$_ = join("\n", @list);
like($_, qr{^$re_net$}, 'content_network_default did set-up "named" network');

$singleton->{SYSTEM_DEFAULT} = T_PATH . '/mockup-files/network-empty.conf';
@list = App::LXC::Container::Data::content_network_default();
$_ = join("\n", @list);
like($_, qr{^$re_net$}, 'content_network_default did set-up "empty" network');

eval {   App::LXC::Container::Data::package_of('/');   };
like($@,
     qr{^INTERNAL ERROR .*: not a file: /$re_data_tail},
     'executable with directory fails');

eval {   App::LXC::Container::Data::common::_check_singleton(\@list);   };
$_ = 'reference to singleton is not correct: ARRAY != ' .
    'App::LXC::Container::Data::Debian';
like($@, qr{^$_$re_msg_tail}, 'broken singleton fails');
