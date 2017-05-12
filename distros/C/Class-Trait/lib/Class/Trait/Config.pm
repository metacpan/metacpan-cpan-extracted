package Class::Trait::Config;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

our $VERSION = '0.31';

# we are going for a very struct-like class here to try and keep the
# syntactical noise down.

# We never intend this class to be subclassed, so the constructor is very
# simple on purpose.  you can consider this class to be effectively sealed.

sub new {
    my $class = shift;
    return bless {
        name         => "",
        sub_traits   => [],
        requirements => {},
        methods      => {},
        overloads    => {},
        conflicts    => {}
    }, $class;
}

__PACKAGE__->mk_accessors(qw(
    name sub_traits requirements methods overloads conflicts
));

# a basic clone function for moving in and out of the cache.
sub clone {
    my $self  = shift;
    my $class = ref $self;
    return bless {
        name         => $self->{name},
        sub_traits   => [ @{ $self->{sub_traits} } ],
        requirements => { %{ $self->{requirements} } },
        methods      => { %{ $self->{methods} } },
        overloads    => { %{ $self->{overloads} } },
        conflicts    => { %{ $self->{conflicts} } },
    }, $class;
}

1;

__END__

=head1 NAME

Class::Trait::Config - Trait configuration information storage package.

=head1 SYNOPSIS

This package is used internally by Class::Trait to store Trait configuration
information. It is also used by Class::Trait::Reflection to gather information
about a Trait.

=head1 DESCRIPTION

This class is a intentionally very C-struct-like. It is meant to help
encapsulate the Trait configuration information in a clean easy to access way.

This class is effectively sealed. It is not meant to be extended, only to be
used. 

=head1 METHODS

=over 4

=item B<new>

Creates a new empty Class::Trait::Config object, with fields initialized to
empty containers. 

=item B<name>

An accessor to the C<name> string field of the Class::Trait::Config object.

=item B<sub_traits>

An accessor to the C<sub_traits> array reference field of the Class::Trait::Config object.

=item B<requirements>

An accessor to the C<requirements> hash reference field
of the Class::Trait::Config object. Note, the requirements field is a hash
reference to speed requirement lookup, the values of the hash are simply
booleans.

=item B<methods>

An accessor to the C<methods> hash reference field of the Class::Trait::Config object.

=item B<overloads>

An accessor to the C<overloads> hash reference field of
the Class::Trait::Config object.

=item B<conflicts>

An accessor to the C<conflicts> hash reference field of
the Class::Trait::Config object. Note, the conflicts field is a hash reference
to speed conflict lookup, the values of the hash are simply booleans.

=item B<clone>

Provides deep copy functionality for the Class::Trait::Config object. This
will be sure to copy all sub-elements of the object, but not to attempt to
copy and subroutine references found.

=back

=head1 SEE ALSO

B<Class::Trait>, B<Class::Trait::Reflection>

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com> 

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut
