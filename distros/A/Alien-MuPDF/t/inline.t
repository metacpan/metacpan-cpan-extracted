use Test::More;

use strict;
use warnings;
use Module::Load;
use File::Basename;
use File::Spec;
use Cwd 'abs_path';

use_ok('Alien::MuPDF');

SKIP: {
	eval { load 'Inline::C' } or do {
		my $error = $@;
		skip "Inline::C not installed", 1 if $error;
	};

	skip "Build issues on Strawberry Perl for Windows."
		." See issue at <https://github.com/project-renard/p5-Alien-MuPDF/issues/30>."
		if $^O eq 'MSWin32';


	Inline->import( with => qw(Alien::MuPDF) );

	subtest 'Retrieve a constant' => sub {
		Inline->bind( C => q|
			char* get_fitz_version() {
				return FZ_VERSION;
			}
		|, ENABLE => AUTOWRAP => );

		# single digit for the major version,
		# multiple digits for the minor version,
		# followed by optional letter
		like( get_fitz_version(), qr/^\d\.\d+[a-z]?$/);
	};

	subtest 'Call a function' => sub {
		Inline->bind( C => q|
			int can_create_context() {
				fz_context* ctx = fz_new_context(NULL, NULL, FZ_STORE_UNLIMITED);
				return NULL != ctx;
			}
		|, ENABLE => AUTOWRAP => );

		# single digit for the major version,
		# multiple digits for the minor version,
		# followed by optional letter
		ok( can_create_context(), 'fz_context* created');;
	};

}

done_testing;
