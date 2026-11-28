package DBIx::QuickORM::Type::UUID;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;
use UUID();

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Type';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Type::UUID - UUIDs stored as text or as 16 bytes.

=head1 DESCRIPTION

The inflated form is the 36-character string. A field of C<binary> affinity
(C<binary(16)>, C<bytea>, C<BLOB>) stores the 16 bytes. Any other field,
including a native C<uuid> column, stores the string as given.

A primary key field of this type that an insert leaves out gets a new
version 7 UUID, unless the database fills the column and can return it
with C<RETURNING> (so on MySQL it is generated). The field's
C<generate> hint changes that (see
L<DBIx::QuickORM::Role::Type/Field hints>).

=head1 SYNOPSIS

    # CREATE TABLE sessions (id UUID PRIMARY KEY, owner_uuid BYTEA)

    my $uuid    = '0190a6e8-1d2c-7c3b-9f00-123456789abc';
    my $session = $orm->insert(
        sessions => {
            id         => $uuid,
            owner_uuid => $uuid,
        },
    );

    my $sid   = $session->field('id');            # the string, from a native uuid column
    my $owner = $session->field('owner_uuid');    # the string, stored as 16 bytes

    my $fresh = $orm->insert(sessions => {owner_uuid => $uuid});    # id gets a new version 7 UUID

=cut

my $UUID = qr/^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i;

=head1 PUBLIC METHODS

=over 4

=item @types = $type->base_types

C<uuid>.

=item $bool = $type->inflated_is_immutable_for_cache

True: a UUID inflates to a plain string.

=back

=cut

sub base_types                      { 'uuid' }
sub inflated_is_immutable_for_cache { 1 }

=pod

=over 4

=item $bool = $type->is_inflated($value)

True for a 36-character UUID string.

=back

=cut

sub is_inflated {
    my $class = shift;
    my ($value) = @_;
    return $value =~ $UUID ? 1 : 0;
}

=pod

=over 4

=item $bool = $type->matches($field_name, \%field, $dialect)

True for a field named C<uuid>, C<..._uuid>, C<uuid_...>, or C<..._uuid_...>
that can hold one: C<binary> affinity of size 16 or no size, or C<string>
affinity of size 36 or no size.

C<uuid_count int> is not a UUID.

=back

=cut

sub matches {
    my $class = shift;
    my ($name, $field) = @_;

    return 0 unless $name =~ m/(?:^|_)uuid(?:_|$)/i;
    my $size     = $field->{size};
    my $affinity = $field->{affinity} // '';
    return 1 if $affinity eq 'binary' && (!$size || $size == 16);
    return 1 if $affinity eq 'string' && (!$size || $size == 36);
    return 0;
}

=pod

=over 4

=item $uuid = $type->inflate($raw, \%field, $conn)

The lowercase string for the 16 bytes of a binary field, or text as stored.

A binary value that is not 16 bytes croaks, naming the field when its
record has its C<table> and C<name>.

=back

=cut

sub inflate {
    my $class = shift;
    my ($raw, $field) = @_;
    return $raw unless ($field->{affinity} // '') eq 'binary';

    croak "A binary UUID must be 16 bytes, got " . length($raw) . $class->_for_field($field) unless length($raw) == 16;

    my $str;
    UUID::unparse_lower($raw, $str);
    return $str;
}

=pod

=over 4

=item $bool = $type->inflate_is_identity(\%field)

True for a text field, which C<inflate> returns as stored.

=back

=cut

sub inflate_is_identity { ($_[1]->{affinity} // '') ne 'binary' ? 1 : 0 }

=pod

=over 4

=item $raw = $type->deflate($uuid, \%field, $conn)

The 16 bytes for a binary field, or the value as given for any other field.

A reference croaks. For a binary field, so does anything but a UUID string.
The croak names the field when its record has its C<table> and C<name>.

=back

=cut

sub deflate {
    my $class = shift;
    my ($value, $field) = @_;

    my $binary = ($field->{affinity} // '') eq 'binary';
    croak "'$value' is not a UUID" . $class->_for_field($field) if ref($value) || ($binary && $value !~ $UUID);
    return $value unless $binary;

    my $bin;
    UUID::parse($value, $bin);
    return $bin;
}

=pod

=over 4

=item $uuid = $type->generate_key_value(\%field, $conn)

A new version 7 UUID string, from L<UUID/uuid7>.

=back

=cut

sub generate_key_value { UUID::uuid7() }

=pod

=over 4

=item $key = $type->canonical_key_value($value, \%field, $conn)

The lowercase hyphenated string for a key value given as that string, in
upper case, or as 16 bytes, told apart by length alone (the digits are not
checked). Any other length is returned as given.

=back

=cut

sub canonical_key_value {
    my $class   = shift;
    my ($value) = @_;
    my $len     = length($value);
    return $value                                          if $value !~ m/[A-F]/ && $len == 36;
    return lc($value)                                      if $len == 36;
    return $class->inflate($value, {affinity => 'binary'}) if $len == 16;
    return $value;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
