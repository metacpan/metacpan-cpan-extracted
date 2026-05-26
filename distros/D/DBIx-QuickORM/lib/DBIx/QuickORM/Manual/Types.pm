package DBIx::QuickORM::Manual::Types;
use strict;
use warnings;

our $VERSION = '0.000020';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Types - Inflating and deflating column values.

=head1 DESCRIPTION

A B<type> in L<DBIx::QuickORM> is a class that knows how to convert a column
value between the form stored in the database and a richer Perl form. Going
from the database to Perl is I<inflation>; going from Perl back to the database
is I<deflation>.

The database stores a JSON document as a string; you usually want a Perl hash
or array. A UUID is bytes or text in a column; you usually want the canonical
hyphenated string. A type bridges that gap so your row accessors hand back the
inflated value and your writes are deflated transparently.

This document covers the built-in JSON and UUID types, how to apply a type to a
column, how C<autotype> applies types automatically, and how to write your own
type class.

This is part of the L<DBIx::QuickORM::Manual>.

=head1 HOW A TYPE MAPS DATABASE VALUE TO PERL VALUE

A type class consumes L<DBIx::QuickORM::Role::Type> and implements a small set
of methods. The two you care about most are:

=over 4

=item $perl = $type->qorm_inflate(...)

Convert a raw value just read from the database into its inflated Perl form.

=item $raw = $type->qorm_deflate(...)

Convert an inflated Perl value back into the form to store in the database.

=back

The remaining contract methods (C<qorm_compare>, C<qorm_affinity>, and
C<qorm_sql_type>) let the type compare two values for equality, declare its
storage affinity, and pick a SQL column type. See
L<DBIx::QuickORM::Role::Type> for the full contract.

=head1 AFFINITY IN BRIEF

Every column has an I<affinity> - one of C<string>, C<numeric>, C<binary>, or
C<boolean> - that describes how its value is treated when written to or read
from the database. A type usually declares an affinity (via
C<qorm_affinity>), and deflation can vary by affinity: the UUID type, for
example, deflates to a hyphenated string for C<string> columns and to packed
16-byte data for C<binary> columns.

This is only a summary. For the full explanation of affinities and where they
come from, see the L<AFFINITY|DBIx::QuickORM::Manual::Concepts/AFFINITY>
section of L<DBIx::QuickORM::Manual::Concepts> and the helper functions in
L<DBIx::QuickORM::Affinity>.

=head1 BUILT-IN TYPES

DBIx::QuickORM ships three type classes.

=head2 JSON

L<DBIx::QuickORM::Type::JSON> stores Perl data structures as JSON. Inflation
decodes the stored JSON into a Perl reference; deflation encodes a reference
back to JSON. Comparison uses a canonical encoding so structurally identical
values compare equal. Its affinity is C<string>, and its SQL type prefers a
native C<jsonb>/C<json> column, falling back to C<longtext>/C<text>.

=head2 UUID

L<DBIx::QuickORM::Type::UUID> handles UUID columns. Values inflate to the
canonical hyphenated string. Deflation honors the affinity: C<string> produces
the hyphenated form, C<binary> produces the packed 16-byte form. Its SQL type
uses a native C<uuid> type when available, otherwise C<VARCHAR(36)>.

C<< DBIx::QuickORM::Type::UUID->new >> returns a fresh v7 UUID string, which
makes it convenient as a Perl C<default> for a UUID column.

=head2 DATETIME

L<DBIx::QuickORM::Type::DateTime> handles date/time columns. Its affinity is
C<string>, and the parse/format and SQL type come from the dialect.

It is B<lazy>: the inflated value is a L<DBIx::QuickORM::Util::Mask> wrapping a
L<DateTime>, and the DateTime is not built until you actually use it (call a
method, do arithmetic, etc.). Reading a row and writing it back without
inspecting the column costs nothing - deflation of an untouched value returns
the original database string with no parsing.

Stringification always returns the original database string and never builds
the DateTime, so printing a value is cheap:

    my $dt = $row->field('created');
    print "$dt\n";        # the db string, e.g. "2026-05-24 12:00:00" - nothing parsed
    my $year = $dt->year; # builds the DateTime now, then delegates

The mask also keeps the (large) DateTime out of L<Data::Dumper> output and
L<Carp> stack traces. See L<DBIx::QuickORM::Util::Mask>.

=head1 APPLYING A TYPE TO A COLUMN

Use the C<type> DSL function inside a column builder. A bare name is loaded as
C<DBIx::QuickORM::Type::NAME>; prefix with C<+> to use a fully-qualified class
name unchanged.

    column data => sub {
        type 'JSON';
    };

    column ident => sub {
        type 'UUID';
    };

    column custom => sub {
        type '+My::App::Type::Money';
    };

