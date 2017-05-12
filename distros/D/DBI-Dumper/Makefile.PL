use 5.006001;
use ExtUtils::MakeMaker;
#use Inline::MakeMaker;

my $USE_INLINE_C = 1;
eval { require Inline };
if($@) {
	print << 'END_PRINT';

## INLINE MISSING ##

The module Inline is not available. With this module, the Inline::C extension
can be created to increase performance of DBI::Dumper by orders of magnitude.

DBI::Dumper does include a pureperl version of the string builder and will work
correctly, but it cannot reach the performance of the inlined c version.

END_PRINT
	my $ret = prompt("Continue installing DBI::Dumper?", "N");
	exit 255 if $ret !~ /^y/i;

	$USE_INLINE_C = 0;
}


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBI::Dumper',
    VERSION_FROM      => 'lib/DBI/Dumper.pm', # finds $VERSION
    PREREQ_PM         => {
		Parse::RecDescent => 0,
		Term::ReadKey => 0,
		DBI => 0,
	}, # e.g., Module::Name => 1.1
	EXE_FILES         => [qw(bin/dbidumper.pl)],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBI/Dumper.pm', # retrieve abstract from module
       AUTHOR         => 'Warren Smith <wsmith@cpan.org>') : ()),
);

sub MY::postamble {
	my $output = << 'END_POSTAMBLE';

all::
	# recreate grammar
	$(PERL) -MParse::RecDescent - grammar.prd DBI::Dumper::Grammar
	$(MV) -f Grammar.pm lib/DBI/Dumper/Grammar.pm

doc: lib/DBI/Dumper.pm
	pod2text lib/DBI/Dumper.pm > README

clean ::
	$(RM_RF) C.inl _Inline
END_POSTAMBLE

	if($USE_INLINE_C) {
		$output .= << 'END_POSTAMBLE';
all:: C.inl

C.inl::
	# precompile inline::c block
	$(PERL) -Mblib -MInline=_INSTALL_ -MDBI::Dumper::C -e1 1.00 $(INST_ARCHLIB)
END_POSTAMBLE

	}

	return $output;
}


