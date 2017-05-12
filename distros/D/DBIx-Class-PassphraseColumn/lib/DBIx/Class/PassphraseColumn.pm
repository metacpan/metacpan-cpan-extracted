use strict;
use warnings;

package DBIx::Class::PassphraseColumn;
BEGIN {
  $DBIx::Class::PassphraseColumn::AUTHORITY = 'cpan:FLORA';
}
BEGIN {
  $DBIx::Class::PassphraseColumn::VERSION = '0.02';
}
# ABSTRACT: Automatically hash password/passphrase columns

use Class::Load 'load_class';
use Sub::Name 'subname';
use namespace::clean;

use parent 'DBIx::Class';


__PACKAGE__->load_components(qw(InflateColumn::Authen::Passphrase));

__PACKAGE__->mk_classdata('_passphrase_columns');


sub register_column {
    my ($self, $column, $info, @rest) = @_;

    if (my $encoding = $info->{passphrase}) {
        $info->{inflate_passphrase} = $encoding;

        $self->throw_exception(q['passphrase_class' is a required argument])
            unless exists $info->{passphrase_class}
                && defined $info->{passphrase_class};

        my $class = 'Authen::Passphrase::' . $info->{passphrase_class};
        load_class $class;

        my $args = $info->{passphrase_args} || {};
        $self->throw_exception(q['passphrase_args' must be a hash reference])
            unless ref $args eq 'HASH';

        my $encoder = sub {
            my ($val) = @_;
            $class->new(%{ $args }, passphrase => $val)->${\"as_${encoding}"};
        };

        $self->_passphrase_columns({
            %{ $self->_passphrase_columns || {} },
            $column => $encoder,
        });

        if (defined(my $meth = $info->{passphrase_check_method})) {
            my $checker = sub {
                my ($row, $val) = @_;
                return $row->get_inflated_column($column)->match($val);
            };

            my $name = join q[::] => $self->result_class, $meth;

            {
                no strict 'refs';
                *$name = subname $name => $checker;
            }
        }
    }

    $self->next::method($column, $info, @rest);
}


sub set_column {
    my ($self, $col, $val, @rest) = @_;

    my $ppr_cols = $self->_passphrase_columns;
    return $self->next::method($col, $ppr_cols->{$col}->($val), @rest)
        if exists $ppr_cols->{$col};

    return $self->next::method($col, $val, @rest);
}


sub new {
    my ($self, $attr, @rest) = @_;

    my $ppr_cols = $self->_passphrase_columns;
    for my $col (keys %{ $ppr_cols }) {
        next unless exists $attr->{$col} && !ref $attr->{$col};
        $attr->{$col} = $ppr_cols->{$col}->( $attr->{$col} );
    }

    return $self->next::method($attr, @rest);
}


1;

__END__
=pod

=encoding utf-8

=head1 NAME

DBIx::Class::PassphraseColumn - Automatically hash password/passphrase columns

=head1 SYNOPSIS

    __PACKAGE__->load_components(qw(PassphraseColumn));

    __PACKAGE__->add_columns(
        id => {
            data_type         => 'integer',
            is_auto_increment => 1,
        },
        passphrase => {
            data_type        => 'text',
            passphrase       => 'rfc2307',
            passphrase_class => 'SaltedDigest',
            passphrase_args  => {
                algorithm   => 'SHA-1',
                salt_random => 20,
            },
            passphrase_check_method => 'check_passphrase',
        },
    );

    __PACKAGE__->set_primary_key('id');

In application code:

    # 'plain' will automatically be hashed using the specified passphrase_class
    # and passphrase_args. The result of the hashing will stored in the
    # specified encoding
    $rs->create({ passphrase => 'plain' });

    my $row = $rs->find({ id => $id });
    my $passphrase = $row->passphrase; # an Authen::Passphrase instance

    if ($row->check_passphrase($input)) { ...

    $row->passphrase('new passphrase');
    $row->passphrase( Authen::Passphrase::RejectAll->new );

=head1 DESCRIPTION

This component can be used to automatically hash password columns using any
scheme supported by L<Authen::Passphrase> whenever the value of these columns is
changed.

=head1 METHODS

=head2 register_column

Chains with the C<register_column> method in C<DBIx::Class::Row>, and sets up
passphrase columns according to the options documented above. This would not
normally be directly called by end users.

=head2 set_column

Hash a passphrase column whenever it is set.

=head2 new

Hash all passphrase columns on C<new()> so that C<copy()>, C<create()>, and
others B<DWIM>.

=head1 COMPARISON TO SIMILAR MODULES

This module is similar to both L<DBIx::Class::EncodedColumn> and
L<DBIx::Class::DigestColumns>. Here's a brief comparison that might help you
decide which one to choose.

=over 4

=item * C<DigestColumns> performs the hashing operation on C<insert> and
C<update>. C<PassphraseColumn> and C<EncodedColumn> perform the operation when
the value is set, or on C<new>.

=item * C<DigestColumns> supports only algorithms of the Digest family.

=item * C<EncodedColumn> employs a set of thin wrappers around different cipher
modules to provide support for any cipher you wish to use and wrappers are very
simple to write.

=item * C<PassphraseColumn> delegates password hashing and encoding to
C<Authen::Passphrase>, which already has support for a huge number of hashing
schemes. Writing a new C<Authen::Passphrase> subclass to support other schemes
is easy.

=item * C<EncodedColumn> and C<DigestColumns> require all values in a hashed column to
use the same hashing scheme. C<PassphraseColumn> stores both the hashed
passphrase value I<and> the scheme used to hash it. Therefore it's possible to
have different rows using different hashing schemes.

This is especially useful when, for example, being tasked with importing records
(e.g. users) from a legacy application, that used a certain hashing scheme and
has no plain-text passwords available, into another application that uses
another hashing scheme.

=item * C<PassphraseColumn> and C<EncodedColumn> support having more than one hashed
column per table and each column can use a different hashing
scheme. C<DigestColumns> is limited to one hashed column per table.

=item * C<DigestColumns> supports changing certain options at runtime, as well as the
option to not automatically hash values on set. Neither C<PassphraseColumn> nor
C<EncodedColumn> support this.

=back

=head1 OPTIONS

This module provides the following options for C<add_column>:

=over 4

=item C<< passphrase => $encoding >>

This specifies the encoding passphrases will be stored in. Possible values are
C<rfc2307> and C<crypt>. The value of C<$encoding> is pass on unmodified to the
C<inflate_passphrase> option provided by
L<DBIx::Class::InflateColumn::Authen::Passphrase>. Please refer to its
documentation for details.

=item C<< passphrase_class => $name >>

When receiving a plain string value for a passphrase, that value will be hashed
using the C<Authen::Passphrase> subclass specified by C<$name>. A value of
C<SaltedDigest>, for example, will cause passphrases to be hashed using
C<Authen::Passphrase::SaltedDigest>.

=item C<< passphrase_args => \%args >>

When attempting to hash a given passphrase, the C<%args> specified in this
options will be passed to the constructor of the C<Authen::Passphrase> class
specified using C<passphrase_class>, in addition to the actual password to hash.

=item C<< passphrase_check_method => $method_name >>

If this option is specified, a method with the name C<$method_name> will be
created in the result class. This method takes one argument, a plain text
passphrase, and returns a true value if the provided passphrase matches the
encoded passphrase stored in the row it's being called on.

=back

=head1 SEE ALSO

L<DBIx::Class::InflateColumn::Authen::Passphrase>

L<DBIx::Class::EncodedColumn>

L<DBIx::Class::DigestColumns>

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

