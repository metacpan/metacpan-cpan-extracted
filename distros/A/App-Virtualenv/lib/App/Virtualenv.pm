package App::Virtualenv;
=head1 NAME

App::Virtualenv - Perl virtual environment

=head1 VERSION

version 2.06

=head1 ABSTRACT

Perl virtual environment

	#!/bin/sh
	perl -MApp::Virtualenv -erun -- environment_path

See also: L<virtualenv.pl|https://metacpan.org/pod/distribution/App-Virtualenv/lib/App/Virtualenv/virtualenv.pl>

=head1 DESCRIPTION

App::Virtualenv is a Perl package to create isolated Perl virtual environments, like Python virtual environment.

=cut
use strict;
use warnings;
use v5.10.1;
use feature qw(switch);
no if ($] >= 5.018), 'warnings' => 'experimental';
use Config;
use FindBin;
use File::Basename;
use File::Copy;
use Cwd;
use ExtUtils::Installed;
use Lazy::Utils;


BEGIN
{
	require Exporter;
	our $VERSION     = '2.06';
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(main run);
	our @EXPORT_OK   = qw();
}


=head2 Functions

=head3 sh(@args)

runs shell program defined in SHELL environment variable, otherwise /bin/sh

@args: I<arguments of shell program>

return value: I<exit code of shell program>

=cut
sub sh
{
	my (@args) = @_;
	return _system((defined $ENV{SHELL})? $ENV{SHELL}: "/bin/sh", @args);
}

=head3 perl(@args)

runs Perl interpreter

@args: I<arguments of Perl interpreter>

return value: I<exit code of Perl interpreter>

=cut
sub perl
{
	my (@args) = @_;
	return _system($Config{perlpath}, @args);
}

=head3 activate($virtualenvPath)

activates Perl virtual environment

$virtualenvPath: I<virtual environment path>

return value: I<virtual environment path if success, otherwise undef>

=cut
sub activate
{
	my ($virtualenvPath) = @_;
	return unless defined($virtualenvPath) and length($virtualenvPath) > 0 and -d "$virtualenvPath/lib/perl5";
	$virtualenvPath = Cwd::realpath($virtualenvPath);

	deactivate(1);

	$ENV{_OLD_PERL_VIRTUAL_ENV} = $ENV{PERL_VIRTUAL_ENV};
	$ENV{PERL_VIRTUAL_ENV} = $virtualenvPath;

	$ENV{_OLD_PERL_VIRTUAL_PATH} = $ENV{PATH};
	$ENV{PATH} = "$virtualenvPath/bin".((defined $ENV{PATH})? ":${ENV{PATH}}": "");

	$ENV{_OLD_PERL_VIRTUAL_PERL5LIB} = $ENV{PERL5LIB};
	$ENV{PERL5LIB} = "$virtualenvPath/lib/perl5".((defined $ENV{PERL5LIB})? ":${ENV{PERL5LIB}}": "");

	$ENV{_OLD_PERL_VIRTUAL_PERL_LOCAL_LIB_ROOT} = $ENV{PERL_LOCAL_LIB_ROOT};
	$ENV{PERL_LOCAL_LIB_ROOT} = "$virtualenvPath";

	$ENV{_OLD_PERL_VIRTUAL_PERL_MB_OPT} = $ENV{PERL_MB_OPT};
	$ENV{PERL_MB_OPT} = "--install_base \"$virtualenvPath\"";

	$ENV{_OLD_PERL_VIRTUAL_PERL_MM_OPT} = $ENV{PERL_MM_OPT};
	$ENV{PERL_MM_OPT} = "INSTALL_BASE=$virtualenvPath";

	$ENV{_OLD_PERL_VIRTUAL_PS1} = $ENV{PS1};
	$ENV{PS1} = "(".basename($virtualenvPath).") ".((defined $ENV{PS1})? $ENV{PS1}: "");

	return $virtualenvPath;
}

=head3 deactivate($nondestructive)

deactivates Perl virtual environment

$nondestructive: I<leaves envionment variables as it is, unless there are old envionment variables>

return value: I<always 1>

