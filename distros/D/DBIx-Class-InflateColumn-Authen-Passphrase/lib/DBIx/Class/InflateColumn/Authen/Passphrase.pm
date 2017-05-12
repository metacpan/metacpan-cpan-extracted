use strict;
use warnings;

package DBIx::Class::InflateColumn::Authen::Passphrase;
BEGIN {
  $DBIx::Class::InflateColumn::Authen::Passphrase::AUTHORITY = 'cpan:FLORA';
}
BEGIN {
  $DBIx::Class::InflateColumn::Authen::Passphrase::VERSION = '0.01';
}
# ABSTRACT: Inflate/deflate columns to Authen::Passphrase instances

use Authen::Passphrase;
use parent 'DBIx::Class';


sub register_column {
    my ($self, $column, $info, @rest) = @_;

    $self->next::method($column, $info, @rest);
    return unless my $encoding = $info->{inflate_passphrase};

    $self->throw_exception(q['rfc2307' and 'crypt' are the only supported types of passphrase columns])
        unless $encoding eq 'rfc2307' || $encoding eq 'crypt';

    $self->inflate_column(
        $column => {
            inflate => sub { Authen::Passphrase->${\"from_${encoding}"}(shift) },
            deflate => sub { shift->${\"as_${encoding}"} },
        },
    );
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

DBIx::Class::InflateColumn::Authen::Passphrase - Inflate/deflate columns to Authen::Passphrase instances

=head1 SYNOPSIS

    __PACKAGE__->load_components(qw(InflateColumn::Authen::Passphrase));

    __PACKAGE__->add_columns(
        id => {
            data_type         => 'integer',
            is_auto_increment => 1,
        },
        passphrase_rfc2307 => {
            data_type          => 'text',
            inflate_passphrase => 'rfc2307',
        },
        passphrase_crypt => {
            data_type          => 'text',
            inflate_passphrase => 'crypt',
        },
    );

    __PACKAGE__->set_primary_key('id');


    # in application code
    $rs->create({ passphrase_rfc2307 => Authen::Passphrase::RejectAll->new });

    my $row = $rs->find({ id => $id });
    if ($row->passphrase_rfc2307->match($input)) { ...

=head1 DESCRIPTION

Provides inflation and deflation for Authen::Passphrase instances from and to
either RFC 2307 or crypt encoding.

To enable both inflating and deflating, C<inflate_passphrase> must be set to a
valid passhrase encoding. Currently the only supported encodings are C<rfc2307>
and C<crypt>. The specified encoding will be used both when storing
C<Authen::Passphrase> instances in columns, and when creating
C<Authen::Passphrase> instances from columns. See L<Authen::Passphrase> for
details on passphrase encodings.

Note that not all passphrase schemes supported by C<Authen::Passphrase> can be
represented in either RFC 2307 or crypt encoding. Chose the kind of passphrase
encoding you're using based on the encoding the passphrase algorithms you're
using support.

When trying to encode a passphrase instance with an encoding that doesn't
support it, an exception will be thrown. Similarly, when trying to load a
passphrase instance from a faulty or unknown encoded representation, an
exception will be thrown.

=head1 METHODS

=head2 register_column

Chains with the C<register_column> method in C<DBIx::Class::Row>, and sets up
passphrase columns appropriately. This would not normally be directly called by
end users.

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

