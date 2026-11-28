package DBIx::QuickORM::Value;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;

use Exporter qw/import/;
our @EXPORT_OK = qw/raw inflated binary sql/;

use Object::HashBase qw{
    <kind
    <value
    <binds
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Value - Mark how one value is sent to the database.

=head1 DESCRIPTION

Wrapping a value in a marker says how the ORM treats that one value. A marker
overrides the call's C<raw> flag and the usual deflation rules (see
L<DBIx::QuickORM/"CRUD operations">).

Markers work in inserted values, changes, compare-and-swap values, primary key
values, a handle's bulk changes, and as values in a handle's C<where>, where
the SQL builder turns them into SQL and binds.

=head1 SYNOPSIS

    use DBIx::QuickORM::Value qw/raw inflated binary sql/;

    my $ann = $orm->insert(
        users => {
            name    => 'Ann',
            created => sql('now()'),
            prefs   => raw('{"theme":"dark"}'),
        },
    );

    # Every value is in database form (raw => 1) except prefs, which still needs deflating.
    $orm->insert(
        users => {
            name    => 'Bo',
            created => '2024-01-02 03:04:05',
            prefs   => inflated({theme => 'light'}),
        },
        raw => 1,
    );

    my @today = $orm->handle('users')->where({created => {'>=' => sql('CURRENT_DATE')}})->all;

    # A query knows no field types, so mark a binary value (files has a BYTEA data column).
    my @same = $orm->handle(\'SELECT * FROM files')->where({data => binary($bytes)})->all;

=head1 EXPORTS

All are exported on request. C<raw>, C<inflated>, and C<binary> each croak
unless given exactly one value.

=over 4

=item $marker = raw($value)

Already in database form: never deflated.

Also the way to send a reference to a field without a type, such as a
PostgreSQL array.

=item $marker = inflated($value)

Deflated through the field's type, even under C<< raw => 1 >> and even when
the type cannot tell the value is inflated.

The type still decides: on a JSON field a plain value is JSON text, sent as
is (see L<DBIx::QuickORM::Type::JSON>).

=item $marker = binary($value)

Raw, and bound as binary whatever the field.

=back

=cut

sub raw      { __PACKAGE__->_mark(raw      => @_) }
sub inflated { __PACKAGE__->_mark(inflated => @_) }
sub binary   { __PACKAGE__->_mark(binary   => @_) }

=pod

=over 4

=item $marker = sql($sql, @binds)

Literal SQL in place of the value, used as written: nothing in it is quoted,
and its binds are sent without types. Croaks unless the SQL is a non-blank
string.

In inserted values and changes the field's new value then comes back through
C<RETURNING>, or is not fetched.

It croaks in compare-and-swap values and primary key lookups. A primary key
set by it in an update without C<RETURNING> (MySQL, MariaDB) croaks too, since
the new key could not be known. An insert without C<RETURNING> falls back to
the last insert id for a single-field key, as C<insert> describes.

=back

=cut

sub sql {
    my ($sql, @binds) = @_;
    croak "sql() needs the SQL as a string" unless defined($sql) && !ref($sql) && $sql =~ m/\S/;
    return __PACKAGE__->new(kind => 'sql', value => $sql, binds => \@binds);
}

=head1 ATTRIBUTES

=over 4

=item $kind = $marker->kind

C<raw>, C<inflated>, C<binary>, or C<sql>.

=item $value = $marker->value

The value, or the SQL of an C<sql> marker.

=item \@binds = $marker->binds

The binds of an C<sql> marker.

=back

=head1 PRIVATE METHODS

=over 4

=item $marker = DBIx::QuickORM::Value->_mark($kind, $value)

A marker of the kind for the value. Croaks unless given exactly one value.

=back

=cut

sub _mark {
    my $class = shift;
    my ($kind, @args) = @_;
    croak "$kind() takes exactly one value" unless @args == 1;
    return $class->new(kind => $kind, value => $args[0]);
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
