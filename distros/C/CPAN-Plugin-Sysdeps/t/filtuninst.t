use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";
use TestUtil;

use Test::More;
use CPAN::Plugin::Sysdeps ();

my $p = eval { CPAN::Plugin::Sysdeps->new('dryrun') };
plan skip_all => "Construction failed: $@", 1 if !$p;
skip_on_darwin_without_homebrew;
skip_on_os('darwin', 'cannot use dummy packages for testing'); # in some installations homebrew fails with a stacktrace if a package is unknown
skip_on_os('openbsd', 'cannot use dummy packages for testing');
plan 'no_plan';

isa_ok $p, 'CPAN::Plugin::Sysdeps';

if ($p->{installer} =~ m{^(apt-get|pkg|pkg_add|homebrew|chocolatey|yum|dnf)$}) {
    {
	my @packages = $p->_filter_uninstalled_packages(qw(libdoesnotexist1 libdoesnotexist2));
	is_deeply \@packages, [qw(libdoesnotexist1 libdoesnotexist2)];
    }
    {
	my @packages = $p->_filter_uninstalled_packages('libdoesnotexist1 | libdoesnotexist2');
	is_deeply \@packages, [qw(libdoesnotexist1)];
    }
}
