package DBIx::Class::DigestColumns::Lite;
use strict;
use warnings;
use base 'DBIx::Class';
use Digest::SHA1 ();

our $VERSION = 0.03;

__PACKAGE__->mk_classdata( force_digest_columns => [] );
__PACKAGE__->mk_classdata( digest_key => '');

sub digest {
    my ($self ,$val) = @_;
    return Digest::SHA1::sha1_hex(($val || '') . ($self->digest_key || ''));
}

sub digest_columns {
    my $self = shift;

    for (@_) {
        $self->throw_exception("column $_ doesn't exist")
            unless $self->has_column($_);
    }

    $self->force_digest_columns( \@_ );
}

sub store_column {
    my ( $self, $column, $value ) = @_;

    if ( { map { $_ => 1 } @{ $self->force_digest_columns } }->{$column} ) {
        $value = $self->digest($value);
    }

    $self->next::method( $column, $value );
}

1;
__END__

=head1 NAME

DBIx::Class::DigestColumns::Lite -  easy to use Digest Value for DBIx::Class

=head1 SYNOPSIS

    package DBIC::Schema::User;
    use base 'DBIx::Class';
    __PACKAGE__->load_components(qw/DigestColumns::Lite PK::Auto Core/);
    ....
    __PACKAGE__->digest_columns(qw/passwd/);
    __PACKAGE__->digest_key('no not yet...');

=head1 DESCRIPTION

you can easy to use Digest Value.
This module use Digest::SHA1.

=head1 METHOD

=head2 digest_columns

set digest columns colum name.

=head2 store_column

auto set digest value.

=head2 digest

get digested value.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Atsushi Kobayashi  C<< <atsushi __at__ mobilefactory.jp> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Atsushi Kobayashi C<< <atsushi __at__ mobilefactory.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

