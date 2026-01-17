use 5.008008;
use strict;
use warnings;
use Class::XSConstructor ();

package Class::XSDestructor;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.022001';

sub import {
	my $class = shift;
	my ( $package, $methodname );
	if ( 'ARRAY' eq ref $_[0] ) {
		( $package, $methodname ) = @{+shift};
	}
	$package    ||= our($SETUP_FOR) || caller;
	$methodname ||= 'DESTROY';
	
	my @XS_args = (
		"$package\::$methodname",
		"$package\::DEMOLISHALL",
		"$package\::XSCON_CLEAR_DESTRUCTOR_CACHE",
	);
	
	if (our $REDEFINE) {
		no warnings 'redefine';
		Class::XSConstructor::install_destructor( @XS_args );
	}
	else {
		Class::XSConstructor::install_destructor( @XS_args );
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Class::XSDestructor - a destructor in XS

=head1 SYNOPSIS

  package Person {
    use Class::XSConstructor qw( name! age email phone );
    use Class::XSDestructor;
    use Class::XSAccessor {
      accessors         => [qw( name age email phone )],
      exists_predicates => [qw(      age email phone )],
    };
  }

=head1 DESCRIPTION

Importing this class gives you a C<DESTROY> method which acts similarly
to the C<DESTROY> method provided by L<Moose> and L<Moo>, calling C<DEMOLISH>
methods at every level of the inheritance hierarchy.

It also installs a C<DEMOLISHALL> method which does the same but accepts
additional arguments which it passes on to the C<DEMOLISH> methods, while
C<DESTROY> ignores any parameters and passes the C<DEMOLISH> methods a
single boolean parameter indicating whether the Perl process is in global
destruction or not.

=head1 SEE ALSO

L<Class::XSConstructor>, L<Class::XSDelegation>, L<Class::XSReader>,
L<Class::XSAccessor>.

L<Devel::GlobalDestruction>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025-2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

