#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;

use TestSchema;
use DBIx::Class::MockData;

#
# Setup
# Fresh in-memory DB for every subtest via a helper so each subtest is isolated.

sub fresh_schema {
    my $s = TestSchema->connect('dbi:SQLite::memory:');
    DBIx::Class::MockData->new(
        schema     => $s,
        schema_dir => 't/lib',
    )->deploy;
    return $s;
}

sub fresh_mock {
    my ($schema, %args) = @_;
    return DBIx::Class::MockData->new(
        schema     => $schema,
        schema_dir => 't/lib',
        rows       => 3,
        %args,
    );
}

#
#
# FEATURE A: only

subtest 'only: new() accepts arrayref' => sub {
    my $schema = fresh_schema();
    my $mock;
    lives_ok {
        $mock = fresh_mock($schema, only => [qw(Author)])
    } 'new() lives with only';
    isa_ok $mock, 'DBIx::Class::MockData';
};

subtest 'only: populates listed table, leaves others empty' => sub {
    my $schema = fresh_schema();
    fresh_mock($schema, only => [qw(Author)])->generate;

    is $schema->resultset('Author')->count, 3, '3 authors inserted';
    is $schema->resultset('Book')->count,   0, 'no books inserted';
    is $schema->resultset('Review')->count, 0, 'no reviews inserted';
};

subtest 'only: multiple tables are all populated' => sub {
    my $schema = fresh_schema();
    fresh_mock($schema, only => [qw(Author Book)])->generate;

    is $schema->resultset('Author')->count, 3, '3 authors inserted';
    is $schema->resultset('Book')->count,   3, '3 books inserted';
    is $schema->resultset('Review')->count, 0, 'reviews untouched';
};

subtest 'only: FK order preserved within the filtered set' => sub {
    my $schema = fresh_schema();
    fresh_mock($schema, only => [qw(Author Book)])->generate;

    my %author_ids = map { $_ => 1 }
        $schema->resultset('Author')->get_column('id')->all;
    my @bad = grep { !$author_ids{$_} }
        $schema->resultset('Book')->get_column('author_id')->all;
    is scalar(@bad), 0, 'all book.author_id reference valid authors';
};

subtest 'only: dry_run respects filter' => sub {
    my $schema = fresh_schema();
    my $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        fresh_mock($schema, only => [qw(Author)])->dry_run;
    }
    like   $output, qr/DRY RUN: Author/,  'Author appears in dry_run output';
    unlike $output, qr/DRY RUN: Book/,    'Book absent from dry_run output';
    unlike $output, qr/DRY RUN: Review/,  'Review absent from dry_run output';
};

subtest 'only: unknown source name croaks' => sub {
    my $schema = fresh_schema();
    throws_ok {
        fresh_mock($schema, only => [qw(Author NoSuchTable)])->generate
    } qr/Unknown source.*only.*NoSuchTable/i,
      'croaks with unknown source in only';
};

subtest 'only: must be an arrayref, not a string' => sub {
    my $schema = fresh_schema();
    throws_ok {
        fresh_mock($schema, only => 'Author')
    } qr/only must be an arrayref/,
      'croaks when only is a plain string';
};

#
#
# FEATURE B: exclude

subtest 'exclude: new() accepts arrayref' => sub {
    my $schema = fresh_schema();
    my $mock;
    lives_ok {
        $mock = fresh_mock($schema, exclude => [qw(Review)])
    } 'new() lives with exclude';
    isa_ok $mock, 'DBIx::Class::MockData';
};

subtest 'exclude: skips listed table, populates the rest' => sub {
    my $schema = fresh_schema();
    fresh_mock($schema, exclude => [qw(Review)])->generate;

    is $schema->resultset('Author')->count, 3, '3 authors inserted';
    is $schema->resultset('Book')->count,   3, '3 books inserted';
    is $schema->resultset('Review')->count, 0, 'review skipped';
};

subtest 'exclude: multiple tables all skipped' => sub {
    my $schema = fresh_schema();
    fresh_mock($schema, exclude => [qw(Book Review)])->generate;

    is $schema->resultset('Author')->count, 3, '3 authors inserted';
    is $schema->resultset('Book')->count,   0, 'book skipped';
    is $schema->resultset('Review')->count, 0, 'review skipped';
};

subtest 'exclude: FK order preserved for remaining tables' => sub {
    my $schema = fresh_schema();
    fresh_mock($schema, exclude => [qw(Review)])->generate;

    my %author_ids = map { $_ => 1 }
        $schema->resultset('Author')->get_column('id')->all;
    my @bad = grep { !$author_ids{$_} }
        $schema->resultset('Book')->get_column('author_id')->all;
    is scalar(@bad), 0, 'all book.author_id reference valid authors';
};

subtest 'exclude: dry_run respects filter' => sub {
    my $schema = fresh_schema();
    my $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        fresh_mock($schema, exclude => [qw(Review)])->dry_run;
    }
    like   $output, qr/DRY RUN: Author/, 'Author appears in dry_run output';
    like   $output, qr/DRY RUN: Book/,   'Book appears in dry_run output';
    unlike $output, qr/DRY RUN: Review/, 'Review absent from dry_run output';
};

subtest 'exclude: unknown source name croaks' => sub {
    my $schema = fresh_schema();
    throws_ok {
        fresh_mock($schema, exclude => [qw(Review GhostTable)])->generate
    } qr/Unknown source.*exclude.*GhostTable/i,
      'croaks with unknown source in exclude';
};

subtest 'exclude: must be an arrayref, not a string' => sub {
    my $schema = fresh_schema();
    throws_ok {
        fresh_mock($schema, exclude => 'Review')
    } qr/exclude must be an arrayref/,
      'croaks when exclude is a plain string';
};

#
#
# Mutual exclusion

subtest 'only and exclude cannot both be set' => sub {
    my $schema = fresh_schema();
    throws_ok {
        fresh_mock($schema,
            only    => [qw(Author)],
            exclude => [qw(Review)],
        )
    } qr/only and exclude cannot both be specified/,
      'croaks when both only and exclude are supplied';
};

#
#
# Baseline: no filter still populates everything

subtest 'no filter: all tables populated as before' => sub {
    my $schema = fresh_schema();
    fresh_mock($schema)->generate;

    is $schema->resultset('Author')->count, 3, '3 authors';
    is $schema->resultset('Book')->count,   3, '3 books';
    is $schema->resultset('Review')->count, 3, '3 reviews';
};

done_testing;