=cut
sub deactivate
{
	my ($nondestructive) = @_;

	$nondestructive = not defined($ENV{PERL_VIRTUAL_ENV}) if not defined($nondestructive);

	$ENV{PERL_VIRTUAL_ENV} = $ENV{_OLD_PERL_VIRTUAL_ENV} if defined($ENV{_OLD_PERL_VIRTUAL_ENV}) or not $nondestructive;
	undef $ENV{_OLD_PERL_VIRTUAL_ENV};

	$ENV{PATH} = $ENV{_OLD_PERL_VIRTUAL_PATH} if defined($ENV{_OLD_PERL_VIRTUAL_PATH}) or not $nondestructive;
	undef $ENV{_OLD_PERL_VIRTUAL_PATH};

	$ENV{PERL5LIB} = $ENV{_OLD_PERL_VIRTUAL_PERL5LIB} if defined($ENV{_OLD_PERL_VIRTUAL_PERL5LIB}) or not $nondestructive;
	undef $ENV{_OLD_PERL_VIRTUAL_PERL5LIB};

	$ENV{PERL_LOCAL_LIB_ROOT} = $ENV{_OLD_PERL_VIRTUAL_PERL_LOCAL_LIB_ROOT} if defined($ENV{_OLD_PERL_VIRTUAL_PERL_LOCAL_LIB_ROOT}) or not $nondestructive;
	undef $ENV{_OLD_PERL_VIRTUAL_PERL_LOCAL_LIB_ROOT};

	$ENV{PERL_MB_OPT} = $ENV{_OLD_PERL_VIRTUAL_PERL_MB_OPT} if defined($ENV{_OLD_PERL_VIRTUAL_PERL_MB_OPT}) or not $nondestructive;
	undef $ENV{_OLD_PERL_VIRTUAL_PERL_MB_OPT};

	$ENV{PERL_MM_OPT} = $ENV{_OLD_PERL_VIRTUAL_PERL_MM_OPT} if defined($ENV{_OLD_PERL_VIRTUAL_PERL_MM_OPT}) or not $nondestructive;
	undef $ENV{_OLD_PERL_VIRTUAL_PERL_MM_OPT};

	$ENV{PS1} = $ENV{_OLD_PERL_VIRTUAL_PS1} if defined($ENV{_OLD_PERL_VIRTUAL_PS1}) or not $nondestructive;
	undef $ENV{_OLD_PERL_VIRTUAL_PS1};

	return 1;
}

=head3 create($virtualenvPath, $empty)

creates Perl virtual environment

$virtualenvPath: I<new virtual environment path>

$empty: I<create empty virtual environment>

return value: I<virtual environment path if success, otherwise undef>

=cut
sub create
{
	my ($virtualenvPath, $empty) = @_;
	return unless defined($virtualenvPath) and length($virtualenvPath) > 0;
	$virtualenvPath = Cwd::realpath($virtualenvPath);
	say "Creating Perl virtual environment: $virtualenvPath";

	deactivate();
	$ENV{PERL_MM_USE_DEFAULT} = 1;
	$ENV{NONINTERACTIVE_TESTING} = 1;
	$ENV{AUTOMATED_TESTING} = 1;

	require local::lib;
	local::lib->import($virtualenvPath);

	activate($virtualenvPath);

	perl("-MCPAN", "-e exit(defined(CPAN::Shell->force('install', 'CPAN'))? 0: 1);") unless $empty;

	my $pkgPath = dirname(__FILE__);

	say "Copying... bin/activate";
	copy("$pkgPath/Virtualenv/activate", "$virtualenvPath/bin/activate");
	chmod(0644, "$virtualenvPath/bin/activate");

	say "Copying... bin/sh.pl";
	copy("$pkgPath/Virtualenv/sh.pl", "$virtualenvPath/bin/sh.pl");
	chmod(0755, "$virtualenvPath/bin/sh.pl");

	say "Copying... bin/perl.pl";
	file_put_contents("$virtualenvPath/bin/perl.pl", "#!".shellmeta($Config{perlpath})."\n".file_get_contents("$pkgPath/Virtualenv/perl.pl"));
	chmod(0755, "$virtualenvPath/bin/perl.pl");
	symlink("perl.pl", "$virtualenvPath/bin/perl");

	say "Copying... bin/virtualenv.pl";
	copy("$pkgPath/Virtualenv/virtualenv.pl", "$virtualenvPath/bin/virtualenv.pl");
	chmod(0755, "$virtualenvPath/bin/virtualenv.pl");
	symlink("virtualenv.pl", "$virtualenvPath/bin/virtualenv");

	return $virtualenvPath;
}

=head3 findVirtualenvPath($virtualenvPath)

finds Perl virtual environment path by $virtualenvPath argument or activated virtual environment or running script or PERL5LIB environment variable

$virtualenvPath: I<virtual environment path>

return value: I<best matching virtual environment path>

