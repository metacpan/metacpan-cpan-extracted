
my @output_chain_libs = qw( OutputChain MakeCapital PassHtml SSIChain);

use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Apache::OutputChain',
	VERSION_FROM	=> 'OutputChain.pm',
###	PM		=> { map { ("$_.pm" => "\$(INST_LIBDIR)/$_.pm") } @output_chain_libs },
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
	PREREQ_PM => { 'Apache::Constants' => 0 },
	);

