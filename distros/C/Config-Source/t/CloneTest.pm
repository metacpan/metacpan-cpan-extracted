package CloneTest;

use 5.14.0;
use warnings FATAL => 'all';

use FindBin;
use File::Spec;

use Test::More;
use Test::Exception;

sub test {
	my ( $class, $config ) = @_;
	
	ok( $config->can( 'clone' ), 'test clone method' );
	
	# test clone on load_source
	my $hash = config();
	lives_ok { $config->add_source( $hash ) } 'test clone on load source';
	
	$hash->{ 'key' } = 'othervar';
	isnt( $hash->{ 'key' }, $config->get( 'key' ), 'test no alias on load source' );
	
	# set a deep structure
	$hash =  { a => 'b', c => [ 'd', 'e' ] };
	lives_ok { $config->set( 'key2' => $hash ) } 'set a deep structure';
	
	isnt( $hash, $config->get( 'key2' ), 'check memory' );
	is_deeply( $hash,  $config->get( 'key2' ), 'check values' );
		
	# test if getall is clones
	isnt( $config->getall, $config->getall, 'check getall clones' );
	
	1;	
}

sub config {
	{
		'key' => 'var',
		'key2' => [ 1, 2 ],
	}	
}

1;