package Anonymous::Object;
use strict;
use warnings;
use Data::Dumper;
our $VERSION = 0.05;

our $UNIQUE;
BEGIN {
	$Data::Dumper::Deparse = 1;
	$UNIQUE = 0;
}

sub new {
	my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
	my $self = bless {}, $cls;
	my %accessors = (
		object_name => { default => 'Anonymous::Object' },
		meta => { default => {}, },
		default => { default => {}, },
		types => { default => {}, },
		type_library => { default => 'Types::Standard' },
		type_map => {
			default => {
				HASH => 'HashRef',
				ARRAY => 'ArrayRef',
				STRING => 'Str',
				SCALAR => 'ScalarRef',
				REF => 'Ref',
				CODE => 'CodeRef',
				GLOB => 'GlobRef',
				NUM => 'Num',
				INT => 'Int',
				default => 'Any'
			}
		}
	);
	for my $accessor ( keys %accessors ) {
		my $param = defined $args{$accessor}
			? $args{$accessor}
			: $accessors{$accessor}->{default};
		my $value
			= $self->$accessor( $accessors{$accessor}->{builder}
			? $accessors{$accessor}->{builder}->( $self, $param )
			: $param );
		unless ( !$accessors{$accessor}->{required} || defined $value ) {
			die "$accessor accessor is required";
		}
	}
	return $self;
}

sub clean {
	my $class = ref $_[0];
	return $class->new({
		object_name => $_[0]->{object_name},
		type_library => $_[0]->{type_library},
		type_map => $_[0]->{type_map}
	});
}

sub object_name {
	my ($self, $value) = @_;
	if ( defined $value ) {
		if ( ref $value ) {
			die qq{Str: invalid value $value for accessor object_name}
		}
		$self->{object_name} = $value;
	}
	return $self->{object_name};
}

sub default {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ( ref($value) || "" ) ne "HASH" ) {
			die qq{HashRef: invalid value $value for accessor default};
		}
		$self->{default} = $value;
	}
	return $self->{default};
}

sub meta {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ( ref($value) || "" ) ne "HASH" ) {
			die qq{HashRef: invalid value $value for accessor meta};
		}
		$self->{meta} = $value;
	}
	return $self->{meta};
}

sub types {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ( ref($value) || "" ) ne "HASH" ) {
			die qq{HashRef: invalid value $value for accessor types};
		}
		$self->{types} = $value;
	}
	return $self->{types};
}

sub type_library {
	my ($self, $value) = @_;
	if ( defined $value ) {
		if ( ref $value ) {
			die qq{Str: invalid value $value for accessor type_library}
		}
		$self->{type_library} = $value;
	}
	return $self->{type_library};
}

sub type_map {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ( ref($value) || "" ) ne "HASH" ) {
			die qq{HashRef: invalid value $value for accessor type_map};
		}
		$self->{type_map} = $value;
	}
	return $self->{type_map};
}

sub hash_to_object {
	my ( $self, $hash, %accessors ) = @_;
	if ( ( ref($hash) || "" ) ne "HASH" ) {
		$hash = defined $hash ? $hash : 'undef';
		die
			qq{HashRef: invalid value $hash for variable \$hash in method hash_to_object};
	}
	$self = $self->clean();
	$self->default($hash);
	for my $key ( keys %{$hash} ) {
		$self->add_method(
			{
				name => $key,
				%accessors
			}
		);
	}
	return $self->build;
}

sub hash_to_nested_object {
	my ( $self, $hash, %accessors ) = @_;
	if ( ( ref($hash) || "" ) ne "HASH" ) {
		$hash = defined $hash ? $hash : 'undef';
		die
			qq{HashRef: invalid value $hash for variable \$hash in method hash_to_object};
	}
	$self = $self->clean();
	for my $key ( keys %{$hash} ) {
		my $val = $hash->{$key};
		my $ref = ref $val || "";
		if ($ref eq 'HASH') {
			$val = $self->hash_to_nested_object(
				$val,
				%accessors
			);
		} elsif ($ref eq 'ARRAY') {
			$val = $self->array_to_nested_object(
				$val,
				%accessors
			);
		}
		$self->add_method(
			{
				name => $key,
				default => $val,
				nested => 1,
				%accessors
			}
		);
	}
	return $self->build;
}

