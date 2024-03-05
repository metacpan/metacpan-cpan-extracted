use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";
use TestUtil;

use Getopt::Long;
use List::Util 'first';
use File::Temp 'tempdir';
use Test::More;

use CPAN::Plugin::Sysdeps ();
require_CPAN_Distribution;

sub os_release_test ($$$$$$);

plan skip_all => "Only works on linux" if $^O ne 'linux';
plan 'no_plan';

GetOptions(
    "os-release=s" => \my $os_release_file,
)
    or die "usage: $0 [--os-release /path/to/os-release]\n";

my $tempdir = tempdir("cpan-plugin-sysdeps-os-release-XXXXXXXX", TMPDIR => 1, CLEANUP => 1);

if ($os_release_file) {
    @CPAN::Plugin::Sysdeps::OS_RELEASE_PATH_CANDIDATES = ($os_release_file);
    diag "Use $os_release_file as /etc/os-release replacement";
    traverse_warnings_test();
}

{
    local @CPAN::Plugin::Sysdeps::OS_RELEASE_PATH_CANDIDATES = ("/this/file/does/not/exist/" . rand() . "/os-release");
    my $info = CPAN::Plugin::Sysdeps::_detect_linux_distribution_os_release();
    ok !$info, 'No error on missing os-release file';
}

# note: VERSION_CODENAME is missing here, but heuristics exist in _detect_linux_distribution_os_release()
os_release_test 'debian/wheezy', <<'EOF', 1, 'debian', 7, 'wheezy';
PRETTY_NAME="Debian GNU/Linux 7 (wheezy)"
NAME="Debian GNU/Linux"
VERSION_ID="7"
VERSION="7 (wheezy)"
ID=debian
ANSI_COLOR="1;31"
HOME_URL="http://www.debian.org/"
SUPPORT_URL="http://www.debian.org/support/"
BUG_REPORT_URL="http://bugs.debian.org/"
EOF

os_release_test 'debian/stretch', <<'EOF', 1, 'debian', 9, 'stretch';
PRETTY_NAME="Debian GNU/Linux 9 (stretch)"
NAME="Debian GNU/Linux"
VERSION_ID="9"
VERSION="9 (stretch)"
VERSION_CODENAME=stretch
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
EOF

os_release_test 'debian/bullseye', <<'EOF', 1, 'debian', 11, 'bullseye';
PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"
NAME="Debian GNU/Linux"
VERSION_ID="11"
VERSION="11 (bullseye)"
VERSION_CODENAME=bullseye
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
EOF

os_release_test 'raspbian 11', <<'EOF', 1, 'raspbian', 11, 'bullseye';
PRETTY_NAME="Raspbian GNU/Linux 11 (bullseye)"
NAME="Raspbian GNU/Linux"
VERSION_ID="11"
VERSION="11 (bullseye)"
VERSION_CODENAME=bullseye
ID=raspbian
ID_LIKE=debian
HOME_URL="http://www.raspbian.org/"
SUPPORT_URL="http://www.raspbian.org/RaspbianForums"
EOF

os_release_test 'debian/trixie versionless', <<'EOF', 1, 'debian', undef, 'trixie';
PRETTY_NAME="Debian GNU/Linux trixie/sid"
NAME="Debian GNU/Linux"
VERSION_CODENAME=trixie
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
EOF

os_release_test 'ubuntu:22.04', <<'EOF', 1, 'ubuntu', '22.04', 'jammy';
PRETTY_NAME="Ubuntu 22.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.4 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy
EOF

# no codename heuristics for non-debian
os_release_test 'centos:7', <<'EOF', 1, 'centos', 7, undef;
NAME="CentOS Linux"
VERSION="7 (Core)"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="7"
PRETTY_NAME="CentOS Linux 7 (Core)"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:7"
HOME_URL="https://www.centos.org/"
BUG_REPORT_URL="https://bugs.centos.org/"

