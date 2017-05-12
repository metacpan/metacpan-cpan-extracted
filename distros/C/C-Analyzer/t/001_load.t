# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'C::Analyzer' ); }

my $object = C::Analyzer->new (_inputPath => "/home/sindhu/test/afs",
                            _cppPath => "/usr/bin",
			    _inputOption => "dir_and_subdir",
			   );
isa_ok ($object, 'C::Analyzer');


