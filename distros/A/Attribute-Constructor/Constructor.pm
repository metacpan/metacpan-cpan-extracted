package Attribute::Constructor;

use 5.006;
use strict;
use warnings;

use Attribute::Handlers;

our $VERSION = '0.04';

sub UNIVERSAL::Constructor : ATTR(CODE) {
	my ($package, $symbol, $referent, $attr, $data) = @_;

	no warnings 'redefine';
	*{$symbol} = sub {

		my $self = shift;
		my $class = ref($self) || $self;
		my $instance = {};
		bless( $instance, $class );

		# Run the constructor
		$referent->( $instance, @_ );

		# Return the new object
		return $instance;
	}
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Attribute::Constructor - implementing constructors with attributes

=head1 SYNOPSIS

	package SomeObj;
	use Attribute::Constructor;

	sub new : Constructor {
		my $self = shift;
		$self->{attribute1} = shift;
		$self->{attribute2} = shift;
	}
	
	--- Calling Code ----
	
	# Will create the object with 'attribute1' and
	# 'attribute2' being set to 'foo' and 'bar' respectively
	my $new_obj = SomeObj->new( 'foo', 'bar' );
	or
	my $new_obj = $old_obj->new( 'foo', 'bar' );

=head1 DESCRIPTION

Declaring a method of an object as a constructor will cause the object
to be created, blessed, and returned to the calling code. This will allow
the constructor to look more like a "real" constructor from an OO language
that supports the idea of constructor with syntax.

The object is already returned to the calling code so there is no need to
return it. The first argument will be a reference to the new class instead
of a reference to the class so that it behaves more like a normal constructor
in the fact that it is a instance method not a class method.


=head1 HISTORY

=over 8

=item 0.04

Made the constructor behave as a static or virtual method

=item 0.03

Packaged it up so that it can be uploaded to CPAN

=item 0.02

Modified the code some to make it behave more generically

=item 0.01

Original Version: Used for internal project

=back

=head1 BUGS

None known so far. If you find any please send the AUTHOR a message.

=head1 AUTHOR

Eric Anderson, E<lt>eric.anderson@cordata.netE<gt>

=head1 COPYRIGHT

Copyright 2002 Eric Anderson. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>.

=cut
