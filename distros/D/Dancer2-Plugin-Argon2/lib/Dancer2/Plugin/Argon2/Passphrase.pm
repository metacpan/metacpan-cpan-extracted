package Dancer2::Plugin::Argon2::Passphrase;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

use Crypt::Argon2 qw( argon2id_pass argon2id_verify );
use Crypt::URandom;

sub new {
    my ( $class, $settings ) = @_;
    return bless $settings, $class;
}

sub encoded {
    my $self = shift;
    $self->{salt} = Crypt::URandom::urandom(16);
    my @argon2_params = ( map { $self->{$_} } qw( salt cost factor parallelism size ) );
    return argon2id_pass( $self->{password}, @argon2_params );
}

sub matches {
    my ( $self, $passphrase ) = @_;
    return argon2id_verify( $passphrase, $self->{password} );
}

1;
__END__

=encoding utf-8

=head1 NAME

Dancer2::Plugin::Argon2::Passphrase - Argon2 Passphrase object

=head1 SYNOPSIS

    use Dancer2::Plugin::Argon2;

=head1 DESCRIPTION

The class is for creating a C<Passphrase> object.

=head1 METHODS

=head2 encoded()

Returns crypt-like encoded argon2 string (AKA encoded hash).
Like: C<$argon2id$v=19$m=65536,t=3,p=1$c29tZXNhbHQ$noeJyLQoNCIK/AAIWsc6zDCGUSFplKu/3dabJZIDLv0>.

=head2 matches($passphrase)

Checks whether password (in the current object) matches provided password phrase (usually stored value).
Returns a truth value.

=head1 TODO

=over

=item * Add accessors (salt, cost, etc)

=item * RFC 2307 encoding

=back

=head1 SEE ALSO

L<Crypt::Argon2>,
L<https://github.com/p-h-c/phc-winner-argon2>

=head1 LICENSE

Copyright (C) Sergiy Borodych.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Sergiy Borodych C<< <bor at cpan.org> >>

=cut