sub array_to_nested_object {
	my ( $self, $array, %accessors ) = @_;
	if ( ( ref($array) || "" ) ne "ARRAY" ) {
		$array = defined $array ? $array : 'undef';
		die
			qq{ArrayRef: invalid value $array for variable \$array in method array_to_object};
	}
	for (my $i = 0; $i < scalar @{$array}; $i++) {
		my $val = $array->[$i];
		my $ref = ref $val || "";
		if ($ref eq 'HASH') {
			$val = $self->hash_to_nested_object(
				$val,
				%accessors
			);
		} elsif ($ref eq 'ARRAY') {
			$val = $self->array_to_nested_object(
				$val,
				%accessors
			);
		}
		$array->[$i] = $val;
	}
	return $array;
}

sub add_new {
	my ( $self, $new ) = @_;
	if ( ( ref($new) || "" ) ne "HASH" ) {
		$new = defined $new ? $new : 'undef';
		die
			qq{HashRef: invalid value $new for variable \$new in method add_new};
	}

	return sprintf q|return bless { %s }, __PACKAGE__;|, join q|,|,
		map { sprintf q|%s => %s|, $_, $self->stringify_struct( $new->{$_} ) }
		keys %{$new};

}

sub add_methods {
	my ( $self, $methods ) = @_;
	if ( !defined($methods) || ( ref($methods) || "" ) ne "ARRAY" ) {
		$methods = defined $methods ? $methods : 'undef';
		die
			qq{ArrayRef: invalid value $methods for variable \$methods in method add_methods};
	}

	for my $method ( @{$methods} ) {
		$self->add_method($method);
	}

}

sub add_method {
	my ( $self, $method ) = @_;
	if ( ( ref($method) || "" ) ne "HASH" ) {
		$method = defined $method ? $method : 'undef';
		die
			qq{HashRef: invalid value $method for variable \$method in method add_method};
	}
	if ( ( ! defined $method->{name} || ref($method->{name}) ) ) {
		$method->{name} = defined $method->{name} ? $method->{name} : 'undef';
		die
			qq{Str: invalid value $method->{name} for variable \$method->{name} in method add_method};
	}

	my $name = $method->{name};
	if ( $method->{clearer} ) {
		$self->meta->{ q|clear_| . $name }
			= qq|return delete \$_[0]->{$name};|;
	}
	if ( $method->{predicate} ) {
		$self->meta->{ q|has_| . $name }
			= qq|return exists \$_[0]->{$name};|;
	}
	if ( $method->{get} ) {
		$self->meta->{ q|get_| . $name }
			= qq|return \$_[0]->{$name};|;
	}
	if ( $method->{set} ) {
		my $set = q|my ($self, $val) = @_; |;
		$method->{type} = $self->identify_type($method->{default})
			if ($method->{autotype});
		if ($method->{type}) {
			$self->add_type($method->{type});
			$set .= qq|$method->{type}\->(\$val); |;
		}
		my $merge = $method->{merge} ? '|| $first' : '';
		$set .= qq|
			if (defined \$self->{$name}) {
				my \$recurse;
				\$recurse = sub {
					my (\$first, \$second) = \@_;
					my \$fref = Scalar::Util::reftype(\$first) \|\| "";
					my \$sref = Scalar::Util::reftype(\$second) \|\| "";
					if (\$fref eq 'ARRAY' && \$sref eq 'ARRAY') {
						for (my \$i = 0; \$i < scalar \@{ \$first }; \$i++) {
							my (\$f, \$s) = (\$first->[0], \$second->[0]);
							\$second->[\$i] = \$recurse->(\$first->[\$i], \$second->[\$i]);
						}
					} elsif (\$fref eq 'HASH' && \$sref eq 'HASH') {
						my \@keys = (keys \%{ \$first }, keys \%{ \$second });
						for my \$key ( \@keys ) {
							\$second->{\$key} = \$recurse->(\$first->{\$key}, \$second->{\$key});
						}
						\$second = bless \$second, ref \$first;
					}
					return \$second${merge};
				};
				\$val = \$recurse->(\$self->{$name}, \$val);
			}
		| if ($method->{nested});
		$set .= qq|
			\$self->{$name} = \$val;
			return \$self->{$name};
		|;
		$self->meta->{ q|set_| . $name } = $set;
	}
	if ( $method->{ref} ) {
		$self->meta->{ q|ref_| . $name }
			= qq|return ref \$_[0]->{$name};|;
	}
	if ( $method->{reftype} ) {
		$self->meta->{ q|reftype_| . $name }
			= qq|return Scalar::Util::reftype \$_[0]->{$name};|;
	}
	if ( exists $method->{default} ) {
		$self->default->{ $name } = $method->{default};
	}
	unless ($method->{code}) {
		$method->{code} = qq|return \$_[0]->{$name}|;
	}
	$self->meta->{ $name } = $method->{code};
	return $self;
}

