use 5.010;
use strict;
use warnings;

package Data::OptList::Object;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001003';

use Exporter::Tiny qw( mkopt );
use List::Util 1.39 qw( first any uniqstr );
use Scalar::Util qw( blessed );
use re qw( is_regexp );
use namespace::autoclean;

use constant SLOT_OPTLIST => 0;
use constant SLOT_HASHREF => 1;
use constant NEXT_SLOT => 2;

use overload (
	q{bool}   => sub { !!1 },
	q{""}     => sub { sprintf( 'OptList(%s)', join q{ }, $_[0]->KEYS ) },
	q{0+}     => 'COUNT',
	q{%{}}    => 'TO_HASHREF',
	q{@{}}    => 'TO_ARRAYREF',
	q{qr}     => 'TO_REGEXP',
	fallback  => 1,
);

{
	package Data::OptList::Object::_Pair;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001003';
	use overload (
		q{bool}   => 'exists',
		q{""}     => 'key',
		fallback  => 1,
	);
	sub key     { shift->[0] }
	sub value   { shift->[1] }
	sub exists  { !!1 }
	sub kind    { ref(shift->[1]) or 'undef' }
	sub TO_JSON { [ @{+shift} ] }
}

{
	package Data::OptList::Object::_NoValue;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001003';
	our @ISA = 'Data::OptList::Object::_Pair';
	sub key     { defined $_[0][0] ? $_[0][0] : '' }
	sub value   { undef; }
	sub exists  { !!0 }
	sub kind    { '' }
	sub TO_JSON { undef; }
}

sub new {
	my $class = shift;
	$class = ref $class if ref $class;

	my $optlist =
		( @_ == 1 and 'ARRAY' eq ref $_[0] ) ? mkopt( $_[0] ) :
		( @_ == 1 and 'HASH'  eq ref $_[0] ) ? mkopt( $_[0] ) :
		( @_ == 1 and blessed $_[0] and $_[0]->DOES(__PACKAGE__) and $_[0]->can('TO_LIST') ) ? mkopt( [ $_[0]->TO_LIST ] ) :
		mkopt( \@_ );
	bless $_, __PACKAGE__ . '::_Pair' for @$optlist;

	my $self = bless \[ 0 .. $class->NEXT_SLOT - 1 ], $class;
	$$self->[SLOT_OPTLIST] = $optlist;
	$$self->[SLOT_HASHREF] = undef;

	&Internals::SvREADONLY( $_, 1 ) for @{ $$self->[SLOT_OPTLIST] };
	&Internals::SvREADONLY( $_, 1 ) for $$self->[SLOT_OPTLIST];
	&Internals::SvREADONLY( $_, 1 ) for $$self;

	return $self;
}

sub ALL {
	my $self = shift;

	return @{ $$self->[SLOT_OPTLIST] };
}

sub COUNT {
	my $self = shift;

	return scalar @{ $$self->[SLOT_OPTLIST] };
}

sub KEYS {
	my $self = shift;

	return map $_->[0], $self->ALL;
}

sub VALUES {
	my $self = shift;

	return map $_->[1], $self->ALL;
}

sub TO_LIST {
	my $self = shift;

	return map {
		my ( $key, $value ) = @$_;
		defined($value) ? ( $key => $value ) : ( $key );
	} $self->ALL;
}

sub TO_ARRAYREF {
	my $self = shift;

	return $$self->[SLOT_OPTLIST];
}

sub TO_JSON {
	my $self = shift;

	return [ $self->TO_LIST ];
}

sub TO_HASHREF {
	my $self = shift;

	if ( not defined $$self->[SLOT_HASHREF] ) {
		$$self->[SLOT_HASHREF] = +{ map {
			my ( $key, $value ) = @$_;
			( $key => $value );
		} $self->ALL };
		&Internals::SvREADONLY( $_, 1 ) for $$self->[SLOT_HASHREF];
	}

	return $$self->[SLOT_HASHREF];
}

sub TO_REGEXP {
	my $self = shift;

	my $re = join q{|}, map { quotemeta($_) } uniqstr( $self->KEYS );

	return qr/\A(?:$re)\z/;
}

sub GET {
	my $self    = shift;
	my $key     = shift;
	my $is_re   = is_regexp $key;
	my $is_code = ref($key) eq 'CODE';

	if ( wantarray ) {
		return grep {
			$is_re ? !!( $_->key =~ $key ) : $is_code ? $key->(@$_) : ( $_->key eq $key )
		} $self->ALL;
	}
	elsif ( defined wantarray ) {
		my $found = first {
			$is_re ? !!( $_->key =~ $key ) : $is_code ? $key->(@$_) : ( $_->key eq $key )
		} $self->ALL;
		return $found if $found;
		return bless [ $is_code ? undef : $key ], __PACKAGE__ . '::_NoValue';
	}
	else {
		return;
	}
}