=cut
sub findVirtualenvPath
{
	my ($virtualenvPath) = @_;
	$virtualenvPath = $ENV{PERL_VIRTUAL_ENV} if not (defined($virtualenvPath) and length($virtualenvPath) > 0 and -d "$virtualenvPath/lib/perl5");
	$virtualenvPath = "${FindBin::Bin}/.." if not (defined($virtualenvPath) and length($virtualenvPath) > 0 and -d "$virtualenvPath/lib/perl5") and ${FindBin::Bin} !~ qr'^(/usr/|/bin/)' and -d "${FindBin::Bin}/../lib/perl5";
	for (split(":", defined($ENV{PERL5LIB})? $ENV{PERL5LIB}: ""))
	{
		last if defined($virtualenvPath) and length($virtualenvPath) > 0 and -d "$virtualenvPath/lib/perl5";
		$virtualenvPath = "$_/../..";
	}
	return if not (defined($virtualenvPath) and length($virtualenvPath) > 0 and -d "$virtualenvPath/lib/perl5");
	return $virtualenvPath;
}

=head3 activate2($virtualenvPath, $inform)

activates Perl virtual environment by findVirtualenvPath function

$virtualenvPath: I<virtual environment path>

$inform: I<informs activated virtual environment path to STDERR if new activated path differs old one>

return value: I<activated best matching virtual environment path if success, otherwise undef>

=cut
sub activate2
{
	my ($virtualenvPath, $inform) = @_;
	my $oldVirtualenvPath = $ENV{PERL_VIRTUAL_ENV};
	$virtualenvPath = activate(findVirtualenvPath($virtualenvPath));
	if ($inform)
	{
		if (defined($virtualenvPath))
		{
			say STDERR "Perl virtual environment path: $virtualenvPath" if not defined $oldVirtualenvPath or $oldVirtualenvPath ne $virtualenvPath;
		} else
		{
			say STDERR "Perl virtual environment is not activated";
		}
	}
	return $virtualenvPath;
}

=head3 getInc($virtualenvPath)

gets array ref of include paths given virtual environment path or sitelib paths

$virtualenvPath: I<virtual environment path>

return value: I<array ref of paths>

=cut
sub getInc
{
	my ($virtualenvPath) = @_;
	my $perl5lib;
	$perl5lib = "$virtualenvPath/lib/perl5" if defined($virtualenvPath) and length($virtualenvPath) > 0 and -d "$virtualenvPath/lib/perl5";
	my $inc = [(defined($perl5lib)? ("$perl5lib/$Config{version}/$Config{archname}", "$perl5lib/$Config{version}", "$perl5lib/$Config{archname}", "$perl5lib"): ($Config{sitearch}, $Config{sitelib}))];
	@$inc = map(((length($_) < 1 or substr($_, -1, 1) ne "/")? "$_/": $_), @$inc);
	return $inc;
}

=head3 list(%params)

lists packages or modules or files by given %params

%params: I<parameters of function>

=over

one: I<output is one-column, by default 0>

detail: I<prints additional detail by given value: module or file. by default undef>

=back

return value: I<always 1>

=cut
sub list
{
	my %params = @_;
	my $inc = getInc(activate2(undef, 1));
	my $inst = ExtUtils::Installed->new(inc_override => $inc, extra_libs =>[]);
	my @packages = sort({lc($a) cmp lc($b)} $inst->modules());
	for my $packageName (grep({ my $package = $_; not defined($params{packages}) or not @{$params{packages}} or grep($_ eq $package, @{$params{packages}}) } @packages))
	{
		next if $packageName eq 'Perl';
		my $version = $inst->version($packageName);
		$version = "0" if not $version;
		if ($params{detail})
		{
			say sprintf("%-40s %10s", $packageName, $version) unless $params{one};
			my @files = sort({lc($a) cmp lc($b)} $inst->files($packageName, "all"));
			my $packlist_file = $inst->packlist($packageName)->packlist_file();
			unshift @files, $packlist_file if defined($packlist_file);
			for my $file (@files)
			{
				my $incPath = (grep($file =~ /^\Q$_\E/, @$inc))[0];
				my $relPath = ($file =~ /^\Q$incPath\E(.*)\.pm$/)[0] if defined($incPath);
				given ($params{detail})
				{
					when ("module")
					{
						if (defined($relPath))
						{
							my $module = $relPath;
							$module =~ s/\//::/g;
							print "  " unless $params{one};
							say $module;
						}
					}
					when ("file")
					{
						print "  " unless $params{one};
						say $file;
					}
				}
			}
			next;
		}
		if ($params{one})
		{
			say $packageName;
			next;
		}
		say sprintf("%-40s %10s", $packageName, $version);
	}
	return 1;
}

