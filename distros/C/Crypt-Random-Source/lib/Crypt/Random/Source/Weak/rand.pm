package Crypt::Random::Source::Weak::rand;
# ABSTRACT: Use C<rand> to create random bytes

our $VERSION = '0.12';

use Moo;

use bytes;

extends qw(
    Crypt::Random::Source::Weak
    Crypt::Random::Source::Base
);
use namespace::clean;

sub rank { -100 } # slow fallback

sub available { 1 }

sub seed {
    my ( $self, @args ) = @_;
    srand( unpack("%L*", @args) );
}

sub get {
    my ( $self, $n ) = @_;
    pack "C*", map { int rand 256 } 1 .. $n;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Crypt::Random::Source::Weak::rand - Use C<rand> to create random bytes

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Crypt::Random::Source::Weak::rand;

    my $p = Crypt::Random::Source::Weak::rand->new;

    $p->get(1024);

=head1 DESCRIPTION

This is a weak source of random data, that uses Perl's builtin C<rand>
function.

=head1 METHODS

=head2 seed @blah

Sets the random seed to a checksum of the stringified values of C<@blah>.

There is no need to call this method unless you want the random sequence to be
identical to a previously run, in which case you should seed with the same
value.

=head2 get $n

Produces C<$n> random bytes.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Crypt-Random-Source>
(or L<bug-Crypt-Random-Source@rt.cpan.org|mailto:bug-Crypt-Random-Source@rt.cpan.org>).

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


# ex: set sw=4 et:
