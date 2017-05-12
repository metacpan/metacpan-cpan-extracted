package Class::Meta::Types::Perl;

=head1 NAME

Class::Meta::Types::Perl - Perl data types

=head1 SYNOPSIS

  package MyApp::Thingy;
  use strict;
  use Class::Meta;
  use Class::Meta::Types::Perl;
  # OR...
  # use Class::Meta::Types::Perl 'affordance';
  # OR...
  # use Class::Meta::Types::Perl 'semi-affordance';

  BEGIN {
      # Create a Class::Meta object for this class.
      my $cm = Class::Meta->new( key => 'thingy' );

      # Add an integer attribute.
      $cm->add_attribute( name => 'my_hash',
                          type => 'hash' );
      $cm->build;
  }

=head1 DESCRIPTION

This module provides Perl data types for use with Class::Meta attributes.
Simply load it, then pass the name of one of its types to the
C<add_attribute()> method of a Class::Meta object. See
L<Class::Meta::Type|Class::Meta::Type> for more information on using and
creating data types.

The validation checks for Class::Meta::Types::Perl are provided by the
Class::Meta::Type's support for object type validation, since Perl data types
are understood by C<UNIVERSAL::isa()>.

The data types created by Class::Meta::Types::Perl are:

=over

=item scalar

A simple scalar value. This can be anything, and has no validation checks.

=item scalarref

A scalar reference. C<UNIVERSAL::isa()> must return 'SCALAR'.

=item array

=item arrayref

A array reference. C<UNIVERSAL::isa()> must return 'ARRAY'.

=item hash

=item hashref

A hash reference. C<UNIVERSAL::isa()> must return 'HASH'.

=item code

=item coderef

=item closure

A code reference. Also known as a closure. C<UNIVERSAL::isa()> must return
'CODE'.

=back

=cut

use strict;
use Class::Meta::Type;
our $VERSION = '0.66';

sub import {
    my ($pkg, $builder) = @_;
    $builder ||= 'default';
    return if eval "Class::Meta::Type->new('array')";

    Class::Meta::Type->add(
        key     => "scalar",
        name    => "Scalar",
        desc    => "Scalar",
        builder => $builder,
    );

    Class::Meta::Type->add(
        key     => "scalarref",
        name    => "Scalar Reference",
        desc    => "Scalar reference",
        builder => $builder,
        check   => 'SCALAR',
    );

    Class::Meta::Type->add(
        key     => "array",
        name    => "Array Reference",
        desc    => "Array reference",
        alias   => 'arrayref',
        builder => $builder,
        check   => 'ARRAY',
    );

    Class::Meta::Type->add(
        key     => "hash",
        name    => "Hash Reference",
        desc    => "Hash reference",
        alias   => 'hashref',
        builder => $builder,
        check   => 'HASH',
    );

    Class::Meta::Type->add(
        key     => "code",
        name    => "Code Reference",
        desc    => "Code reference",
        alias   => [qw(coderef closure)],
        builder => $builder,
        check   => 'CODE',
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

=item L<Class::Meta::Types::String|Class::Meta::Types::String>

=item L<Class::Meta::Types::Boolean|Class::Meta::Types::Boolean>

=item L<Class::Meta::Types::Numeric|Class::Meta::Types::Numeric>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
