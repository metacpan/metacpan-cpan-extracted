package Class::Meta::Types::Boolean;

=head1 NAME

Class::Meta::Types::Boolean - Boolean data types

=head1 SYNOPSIS

  package MyApp::Thingy;
  use strict;
  use Class::Meta;
  use Class::Meta::Types::Boolean;
  # OR...
  # use Class::Meta::Types::Boolean 'affordance';
  # OR...
  # use Class::Meta::Types::Boolean 'semi-affordance';

  BEGIN {
      # Create a Class::Meta object for this class.
      my $cm = Class::Meta->new( key => 'thingy' );

      # Add a boolean attribute.
      $cm->add_attribute( name => 'alive',
                          type => 'boolean' );
      $cm->build;
  }

=head1 DESCRIPTION

This module provides a boolean data type for use with Class::Meta attributes.
Simply load it, then pass "boolean" (or the alias "bool") to the
C<add_attribute()> method of a Class::Meta object to create an attribute of
the boolean data type. See L<Class::Meta::Type|Class::Meta::Type> for more
information on using and creating data types.

=head2 Accessors

Although the boolean data type has both "default" and "affordance" accessor
options available, unlike the other data types that ship with Class::Meta,
they have different implementations. The reason for this is to ensure that
the value of a boolean attribute is always 0 or 1.

For the "default" accessor style, there is no difference in the interface from
the default accessors for other data types. The default accessor merely checks
the truth of the new value, and assigns 1 if it's a true value, and 0 if it's
a false value. The result is an efficient accessor that maintains the
consistency of the data.

For the "affordance" accessor style, however, the boolean data type varies in
the accessors it creates. For example, for a boolean attributed named "alive",
instead of creating the C<get_alive> and C<set_alive> accessors common to
other affordance-style accessors, it instead creates three:

=over 4

=item C<is_alive>

=item C<set_alive_on>

=item C<set_alive_off>

=back

The result is highly efficient accessors that ensure the integrity of the data
without the overhead of validation checks.

=cut

use strict;
use Class::Meta::Type;
our $VERSION = '0.66';

sub import {
    my ($pkg, $builder) = @_;
    $builder ||= 'default';
    return if eval "Class::Meta::Type->new('boolean')";

    if ($builder eq 'default') {
        eval q|
sub build_attr_get {
    UNIVERSAL::can($_[0]->package, $_[0]->name);
}

*build_attr_set = \&build_attr_get;

sub build {
    my ($pkg, $attr, $create) = @_;
    $attr = $attr->name;

    no strict 'refs';
    if ($create == Class::Meta::GET) {
        # Create GET accessor.
        *{"${pkg}::$attr"} = sub { $_[0]->{$attr} };

    } elsif ($create == Class::Meta::SET) {
        # Create SET accessor.
        *{"${pkg}::$attr"} = sub { $_[0]->{$attr} = $_[1] ? 1 : 0 };

    } elsif ($create == Class::Meta::GETSET) {
        # Create GETSET accessor.
        *{"${pkg}::$attr"} = sub {
            my $self = shift;
            return $self->{$attr} unless @_;
            $self->{$attr} = $_[0] ? 1 : 0
        };
    } else {
        # Well, nothing I guess.
    }
}|
    } else {

        my $code = q|
sub build_attr_get {
    UNIVERSAL::can($_[0]->package, 'is_' . $_[0]->name);
}

sub build_attr_set {
    my $name = shift->name;
    eval "sub { \$_[1] ? \$_[0]->set_$name\_on : \$_[0]->set_$name\_off }";
}

sub build {
    my ($pkg, $attr, $create) = @_;
    $attr = $attr->name;

    no strict 'refs';
    if ($create >= Class::Meta::GET) {
        # Create GET accessor.
        *{"${pkg}::is_$attr"} = sub { $_[0]->{$attr} };
    }
    if ($create >= Class::Meta::SET) {
        # Create SET accessors.
        *{"${pkg}::set_$attr\_on"} = sub { $_[0]->{$attr} = 1 };
        *{"${pkg}::set_$attr\_off"} = sub { $_[0]->{$attr} = 0 };
    }
}|;

        $code =~ s/get_//g unless $builder eq 'affordance';
        eval $code;
    }

    Class::Meta::Type->add(
        key     => "boolean",
        name    => "Boolean",
        desc    => "Boolean",
        alias   => 'bool',
        builder => __PACKAGE__
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

=item L<Class::Meta::Types::Numeric|Class::Meta::Types::Numeric>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