See L<DBIx::QuickORM/type> for the full DSL reference, including passing
construction arguments and supplying an already-built type object.

=head1 AUTOMATIC APPLICATION WITH autotype

Rather than naming a type on every column, register it with C<autotype> in the
autofill block. The type then applies itself to any matching column the ORM
introspects, matching on the column's SQL type and on its name.

    autotype 'JSON';     # json/jsonb columns, and columns with "json" in the name
    autotype 'UUID';     # uuid columns, and columns with "uuid" in the name
    autotype 'DateTime'; # date/time/datetime/timestamp columns (matched by SQL type)

Each built-in type implements C<qorm_register_type> to say which columns it
claims. JSON and UUID match by B<column name>: they register a matcher that
catches B<any> column whose name (or database name) B<contains> the word,
case-insensitively - not only a column named exactly C<json> or C<uuid>. So
C<user_uuid>, C<uuid_pk>, and C<MetaJSON> all match. That name matcher only
applies to columns of the relevant affinity (JSON to C<string> columns; UUID
to C<string> or C<binary> columns).

DateTime instead matches by B<SQL type> (C<datetime>/C<timestamp>/
C<timestamptz>/C<date>/C<time>/C<year>, including variants like C<timestamp
without time zone>); it does not match on column name.

In all cases a recognized SQL type takes precedence over a name match. See
L<DBIx::QuickORM/autotype> for the DSL reference.

=head1 WRITING A CUSTOM TYPE

A custom type is a class that consumes L<DBIx::QuickORM::Role::Type> and
implements the contract. The role provides a default C<qorm_register_type> that
croaks, so you only need that method if you want the type usable with
C<autotype>.

The inflate/deflate methods receive their arguments via
C<parse_conflate_args> (exported by L<DBIx::QuickORM::Util>), which normalizes
the various calling conventions into a hashref. The keys you typically read are
C<value>, C<affinity>, and C<class>.

This example stores a comma-joined list of tags as a string and inflates it to
an array reference:

    package My::App::Type::CSV;
    use strict;
    use warnings;

    use DBIx::QuickORM::Util qw/parse_conflate_args/;

    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Type';

    sub qorm_affinity { 'string' }

    sub qorm_inflate {
        my $params = parse_conflate_args(@_);
        my $val    = $params->{value};
        return undef unless defined $val;
        return $val if ref($val);          # already inflated
        return [split /,/, $val];
    }

    sub qorm_deflate {
        my $params = parse_conflate_args(@_);
        my $val    = $params->{value};
        return undef unless defined $val;
        return $val unless ref($val);      # already deflated
        return join(',', @$val);
    }

    sub qorm_compare {
        my $class = shift;
        my ($a, $b) = @_;
        $a = $class->qorm_inflate($a);
        $b = $class->qorm_inflate($b);
        return join(',', @{$a // []}) cmp join(',', @{$b // []});
    }

    sub qorm_sql_type {
        my $self = shift;
        my ($dialect) = @_;
        return $dialect->supports_type('text') // 'TEXT';
    }

    1;

Apply it to a column the same way as any other type:

    column tags => sub {
        type '+My::App::Type::CSV';
    };

=head2 Making it work with autotype

To let C<autotype> apply your type automatically, implement
C<qorm_register_type>. It receives a hashref of SQL-type-name to type-class
mappings and a hashref of per-affinity name-matcher lists. Claim the SQL types
your type owns, and push name matchers onto the affinity lists:

    sub qorm_register_type {
        my $self = shift;
        my ($types, $affinities) = @_;

        my $class = ref($self) || $self;

        # Claim columns declared with this SQL type, but do not clobber an
        # existing claim.
        $types->{csv} //= $class;

        # Match any string column whose name looks like a tag list.
        push @{$affinities->{string}} => sub {
            my %params = @_;
            return $class if $params{name}    =~ m/tags?/i;
            return $class if $params{db_name} =~ m/tags?/i;
            return;
        };
    }

With that in place:

    autotype '+My::App::Type::CSV';

See L<DBIx::QuickORM::Type::JSON> and L<DBIx::QuickORM::Type::UUID> for the
two shipped implementations to model your own on.

=head1 SEE ALSO

=over 4

=item L<DBIx::QuickORM::Manual>

The documentation hub.

=item L<DBIx::QuickORM::Role::Type>

The full type contract.

=item L<DBIx::QuickORM::Type::JSON>, L<DBIx::QuickORM::Type::UUID>

The built-in types.

=item L<DBIx::QuickORM::Manual::Concepts>

Affinity and other core concepts.

=item L<DBIx::QuickORM>

The C<type> and C<autotype> DSL functions.

=back

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
