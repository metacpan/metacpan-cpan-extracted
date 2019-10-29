use strict;
use warnings;

package DBIx::Class::PassphraseColumn; # git description: v0.04-6-g3f91ab8
# ABSTRACT: Automatically hash password/passphrase columns

our $VERSION = '0.05';

use Module::Runtime 'require_module';
use Sub::Name 'subname';
use Encode ();
use namespace::clean;

use parent 'DBIx::Class';

#pod =head1 SYNOPSIS
#pod
#pod     __PACKAGE__->load_components(qw(PassphraseColumn));
#pod
#pod     __PACKAGE__->add_columns(
#pod         id => {
#pod             data_type         => 'integer',
#pod             is_auto_increment => 1,
#pod         },
#pod         passphrase => {
#pod             data_type        => 'text',
#pod             passphrase       => 'rfc2307',
#pod             passphrase_class => 'SaltedDigest',
#pod             passphrase_args  => {
#pod                 algorithm   => 'SHA-1',
#pod                 salt_random => 20,
#pod             },
#pod             passphrase_check_method => 'check_passphrase',
#pod         },
#pod     );
#pod
#pod     __PACKAGE__->set_primary_key('id');
#pod
#pod
#pod In application code:
#pod
#pod     # 'plain' will automatically be hashed using the specified passphrase_class
#pod     # and passphrase_args. The result of the hashing will stored in the
#pod     # specified encoding
#pod     $rs->create({ passphrase => 'plain' });
#pod
#pod     my $row = $rs->find({ id => $id });
#pod     my $passphrase = $row->passphrase; # an Authen::Passphrase instance
#pod
#pod     if ($row->check_passphrase($input)) { ...
#pod
#pod     $row->passphrase('new passphrase');
#pod     $row->passphrase( Authen::Passphrase::RejectAll->new );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This component can be used to automatically hash password columns using any
#pod scheme supported by L<Authen::Passphrase> whenever the value of these columns is
#pod changed.
#pod
#pod =head1 COMPARISON TO SIMILAR MODULES
#pod
#pod This module is similar to both L<DBIx::Class::EncodedColumn> and
#pod L<DBIx::Class::DigestColumns>. Here's a brief comparison that might help you
#pod decide which one to choose.
#pod
#pod =over 4
#pod
#pod =item * C<DigestColumns> performs the hashing operation on C<insert> and
#pod C<update>. C<PassphraseColumn> and C<EncodedColumn> perform the operation when
#pod the value is set, or on C<new>.
#pod
#pod =item * C<DigestColumns> supports only algorithms of the Digest family.
#pod
#pod =item * C<EncodedColumn> employs a set of thin wrappers around different cipher
#pod modules to provide support for any cipher you wish to use and wrappers are very
#pod simple to write.
#pod
#pod =item * C<PassphraseColumn> delegates password hashing and encoding to
#pod C<Authen::Passphrase>, which already has support for a huge number of hashing
#pod schemes. Writing a new C<Authen::Passphrase> subclass to support other schemes
#pod is easy.
#pod
#pod =item * C<EncodedColumn> and C<DigestColumns> require all values in a hashed column to
#pod use the same hashing scheme. C<PassphraseColumn> stores both the hashed
#pod passphrase value I<and> the scheme used to hash it. Therefore it's possible to
#pod have different rows using different hashing schemes.
#pod
#pod This is especially useful when, for example, being tasked with importing records
#pod (e.g. users) from a legacy application, that used a certain hashing scheme and
#pod has no plain-text passwords available, into another application that uses
#pod another hashing scheme.
#pod
#pod =item * C<PassphraseColumn> and C<EncodedColumn> support having more than one hashed
#pod column per table and each column can use a different hashing
#pod scheme. C<DigestColumns> is limited to one hashed column per table.
#pod
#pod =item * C<DigestColumns> supports changing certain options at runtime, as well as the
#pod option to not automatically hash values on set. Neither C<PassphraseColumn> nor
#pod C<EncodedColumn> support this.
#pod
#pod =back
#pod
#pod =head1 OPTIONS
#pod
#pod This module provides the following options for C<add_column>:
#pod
#pod =begin :list
#pod
#pod = C<< passphrase => $encoding >>
#pod
#pod This specifies the encoding that passphrases will be stored in. Possible values are
#pod C<rfc2307> and C<crypt>. The value of C<$encoding> is passed on unmodified to the
#pod C<inflate_passphrase> option provided by
#pod L<DBIx::Class::InflateColumn::Authen::Passphrase>. Please refer to its
#pod documentation for details.
#pod
#pod = C<< passphrase_class => $name >>
#pod
#pod When receiving a plain string value for a passphrase, that value will be hashed
#pod using the C<Authen::Passphrase> subclass specified by C<$name>. A value of
#pod C<SaltedDigest>, for example, will cause passphrases to be hashed using
#pod C<Authen::Passphrase::SaltedDigest>.
#pod
#pod = C<< passphrase_args => \%args >>
#pod
#pod When attempting to hash a given passphrase, the C<%args> specified in this
#pod options will be passed to the constructor of the C<Authen::Passphrase> class
#pod specified using C<passphrase_class>, in addition to the actual password to hash.
#pod
#pod = C<< passphrase_check_method => $method_name >>
#pod
#pod If this option is specified, a method with the name C<$method_name> will be
#pod created in the result class. This method takes one argument, a plain text
#pod passphrase, and returns a true value if the provided passphrase matches the
#pod encoded passphrase stored in the row it's being called on.
#pod
#pod =end :list
#pod
#pod =cut

