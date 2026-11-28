package DBIx::QuickORM::Manual::Types;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Types - Write a type: inflate, deflate, keys, caching, and registering it, by example.

=head1 DESCRIPTION

A type is a class that consumes L<DBIx::QuickORM::Role::Type> and implements
C<inflate> (a stored value to the Perl value your code wants) and C<deflate>
(back). The role supplies defaults for how rows cache inflated values. The
other methods below are optional.

Two example types. B<Money> inflates an integer column of cents into an
object, and can be a primary key. B<Tags> inflates text into an arrayref,
and cannot.

=head1 SCHEMA

The examples use PostgreSQL and this schema:

=for highlighter language=sql

    CREATE TABLE users (
        id          SERIAL PRIMARY KEY,
        name        TEXT NOT NULL,
        email       TEXT UNIQUE,
        prefs       JSON,
        referred_by INTEGER REFERENCES users (id),
        created     TIMESTAMP NOT NULL DEFAULT now()
    );

    CREATE TABLE posts (
        id      SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users (id),
        title   TEXT NOT NULL,
        views   INTEGER NOT NULL DEFAULT 0
    );

    CREATE DOMAIN cents AS INTEGER;

    CREATE TABLE products (
        id             SERIAL PRIMARY KEY,
        name           TEXT NOT NULL,
        price          cents NOT NULL,
        shipping_cents INTEGER NOT NULL DEFAULT 0,
        tags           TEXT
    );

    CREATE TABLE price_points (price cents PRIMARY KEY, label TEXT);
    CREATE TABLE labels       (tags TEXT PRIMARY KEY);

=head1 MONEY: A VALUE OBJECT

The inflated value is a read-only object. C<plus> returns a new object
rather than changing one:

=for highlighter language=perl

    package My::Money;
    use Hash::Util qw/lock_hashref/;
    use overload
        '""'     => sub { $_[0]->amount },
        '<=>'    => sub {
            my ($x, $y, $swap) = @_;
            my $r = $x->cents <=> (ref($y) ? $y->cents : $y);
            $swap ? -$r : $r;
        },
        fallback => 1;

    sub new    { my ($class, $cents) = @_; lock_hashref(bless {cents => $cents}, $class) }
    sub cents  { $_[0]->{cents} }
    sub amount { sprintf '%.2f', $_[0]->cents / 100 }    # '12.50', and -1 cent is '-0.01'
    sub plus   { my ($self, $other) = @_; My::Money->new($self->cents + $other->cents) }

The type claims every column of the C<cents> domain, and numeric columns
named C<*_cents>:

    package My::Type::Money;
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Type';

    sub base_types { 'cents' }

    sub matches {
        my ($class, $name, $field, $dialect) = @_;
        $name =~ m/_cents$/ && $field->{affinity} eq 'numeric';
    }

C<deflate> takes an object, an amount (C<'12.5'>, C<'-0.01'>), or cents
already:

    sub inflate { my ($class, $raw, $field, $conn) = @_; My::Money->new($raw) }

    sub deflate {
        my ($class, $value, $field, $conn) = @_;
        ref($value) ? $value->cents : $value =~ m/\./ ? sprintf('%.0f', $value * 100) : $value;
    }

C<inflate> and C<deflate> get the field's record from the map (a hashref:
C<name>, C<affinity>, C<db_type>, and more, listed in
L<DBIx::QuickORM::Role::Type>) and the connection (C<< $conn->dialect >>,
C<< $conn->time_zone >>, see
L<DBIx::QuickORM::Manual::Dialects/"TIME ZONES">). Neither sees NULL.

