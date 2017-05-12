use 5.005;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Arch',
	DISTNAME => 'Arch',
	dist => {
		# default CP 'ln' is buggy, it changes source file permissions
		DIST_CP => 'cp',
		COMPRESS => 'gzip --best --force',
	},
	test => {
		TESTS => 'tests/*-[1-9]',
	},
	PM => {
		map {
			my $t = $_; $t =~ s!^perllib/!!;
			($_, '$(INST_LIB)/' . $t)
		} "perllib/Arch.pm", glob("perllib/Arch/*.pm"), glob("perllib/Arch/*/*.pm")
	},
	# this translation should not be needed, but MakeMaker is buggy again
	MAN3PODS => {
		map {
			my $t = $_; $t =~ s!^perllib/!!; 
			$t =~ s!/!::!g; $t =~ s/\.pm$//;
			($_, '$(INST_MAN3DIR)/' . "$t.3pm")
		} "perllib/Arch.pm", glob("perllib/Arch/*.pm"), glob("perllib/Arch/*/*.pm")
	},
	VERSION_FROM => 'perllib/Arch.pm',
	ABSTRACT_FROM => 'perllib/Arch.pm',
	AUTHOR => 'Mikhael Goikhman <migo@homemail.com>',
	LICENSE => 'gpl',
);

open MANIFEST, "<MANIFEST";
my @old_lines = grep !/^META.yml/, <MANIFEST>;
close MANIFEST;
my @new_lines = map { "$_\n" } (
	qw(
		AUTHORS
		COPYING
		Makefile.PL
		MANIFEST
		INSTALL
		NEWS
		README
		TODO
	),
	glob("doc/*"),
	"perllib/Arch.pm",
	glob("perllib/Arch/*.pm"),
	glob("perllib/Arch/*/*.pm"),
	glob("rpm/*"),
	glob("samples/*-[1-9]"),
	glob("tests/*-[1-9]"),
);
if (join(',', @old_lines) ne join(',', @new_lines)) {
	print "Creating MANIFEST file\n";
	open MANIFEST, ">MANIFEST" or die "Can't write MANIFEST: $!\n";
	print MANIFEST @new_lines;
	close MANIFEST;
}

sub MY::postamble {
	return <<'MAKE_FRAG';
test-network:
	@env USE_NETWORK=1 $(MAKE) test

debian:
	tla register-archive \
		http://arch.debian.org/arch/private/schizo/debian--2004 \
		2>/dev/null || true
	tla get schizo@debian.org--2004-primary/arch-perl-debian--debian debian

# Produce an rpm package using dist in place or from the given tarball
# Usage:
#   make rpm-dist
#   make release=1 rpm-dist
#   make rpm-this
#   make version=0.4.2 release=2 rpm-this
#   make rpm-dist cparams='--quiet' mparams='CFLAGS="-O2 -g"'

rpm-dist: dist rpm-this

rpm-this:
	(cd rpm && $(MAKE) $(AM_MAKEFLAGS) rpm) || exit 1

MAKE_FRAG
}
