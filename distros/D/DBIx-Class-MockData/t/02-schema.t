#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;

use TestSchema;
use DBIx::Class::MockData;

my $schema = TestSchema->connect('dbi:SQLite::memory:');

my $SCHEMA_DIR = 't/lib';
my $ROWS       = 4;

#
#
# HELPER

sub fresh_mock {
    my (%args) = @_;
    return DBIx::Class::MockData->new(
        schema     => $schema,
        schema_dir => $SCHEMA_DIR,
        rows       => $ROWS,
        %args,
    );
}

subtest 'schema is a valid DBIx::Class::Schema' => sub {
    isa_ok $schema, 'DBIx::Class::Schema';
    my @sources = sort $schema->sources;
    is_deeply \@sources, [qw(Author Book Review)], 'three result sources registered';
};

subtest 'new() with real schema' => sub {
    my $mock;
    lives_ok { $mock = fresh_mock() } 'new() lives';
    isa_ok $mock, 'DBIx::Class::MockData';
    is $mock->{rows}, $ROWS, "rows set to $ROWS";
};

subtest 'deploy creates tables' => sub {
    my $mock = fresh_mock();
    lives_ok { $mock->deploy } 'deploy lives';

    my $dbh = $schema->storage->dbh;
    for my $table (qw(author book review)) {
        my $sth = $dbh->table_info('%', '%', $table, 'TABLE');
        ok $sth->fetchrow_arrayref, "table '$table' exists after deploy";
    }
};

subtest 'generate inserts rows into every table' => sub {
    fresh_mock()->generate;

    is $schema->resultset('Author')->count, $ROWS, "$ROWS authors inserted";
    is $schema->resultset('Book')->count,   $ROWS, "$ROWS books inserted";
    is $schema->resultset('Review')->count, $ROWS, "$ROWS reviews inserted";
};

subtest 'FK chain is satisfied' => sub {
    my %author_ids = map { $_ => 1 }
        $schema->resultset('Author')->get_column('id')->all;
    my %book_ids = map { $_ => 1 }
        $schema->resultset('Book')->get_column('id')->all;

    # Every book.author_id must reference an existing author
    my @bad_book_fks = grep { !$author_ids{$_} }
        $schema->resultset('Book')->get_column('author_id')->all;
    is scalar(@bad_book_fks), 0, 'all book.author_id reference valid authors';

    # Every review.book_id must reference an existing book
    my @bad_review_fks = grep { !$book_ids{$_} }
        $schema->resultset('Review')->get_column('book_id')->all;
    is scalar(@bad_review_fks), 0, 'all review.book_id reference valid books';
};

subtest 'unique constraints respected' => sub {
    # author.email must be unique
    my @emails = $schema->resultset('Author')->get_column('email')->all;
    my %seen;
    $seen{$_}++ for @emails;
    my @dupes = grep { $seen{$_} > 1 } keys %seen;
    is scalar(@dupes), 0, 'author.email values are unique';

    # book.slug must be unique
    my @slugs = $schema->resultset('Book')->get_column('slug')->all;
    %seen = ();
    $seen{$_}++ for @slugs;
    @dupes = grep { $seen{$_} > 1 } keys %seen;
    is scalar(@dupes), 0, 'book.slug values are unique';
};

subtest 'generated column values match expected types' => sub {
    my $author = $schema->resultset('Author')->first;
    like $author->email,      qr/\@example\.com$/, 'email looks like an email';
    like $author->first_name, qr/\w+/,             'first_name is non-empty';
    like $author->last_name,  qr/\w+/,             'last_name is non-empty';

    my $book = $schema->resultset('Book')->first;
    like $book->price,  qr/^\d+\.\d{1,2}$/, 'price is a decimal';
    like $book->slug,   qr/^slug-/,        'slug starts with "slug-"';
    ok defined($book->in_print), 'in_print is defined';
    ok $book->in_print == 0 || $book->in_print == 1, 'in_print is boolean (0 or 1)';

    my $review = $schema->resultset('Review')->first;
    ok $review->rating > 0, 'rating is a positive integer';
};

subtest 'wipe->generate resets row counts' => sub {
    fresh_mock(rows => 2)->wipe->generate;

    is $schema->resultset('Author')->count, 2, '2 authors after wipe+generate';
    is $schema->resultset('Book')->count,   2, '2 books after wipe+generate';
    is $schema->resultset('Review')->count, 2, '2 reviews after wipe+generate';
};

subtest 'dry_run leaves database unchanged' => sub {
    my $before_authors = $schema->resultset('Author')->count;
    my $before_books   = $schema->resultset('Book')->count;

    lives_ok { fresh_mock()->dry_run } 'dry_run lives';

    is $schema->resultset('Author')->count, $before_authors, 'author count unchanged';
    is $schema->resultset('Book')->count,   $before_books,   'book count unchanged';
};

subtest 'seed produces reproducible email values' => sub {
    fresh_mock(seed => 999)->wipe->generate;
    my @emails_a = sort $schema->resultset('Author')->get_column('email')->all;

    fresh_mock(seed => 999)->wipe->generate;
    my @emails_b = sort $schema->resultset('Author')->get_column('email')->all;

    is_deeply \@emails_a, \@emails_b, 'same seed yields same email values';
};

done_testing;
