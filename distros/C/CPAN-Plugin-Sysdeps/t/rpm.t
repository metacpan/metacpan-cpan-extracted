use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'Do not test on MSWin32' if $^O eq 'MSWin32';
    plan 'no_plan';
}

use File::Temp qw(tempdir);

use CPAN::Plugin::Sysdeps ();
my $cps = CPAN::Plugin::Sysdeps->new({os => 'linux', linuxdistro => 'fedora', linuxdistroversion => 39, linuxdistrocodename => ''});

is_deeply [$cps->_find_missing_rpm_packages()], [], 'no package specified - empty result';

my $tempdir = tempdir("cpan-plugin-sysdeps-rpm-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);
my $mocked_rpm = "$tempdir/rpm";
open my $ofh, '>', $mocked_rpm or die "Can't write $mocked_rpm: $!";
print $ofh <<"EOS" . <<'EOS';
#!$^X
EOS
use strict;
use warnings;
if      ("@ARGV" eq "--version") {
    print "Dummy rpm for testing purposes.\n";
} elsif ("@ARGV" eq "-q existing-package") {
    print <<EOF;
existing-package-8.0.1-6.fc38.x86_64
existing-package-8.2.1-4.fc39.x86_64
EOF
} elsif ("@ARGV" eq "-q existing-provided-package") {
    print <<EOF;
package existing-provided-package is not installed
EOF
    exit 1;
} elsif ("@ARGV" eq "-q --whatprovides existing-provided-package") {
    print <<EOF;
existing-package-2.37-16.fc38.x86_64
existing-package-2.38-14.fc39.x86_64
EOF
} elsif ("@ARGV" eq "-q non-existing-package") {
    print <<EOF;
package non-existing-package is not installed
EOF
    exit 1;
} elsif ("@ARGV" eq "-q --whatprovides non-existing-package") {
    print <<EOF;
no package provides non-existing-package
EOF
    exit 1;
} elsif ("@ARGV" eq "-q non-existing-provided-package") {
    print <<EOF;
package non-existing-provided-package is not installed
EOF
    exit 1;
} elsif ("@ARGV" eq "-q --whatprovides non-existing-provided-package") {
    print <<EOF;
no package provides non-existing-provided-package
EOF
    exit 1;
} elsif ("@ARGV" eq "-q existing-package non-existing-package") {
    print <<EOF;
package non-existing-package is not installed
existing-package-8.0.1-6.fc38.x86_64
existing-package-8.2.1-4.fc39.x86_64
EOF
    exit 1;
} else {
    die "No mock for arguments '@ARGV'";
}
EOS
close $ofh or die $!;
chmod 0755, $mocked_rpm;

$ENV{PATH} = "$tempdir:$ENV{PATH}";
SKIP: {
    my $out = `rpm --version`;
    skip "Cannot run mocked rpm script", 5
	if $out !~ /Dummy rpm for testing purposes/;

    is_deeply [$cps->_find_missing_rpm_packages('existing-package')], [], 'existing package';
    is_deeply [$cps->_find_missing_rpm_packages('existing-provided-package')], [], 'existing provided package';

    is_deeply [$cps->_find_missing_rpm_packages('non-existing-package')], ['non-existing-package'], 'non-existing package';
    is_deeply [$cps->_find_missing_rpm_packages('non-existing-provided-package')], ['non-existing-provided-package'], 'non-existing provided package';

    is_deeply [$cps->_find_missing_rpm_packages('existing-package', 'non-existing-package')], ['non-existing-package'], 'multiple packages';
}

__END__
