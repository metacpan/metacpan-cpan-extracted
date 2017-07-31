#!/usr/bin/perl

# Copyright PROCURA B.V. (c) 2008-2017 H.Merijn Brand

require 5.008; # <- also see postamble at the bottom for META.yml
use strict;

use ExtUtils::MakeMaker;

my %wm = (
    NAME         => "Data::Peek",
    DISTNAME     => "Data-Peek",
    ABSTRACT     => "Extended/Modified debugging utilities",
    AUTHOR       => "H.Merijn Brand <h.merijn\@xs4all.nl>",
    VERSION_FROM => "Peek.pm",
    PREREQ_PM	 => { "DynaLoader"	 => 0,
		      "Data::Dumper"	 => 0,
		      "Test::More"	 => 0.88,
		      "Test::NoWarnings" => 0,
		      },
    clean        => { FILES => join " ", qw(
			 Peek.c.gcov
			 Peek.gcda
			 Peek.gcno
			 Peek.xs.gcov
			 cover_db
			 valgrind.log
			 )
		      },
    macro        => { TARFLAGS => "--format=ustar -c -v -f",
		      },
    );
$ExtUtils::MakeMaker::VERSION > 6.30 and $wm{LICENSE} = "perl";

unless (exists $ENV{AUTOMATED_TESTING} and $ENV{AUTOMATED_TESTING} == 1) {
    if (prompt ("Do you want to install module DP as a shortcut for Data::Peek ?", "y") =~ m/[yY]/) {
	local $/;
	open my $pm, "<", "Peek.pm" or die "CAnnot read Peek.pm: $!\n";
	my $vsn = do { <$pm> =~ m/^\$VERSION\s*=\s*"([0-9._]+)/m; $1 };
	close   $pm;

	(my $dp = <DATA>) =~ s/::VERSION::/"$vsn"/;
	open my $fh, ">", "DP.pm"   or die "Cannot open DP.pm: $!\n";
	print   $fh $dp;
	close   $fh;
	$wm{PM} = {
	    "Peek.pm" => '$(INST_LIB)/Data/Peek.pm',
	    "DP.pm"   => '$(INST_LIB)/DP.pm',
	    };
	$wm{clean}{FILES} .= " DP.pm";
	}
    }

$ENV{NO_SV_PEEK} and $wm{DEFINE} = "-DNO_SV_PEEK";

my $rv = WriteMakefile (%wm);

1;

package MY;

sub postamble
{
    my $valgrind = join " ", qw(
	PERL_DESTRUCT_LEVEL=2 PERL_DL_NONLAZY=1
	    valgrind
		--suppressions=sandbox/perl.supp
		--leak-check=yes
		--leak-resolution=high
		--show-reachable=yes
		--num-callers=50
		--log-fd=3
		$(FULLPERLRUN) "-MExtUtils::Command::MM" "-e"
		    "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')"
		    $(TEST_FILES) 3>valgrind.log
		    );

    my $min_vsn = ($] >= 5.010 && -d "xt" && ($ENV{AUTOMATED_TESTING} || 0) != 1)
	? join "\n" =>
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    ''
	: "";
    join "\n" =>
	'cover test_cover:',
	'	ccache -C',
	'	cover -test',
	'',
	'leakcheck:',
	"	$valgrind",
	'	-@tail -5 valgrind.log',
	'',
	'leaktest:',
	q{	sandbox/leaktest $(FULLPERLRUN) "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)},
	'',
	'spellcheck:',
	'	pod-spell-check --aspell --ispell',
	'',
	'checkmeta:	spellcheck',
	'	perl sandbox/genPPPort_h.pl',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	distmeta',
	'	perl sandbox/genMETA.pl',
	'',
	'tgzdist:	checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	$min_vsn;
    } # postamble

__END__
use Data::Peek;

BEGIN { *DP:: = \%Data::Peek:: }
$VERSION = ::VERSION::;

1;

=head1 NAME

DP - Alias for Data::Peek

=head1 SYNOPSIS

  perl -MDP -wle'print DPeek for DDual ($?, 1)'

=head1 DESCRIPTION

See L<Data::Peek>.

=head1 AUTHOR

H.Merijn Brand <h.m.brand@xs4all.nl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2014 H.Merijn Brand

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
