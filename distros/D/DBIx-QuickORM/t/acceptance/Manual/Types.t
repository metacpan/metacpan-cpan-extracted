# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/Types.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    my $dbh = $db->connect;
    $dbh->do(<<'    SQL');
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
    SQL
    $dbh->disconnect;
    my ($dsn, $user, $pass) = ($db->connect_string, $db->username, $db->password);

    # MONEY: A VALUE OBJECT
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

    package My::Type::Money;
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Type';

    sub base_types { 'cents' }

    sub matches {
        my ($class, $name, $field, $dialect) = @_;
        $name =~ m/_cents$/ && $field->{affinity} eq 'numeric';
    }

    sub inflate { my ($class, $raw, $field, $conn) = @_; My::Money->new($raw) }

    sub deflate {
        my ($class, $value, $field, $conn) = @_;
        ref($value) ? $value->cents : $value =~ m/\./ ? sprintf('%.0f', $value * 100) : $value;
    }

    sub is_inflated { my ($class, $value) = @_; $value =~ m/\./ ? 1 : 0 }

    sub inflated_is_immutable_for_cache { 1 }

    sub canonical_key_value {
        my ($class, $value, $field, $conn) = @_;
        0 + $class->deflate($value, $field, $conn);
    }

    package main;

    is("" . My::Money->new(-1),                       '-0.01', "a negative amount formats with its sign");
    is(My::Type::Money->deflate('12.5'),              1250,    "one decimal deflates to cents");
    is(My::Type::Money->deflate('-0.01'),             -1,      "and so does a negative amount");
    is(My::Type::Money->deflate(999),                 999,     "cents pass through deflate");
    is(My::Type::Money->canonical_key_value('00999'), 999,     "the key form is integer cents");
    like(dies { My::Money->new(5)->{cents} = 6 }, qr/read-only/, "the object is locked");

    my $orm = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        append_autotype => ['+My::Type::Money'],
    );

    my $book = $orm->insert(
        products => {
            name           => 'Book',
            price          => '12.50',    # is_inflated is true: deflated to 1250
            shipping_cents => 300,        # is_inflated is false: 300 goes as given
        }
    );

    my $price = $book->field('price');
    my $text  = "$price";                                        # '12.50'
    my $cents = $book->raw_field('price');                       # 1250, as stored
    my $total = $price->plus($book->field('shipping_cents'));    # 15.50
    my $more  = $price > $book->field('shipping_cents');         # true: the overloaded <=>

    $book->update({price => My::Money->new(1399)});    # a reference is always deflated

    is($orm->db_map->field(products => 'price')->{orm_type},          'My::Type::Money',            "base_types claims the domain column");
    is($orm->db_map->field(products => 'shipping_cents')->{orm_type}, 'My::Type::Money',            "matches claims the *_cents column");
    is($orm->db_map->field(products => 'id')->{orm_type},             undef,                        "and nothing else");
    is($orm->db_map->field(users    => 'prefs')->{orm_type},          'DBIx::QuickORM::Type::JSON', "append_autotype keeps the built-in types");
    isa_ok($price, ['My::Money'], "the field inflates to the object");
    ref_is($book->field('price'), $book->field('price'), "immutable for the cache: every read is the one object");
    is($text,                              '12.50', "the amount, through overloading");
    is($cents,                             1250,    "'12.50' was deflated to cents");
    is($book->raw_field('shipping_cents'), 300,     "300 went as given");
    is("$total",                           '15.50', "plus makes a new object");
    ok($more, "the overloaded comparison works between two inflated values");
    is($book->raw_field('price'), 1399, "a My::Money deflates to its cents");

    use DBIx::QuickORM::Value qw/inflated/;

    my @cheap = $orm->handle('products')->where({price => {'<' => 2000}})->all;
    my @again = $orm->handle('products')->where({price => {'<' => inflated(My::Money->new(2000))}})->all;

    is([map { $_->field('name') } @cheap], ['Book'], "a where compares in cents");
    is([map { $_->field('name') } @again], ['Book'], "inflated() deflates the object for the where");
    like(dies { $orm->handle('products')->where({price => {'<' => My::Money->new(2000)}})->all }, qr/invalid input syntax for (?:type )?integer: "20.00"/, "without it the object goes as its text");

    # TAGS: A LIST
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

    package main;

    is(My::Type::Tags->is_inflated('a,b'),              undef, "is_inflated is the role's undef");
    is(My::Type::Tags->inflated_is_immutable_for_cache, 0,     "inflated values are not immutable");
    ok(!My::Type::Tags->can('canonical_key_value'), "and there is no canonical_key_value");

    my $tagged = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        types => {products => {tags => '+My::Type::Tags'}},    # this one field
    );

    my $pen = $tagged->insert(
        products => {
            name  => 'Pen',
            price => 199,
            tags  => ['office', 'blue'],
        }
    );

    my $tags = $pen->field('tags');          # ['office', 'blue']: a copy
    push @$tags, 'sale';                     # changes the copy only
    my $again = $pen->field('tags');         # ['office', 'blue']: the row is as it was
    $pen->update({tags => $tags});           # write the change back
    my $joined = $pen->raw_field('tags');    # 'office,blue,sale'

    is($tagged->db_map->field(products => 'tags')->{orm_type}, 'My::Type::Tags',           "types gives the field its type");
    is($tagged->db_map->field(labels => 'tags')->{orm_type},   undef,                      "and no other");
    is($again,                                                 ['office', 'blue'],         "a read gets a copy, so the push changed nothing in the row");
    is($pen->field('tags'),                                    ['office', 'blue', 'sale'], "the update wrote the list");
    is($joined,                                                'office,blue,sale',         "as joined text");
    is($pen->raw_field('price'),                               199,                        "a plain value on a Money field is sent as given");
    $pen->update({tags => 'red,green'});
    is($pen->field('tags'), ['red', 'green'], "a plain string is stored text");

    # TYPES ON PRIMARY KEYS
    my $point = $orm->insert(
        price_points => {
            price => My::Money->new(999),
            label => 'budget',
        }
    );
    my $held = $orm->find(price_points => '9.99');    # the held row, with no query

    # same hashref: canonical_key_value made '9.99' and the object one key
    my $one = $held->row_data == $point->row_data;
    my $hit = $orm->refresh_row(
        price_points => {price => 999},
        # the cache only, no query: the same row, or undef when it is not held
        db => 0,
    );

    ok($one, "find with the amount text returns the held row");
    ref_is($hit->row_data,                                $point->row_data, "and so does the cents form");
    ref_is($orm->find(price_points => '00999')->row_data, $point->row_data, "and a zero-padded form");
    is($point->raw_field('price'), 999,    "the key was stored as cents");
    is("" . $held->field('price'), '9.99', "and inflates");

    my $ok = eval {
        DBIx::QuickORM->new(
            credentials => {
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
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        append_autotype => ['+My::Type::Tags'],
        types           => {labels => {tags => undef}},    # key it by its plain text instead
    );

    ok(!$ok, "a type without canonical_key_value cannot sit on a primary key");
    like($error, qr/The primary key field 'tags' of the table 'labels' has the type 'My::Type::Tags', which has no canonical_key_value\(\); pass types => \{'labels' => \{'tags' => undef\}\} to key it by its plain value/, "the croak names the field and the way out");
    is($plain->db_map->field(labels   => 'tags')->{orm_type}, undef,            "types => undef makes it a plain key");
    is($plain->db_map->field(products => 'tags')->{orm_type}, 'My::Type::Tags', "while the claim still types the other tags column");

    # REGISTERING TYPES
    my $shop = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        # asked after UUID, JSON, and DateTime. The first to claim a field wins
        append_autotype => ['+My::Type::Money', '+My::Type::Tags'],
        types           => {
            products     => {shipping_cents => undef},                # no type, whatever a claim said
            labels       => {tags           => undef},
            price_points => {label          => '+My::Type::Tags'},    # this field, claim or not
        },
        # an option for every field of a type: here, store lower case
        type_options => {'+My::Type::Tags' => {format => sub { lc $_[0] }}},
    );

    my $only = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        # in place of the built-in list: JSON and DateTime fields are plain now
        autotype => ['+My::Type::Money'],
    );

    my %shop = map { $_ => $shop->db_map->field(products => $_)->{orm_type} } qw/price shipping_cents tags/;
    is(\%shop,                                                    {price => 'My::Type::Money', shipping_cents => undef, tags => 'My::Type::Tags'}, "claims, with types removing one");
    is($shop->db_map->field(price_points => 'label')->{orm_type}, 'My::Type::Tags',                                                                "types adds a type no claim gave");
    my $mug = $shop->insert(products => {name => 'Mug', price => 500, tags => ['Kitchen', 'GIFT']});
    is($mug->raw_field('tags'),                                                                     'kitchen,gift', "type_options' format ran on the deflated text");
    is($shop->insert(products => {name => 'Cup', price => 500, tags => 'BLUE'})->raw_field('tags'), 'BLUE',         "a plain value goes as given, so format does not run");

    is($only->db_map->field(products => 'price')->{orm_type},   'My::Type::Money', "autotype asks only the types given");
    is($only->db_map->field(users    => 'prefs')->{orm_type},   undef,             "so the built-in types are not asked");
    is($only->db_map->field(users    => 'created')->{orm_type}, undef,             "for any field");
};

done_testing;
