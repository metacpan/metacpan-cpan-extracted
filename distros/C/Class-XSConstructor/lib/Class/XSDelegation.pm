use 5.008008;
use strict;
use warnings;
use Class::XSConstructor ();

package Class::XSDelegation;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.016001';

sub import {
	my $class = shift;
	
	my $package;
	if ( 'SCALAR' eq ref $_[0] ) {
		$package = ${+shift};
	}
	$package ||= our($SETUP_FOR) || caller;
	
	for my $delegation ( @_ ) {
		my ( $methodname, $handler_slot, $handler_method, $opts ) = @$delegation;
		$opts ||= {};
		
		my @args = (
			"$package\::$methodname",
			$handler_slot,
			$handler_method,
			$opts->{curry} || $opts->{curried} || undef,
			!!( $opts->{is_accessor}  || $opts->{accessor}  || 0 ),
			!!( $opts->{is_try}       || $opts->{try}       || 0 ),
		);
		
		if (our $REDEFINE) {
			no warnings 'redefine';
			Class::XSConstructor::install_delegation(@args);
		}
		else {
			Class::XSConstructor::install_delegation(@args);
		}
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Class::XSDelegation - delegations in XS

=head1 SYNOPSIS

  package Address {
    use Class::XSConstructor qw( number street city region postcode );
    use Class::XSDestructor;
    use Class::XSAccessor {
      accessors => [qw( number street city region postcode )],
    };
  }
  
  package Person {
    use Class::XSConstructor qw( name! age email phone address );
    use Class::XSDestructor;
    use Class::XSAccessor {
      accessors         => [qw( name age email phone address )],
      exists_predicates => [qw(      age email phone address )],
    };
    use Class::XSDelegation [ 'locality' => 'address' => 'city' ];
  }

The delegation is equivalent to:

  sub Person::locality {
    return shift->{address}->city( @_ );
  }

=head1 DESCRIPTION

The constructor may be passed a list of arrayrefs. Each arrayref consists of:

  [ $local_method, $handler, $handler_method, \%options ]

Valid options are:

  {
    curry       => ARRAYREF,
    is_try      => BOOL,
    is_accessor => BOOL,
  }

If an arrayref is provided to C<curry>, then the generated method is:

  sub Person::locality {
    return shift->{address}->city( @curried, @_ );
  }

If C<is_try> is true, then the method will quietly return undef if
C<< shift->{address} >> isn't a blessed object.

If C<is_accessor> is true, then the generated method is:

  sub Person::locality {
    return shift->address->city( @_ );
  }

... so it calls the C<address> accessor method instead of accessing
the object hashref directly. This is useful if C<address> has a lazily
built default or has any more complex logic.

The package to create these methods is usually determined by C<caller>,
but you can override it using:

  use Class::XSDelegation \"Some::Package", [ ... ];

=head1 SEE ALSO

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

