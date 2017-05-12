use Test::More;
use Module::Load;
use File::Basename;
use File::Spec;
use Cwd 'abs_path';

use_ok('Alien::MuPDF');

# for dev testing, get the headers out of the build directory
my ($built_fitz) = glob '_alien/mupdf-*-source/include/mupdf/fitz.h';
my $built_dir = abs_path( File::Spec->rel2abs(File::Spec->catfile( dirname($built_fitz), File::Spec->updir) ) );
my @inc_built = defined $built_fitz && -f $built_fitz ? (INC => "-I$built_dir") : ();

SKIP: {
	eval { load 'Inline::C' } or do {
		my $error = $@;
		skip "Inline::C not installed", 1 if $error;
	};

	Inline->import( with => qw(Alien::MuPDF) );
	Inline->bind( C => q|
		char* get_fitz_version() {
			return FZ_VERSION;
		}
	|, ENABLE => AUTOWRAP => @inc_built);

	# single digit for the major version,
	# multiple digits for the minor version,
	# followed by optional letter
	like( get_fitz_version(), qr/^\d\.\d+[a-z]?$/);
}

done_testing;
