use Test::More;
use Module::Load;
use File::Basename;
use File::Spec;

use_ok('Alien::Leptonica');

# for dev testing, get the headers out of the build directory
my ($built_allheaders) = glob '_alien/leptonica-*/src/allheaders.h';
my $built_dir = defined $built_allheaders && File::Spec->rel2abs(dirname($built_allheaders));
my @inc_built = defined $built_allheaders && -f $built_allheaders ? (INC => "-I$built_dir") : ();

SKIP: {
	eval { load 'Inline::C' } or do {
		my $error = $@;
		skip "Inline::C not installed", 1 if $error;
	};

	Inline->import( with => qw(Alien::Leptonica) );
	Inline->bind( C => q{ extern char * getLeptonicaVersion (  ); },
		ENABLE => AUTOWRAP => @inc_built);

	like( getLeptonicaVersion(), qr/^leptonica-/);
}

done_testing;
