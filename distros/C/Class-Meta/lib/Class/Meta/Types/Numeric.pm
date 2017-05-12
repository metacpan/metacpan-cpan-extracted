package Class::Meta::Types::Numeric;

=head1 NAME

Class::Meta::Types::Numeric - Numeric data types

=head1 SYNOPSIS

  package MyApp::Thingy;
  use strict;
  use Class::Meta;
  use Class::Meta::Types::Numeric;
  # OR...
  # use Class::Meta::Types::Numeric 'affordance';
  # OR...
  # use Class::Meta::Types::Numeric 'semi-affordance';

  BEGIN {
      # Create a Class::Meta object for this class.
      my $cm = Class::Meta->new( key => 'thingy' );

      # Add an integer attribute.
      $cm->add_attribute( name => 'age',
                          type => 'integer' );
      $cm->build;
  }

=head1 DESCRIPTION

This module provides numeric data types for use with Class::Meta attributes.
Simply load it, then pass the name of one of its types to the
C<add_attribute()> method of a Class::Meta object to create attributes of the
numeric data type. See L<Class::Meta::Type|Class::Meta::Type> for more
information on using and creating data types.

The validation checks for Class::Meta::Types::Numeric are provided by the
Data::Types module. Consult its documentation to find out what it considers to
be a number and what's not.

The data types created by Class::Meta::Types::Numeric are:

=over

=item whole

A whole number. That is, a positive integer.

=item integer

=item int

An integer number.

=item decimal

=item dec

A decimal number.

=item real

A real number.

=item float

A floating point number.

=back

=cut

use strict;
use Class::Meta::Type;
use Data::Types ();
our $VERSION = '0.66';

# This code ref builds value checkers.
my $mk_chk = sub {
    my ($code, $type) = @_;
    return [
        sub {
            return unless defined $_[0];
            $code->($_[0])
              or $_[2]->class->handle_error("Value '$_[0]' is not a valid "
                                              . "$type");
            }
    ];
};

##############################################################################
sub import {
    my ($pkg, $builder) = @_;
    $builder ||= 'default';
    return if eval { Class::Meta::Type->new('whole') };

    Class::Meta::Type->add(
        key     => "whole",
        name    => "Whole Number",
        desc    => "Whole number",
        builder => $builder,
        check   => $mk_chk->(\&Data::Types::is_whole, 'whole number'),
    );

    Class::Meta::Type->add(
        key     => "integer",
        name    => "Integer",
        desc    => "Integer",
        alias   => 'int',
        builder => $builder,
        check   => $mk_chk->(\&Data::Types::is_int, 'integer'),
    );

    Class::Meta::Type->add(
        key     => "decimal",
        name    => "Decimal Number",
        desc    => "Decimal number",
        alias   => 'dec',
        builder => $builder,
        check   => $mk_chk->(\&Data::Types::is_decimal, 'decimal number'),
    );

    Class::Meta::Type->add(
        key     => "real",
        name    => "Real Number",
        desc    => "Real number",
        builder => $builder,
        check   => $mk_chk->(\&Data::Types::is_real, 'real number'),
    );

    Class::Meta::Type->add(
        key     => "float",
        name    => "Floating Point Number",
        desc    => "Floating point number",
        builder => $builder,
        check   => $mk_chk->(\&Data::Types::is_float, 'floating point number'),
    );
}

1;
__END__

=head1 SUPPORT

This module is stored in an open L<GitHub
repository|http://github.com/theory/class-meta/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/class-meta/issues/> or by sending mail to
L<bug-Class-Meta@rt.cpan.org|mailto:bug-Class-Meta@rt.cpan.org>.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

=head1 SEE ALSO

Other classes of interest within the Class::Meta distribution include:

=over 4

=item L<Class::Meta|Class::Meta>

This class contains most of the documentation you need to get started with
Class::Meta.

=item L<Class::Meta::Type|Class::Meta::Type>

This class manages the creation of data types.

=item L<Class::Meta::Attribute|Class::Meta::Attribute>

This class manages Class::Meta class attributes, all of which are based on
data types.

=back

Other data type modules:

=over 4

=item L<Class::Meta::Types::Perl|Class::Meta::Types::Perl>

=item L<Class::Meta::Types::String|Class::Meta::Types::String>

=item L<Class::Meta::Types::Boolean|Class::Meta::Types::Boolean>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
