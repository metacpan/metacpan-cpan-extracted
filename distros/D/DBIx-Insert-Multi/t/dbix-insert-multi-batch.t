use Test::Most;

use DBIx::Insert::Multi;
use DBIx::Insert::Multi::Batch;
use DateTime;



note "*** Unit testing";

sub Test::DBIx::Insert::Multi::DBI::quote_identifier {
    my $self = shift;
    my ($identifier) = @_;
    return qq|"$identifier"|;
}
my $fake_dbh = bless {}, "Test::DBIx::Insert::Multi::DBI";

my $book_records = [
    {
        title            => "Winnie the Pooh",
        author           => "Milne",
        publication_date => DateTime->new(year => 1926),
    },
    {
        title            => "Paddington",
        author           => "Bond",
        publication_date => DateTime->new(year => 1958),
    },
];
my %default_args = (
    insert_sql_fragment        => "INSERT INTO",
    is_last_insert_id_required => 1,
    dbh                        => $fake_dbh,
);

subtest record_placeholders => sub {
    my $multi = DBIx::Insert::Multi::Batch->new({
        %default_args,
        table   => "book",
        records => $book_records,
    });
    is(
        $multi->record_placeholders,
        "    (?, ?, ?),
    (?, ?, ?)
",
        "record_placeholders rendered correctly",
    );
};

subtest record_values => sub {
    my $multi = DBIx::Insert::Multi::Batch->new({
        %default_args,
        table   => "book",
        records => $book_records,
    });
    cmp_deeply(
        $multi->record_values,
        [
            "Milne", "1926-01-01T00:00:00", "Winnie the Pooh",
            "Bond",  "1958-01-01T00:00:00", "Paddington",
        ],
    );
};

subtest sql => sub {
    my $multi = DBIx::Insert::Multi::Batch->new({
        %default_args,
        table   => "book",
        records => $book_records,
    });
    is(
        $multi->sql,
        q|INSERT INTO "book" ("author", "publication_date", "title") VALUES
    (?, ?, ?),
    (?, ?, ?)
|,
        "sql rendered correctly",
    );
};



# note "*** Integration testing";

# subtest "Quoting with Postgres" => sub {
#     my $batch = DBIx::Insert::Multi::Batch->new({
#         %default_args,
#         dbh     => $schema->storage->dbh,
#         table   => "book",
#         records => $book_records,
#     });
#     is(
#         $batch->sql,
#         q|INSERT INTO "book" ("author", "publication_date", "title") VALUES
#     (?, ?, ?),
#     (?, ?, ?)
# |,
#         "sql rendered correctly",
#     );
# };



done_testing();