=head3 main(@argv)

App::Virtualenv main function to run on command-line

See also: L<virtualenv.pl|https://metacpan.org/pod/distribution/App-Virtualenv/lib/App/Virtualenv/virtualenv.pl>

@argv: I<command-line arguments>

return value: I<exit code of program>

=cut
sub main
{
	my (@argv) = @_;
	my $args = commandArgs({ valuableArgs => 0, noCommand => 1 }, @argv);
	my $cmd;
	for my $arg (grep(/^\-/, keys %$args))
	{
		my $newcmd;
		$newcmd = $arg if
			$arg =~ /^\-(h|\-help)$/ or
			$arg =~ /^\-(c|\-create)$/ or
			$arg =~ /^\-(l|\-list)$/ or
			$arg =~ /^\-(m|\-list-modules)$/ or
			$arg =~ /^\-(f|\-list-files)$/;
		if (defined($newcmd))
		{
			die "Argument $newcmd doesn't use with $cmd.\n" if defined($cmd);
			$cmd = $newcmd;
		}
	}
	$cmd = "-c" unless defined($cmd);
	given ($cmd)
	{
		when (/^\-(h|\-help)$/)
		{
			my @lines = getPodText(dirname(__FILE__)."/Virtualenv/virtualenv.pl", "ABSTRACT");
			$lines[0] = "virtualenv.pl";
			say join("\n", @lines);
		}
		when (/^\-(c|\-create)$/)
		{
			die "Perl virtual environment path must be specified.\n" unless defined($args->{parameters}->[0]) and length($args->{parameters}->[0]) > 0;
			create($args->{parameters}->[0], (exists($args->{'-e'}) or exists($args->{'--empty'})));
		}
		when (/^\-(l|\-list)$/)
		{
			list(one => (exists($args->{'-1'}) or exists($args->{'--one'})), packages => $args->{parameters});
		}
		when (/^\-(m|\-list-modules)$/)
		{
			list(one => (exists($args->{'-1'}) or exists($args->{'--one'})), packages => $args->{parameters}, detail => 'module');
		}
		when (/^\-(f|\-list-files)$/)
		{
			list(one => (exists($args->{'-1'}) or exists($args->{'--one'})), packages => $args->{parameters}, detail => 'file');
		}
	}
	return 0;
}

=head3 run

runs App::Virtualenv by main function with command-line arguments by @ARGV

return value: I<function doesn't return, exits with main function return code>

=cut
sub run
{
	exit main(@ARGV);
}


1;
__END__
=head1 PREVIOUS VERSION

Previous version of App::Virtualenv has include PiV(Perl in Virtual environment) to list/install/uninstall modules
using CPANPLUS API. Aimed with PiV making a package manager like Python pip. But Perl has various powerful package tools
mainly CPAN and cpanminus, CPANPLUS and etc. And also building a great package manager requires huge community support.
So, PiV is deprecated in version 2.xx.

You should uninstall previous version before upgrading from v1.xx: B<cpanm -U App::Virtualenv; cpanm -i App::Virtualenv;>

See also: L<App::Virtualenv 1.13|https://metacpan.org/release/ORKUN/App-Virtualenv-1.13>

=head2 Deprecated Modules

=over

=item *

App::Virtualenv::Piv

=item *

App::Virtualenv::Module

=item *

App::Virtualenv::Utils

=back

=head1 INSTALLATION

To install this module type the following

	perl Makefile.PL
	make
	make test
	make install

from CPAN

	cpan -i App::Virtualenv

You should uninstall previous version before upgrading from v1.xx: B<cpanm -U App::Virtualenv; cpanm -i App::Virtualenv;>

=head1 DEPENDENCIES

This module requires these other modules and libraries:

=over

=item *

local::lib

=item *

ExtUtils::Installed

=item *

CPAN

=item *

Cwd

=item *

Lazy::Utils

=back

=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/perl5-virtualenv>

B<CPAN> L<https://metacpan.org/release/App-Virtualenv>

=head1 SEE ALSO

=over

=item *

L<App::Virtualenv 1.13|https://metacpan.org/release/ORKUN/App-Virtualenv-1.13>

=item *

L<CPAN|https://metacpan.org/pod/CPAN>

=item *

L<App::cpanminus|https://metacpan.org/pod/App::cpanminus>

=item *

L<CPANPLUS|https://metacpan.org/pod/CPANPLUS>

=back

=head1 AUTHOR

Orkun Karaduman <orkunkaraduman@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman <orkunkaraduman@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