C<is_inflated> (L<DBIx::QuickORM::Manual::Values/DEFLATION>) distinguishes an
amount to deflate (C<'12.50'>) from cents already (C<1250>). The object is
read-only, so every read may share one cached object. C<canonical_key_value>
makes C<1250>, C<'12.50'>, C<'01250'>, and a C<My::Money> one key
(L<DBIx::QuickORM::Manual::Keys/"TYPED KEYS">):

    sub is_inflated { my ($class, $value) = @_; $value =~ m/\./ ? 1 : 0 }

    sub inflated_is_immutable_for_cache { 1 }

    sub canonical_key_value {
        my ($class, $value, $field, $conn) = @_;
        0 + $class->deflate($value, $field, $conn);
    }

C<append_autotype> asks the type after the built-in types. C<+> marks a full
class name:

    my $orm = DBIx::QuickORM->new(
        credentials     => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        append_autotype => ['+My::Type::Money'],
    );

    my $book = $orm->insert(products => {
        name           => 'Book',
        price          => '12.50',    # is_inflated is true: deflated to 1250
        shipping_cents => 300,        # is_inflated is false: 300 goes as given
    });

Reads return a C<My::Money>, the same object every time:

    my $price = $book->field('price');
    my $text  = "$price";                                        # '12.50'
    my $cents = $book->raw_field('price');                       # 1250, as stored
    my $total = $price->plus($book->field('shipping_cents'));    # 15.50
    my $more  = $price > $book->field('shipping_cents');         # true: the overloaded <=>

    $book->update({price => My::Money->new(1399)});    # a reference is always deflated

A C<where> sends values as given, so a C<My::Money> there would go as its
text (C<'20.00'>). Compare in cents, or mark a value to deflate with
C<inflated> (L<DBIx::QuickORM::Manual::Values/INFLATED>):

    use DBIx::QuickORM::Value qw/inflated/;

    my @cheap = $orm->handle('products')->where({price => {'<' => 2000}})->all;
    my @again = $orm->handle('products')
        ->where({price => {'<' => inflated(My::Money->new(2000))}})
        ->all;

=head1 TAGS: A LIST

    package My::Type::Tags;
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Type';

    sub matches {
        my ($class, $name, $field, $dialect) = @_;
        $name =~ m/(?:^|_)tags$/ && $field->{affinity} eq 'string';
    }

    sub inflate { my ($class, $raw, $field, $conn) = @_; [split /,/, $raw] }

    # a plain string is stored text already
    sub deflate {
        my ($class, $value, $field, $conn) = @_;
        ref($value) ? join(',', @$value) : $value;
    }

    # a shallow copy is enough for strings, and cheaper than the default deep copy
    sub clone_inflated { my ($class, $value) = @_; [@$value] }

The inflated value is an arrayref of non-empty, comma-free strings:
C<['a,b']> is stored as C<a,b> and reads back as two tags.

Tags leaves the rest to the role. C<is_inflated> returns undef (the type
cannot tell, so a plain string goes as given). C<inflated_is_immutable_for_cache>
is false (an arrayref can be changed, so every read gets a copy). There is no
C<canonical_key_value> (see L</TYPES ON PRIMARY KEYS>).

    my $tagged = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        types       => {products => {tags => '+My::Type::Tags'}},    # this one field
    );

    my $pen = $tagged->insert(products => {
        name  => 'Pen',
        price => 199,
        tags  => ['office', 'blue'],
    });

    my $tags = $pen->field('tags');          # ['office', 'blue']: a copy
    push @$tags, 'sale';                     # changes the copy only
    my $again = $pen->field('tags');         # ['office', 'blue']: the row is as it was
    $pen->update({tags => $tags});           # write the change back
    my $joined = $pen->raw_field('tags');    # 'office,blue,sale'

=head1 TYPES ON PRIMARY KEYS

    my $point = $orm->insert(price_points => {
        price => My::Money->new(999),
        label => 'budget',
    });

    my $held = $orm->find(price_points => '9.99');    # the held row, with no query

    # same hashref: canonical_key_value made '9.99' and the object one key
    my $one = $held->row_data == $point->row_data;

    my $hit = $orm->refresh_row(
        price_points => {price => 999},
        # the cache only, no query: the same row, or undef when it is not held
        db           => 0,
    );

