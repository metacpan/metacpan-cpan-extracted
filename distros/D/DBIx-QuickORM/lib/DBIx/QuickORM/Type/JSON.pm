package DBIx::QuickORM::Type::JSON;
use strict;
use warnings;

our $VERSION = '0.000031';

use Cpanel::JSON::XS();

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Type';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Type::JSON - Perl data structures stored as JSON text.

=head1 DESCRIPTION

Inflates JSON text into Perl data and deflates references into JSON text.
Encoding is canonical (hash keys sorted), so the same data always deflates to
the same text. Any JSON value may be stored, including a plain string or
number at the top level.

A reference is inflated data and is encoded. A plain value is JSON text and is
sent as is, even inside C<inflated()>: C<'{"a":1}'> stores that object.

So C<'foo'> is not valid JSON, but C<'"foo"'> is: encode a string with a JSON
encoder, or write proper JSON. To write back a decoded top-level string, such
as C<foo> read from the JSON C<"foo">, encode it or send C<raw_field>'s text.

Inflated data can be changed by whoever holds it, so a row hands every read a
deep copy (see L<DBIx::QuickORM::Role::Type/Cached inflated values>):
changing the data read from a row changes neither the row nor the next read.
Write changes back with C<< $row->update >>.

Reading a large document often means copying it each time, but
C<< $row->raw_field >> gives the JSON text without copying.

=head1 SYNOPSIS

    # json and jsonb fields are typed
    my $orm = DBIx::QuickORM->new(credentials => \%credentials);

    my $ann = $orm->insert(
        users => {
            name  => 'Ann',
            prefs => {
                theme => 'dark',
                tags  => ['a', 'b'],
            },
        },
    );

    my $theme = $ann->field('prefs')->{theme};
    my $text  = $ann->raw_field('prefs');    # the JSON text

    # a plain string is JSON text
    $orm->insert(
        users => {
            name  => 'Bo',
            prefs => '{"theme":"light"}',
        },
    );

    # Keep a JSON field as text:
    my $plain = DBIx::QuickORM->new(
        credentials => \%credentials,
        types       => {users => {prefs => undef}},
    );

    my $json = $plain->find(users => $ann->field('id'))->field('prefs');

=cut

my $JSON       = Cpanel::JSON::XS->new->canonical(1)->allow_nonref(1);
my $JSON_BYTES = Cpanel::JSON::XS->new->utf8(1)->allow_nonref(1);

=head1 PUBLIC METHODS

=over 4

=item @types = $type->base_types

C<json> and C<jsonb>.

=item $bool = $type->is_inflated($value)

True for a reference, which is never JSON text. Undef for a plain value: it
cannot tell, so the value is sent as given.

=back

=cut

sub base_types  { qw/json jsonb/ }
sub is_inflated { ref($_[1]) ? 1 : undef }

=pod

=over 4

=item $bool = $type->matches($field_name, \%field, $dialect)

True for a field of C<string> affinity named C<json>, C<..._json>,
C<json_...>, or C<..._json_...>.

This covers MariaDB, whose C<JSON> columns report themselves as C<longtext>.

=back

=cut

sub matches {
    my $class = shift;
    my ($name, $field) = @_;
    return ($field->{affinity} // '') eq 'string' && $name =~ m/(?:^|_)json(?:_|$)/i ? 1 : 0;
}

=pod

=over 4

=item $data = $type->inflate($raw, \%field, $conn)

Decodes the JSON text.

Text without Perl's UTF-8 flag, as the driver returns MySQL's C<JSON>
columns, is decoded as UTF-8 bytes.

=back

=cut

sub inflate {
    my $class = shift;
    my ($raw) = @_;
    return utf8::is_utf8($raw) ? $JSON->decode($raw) : $JSON_BYTES->decode($raw);
}

=pod

=over 4

=item $raw = $type->deflate($value, \%field, $conn)

Canonical JSON text for a reference. A plain value is returned as given.

=back

=cut

sub deflate {
    my $class = shift;
    my ($value) = @_;
    return ref($value) ? $JSON->encode($value) : $value;
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