sub build {
	my ($self) = @_;


	$self->meta->{new} = $self->add_new( $self->default );

	my $class = sprintf q|%s::%s|, $self->{object_name}, $UNIQUE++;
	my @methods;
	for my $method ( keys %{ $self->meta } ) {
		push @methods, sprintf q|sub %s { %s }|, $method,
			$self->meta->{$method};
	}
	my $c = sprintf(
		q|
			package %s;
			use Scalar::Util qw//;
			use %s qw/%s/;
			%s
			1;
		|, $class, $self->type_library, join(" ", keys %{$self->types}), join( "\n", @methods) );
	eval $c;
	return $class->new;
}

sub stringify_struct {
	my ( $self, $struct ) = @_;
	$struct = ref $struct ? Dumper $struct : "'$struct'";
	return 'undefined' unless defined $struct;
	$struct =~ s/\$VAR1 = //;
	$struct =~ s/\s*\n*\s*package Module\:\:Generate\;|use warnings\;|use strict\;//g;
	$struct =~ s/{\s*\n*/{/;
	$struct =~ s/;$//;
	return $struct;
}

sub add_type {
	my ($self, $value) = @_;
	if ( ! defined $value || ref $value ) {
		die qq{Str: invalid value $value for method push_type};
	}
	$self->{types}->{$value}++;
}

sub identify_type {
	my ($self, $value) = @_;
	my $type_map = $self->type_map;
	my $ref = ref $value;
	return $type_map->{default}
		if (! defined $value);
	return $type_map->{$ref} || $type_map->{REF}
		if ($ref);
	return $type_map->{NUM} if $value =~ m/\d+\.\d+/;
	return $type_map->{INT} if $value =~ m/\d+/;
	return $type_map->{STRING} if $value =~ m/\s+/;
}


1;

__END__

=head1 NAME

Anonymous::Object - Generate Anonymous Objects

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use Anonymous::Object;

	my $anon = Anonymous::Object->new({
		object_name => 'Custom::Object'
	})->hash_to_object({
		a => 1,
		b => 2,
		c => 3
	}, autotype => 1, set => 1);

	$anon->a; # 1
	$anon->b; # 2
	$anon->c; # 3

	....

	my $anon = Anonymous::Object->new({});

	$anon->add_method({
		name => 'test_accessor',
		clearer => 1,
		predicate => 1,
		get => 1,
		set => 1,
		ref => 1,
		reftype => 1,
		type => 'Str',
		default => 'xyz',
	});

	$anon->build;

=head1 DESCRIPTION

Anonymous object. Anonymous simply means nameless. An object which has no reference is known as an anonymous object. It can be used at the time of object creation only. If you have to use an object only once, an anonymous object is a good approach.

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Anonymous::Object object.

	my $anon = Anonymous::Object->new({
		object_name => 'Custom::Object',
		types => {
			Str => 1,
			HashRef => 1,
			...
		},
		type_library => 'Types::Standard',
		type_map => {
			HASH => 'HashRef',
			ARRAY => 'ArrayRef',
			STRING => 'Str',
			SCALAR => 'ScalarRef',
			REF => 'Ref',
			CODE => 'CodeRef',
			GLOB => 'GlobRef',
			NUM => 'Num',
			INT => 'Int',
			default => 'Any'
		},
		meta => {
			sub1 => 'return $_[1] * $_[2]',
			sub2 => 'return $_[0]->{sub2};'
		},
		default => {
			sub2 => 'xyz'
		}
	});

=head3 object_name

The object name used when bulding the Anonymous::Object. Expects a Str.

=head3 types

The types that will be loaded into the Anonymous::Object when built. Expects a HashRef.

=head3 type_library

The type library that you would like the Anonymous::Object to use. The default is Types::Standard. Expects a Str.

=head3 type_map

The mapping that is used when auto detecting types from perl data structures. Expects a HashRef.

=head3 meta

The method meta store. Expects a HashRef.

=head3 default

The default values for Anonymous::Object accessors. Expects a HashRef.

=head2 clean

Instantiate a clean Anonymous::Object passing through object_name, type_library and type_map;

	my $clean_anon = $anon->clean;

=head2 hash_to_object

Convert a perl hash into a single level perl object. Expects param $hash to be a HashRef.

	my $hash = {
		one => 1,
		two => 2,
		three => {
			four => 4,
			five => [
				{
					six => 6
				}
			],
		}
	};

	my $obj = $obj->hash_to_object($hash, %method_options)

	$hash->one; # 1
	$hash->three->{four}; # 4
	$hash->three->{five}->[0]->{six}; # 6

=head2 hash_to_nested_object

Convert a perl hash into a multi level perl object. Expects param $hash to be a HashRef.

	my $hash = {
		one => 1,
		two => 2,
		three => {
			four => 4,
			five => [
				{
					six => 6
				}
			],
		}
	};

	my $obj = $obj->hash_to_nested_object($hash, %method_options)

	$hash->one; # 1
	$hash->three->four; # 4
	$hash->three->five->[0]->six; # 6

=head2 array_to_nested_object

Convert a perl array into a multi level perl object. Expects param $array to be a ArrayRef.

	my $array = [{
		one => 1,
		two => 2,
		three => {
			four => 4,
			five => [
				{
					six => 6
				}
			],
		}
	}];

	my $obj = $obj->array_to_nested_object($hash, %method_options)

	$array->[0]->one; # 1
	$array->[0]->three->four; # 4
	$array->[0]->three->five->[0]->six; # 6

=head2 add_new

Builds the 'new' method for the Anonymous::Object.  Expects param $new to be a HashRef of default values.

	$obj->add_new({
		one => 1,
		two => 2,
		three => {
			four => 4,
			five => [
				{
					six => 6
				}
			],
		}
	});

=head2 add_methods

Add multiple methods to the Anonymous::Object. Expects param $methods to be a ArrayRef of HashRefs that represent a method..

	my $anon = Anonymous::Object->new({});

	$anon->add_methods([
		{
			name => 'test_accessor',
			clearer => 1,
			predicate => 1,
			get => 1,
			set => 1,
			ref => 1,
			type => 'Str',
			reftype => 1,
			default => 'xyz',
		},
		{
			name => 'test_accessor2',
			set => 1,
			type => 'HashRef',
			default => { a => 1, b => 2 },
		}
	]);

	$anon->build;

=head2 add_method

Add a method to the Anonymous::Object. Expects param $method to be a HashRef.

	my $anon = Anonymous::Object->new({});

	$anon->add_method({
		name => 'test_accessor',
		clearer => 1,
		predicate => 1,
		get => 1,
		set => 1,
		ref => 1,
		reftype => 1,
		type => 'Str',
		default => 'xyz',
	});

	$anon->build;

=head3 name

The name of the Anonymous::Object method.

=head3 clearer

Generates a clearer method.

	$self->clear_$name;

=head3 predicate

Generates a predicate method.

	$self->has_$name;

=head3 get

Generates a get method.

	$self->get_$name;

=head3 set

Generates a set method.

	$self->set_$name;

=head3 ref

Generates a ref method.

	$self->ref_$name;

=head3 reftype

Generates a reftype method.

	$self->reftype_$name;

=head3 type

Specify a type check for the set method.

=head3 autotype

Auto detect types based on the passed default values.

=head3 default

Set a default value for the method.

=head2 build

Build/Generate the Anonymous::Object. Expects no params.

	$obj->build()

=head2 stringify_struct

Stringify a perl data structure.  Expects param $struct to be any value including undef.

	$obj->stringify_struct($struct)

=head2 add_type

Add a type constaint to the Anonymous::Object. Expects param $value to be a Str.

	$obj->add_type('Str');

=head2 identify_type

Identify the type of the passed data. Expects param $value to be any value including undef.

	my $type = $obj->identify_type($data);

=head1 ACCESSORS

=head2 object_name

get or set object_name.

	$obj->object_name;

	$obj->object_name($value);

=head2 default

get or set default.

	$obj->default;

	$obj->default($value);

=head2 meta

get or set meta.

	$obj->meta;

	$obj->meta($value);

=head2 types

get or set types.

	$obj->types;

	$obj->types($value);

=head2 type_library

get or set type_library.

	$obj->type_library;

	$obj->type_library($value);

=head2 type_map

get or set type_map.

	$obj->type_map;

	$obj->type_map($value);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-anonymous::object at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Anonymous-Object>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Anonymous::Object

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Anonymous-Object>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Anonymous-Object>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Anonymous-Object>

=item * Search CPAN

L<https://metacpan.org/release/Anonymous-Object>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