The ORM files each held row (L<DBIx::QuickORM::Manual::Caching>) under its
type's C<canonical_key_value>, so every form of one key finds the same row. A
type without it cannot sit on a primary key:

    my $ok = eval {
        DBIx::QuickORM->new(
            credentials     => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            },
            # croaks: labels.tags is a primary key, and Tags has no canonical_key_value()
            append_autotype => ['+My::Type::Tags'],
        );
        1;
    };
    # "... has no canonical_key_value(); pass types => {'labels' => {'tags' => undef}}
    # to key it by its plain value"
    my $error = $@;

    my $plain = DBIx::QuickORM->new(
        credentials     => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        append_autotype => ['+My::Type::Tags'],
        types           => {labels => {tags => undef}},    # key it by its plain text instead
    );

A type can also make a key value for an insert that leaves it out
(C<generate_key_value>). See L<DBIx::QuickORM::Manual::Keys/"GENERATED KEYS">.

=head1 REGISTERING TYPES

    my $shop = DBIx::QuickORM->new(
        credentials     => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        # asked after UUID, JSON, and DateTime. The first to claim a field wins
        append_autotype => ['+My::Type::Money', '+My::Type::Tags'],
        types           => {
            products     => {shipping_cents => undef},       # no type, whatever a claim said
            labels       => {tags => undef},
            price_points => {label => '+My::Type::Tags'},    # this field, claim or not
        },
        # an option for every field of a type: here, store lower case
        type_options    => {'+My::Type::Tags' => {format => sub { lc $_[0] }}},
    );

    my $only = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        # in place of the built-in list: JSON and DateTime fields are plain now
        autotype    => ['+My::Type::Money'],
    );

A type named for C<autotype> or C<append_autotype> needs C<base_types> or
C<matches>. One named only in C<types> needs neither. A bare name (C<JSON>)
is a class under C<DBIx::QuickORM::Type::>. C<+> marks a full class name.
Types are loaded for you. Array columns (C<TEXT[]>) are never claimed, but
C<types> can still type one.

The hashref form of C<types> gives one field options:
C<< {class => '+My::Type::Tags', format => sub { lc $_[0] }} >>. Without
C<class> the field keeps its type.
C<format> runs on text the type deflated for a non-binary field. A value sent
as given (a plain C<'BLUE'> on a Tags field) skips it. C<generate> is for
keys (L<DBIx::QuickORM::Manual::Keys>). C<type_options> gives the same options
to every field of a type. An ORM defined as a package takes the same names
through C<type>, C<autotype>, and C<append_autotype> (L<DBIx::QuickORM::DSL>,
L<DBIx::QuickORM::Manual::Classes>).

=head1 THE METHODS

=over 4

=item C<inflate>, C<deflate>

Required.

=item C<is_inflated>

Whether a plain value is already inflated (an amount with a decimal point)
and must be deflated. The default, undef, means the type cannot tell, so a
plain value goes as given. A reference is always deflated.

=item C<base_types>, C<matches>

To be chosen by C<autotype>. C<base_types> lists the column types claimed.
C<matches> gets the field's name, its record, and the dialect.

=item C<inflated_is_immutable_for_cache>, C<clone_inflated>

True when nothing can change an inflated value: rows share the cached one.
Otherwise rows hand out C<clone_inflated> copies. The default deep-copies
with L<Storable>.

=item C<inflate_is_identity>

True when C<inflate> returns the stored value unchanged for this field (UUID
on a text column): rows then hand out the raw value without inflating or
caching. Default false.

=item C<canonical_key_value>

Needed on a primary key field: one string for every form of a key value.

=item C<generate_key_value>

Optional: a new value for a key an insert leaves out.

=back

L<DBIx::QuickORM::Role::Type> has every signature.

=cut

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
