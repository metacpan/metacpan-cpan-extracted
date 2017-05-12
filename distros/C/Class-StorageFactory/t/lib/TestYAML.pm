package TestYAML;

use strict;
use warnings;

use base 'TestBase';

use Astronaut;

use File::Path;
use YAML qw( DumpFile LoadFile );
use File::Spec::Functions 'catfile';

use Test::More;
use Test::Exception;

sub test_data
{
	return
	{
		type        => 'Astronaut',
		class       => 'Class::StorageFactory::YAML',
		storage     => 'data',
		add_files   =>
		[
			boris => { name => 'Boris', rank => 'Captain', age => 33 },
		],
	}
}

sub create_test_data :Test( startup )
{
	my $self      = shift;
	my $test_data = $self->test_data();
	my $path      = $test_data->{storage};
	my %add_files = @{ $test_data->{add_files} };

	mkpath( $path );

	while (my ($name, $data) = each %add_files)
	{
		my $file = catfile( $path, $name . '.yml' );
		DumpFile( $file, $data );
	}
}

sub remove_test_data :Test( shutdown )
{
	my $self      = shift;
	my $test_data = $self->test_data();
	my $path      = $test_data->{storage};
	rmtree( $path );
}

sub fetch :Test( 5 )
{
	my $self     = shift;
	my $factory  = $self->{factory};
	throws_ok { $factory->fetch() } qr/No id specified for fetch()/,
		'fetch() should throw exception unless it has an id';
	throws_ok { $factory->fetch( 'empty' ) } qr/No file found for id 'empty'/,
		'... or if id does not exist';

	my $astronaut;
	lives_ok  { $astronaut = $factory->fetch( 'boris' ) }
		'... but should live if it does exist';
	isa_ok( $astronaut, 'Astronaut', '... blessing results so that it' );

	is_deeply( $astronaut->data(),
		{ name => 'Boris', rank => 'Captain', age => 33 },
		'... blessing all data' );
}

sub store :Test( 3 )
{
	my $self       = shift;
	my $factory    = $self->{factory};
	my $test_data  = $self->test_data();
	my $path       = $test_data->{storage};

	throws_ok { $factory->store() } qr/No id specified for store()/,
		'store() should throw exception unless it has an id';

	my $attributes = { name => 'Natasha', rank => 'Commander', age => 31 };
	my $natasha    = Astronaut->new( $attributes );
	my $stored_file = catfile( $path, 'natasha' . '.yml' );

	$factory->store( natasha => $natasha );
	ok( -e $stored_file, '... saving file with the id, if passed' );
	my $stored_atts = LoadFile( $stored_file );
	is_deeply( $stored_atts, $attributes, '... with all of its data' );
}

1;
