use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";
use TestUtil;

use Test::More;
use CPAN::Plugin::Sysdeps ();

plan 'no_plan';

sub maybe_shift_sudo ($) {
    my $cmds_ref = shift;
    if ($< != 0) {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	is $cmds_ref->[0], 'sudo';
	shift @{ $cmds_ref };
    }
}

if ($^O ne 'MSWin32') {
    {
	for my $debinst (qw(apt-get aptitude)) {
	    my $p = CPAN::Plugin::Sysdeps->new($debinst);
	    my @cmds = $p->_install_packages_commands(qw(libfoo libbar));
	    is scalar(@cmds), 2;
	    is_deeply [ @{$cmds[0]}[0,1] ], [qw(sh -c)];
	    like $cmds[0][-1], qr{^echo.*Install package.*libfoo libbar.*read.*yn};
	    maybe_shift_sudo $cmds[-1];
	    is_deeply $cmds[-1], [$debinst, qw(install libfoo libbar)];
	}
    }

    {
	my $p = CPAN::Plugin::Sysdeps->new('batch', 'apt-get');
	my @cmds = $p->_install_packages_commands(qw(libfoo libbar));
	is scalar(@cmds), 1;
	maybe_shift_sudo $cmds[-1];
	is_deeply $cmds[-1], [qw(apt-get -y install libfoo libbar)];
    }

    {
	my $p = CPAN::Plugin::Sysdeps->new('interactive', 'apt-get');
	my @cmds = $p->_install_packages_commands(qw(libfoo libbar));
	is scalar(@cmds), 2;
	maybe_shift_sudo $cmds[-1];
	is_deeply $cmds[-1], [qw(apt-get install libfoo libbar)];
    }

    {
	my $p = CPAN::Plugin::Sysdeps->new('pkg');
	my @cmds = $p->_install_packages_commands(qw(libfoo libbar));
	is scalar(@cmds), 1;
	maybe_shift_sudo $cmds[0];
	is $cmds[-1][0], 'pkg';
	is $cmds[-1][-3], 'install';
	is $cmds[-1][-2], 'libfoo';
	is $cmds[-1][-1], 'libbar';
    }

    {
	my $p = CPAN::Plugin::Sysdeps->new('homebrew');
	my @cmds = $p->_install_packages_commands(qw(libfoo libbar));
	is scalar(@cmds), 2;
	is_deeply $cmds[-1], [qw(brew install libfoo libbar)];
    }
} else {
    {
	my $p = CPAN::Plugin::Sysdeps->new('chocolatey');
	my @cmds = $p->_install_packages_commands(qw(libfoo libbar));
	is scalar(@cmds), 1;
	like $cmds[-1][0], qr{^powershell .*Start-Process 'chocolatey'.*'install libfoo libbar'};
    }
}
