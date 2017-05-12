use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::mysql';
use Test::mysqld;
use DBI;
use DBI qw(:sql_types);
use DBIx::Schema::DSL::Dumper;


package Foo::DSL;
use warnings;
use strict;
use DBIx::Schema::DSL;

database 'MySQL';

create_table 'user' => columns {
    integer   'id',   unsigned, primary_key, auto_increment;
    varchar   'name', size => 32, not_null, default => 'unknown';
    # MySQL datatype
    enum      'blood' => ['A', 'B', 'AB', 'O'], null;
    set       'fav'   => ['sushi', 'niku', 'sake'], null;
    text      'description', null;
    timestamp 'updated_at', not_null, default => \'CURRENT_TIMESTAMP';
};

create_table 'book' => columns {
    integer 'id',   unsigned, primary_key, auto_increment;
    varchar 'name', not_null;
    integer 'author_id';
    decimal 'price', 'size' => [4,2];

    add_unique_index 'name_price_idx' => ['name', 'price'];
    belongs_to 'author';
};

create_table 'author' => columns {
    primary_key 'id';
    varchar 'name', not_null;
    decimal 'height', 'precision' => 4, 'scale' => 1;

    add_index 'height_idx' => ['height'];

    has_many 'book';
};


package main;

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '', # no TCP socket
    }
) or plan skip_all => $Test::mysqld::errstr;

my $dbh = DBI->connect($mysqld->dsn(dbname => 'test'), {RaiseError => 1}) or die 'cannot connect to db';

# initialize
my $output = Foo::DSL->output;
#note $output;

$dbh->do($_) for grep { $_ !~ /^\s+$/ } split /;/, $output;

subtest "dump all tables" => sub {

    # generate schema and eval.
    my $code = DBIx::Schema::DSL::Dumper->dump(
        dbh => $dbh,
        pkg => 'Bar::DSL',
    );

    note $code;
    my $schema = eval $code;
    note Bar::DSL->output; # XXX required for translate
    ::ok !$@, 'no syntax error';
    diag $@ if $@;

    is Bar::DSL->context->db, 'MySQL';
    ok !Bar::DSL->context->default_not_null;
    ok !Bar::DSL->context->default_unsigned;


    for my $table (Foo::DSL->context->schema->get_tables) {
        my $other = Bar::DSL->context->schema->get_table($table->name);
        is $table->equals($other), 1;
    }

    subtest 'test each table' => sub {

        subtest 'user' => sub {
            my $user = Bar::DSL->context->schema->get_table('user');
            isa_ok $user, 'SQL::Translator::Schema::Table';

            my $id    = $user->get_field('id');
            my $name  = $user->get_field('name');
            my $blood = $user->get_field('blood');
            my $fav   = $user->get_field('fav');
            my $desc  = $user->get_field('description');
            my $updated_at = $user->get_field('updated_at');

            is_deeply $blood->extra->{list}, ['A','B','AB','O'], 'enum list';
            is_deeply $fav->extra->{list}, ['sushi','niku','sake'], 'set list';

            is $id->sql_data_type,      SQL_INTEGER;
            is $name->sql_data_type,    SQL_VARCHAR;
            is $blood->sql_data_type,   SQL_UNKNOWN_TYPE;
            is $fav->sql_data_type,     SQL_UNKNOWN_TYPE;
            is $desc->sql_data_type,    SQL_LONGVARCHAR;
            is $updated_at->sql_data_type,  SQL_TIMESTAMP;

            is $id->is_primary_key,     1;
            is $id->is_auto_increment,  1;

            is $id->is_nullable,    0;
            is $name->is_nullable,  0;
            is $blood->is_nullable, 1;
            is $fav->is_nullable,   1;
            is $desc->is_nullable,  1;
            is $updated_at->is_nullable, 0;

            is $name->size, 32;

            is $name->default_value, 'unknown';
            is ${$updated_at->default_value}, 'CURRENT_TIMESTAMP', 'CURRENT_TIMESTAMP is SCALAR REF';

            is $id->extra->{unsigned}, 1;
        };

        subtest 'author' => sub {
            my $author = Bar::DSL->context->schema->get_table('author');
            isa_ok $author, 'SQL::Translator::Schema::Table';

            my $id     = $author->get_field('id');
            my $name   = $author->get_field('name');
            my $height = $author->get_field('height');

            is $id->sql_data_type,      SQL_INTEGER;
            is $name->sql_data_type,    SQL_VARCHAR;
            is $height->sql_data_type,  SQL_DECIMAL;

            is $id->is_primary_key, 1;
            is $id->is_auto_increment, 1;

            is $id->is_nullable,        0;
            is $name->is_nullable,      0;
            is $height->is_nullable,    1;

            # SIZE
            is $name->size, 255;
            is_deeply [ $height->size ], [4,1];

            # INDEX
            my %index = map { $_->name => $_ } $author->get_indices;

            is scalar keys %index, 1;
            my $height_idx = $index{height_idx};
            is_deeply [ $height_idx->fields ], ['height'];

            # FOREIGN_KEY
            my $book_cons = $author->fkey_constraints->[0];
            isa_ok $book_cons, 'SQL::Translator::Schema::Constraint';

            is_deeply [ $book_cons->field_names ], ['id'];
            is_deeply [ $book_cons->reference_fields ], ['author_id'];
            is $book_cons->reference_table, 'book';

            ok not $id->extra->{unsigned};
        };

        subtest 'book' => sub {
            my $book   = Bar::DSL->context->schema->get_table('book');
            isa_ok $book, 'SQL::Translator::Schema::Table';

            my $id        = $book->get_field('id');
            my $name      = $book->get_field('name');
            my $author_id = $book->get_field('author_id');
            my $price     = $book->get_field('price');

            is $id->sql_data_type,          SQL_INTEGER;
            is $name->sql_data_type,        SQL_VARCHAR;
            is $author_id->sql_data_type,   SQL_INTEGER;
            is $price->sql_data_type,       SQL_DECIMAL;

            is $id->is_primary_key,     1;
            is $id->is_auto_increment,  1;

            is $id->is_nullable,        0;
            is $name->is_nullable,      0;
            is $author_id->is_nullable, 1;
            is $price->is_nullable,     1;

            is_deeply [ $price->size ], [4,2];

            is $id->extra->{unsigned}, 1;

            # INDEX
            my %index = map { $_->name => $_ } $book->get_indices;

            is scalar keys %index, 1;
            my $name_price_idx = $index{name_price_idx};
            is lc($name_price_idx->type), 'unique';
            is_deeply [ $name_price_idx->fields ], ['name', 'price'];

            # FOREIGN_KEY
            my $author_cons = $book->fkey_constraints->[0];
            isa_ok $author_cons, 'SQL::Translator::Schema::Constraint';

            is_deeply [ $author_cons->field_names ], ['author_id'];
            is_deeply [ $author_cons->reference_fields ], ['id'];
            is $author_cons->reference_table, 'author';
        };
    };
};

