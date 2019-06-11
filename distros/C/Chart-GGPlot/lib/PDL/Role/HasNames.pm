package PDL::Role::HasNames;

# ABSTRACT: Role for attaching per-element names to a piddle

use 5.010;
use strict;
use warnings;

our $VERSION = '0.0005'; # VERSION

use Role::Tiny;
use PDL::SV ();

use Hash::Util::FieldHash qw(fieldhash);
use Safe::Isa;
use Type::Params;
use Types::Standard qw(ConsumerOf ArrayRef);

fieldhash my %objects;


sub names {
    my ( $self, $names ) = @_;

    if ( defined $names ) {
        state $check = Type::Params::compile( ( ConsumerOf ['PDL::SV'] )
            ->plus_coercions( ArrayRef, sub { PDL::SV->new($_) } ) );
        ($names) = $check->($names);

        unless ( ( $names->shape == $self->shape )->all ) {
            die "names has to be of same length as the raw piddle";
        }
        $objects{$self}{names} = $names;
    }
    return $objects{$self}{names};
}

sub _around_and_attach_names {
    my ($f_new_names) = @_;

    return sub {
        my $orig = shift;
        my $self = shift;

        my $new = $self->$orig(@_);
        if ( defined (my $names = $self->names) ) {
            unless ( $new->$_DOES(__PACKAGE__) ) {
                Role::Tiny->apply_roles_to_object( $new, __PACKAGE__ );
            }
            $new->names( $names->$f_new_names(@_) );
        }
        return $new;
    };
}

for my $method (qw(copy setbadif)) {
    around $method => _around_and_attach_names( sub { shift->copy; } );
}
around slice => _around_and_attach_names( sub { shift->slice(@_); } );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDL::Role::HasNames - Role for attaching per-element names to a piddle

=head1 VERSION

version 0.0005

=head1 STATUS

At current stage this module is experimental. It was created for being
internally used by L<Chart::GGPlot>.
Please contact the author if you would like to directly use this module
in your code. 

=head1 SYNOPSIS

    use PDL;
    use Role::Tiny ();

    my $p = pdl(1..3);
    Role::Tiny->apply_roles_to_object($p, 'PDL::Role::HasNames');

    $p->names([qw(foo bar baz)]);

=head1 DESCRIPTION

This role tries to provide a way to make something similar as R's feature
of the C<names> attribute, which allows attaching a per-element string
name to a vector.

For some PDL methods like C<copy> and C<slice>, the C<names> attribute is
retained in the result. For many other methods, it's lost. 

=head1 ATTRIBUTES

=head2 names

Per-element names attached to the piddle.

It's an "rw" attribute.
In the "writer" mode, either an arrayref or a PDL::SV object are
acceptable. PDL::SV is use internally, so in case of an arrayref it
would be converted to a PDL::SV object. The specified value has to be of 
same dimensions as the original piddle.
In the "reader" mode, it returns a PDL::SV object.

=head1 SEE ALSO

L<Role::Tiny>, L<PDL::SV>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
