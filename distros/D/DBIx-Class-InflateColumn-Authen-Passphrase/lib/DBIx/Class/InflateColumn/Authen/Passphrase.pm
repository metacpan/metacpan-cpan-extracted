use strict;
use warnings;

package DBIx::Class::InflateColumn::Authen::Passphrase; # git description: v0.02-2-gdc402d1
# ABSTRACT: Inflate/deflate columns to Authen::Passphrase instances

our $VERSION = '0.03';

use Authen::Passphrase;
use parent 'DBIx::Class';

#pod =head1 SYNOPSIS
#pod
#pod     __PACKAGE__->load_components(qw(InflateColumn::Authen::Passphrase));
#pod
#pod     __PACKAGE__->add_columns(
#pod         id => {
#pod             data_type         => 'integer',
#pod             is_auto_increment => 1,
#pod         },
#pod         passphrase_rfc2307 => {
#pod             data_type          => 'text',
#pod             inflate_passphrase => 'rfc2307',
#pod         },
#pod         passphrase_crypt => {
#pod             data_type          => 'text',
#pod             inflate_passphrase => 'crypt',
#pod         },
#pod     );
#pod
#pod     __PACKAGE__->set_primary_key('id');
#pod
#pod
#pod     # in application code
#pod     $rs->create({ passphrase_rfc2307 => Authen::Passphrase::RejectAll->new });
#pod
#pod     my $row = $rs->find({ id => $id });
#pod     if ($row->passphrase_rfc2307->match($input)) { ...
#pod
#pod =head1 DESCRIPTION
#pod
#pod Provides inflation and deflation for Authen::Passphrase instances from and to
#pod either RFC 2307 or crypt encoding.
#pod
#pod To enable both inflating and deflating, C<inflate_passphrase> must be set to a
#pod valid passphrase encoding. Currently the only supported encodings are C<rfc2307>
#pod and C<crypt>. The specified encoding will be used both when storing
#pod C<Authen::Passphrase> instances in columns, and when creating
#pod C<Authen::Passphrase> instances from columns. See L<Authen::Passphrase> for
#pod details on passphrase encodings.
#pod
#pod Note that not all passphrase schemes supported by C<Authen::Passphrase> can be
#pod represented in either RFC 2307 or crypt encoding. Chose the kind of passphrase
#pod encoding you're using based on the encoding supported by the passphrase algorithms
#pod you're using.
#pod
#pod When trying to encode a passphrase instance with an encoding that doesn't
#pod support it, an exception will be thrown. Similarly, when trying to load a
#pod passphrase instance from a faulty or unknown encoded representation, an
#pod exception will be thrown.
#pod
#pod =method register_column
#pod
#pod Chains with the C<register_column> method in C<DBIx::Class::Row>, and sets up
#pod passphrase columns appropriately. This would not normally be directly called by
#pod end users.
#pod
#pod =cut

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

=encoding UTF-8

=head1 NAME

DBIx::Class::InflateColumn::Authen::Passphrase - Inflate/deflate columns to Authen::Passphrase instances

=head1 VERSION

version 0.03

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
valid passphrase encoding. Currently the only supported encodings are C<rfc2307>
and C<crypt>. The specified encoding will be used both when storing
C<Authen::Passphrase> instances in columns, and when creating
C<Authen::Passphrase> instances from columns. See L<Authen::Passphrase> for
details on passphrase encodings.

Note that not all passphrase schemes supported by C<Authen::Passphrase> can be
represented in either RFC 2307 or crypt encoding. Chose the kind of passphrase
encoding you're using based on the encoding supported by the passphrase algorithms
you're using.

When trying to encode a passphrase instance with an encoding that doesn't
support it, an exception will be thrown. Similarly, when trying to load a
passphrase instance from a faulty or unknown encoded representation, an
exception will be thrown.

=head1 METHODS

=head2 register_column

Chains with the C<register_column> method in C<DBIx::Class::Row>, and sets up
passphrase columns appropriately. This would not normally be directly called by
end users.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Class-InflateColumn-Authen-Passphrase>
(or L<bug-DBIx-Class-InflateColumn-Authen-Passphrase@rt.cpan.org|mailto:bug-DBIx-Class-InflateColumn-Authen-Passphrase@rt.cpan.org>).

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