CENTOS_MANTISBT_PROJECT="CentOS-7"
CENTOS_MANTISBT_PROJECT_VERSION="7"
REDHAT_SUPPORT_PRODUCT="centos"
REDHAT_SUPPORT_PRODUCT_VERSION="7"

EOF

os_release_test 'fedora:39', <<'EOF', 1, 'fedora', 39, '';
NAME="Fedora Linux"
VERSION="39 (Thirty Nine)"
ID=fedora
VERSION_ID=39
VERSION_CODENAME=""
PLATFORM_ID="platform:f39"
PRETTY_NAME="Fedora Linux 39 (Thirty Nine)"
ANSI_COLOR="0;38;2;60;110;180"
LOGO=fedora-logo-icon
CPE_NAME="cpe:/o:fedoraproject:fedora:39"
DEFAULT_HOSTNAME="fedora"
HOME_URL="https://fedoraproject.org/"
DOCUMENTATION_URL="https://docs.fedoraproject.org/en-US/fedora/f39/system-administrators-guide/"
SUPPORT_URL="https://ask.fedoraproject.org/"
BUG_REPORT_URL="https://bugzilla.redhat.com/"
REDHAT_BUGZILLA_PRODUCT="Fedora"
REDHAT_BUGZILLA_PRODUCT_VERSION=39
REDHAT_SUPPORT_PRODUCT="Fedora"
REDHAT_SUPPORT_PRODUCT_VERSION=39
SUPPORT_END=2024-11-12
EOF

os_release_test 'alpine', <<'EOF', 1, 'alpine', '3.18.4', undef;
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.18.4
PRETTY_NAME="Alpine Linux v3.18"
HOME_URL="https://alpinelinux.org/"
BUG_REPORT_URL="https://gitlab.alpinelinux.org/alpine/aports/-/issues"
EOF

os_release_test 'freebsd:14', <<'EOF', 1, 'freebsd', '14.0', undef;
NAME=FreeBSD
VERSION="14.0-STABLE"
VERSION_ID="14.0"
ID=freebsd
ANSI_COLOR="0;31"
PRETTY_NAME="FreeBSD 14.0-STABLE"
CPE_NAME="cpe:/o:freebsd:freebsd:14.0"
HOME_URL="https://FreeBSD.org/"
BUG_REPORT_URL="https://bugs.FreeBSD.org/"
EOF

