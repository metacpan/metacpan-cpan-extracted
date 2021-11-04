use Test2::V0;
use Test::Alien;
use Alien::PLplot;

use Env qw(@LD_LIBRARY_PATH @DYLD_FALLBACK_LIBRARY_PATH @PATH);
use DynaLoader;
use File::Basename qw(dirname);

if( Alien::PLplot->install_type('share') ) {
	if( Alien::PLplot->dynamic_libs ) {
		my $rpath = dirname( ( Alien::PLplot->dynamic_libs )[0] );
		unshift @LD_LIBRARY_PATH, $rpath;
		unshift @DYLD_FALLBACK_LIBRARY_PATH, $rpath;
		unshift @PATH, $rpath;
		unshift @DynaLoader::dl_library_path, $rpath;
		# load shared object dependencies
		for my $lib ( qw(-lcsirocsa -lqsastime -lplplot) ) {
			my @files = DynaLoader::dl_findfile($lib);
			DynaLoader::dl_load_file($files[0]) if @files;
		}
	} else {
		plan skip_all => 'share install does not support dynamic linkage';
	}

}

alien_ok 'Alien::PLplot';

my $version_re = qr/^(\d+)\.(\d+)\.(\d+)$/;

ffi_ok { symbols => ['c_plgver'] }, with_subtest {
	my ($ffi) = @_;
	eval q{
		use FFI::Platypus::Memory qw( malloc free );
		use FFI::Platypus::Buffer qw( scalar_to_buffer );
		1; } or skip "$@";
	my $get_version = $ffi->function( c_plgver => ['opaque'] => 'void' );

	my $buffer = malloc(80);
	$get_version->call($buffer);
	my $version = $ffi->cast( 'opaque' => 'string', $buffer );

	note "version: $version";
	like $version, $version_re;

	free($buffer);
};


done_testing;