subtest "dump single table" => sub {
    my $code = DBIx::Schema::DSL::Dumper->dump(
        dbh    => $dbh,
        tables => 'user',
    );
    #note $code;
    like $code, qr/user/;
    unlike $code, qr/author/;
    unlike $code, qr/book/;
};

subtest "dump multiple tables" => sub {
    my $code = DBIx::Schema::DSL::Dumper->dump(
        dbh    => $dbh,
        tables => [qw/author book/],
    );
    #note $code;
    unlike $code, qr/user/;
    like $code, qr/book/;
    like $code, qr/author/;
};

subtest "default_unsigned" => sub {

    my $code = DBIx::Schema::DSL::Dumper->dump(
        dbh    => $dbh,
        pkg    => 'Bar::Unsigned::DSL',
        default_unsigned => 1,
    );

    my $schema = eval $code;
    ok !!Bar::Unsigned::DSL->context->default_unsigned;
    unlike $code, qr/ unsigned/;
};

subtest "default_not_null" => sub {

    my $code = DBIx::Schema::DSL::Dumper->dump(
        dbh    => $dbh,
        pkg    => 'Bar::NotNull::DSL',
        default_not_null => 1,
    );

    my $schema = eval $code;
    ok !!Bar::NotNull::DSL->context->default_not_null;
    unlike $code, qr/ not_null/;
};

subtest "table_options" => sub {

    my $code = DBIx::Schema::DSL::Dumper->dump(
        dbh => $dbh,
        pkg => 'Bar::TableOptions::DSL',
        table_options => +{
            'mysql_table_type' => 'MyISAM',
            'mysql_charset'    => 'latin1',
        },
    );

    my $schema = eval $code;
    is Bar::TableOptions::DSL->context->table_extra->{mysql_table_type} ,'MyISAM';
    is Bar::TableOptions::DSL->context->table_extra->{mysql_charset} ,'latin1';
};


done_testing;