SKIP: {
    my $info = CPAN::Plugin::Sysdeps::_detect_linux_distribution();
    # may happen for exotic or old linux distributions
    skip "Cannot detect linux distribution", if !$info;

    my $info_os_release;
    my $os_release_exists = first { -e $_ } @CPAN::Plugin::Sysdeps::OS_RELEASE_PATH_CANDIDATES;
    if ($os_release_exists) {
	$info_os_release = CPAN::Plugin::Sysdeps::_detect_linux_distribution_os_release();
	if (!$info_os_release) {
	    fail "Unexpected error: os-release file exists, but cannot be parsed";
	} else {
	    ok $info_os_release->{linuxdistro},         "via os-release: linuxdistro=$info_os_release->{linuxdistro}";
	    ok $info_os_release->{linuxdistroversion},  "via os-release: linuxdistroversion=$info_os_release->{linuxdistroversion}";
	    if ($info_os_release->{linuxdistrocodename}) {
		ok $info_os_release->{linuxdistrocodename}, "via os-release: linuxdistrocodename=$info_os_release->{linuxdistrocodename}";
	    } else {
		diag "linuxdistrocodename not defined";
	    }
	}
    }

    my $info_lsb_release;
    if (-x '/usr/bin/lsb_release') {
	$info_lsb_release = CPAN::Plugin::Sysdeps::_detect_linux_distribution_lsb_release();
	if (!$info_lsb_release) {
	    fail "Unexpected error: lsb_release exists, but output cannot be parsed";
	} else {
	    ok $info_lsb_release->{linuxdistro},         "via lsb_release: linuxdistro=$info_lsb_release->{linuxdistro}";
	    ok $info_lsb_release->{linuxdistroversion},  "via lsb_release: linuxdistroversion=$info_lsb_release->{linuxdistroversion}";
	    if (defined $info_lsb_release->{linuxdistrocodename}) {
		ok $info_lsb_release->{linuxdistrocodename}, "via lsb_release: linuxdistrocodename=$info_lsb_release->{linuxdistrocodename}";
	    } else {
		diag "linuxdistrocodename not defined";
	    }
	}
    }

    if ($info_os_release && $info_lsb_release) {
	is $info_lsb_release->{linuxdistro}, $info_os_release->{linuxdistro}, 'os-release vs lsb_release: compare linuxdistro';
	if ($info_os_release->{linuxdistro} eq 'ubuntu' || ($info_os_release->{linuxdistro} eq 'debian' && $info_os_release->{linuxdistroversion} >= 8)) {
	    # inconsistent codename handling seen in CentOS + Fedora
	    is $info_lsb_release->{linuxdistrocodename}, $info_os_release->{linuxdistrocodename}, 'os-release vs lsb_release: compare linuxdistrocodename';
	} else {
	    no warnings 'uninitialized'; # codename may be unef
	    diag "linuxdistrocodename comparison: lsb_release=$info_lsb_release->{linuxdistrocodename} os-release=$info_os_release->{linuxdistrocodename}";
	}
	if ($info_os_release->{linuxdistro} eq 'debian') {
	    (my $lsb_major_version = $info_lsb_release->{linuxdistroversion}) =~ s{\..*}{};
	    is $lsb_major_version, $info_os_release->{linuxdistroversion}, 'os-release vs lsb_release: compare linuxdistroversion (debian: only major version)';
	} elsif ($info_os_release->{linuxdistro} =~ m{^(ubuntu|fedora)$}) {
	    is $info_lsb_release->{linuxdistroversion}, $info_os_release->{linuxdistroversion}, 'os-release vs lsb_release: compare linuxdistroversion (ubuntu+fedora: full version comparison)';
	} else {
	    diag "linuxdistroversion comparison: lsb_release=$info_lsb_release->{linuxdistroversion} os-release=$info_os_release->{linuxdistroversion}";
	}
    }
}

sub os_release_test ($$$$$$) {
    my($name, $os_release_contents, $expected_info, $expected_linuxdistro, $expected_linuxdistroversion, $expected_linuxdistrocodename) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    (my $safe_name = $name) =~ s{[^A-Za-z0-9_-]}{_}g;
    my $test_os_release_file = "$tempdir/${safe_name}-os-release";
    open my $ofh, '>', $test_os_release_file
	or die "Error while writing $test_os_release_file: $!";
    print $ofh $os_release_contents;
    close $ofh
	or die $!;

    local @CPAN::Plugin::Sysdeps::OS_RELEASE_PATH_CANDIDATES = ($test_os_release_file);
    my $info = CPAN::Plugin::Sysdeps::_detect_linux_distribution_os_release();
    if ($expected_info) {
	ok $info, "expected information from os-release for $name";
    } else {
	ok !$info, "did not expect information from os-release for $name";
	return;
    }
    is $info->{linuxdistro},         $expected_linuxdistro,         "$name from os-release: detected linuxdistro";
    is $info->{linuxdistroversion},  $expected_linuxdistroversion,  "$name from os-release: detected linuxdistroversion";
    is $info->{linuxdistrocodename}, $expected_linuxdistrocodename, "$name from os-release: detected linuxdistrocodename";

    traverse_warnings_test();
}

sub traverse_warnings_test {
    my $cpandist = CPAN::Distribution->new(
	ID => 'X/XX/XXX/DummyDoesNotExist-1.0.tar.gz',
	CONTAINSMODS => { DummyDoesNotExist => undef },
    );

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $p = CPAN::Plugin::Sysdeps->new('apt-get', 'batch', 'dryrun');
    local $CPAN::Plugin::Sysdeps::TRAVERSE_ONLY = 1;
    $p->post_get($cpandist);
    is_deeply \@warnings, [], "no warnings while traversing";
}

__END__
