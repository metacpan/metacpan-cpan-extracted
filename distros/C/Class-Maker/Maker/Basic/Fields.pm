	# This package contains all classfields
	#
	# class, { attr => ..	# calls Class::Maker::fields::attr

package Class::Maker::Basic::Fields;

sub configure
{
	my $args = shift;

	my $reflex = shift;

	Class::Maker::_make_method( 'new', exists $args->{ctor} ? $args->{ctor} : 'new' );

	if( exists $args->{explicit} )
	{
		$Class::Maker::explicit = $args->{explicit};

		warn "EXPLICIT $explicit" if $DEBUG;
	}

	# dtor is missing here
}

sub persistance
{
	my $args = shift;

	my $reflex = shift;

	no strict 'refs';
}

sub isa
{
	my $args = shift;

	my $reflex = shift;

		no strict 'refs';

			# Transform parent classes
			#
			# package My;
			#
			# .Class::Any # relative to the current package: My::Class::Any
			#
			# *Class::Any # relative to the current package: My::Class::Any

		map { s/^[\*\.]/${Class::Maker::cpkg}::/ } @$args;

		@{ "${Class::Maker::pkg}::ISA" } = @$args;
}

sub version
{
	my $args = shift;

	my $reflex = shift;

	no strict 'refs';

	${ "${Class::Maker::pkg}::VERSION" } = shift @$args;
}

sub can
{
	#my $args = shift;

	#no strict 'refs';

	#my $varname = "${pkg}::CAN";

	#@{ $varname } = @$args;
}

sub default
{
	my $args = shift;

	my $reflex = shift;

	foreach my $attr ( keys %$args )
	{
		warn sprintf "\tpredefined default %s = '%s'\n", $attr, $args->{$attr} if $DEBUG;
	}
}

our $protected_prefix = { public => '', protected => '__', private => '_' };

sub _create_accessor
{
	my $protected = shift;

	my $args = shift;

	my $reflex = shift;

		foreach my $type ( keys %$args )
		{
			my @attributes = ( ref( $args->{$type} ) eq 'HASH' ) ? keys %{$args->{$type}} : @{ $args->{$type} };

			foreach my $name ( @attributes )
			{
				Class::Maker::_make_method( $type, $protected_prefix->{$protected}.$name );
			}
		}
}

sub public
{
	_create_accessor( 'public', @_ );
}

sub private
{
	_create_accessor( 'private', @_ );
}

sub protected
{
	_create_accessor( 'protected', @_ );
}

sub has
{
	my $args = shift;

	my $reflex = shift;

	foreach ( keys %$args )
	{
		warn "\tkey: $_\n" if $DEBUG;
	}
}

1;