__PACKAGE__->load_components(qw(InflateColumn::Authen::Passphrase));

__PACKAGE__->mk_classdata('_passphrase_columns');

#pod =method register_column
#pod
#pod Chains with the C<register_column> method in C<DBIx::Class::Row>, and sets up
#pod passphrase columns according to the options documented above. This would not
#pod normally be directly called by end users.
#pod
#pod =cut

sub register_column {
    my ($self, $column, $info, @rest) = @_;

    if (my $encoding = $info->{passphrase}) {
        $info->{inflate_passphrase} = $encoding;

        $self->throw_exception(q['passphrase_class' is a required argument])
            unless exists $info->{passphrase_class}
                && defined $info->{passphrase_class};

        my $class = 'Authen::Passphrase::' . $info->{passphrase_class};
        require_module($class);

        my $args = $info->{passphrase_args} || {};
        $self->throw_exception(q['passphrase_args' must be a hash reference])
            unless ref $args eq 'HASH';

        my $encoder = sub {
            my ($val) = @_;
            $class->new(%{ $args }, passphrase => Encode::encode('UTF-8', $val))->${\"as_${encoding}"};
        };

        $self->_passphrase_columns({
            %{ $self->_passphrase_columns || {} },
            $column => $encoder,
        });

        if (defined(my $meth = $info->{passphrase_check_method})) {
            my $checker = sub {
                my ($row, $val) = @_;
                return $row->get_inflated_column($column)->match(Encode::encode('UTF-8', $val));
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

#pod =method set_column
#pod
#pod Hash a passphrase column whenever it is set.
#pod
#pod =cut

sub set_column {
    my ($self, $col, $val, @rest) = @_;

    my $ppr_cols = $self->_passphrase_columns;
    return $self->next::method($col, $ppr_cols->{$col}->($val), @rest)
        if exists $ppr_cols->{$col};

    return $self->next::method($col, $val, @rest);
}

#pod =method new
#pod
#pod Hash all passphrase columns on C<new()> so that C<copy()>, C<create()>, and
#pod others B<DWIM>.
#pod
#pod =cut

sub new {
    my ($self, $attr, @rest) = @_;

    my $ppr_cols = $self->_passphrase_columns;
    for my $col (keys %{ $ppr_cols }) {
        next unless exists $attr->{$col} && !ref $attr->{$col};
        $attr->{$col} = $ppr_cols->{$col}->( $attr->{$col} );
    }

    return $self->next::method($attr, @rest);
}

#pod =head1 SEE ALSO
#pod
#pod L<DBIx::Class::InflateColumn::Authen::Passphrase>
#pod
#pod L<DBIx::Class::EncodedColumn>
#pod
#pod L<DBIx::Class::DigestColumns>
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::PassphraseColumn - Automatically hash password/passphrase columns

=head1 VERSION

version 0.05

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

This specifies the encoding that passphrases will be stored in. Possible values are
C<rfc2307> and C<crypt>. The value of C<$encoding> is passed on unmodified to the
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

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Class-PassphraseColumn>
(or L<bug-DBIx-Class-PassphraseColumn@rt.cpan.org|mailto:bug-DBIx-Class-PassphraseColumn@rt.cpan.org>).

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
