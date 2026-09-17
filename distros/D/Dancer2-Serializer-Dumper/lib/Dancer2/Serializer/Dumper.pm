# ABSTRACT: Serializer for handling Dumper data

package Dancer2::Serializer::Dumper;
our $VERSION = '2.2.1'; # VERSION

use Moo;
use Carp 'croak';
use Data::Dumper;
use Safe;

with 'Dancer2::Core::Role::Serializer';

has '+content_type' => ( default => sub {'text/x-data-dumper'} );

# helpers
sub from_dumper { shift; __PACKAGE__->deserialize(@_) }

sub to_dumper { shift; __PACKAGE__->serialize(@_) }

# class definition
sub serialize {
    my ( $self, $entity ) = @_;

    {
        local $Data::Dumper::Purity = 1;
        return Dumper($entity);
    }
}

sub deserialize {
    my ( $self, $content ) = @_;

    my $cpt = Safe->new;

    my $res = $cpt->reval("my \$VAR1; $content");
    croak "unable to deserialize : $@" if $@;
    return $res;
}

1;

__END__

=head1 DESCRIPTION

This is a serializer engine that allows you to turn Perl data structures into
L<Data::Dumper> output and vice-versa.

Since version 2.2.0 of L<Dancer2>, the Dumper serializer is no longer
shipped as part of the core framework, but is available as its own CPAN
distribution, C<Dancer2-Serializer-Dumper>. Install this distribution if you
want to use it, and add its dependencies to your application.

=head1 SECURITY

The C<deserialize> method evaluates the content as Perl code, inside a
L<Safe> compartment. L<Safe> is not a real security sandbox, so this
serializer must never be used to deserialize untrusted input. L<Dancer2>'s
L<Dancer2::Serializer::Mutable> serializer therefore leaves the Dumper
serializer disabled by default: if you really want to opt in to it, you must
set C<enable_dumper> in your Mutable serializer configuration, and you must
have this distribution installed.

=head1 METHODS

=attr content_type

Returns 'text/x-data-dumper'

=func from_dumper($content)

This is an helper available to transform a L<Data::Dumper> output to a Perl
data structures.

=func to_dumper($content)

This is an helper available to transform a Perl data structures to a
L<Data::Dumper> output.

Calling this function will B<not> trigger the serialization's hooks.

=method serialize($content)

Serializes a Perl data structure into a Dumper string.

=method deserialize($content)

Deserialize a Dumper string into a Perl data structure.
