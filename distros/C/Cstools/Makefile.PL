
use Config;

use ExtUtils::MakeMaker;

my $VERSION = '3.42';

=comment

sub MY::dist {
	package MY; # so that "SUPER" works right
	my $inherited = shift->SUPER::dist(@_);
	$inherited =~ s/old text/new text/;
	$inherited;
}

=cut

sub MY::postamble {
	"
specversion: Makefile.PL Cstools.spec.dist
	echo Updating Cstools.spec
	\@\$(PERL) -pe 's/__VERSION__/$VERSION/' Cstools.spec.dist > Cstools.spec

rpm: dist
	rpm -tb -vv ../\$(DISTNAME)-\$(VERSION).tar.gz
";

	}

WriteMakefile(
	NAME		=> 'Cz',
	DISTNAME	=> 'Cstools',
	VERSION		=> $VERSION,
	PL_FILES	=> { 'bin/cstocs.PL' => 'bin/cstocs',
					'bin/cssort.PL' => 'bin/cssort',
					'bin/dbfcstocs.PL' => 'bin/dbfcstocs',
					},
	EXE_FILES	=> [ 'bin/cstocs', 'bin/cssort', 'bin/dbfcstocs'],
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../',
		DIST_DEFAULT => 'specversion tardist' },
	clean		=> { FILES => 'bin/cstocs bin/cssort bin/dbfcstocs' },
	macro		=> { DIST_DEFAULT => 'specversion tardist', },
	);

