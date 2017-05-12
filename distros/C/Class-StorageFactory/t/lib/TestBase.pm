package TestBase;

use base 'Test::Class';

use strict;
use warnings;

use Test::More;
use Test::Exception;

sub test_data
{
	return
	{
		type    => 'Robot',
		class   => 'Class::StorageFactory',
		storage => 'data',
	};
}

sub fetch_class :Test( startup => 1 )
{
	my $self      = shift;
	use_ok( $self->test_data()->{class} ) or exit;
}

sub test_new :Test( startup => 5 )
{
	my $self      = shift;
	my $test_data = $self->test_data();
	my $class     = $test_data->{class};

	can_ok( $class, 'new' );

	throws_ok { $class->new() } qr/No storage specified/,
		'new() should throw exception without storage parameter';

	throws_ok { $class->new( storage => $test_data->{storage} ) }
		qr/No type specified/,
		'... or without type parameter';

	my $factory;
	lives_ok { $factory = $class->new( %$test_data ) }
		'... but should live with both given';

	isa_ok( $factory, $class );

	$self->{factory} = $factory;
}

sub storage :Test( 2 )
{
	my $self = shift;
	$self->test_attribute( 'storage' );
}

sub type :Test( 2 )
{
	my $self = shift;
	$self->test_attribute( 'type' );
}

sub test_attribute
{
	my ($self, $attribute) = @_;
	my $factory            = $self->{factory};
	my $test_data          = $self->test_data();

	can_ok( $factory, $attribute );
	is( $factory->$attribute(), $test_data->{$attribute},
		"$attribute() should return data set in constructor" );
}

sub fetch :Test( 2 )
{
	my $self = shift;
	$self->test_abstract( 'fetch' );
}

sub store :Test( 2 )
{
	my $self = shift;
	$self->test_abstract( 'store' );
}

sub test_abstract
{
	my ($self, $method) = @_;
	my $factory         = $self->{factory};
	can_ok( $factory, $method );
	throws_ok { $factory->$method() }
		qr/Unimplemented method $method called in parent class/,
		"$method() should throw abstract method exception";
}

1;
