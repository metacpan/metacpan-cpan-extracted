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
