require 5.026_000;
use ExtUtils::MakeMaker;

my ($VERSION, $CONTACT);

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

version_and_contact 'c-lib/configh.sh';
system 'cd c-lib; ./configh.sh s_BSDIPA_32=y';

WriteMakefile(
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
	CCFLAGS => '-I. -Ic-lib',
	LIBS => '-lz', # TODO can we reach into perl's built-in zlib?
	clean => { FILES => 'c-lib/s-bsdipa-config.h' }
);

# s-itt-mode
