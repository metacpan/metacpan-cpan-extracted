use Test::More;
use Module::Load;

use_ok('Alien::LibMagic');

SKIP: {
	eval { load 'Inline' } or do {
		my $error = $@;
		skip "Inline not installed", 1 if $error;
	};

	Inline->import( with => qw(Alien::LibMagic) );
	Inline->bind( C => q{  extern int magic_version();  },
		ENABLE => AUTOWRAP => );

	like( magic_version(), qr/^\d+$/); # e.g., 518
}


done_testing;
