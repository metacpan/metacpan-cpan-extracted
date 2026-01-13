use 5.008008;
use strict;
use warnings;
use Class::XSConstructor ();

package Class::XSReader;

BEGIN {
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.020000';
	
	if ( eval { require Types::Standard; 1 } ) {
		Types::Standard->import(
			qw/ is_ArrayRef is_HashRef is_ScalarRef is_CodeRef is_Object /
		);
	}
	else {
		eval q|
			require Scalar::Util;
			sub is_ArrayRef  ($) { ref $_[0] eq 'ARRAY' }
			sub is_HashRef   ($) { ref $_[0] eq 'HASH' }
			sub is_ScalarRef ($) { ref $_[0] eq 'SCALAR' or ref $_[0] eq 'REF' }
			sub is_CodeRef   ($) { ref $_[0] eq 'CODE' }
			sub is_Object    ($) { !!Scalar::Util::blessed($_[0]) }
		|;
	}
};

sub import {
	my $class = shift;
	
	my $package;
	if ( 'SCALAR' eq ref $_[0] ) {
		$package = ${+shift};
	}
	$package ||= our($SETUP_FOR) || caller;
	
	while ( @_ ) {
		my $slot  = shift;
		my $thing = ref($_[0]) ? shift : {};
		my %spec;
		my $type;
		
		if ( is_ArrayRef $thing ) {
			%spec = @$thing;
		}
		elsif ( is_HashRef $thing ) {
			%spec = %$thing;
		}
		elsif ( is_CodeRef $thing ) {
			%spec = ( default => $thing );
		}
		else {
			Exporter::Tiny::_croak( "Expected ARRAY/HASH/CODE reference, not $thing" );
		}
		
		if ( $slot =~ /\A(.*)\!\z/ ) {
			$slot = $1;
			$spec{required} = !!1;
		}
		
		$spec{lazy} = 1 unless exists $spec{lazy};
		
		if ( is_Object $spec{isa} and $spec{isa}->can('compiled_check') ) {
			$type = $spec{isa};
			$spec{isa} = $type->compiled_check;
		}
		elsif ( is_Object $spec{isa} and $spec{isa}->can('check') ) {
			# Support it for compatibility with more basic Type::API::Constraint
			# implementations, but this will be slowwwwww!
			$type = $spec{isa};
			$spec{isa} = sub { !! $type->check($_[0]) };
		}
		
		if ( defined $spec{coerce} and !ref $spec{coerce} and $spec{coerce} eq 1 ) {
			my $c;
			if (
				$type->can('has_coercion')
				and $type->has_coercion
				and $type->can('coercion')
				and is_Object( $c = $type->coercion )
				and $c->can('compiled_coercion') ) {
				$spec{coerce} = $c->compiled_coercion;
			}
			elsif ( $type->can('coerce') ) {
				$spec{coerce} = sub { $type->coerce($_[0]) };
			}
		}
		
		my @unknown_keys = grep !/\A(isa|required|is|lazy|default|builder|coerce|init_arg|trigger|weak_ref|alias|slot_initializer|undef_tolerant|reader)\z/, keys %spec;
		if ( @unknown_keys ) {
			_croak("Unknown keys in spec: %s", join ", ", sort @unknown_keys);
		}
		
		my $has_default = ( exists $spec{default} or defined $spec{builder} ) ? !!$spec{lazy} : 0;
		my $has_type    = exists $spec{isa};
		
		my @args = (
			sprintf( '%s::%s', $package, exists($spec{reader}) ? $spec{reader} : $slot ),
			$slot,
			$has_default,
			$has_default ? Class::XSConstructor::_common_default( $spec{default} ) : 0,
			$has_default ? Class::XSConstructor->_canonicalize_defaults( \%spec ) : undef,
			$has_type ? Class::XSConstructor::_type_to_number( $type ) : 15,
			$has_type ? $spec{isa} : undef,
			$has_type ? $spec{coerce} : undef,
		);
		
		if (our $REDEFINE) {
			no warnings 'redefine';
			Class::XSConstructor::install_reader(@args);
		}
		else {
			Class::XSConstructor::install_reader(@args);
		}
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Class::XSReader - reader functions in XS

=head1 SYNOPSIS

  package Address {
    use Class::XSConstructor qw( number street city region postcode );
    use Class::XSReader      qw( number street city region postcode );
    use Class::XSDestructor;
  }

=head1 DESCRIPTION

L<Class::XSAccessor> should usually be preferred over this module.

However, this module adds support for lazy defaults/builders (with
optional type constraints and coercions).

  use Types::Common qw( Str );
  use Class::XSReader
    name => {
      reader  => "get_name",
      default => "Anonymous",
      isa     => Str,
      coerce  => sub { "$_" },
    };

Note that because this is a reader method only (not a writer/setter),
the type constraints and coercions are only used on the lazy default.
This makes them not especially useful, unless you suspect your default
will sometimes return invalid data.

You can set:

  use Class::XSReader
    name => {
      reader  => "get_name",
      default => "Anonymous",
      lazy    => false,
    };

In which case the default is taken to be eager and the responsibility of
a constructor. It basically means that the default will be ignored, and
therefore any type constraint or coercion will be too. C<< lazy => true >>
is assumed when the C<lazy> option isn't specified.

Builders can be used:

  use Class::XSConstructor qw( first_name! last_name! full_name );
  use Class::XSReader
    qw( first_name last_name ),
    full_name => { builder => '_build_full_name' };
  
  sub _build_full_name ( $self ) {
    return sprintf( '%s %s', $self->first_name, $self->last_name );
  }

=head1 SEE ALSO

L<Class::XSAccessor>.

L<Class::XSConstructor>, L<Class::XSDestructor>, L<Class::XSAccessor>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

