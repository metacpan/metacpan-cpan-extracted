#!/usr/bin/perl

# Copyright PROCURA B.V. (c) 2009-2025 H.Merijn Brand

use strict;

use ExtUtils::MakeMaker;
my $eummv = $ExtUtils::MakeMaker::VERSION;

my %wm = (
    NAME	  =>   "Config::Perl::V",
    DISTNAME	  =>   "Config-Perl-V",
    AUTHOR        =>   "H.Merijn Brand <h.m.brand\@xs4all.nl>",
    VERSION_FROM  =>   "V.pm",
    ABSTRACT_FROM =>   "V.pm",

    PREREQ_PM	  => { "Config"	=> 0,				},
    macro         => { TARFLAGS => "--format=ustar -c -v -f",	},
    );
$eummv >= 6.31 and $wm{LICENSE} = "perl";
my $section = $eummv >= 6.64 ? "TEST_REQUIRES" : "PREREQ_PM";
$wm{$section}{$_} = 0 for qw( Test::More Test::NoWarnings );

-d "xt" and $wm{test}{TESTS} = "t/*.t xt/*.t";

my $rv = WriteMakefile (%wm);

1;

package MY;

sub postamble {
    join "\n" =>
	'test::	doc',
	'',
	'cover test_cover:',
	'	ccache -C',
	'	cover -test',
	'',
	'spellcheck:',
	'	pod-spell-check --aspell --ispell',
	'',
	'checkmeta:	spellcheck',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	distmeta',
	'	perl sandbox/genMETA.pl',
	'	ls -l */META.yml',
	'',
	'tgzdist:	doc checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	'doc docs:		doc/Config-Perl-V.md doc/Config-Perl-V.html doc/Config-Perl-V.man',
	'doc/Config-Perl-V.md:		V.pm',
	'	perl doc/make-doc.pl',
	'';
    } # postamble

1;
