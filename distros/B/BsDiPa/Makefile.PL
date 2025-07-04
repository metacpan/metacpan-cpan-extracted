require 5.026_000;
use ExtUtils::MakeMaker;

# perl Makefile.PL; make distdir (; make distcheck)
my ($VERSION, $CONTACT);
# "LD_PRELOAD=ASAN-LIB make test"
my ($ADDCCF,$ADDLDF) = (' -fno-common -fstrict-aliasing -fstrict-overflow ' .
		'-fstack-protector-strong -D_FORTIFY_SOURCE=3 ' .
		'-DHAVE_SANITIZER -fsanitize=address', '-lasan');
($ADDCCF, $ADDLDF) = ('', '');

sub version_and_contact{
	my ($f) = @_;
	die "open failed: $f: $^E" unless open F, '<', $f;
	while(<F>){
		chomp;
		if(/^VERSION=(.*)$/){
			$VERSION = $1;
		}elsif(/^CONTACT=['"]?(.*?)['"]?$/){
			$CONTACT = $1;
		}
	}
	die "close failed: $f: $^E" unless close F;
}

sub have_xz{
	if(system 'xz --version >/dev/null 2>&1' == 0){
		print "Adding support for liblzma (XZ)\n";
		$ADDCCF .= ' -Ds__BSDIPA_XZ=1 ';
		$ADDLDF .= ' -llzma '
	}else{
		print "! Cannot find xz(1), skipping support for liblzma (XZ)\n";
		$ADDCCF .= ' -Ds__BSDIPA_XZ=0 '
	}
}

version_and_contact 'c-lib/configh.sh';
system 'cd c-lib; ./configh.sh s_BSDIPA_32=y';
have_xz;

WriteMakefile(
#	'OPTIMIZE' => '-g',
	'NAME' => 'BsDiPa',
	#'DISTNAME' => 'S-BsDiPa',
	'VERSION' => $VERSION,
	(
		ABSTRACT => 'Create or apply binary difference patch',
		AUTHOR => $CONTACT,
		LICENSE => 'open_source'
	),
	MIN_PERL_VERSION => '5.26.0', # SvPVCLEAR()
	OBJECT => 'BsDiPa.o',
	CCFLAGS => '-I. -Ic-lib' . $ADDCCF,
	LIBS => $ADDLDF . ' -lz',
	clean => { FILES => 'c-lib/s-bsdipa-config.h' }
);

# s-itt-mode
