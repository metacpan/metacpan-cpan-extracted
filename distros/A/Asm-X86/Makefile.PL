#!/usr/bin/perl -w

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $mod_file = 'lib/Asm/X86.pm';
my $mod_name = 'Asm::X86';

# Dynamic configuration is a workaround for systems where BSD tar
# is installed instead of GNU tar
sub conf {

	my $r = `tar --version`;
	my %cfg = (
		'dist' => {
			'COMPRESS' => 'gzip -9f',
			'SUFFIX' => 'gz'
		}
	);
	if ( $r =~ /BSD/io or $r =~ /libarchive/io ) {

		# TARFLAGS '--format gnutar' is a workaround for some Linux
		# systems where BSD tar is installed instead of GNU tar
		$cfg{'dist'}{'TARFLAGS'} = '--format gnutar -cvf';
		#return {'dist' => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz', 'TARFLAGS' => '--format gnutar -cvf' }};
	}
	return \%cfg;
}

WriteMakefile(
	NAME			=> $mod_name,
	AUTHOR			=> 'Bogdan Drozdowski <bogdro@cpan.org>',
	VERSION_FROM		=> $mod_file,
	ABSTRACT_FROM		=> $mod_file,
	PREREQ_PM => {
		'Test::More'	=> 0,
	},
	# Dynamic configuration is a workaround for systems where BSD tar
	# is installed instead of GNU tar
	#dist			=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', TARFLAGS => '--format gnutar -cvf' },
	CONFIGURE		=> \&conf,
	clean			=> { 'FILES' => 'Asm-X86-*' },
	LICENSE			=> 'perl_5',
	SIGN			=> '1',
	MIN_PERL_VERSION	=> '5.006',	# just because of 'Exporter'
	META_ADD		=> { provides => { $mod_name => {
					file => $mod_file,
					version => '0.61'
					}
				} },

	# When setting 'vendor', the module cannot be installed in local Perl
	#  installations.
	# When changing from 'vendor' to 'site', there are errors building
	#  RPM packages:
	# File not found using glob: .../rpmbuild/BUILDROOT/perl-Asm-X86-0.27-1-omv2015.0.noarch-buildroot/usr/share/man/man3/*
	# Found installed (but unpackaged) files: /usr/local/share/man/man3/Asm::X86.3pm
	# perl-Asm-X86.noarch: W: siteperl-in-perl-module /usr/lib/perl5/site_perl/5.20.3/Asm
	# perl-Asm-X86.noarch: W: siteperl-in-perl-module /usr/lib/perl5/site_perl/5.20.3/Asm/X86.pm
	# perl-Asm-X86.noarch: E: dir-or-file-in-usr-local (Badness: 50) /usr/local/share/man/man3/Asm::X86.3pm
	# (none): E: badness 50 exceeds threshold 49.
	#INSTALLDIRS		=> 'vendor',
	#INSTALLDIRS		=> 'site',
);