sub HAS {
	my $self    = shift;
	my $key     = shift;
	my $is_re   = is_regexp $key;
	my $is_code = ref($key) eq 'CODE';

	return any {
		$is_re ? !!( $_->key =~ $key ) : $is_code ? $key->(@$_) : ( $_->key eq $key )
	} $self->ALL;
}

sub MATCH {
	my $self = shift;

	return $self->HAS( @_ );
}

sub AUTOLOAD {
	my $self = shift;

	our $AUTOLOAD;
	( my $key = $AUTOLOAD ) =~ s/.*:://;

	return $self->GET( $key );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Data::OptList::Object - Data::OptList, but object-oriented

=head1 SYNOPSIS

Data::OptList provides a compact list format for lists of options,
where each option has a key/name which is a string and a value
which must be either undef or a reference.

    my $options = Data::OptList::mkopt([
        qw(key1 key2 key3 key4),
        key5 => { ... },
        key6 => [ ... ],
        key7 => sub { ... },
        key8 => { ... },
        key8 => [ ... ],
    ]);

Is a shorthand for:

    my $options = [
        [ key1 => undef,        ],
        [ key2 => undef,        ],
        [ key3 => undef,        ],
        [ key4 => undef,        ],
        [ key5 => { ... },      ],
        [ key6 => [ ... ],      ],
        [ key7 => sub { ... },  ],
        [ key8 => { ... },      ],
        [ key8 => [ ... ],      ],
    ];

The resulting structure may be looped through easily:

    for my $pair ( @$options ) {
        printf "%s=%s\n", $pair->[0], ref($pair->[1]) || 'undef';
    }

Data::OptList::Object encapsulates the result in a blessed object, allowing
convenient methods to be called on it.

    my $options = Data::OptList::Object->new(
        qw(key1 key2 key3 key4),
        key5 => { ... },
        key6 => [ ... ],
        key7 => sub { ... },
        key8 => { ... },
        key8 => [ ... ],
    );
    
    for my $pair ( @$options ) {
        printf "%s=%s\n", $pair->key, $pair->kind;
    }
    
    if ( $options->key7 ) {
        my $coderef = $options->key7->value;
        $coderef->();
    }

=head1 DESCRIPTION

=head2 Constructor

The constructor can be used to create a new OptList object. It may be
called in any of these fashions:

=over

=item C<< new( @OPTLIST ) >>

=item C<< new( \@OPTLIST ) >>

=item C<< new( \%OPTHASH ) >>

=item C<< new( $OBJECT ) >>

=back

Where C<< \@OPTLIST >> is a reference to any array conforming to the optlist
format, C<< \%OPTHASH >> is any hashref where the values are either undef
or references, and C<< $OBJECT >> is any blessed object where
C<< $OBJECT->DOES('Data::OptList::Object') >> returns True and provides a
C<< TO_LIST >> method.

=head2 Methods

All built-in methods are uppercase.

=over

=item C<< ALL() >>

Calling C<< ALL() >> returns a list of pair objects.

    for my $pair ( $options->ALL ) {
        printf "%s=%s\n", $pair->key, ref($pair->value) || 'undef';
    }

The returned list is like the I<output> of C<< mkopt() >> from L<Data::OptList>
(except as a list instead of an arrayref).

In scalar context, it returns the length of that list.

=item C<< COUNT() >>

Count is like C<< ALL() >>, but forces scalar context, so always returns the
number of pairs.

Data::OptList::Object overloads the C<< 0+ >> operator to call this.

    my $how_many_options = 0 + $options;

=item C<< KEYS() >>

Calling C<< KEYS() >> returns a list of just the keys.

    for my $key ( $options->KEYS ) {
        printf "Found key: %s\n", $key;
    }

This method's behaviour in scalar context is undefined.

=item C<< VALUES() >>

Calling C<< VALUES() >> returns a list of just the values.

    for my $value ( $options->VALUES ) {
        printf "Found value of type %s\n", ref $value;
    }

This method's behaviour in scalar context is undefined.

=item C<< TO_LIST() >>

Returns the options in their original optlist format. This may not exactly
match the format passed to the constructor as it will have been canonicalized.

The returned list is like the I<input> to C<< mkopt() >> from L<Data::OptList>
(except as a list instead of an arrayref).

This method's behaviour in scalar context is undefined.

=item C<< TO_ARRAYREF() >>

Returns the same list as C<< ALL() >>, but as an arrayref.

    for my $pair ( @{ $options->TO_ARRAYREF } ) {
        printf "%s=%s\n", $pair->key, ref($pair->value) || 'undef';
    }

Data::OptList::Object overloads the C<< @{} >> operator to call this.

    for my $pair ( @$options ) {
        printf "%s=%s\n", $pair->key, ref($pair->value) || 'undef';
    }

The returned list is like the I<output> of C<< mkopt() >> from L<Data::OptList>.

=item C<< TO_JSON() >>

Returns the same list as C<< TO_LIST() >>, but as an arrayref. This allows
Data::OptList::Object to play nice with L<JSON> serialization, assuming
the values in your optlist are values that can be represented in JSON.

    my $j = JSON->new->convert_blessed( 1 );
    print $j->encode( $options );

=item C<< TO_HASHREF() >>

Provides a simple key-value hashref for the optlist. This is appropriate if
you do not expect your keys to appear more than once.

The hashref is read-only. A quirk of read-only hashes in Perl is that trying
to read from a key that does not exist will cause an error.

    my $hashref = $options->TO_HASHREF;
    if ( $hashref->{key7} ) {  # might die
        my $coderef = $hashref->{key7};
        $coderef->();
    }

Make sure to use the C<exists> keyword when checking if an option was given.

    my $hashref = $options->TO_HASHREF;
    if ( exists $hashref->{key7} ) {
        my $coderef = $hashref->{key7};
        $coderef->();
    }

As options default to having the value C<undef>, it is sensible to use
C<exists> to check for their presence anyway.

Data::OptList::Object overloads the C<< %{} >> operator to call this.

    if ( exists $options->{key7} ) {
        my $coderef = $options->{key7};
        $coderef->();
    }

=item C<< TO_REGEXP() >>

Returns a regular expression which matches all the keys in the optlist.

    my $re = $options->TO_REGEXP;
    if ( 'key7' =~ $re ) {
        my $coderef = $options->{key7};
        $coderef->();
    }

Data::OptList::Object overloads the C<< qr >> operator to call this.

    if ( 'key7' =~ $options ) {
        my $coderef = $options->{key7};
        $coderef->();
    }

=item C<< GET( $key ) >>

In list context, returns a list of pairs where the key is C<< $key >>.

    my @eights = $options->GET( 'key8' );
    for my $pair ( @eights ) {
        printf "%s=%s\n", $pair->key, ref($pair->value) || 'undef';
    }

You can alternatively provide a regexp or coderef for C<< $key >>.

    my @eights = $options->GET( qr/^key8$/i );
    my @eights = $options->GET( sub { $_->key eq 'key8' } );

In scalar context, will return the first such pair if there are any.

    my $first_key8_value = $options->GET( 'key8' )->value;

If called in scalar context and there are no pairs with the given key,
C<< GET >> will return a special object which overloads boolification
to be false, but provides C<key> and C<value> methods.

    if ( $options->GET( 'does_not_exist' ) ) {
        # The above condition is false, so this block will
        # not execute.
    }
    
    # Yet this doesn't die.
    my $value = $options->GET( 'does_not_exist' )->value;

=item C<< HAS( $key ) >>

Like C<< GET( $key ) >> but returns a simple true or false to indicate
if the key was found.

Also accepts a regexp or coderef.

=item C<< MATCH( $key ) >>

An alias for C<< HAS( $key ) >>. This alias exists to play nicely with
L<match::simple>.

    use match::simple 'match';
    
    if ( match 'key7', $options ) {
        ...;
    }

It also works with L<Syntax::Keyword::Matches>:

    use Syntax::Keyword::Matches;
    
    if ( 'key7' matches $options ) {
        my $coderef = $options->key7->value;
        $coderef->();
    }

=back

=head2 AUTOLOAD

The C<AUTOLOAD> method will call C<< GET($key) >>.

    my $first_key8_value = $options->key8->value;

This is useful for when your option keys are all valid unqualified
bareword identifiers. This is the reason Data::OptList::Object avoids
having any method names with lowercase characters. (Except C<new>.)

=head2 Overloading

The following operators are overloaded:

=over

=item C<< bool >>

Data::OptList::Options objects are always True.

=item C<< "" >>

Data::OptList::Options have a cute stringification which shows their
keys (but not values).

=item C<< 0+ >>

Calls C<COUNT>.

=item C<< %{} >>

Calls C<TO_HASHREF>.

=item C<< @{} >>

Calls C<TO_ARRAYREF>.

=item C<< qr >>

Calls C<TO_REGEXP>.

=back

=head2 Pair Objects

A number of methods return pair objects, representing a key-value pair.
Pair objects are read-only and have the following methods:

=over

=item C<< key() >>

Returns the key as a string.

=item C<< value() >>

Returns the value, which will normally be either undef or a reference.

=item C<< kind() >>

The kind of value this pair has. Either the string returned by Perl's
builtin C<< ref() >> function, or the string "undef" if the value is
undef.

=item C<< exists() >>

Returns True to indicate that the pair exists. Data::OptList::Object's
C<< GET() >> method in scalar context will return a special pair object
where C<< exists() >> returns False to indicate that no pair has been
found.

=item C<< TO_JSON() >>

Returns a two item arrayref consisting of the key followed by the value.

=back

Pair objects are blessed arrayrefs, and you may access the key using
C<< $pair->[0] >> or the value using C<< $pair->[1] >>.

Pair objects overload C<< "" >> to return the key, and override C<< bool >>
to return the result of C<< exists() >>.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-data-optlist-object/issues>.

=head1 SEE ALSO

L<Data::OptList>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

