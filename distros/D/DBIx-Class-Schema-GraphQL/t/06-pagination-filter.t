#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use My::Schema;
use DBIx::Class::Schema::GraphQL;
use GraphQL::Execution qw(execute);

my $db = My::Schema->connect('dbi:SQLite:dbname=:memory:');
$db->deploy;

$db->resultset('Author')->create({ id => 1, name => 'Author One', email => 'one@example.com' });
$db->resultset('Author')->create({ id => 2, name => 'Author Two', email => 'two@example.com' });

for my $i (1..10) {
    $db->resultset('Book')->create({
        id        => $i,
        title     => "Book $i",
        author_id => ($i % 2 == 0) ? 2 : 1,
        price     => $i * 1.5,
    });
}

my $r = DBIx::Class::Schema::GraphQL->to_graphql($db);
my ($schema, $ctx) = @{$r}{qw(schema context)};

sub gql {
    my ($q, $v) = @_;
    return execute($schema, $q, undef, $ctx, $v // {});
}

# Connection wrapper shape
{
    my $res = gql('{ allBooks { total nodes { id title } hasNextPage nextCursor } }');

    ok(!$res->{errors}, 'allBooks no-args: no errors')
       or diag explain $res->{errors};
    my $conn = $res->{data}{allBooks};
    is($conn->{total},           10, 'total is 10'       );
    is(scalar @{$conn->{nodes}}, 10, '10 nodes returned' );
    is($conn->{hasNextPage},      0, 'hasNextPage false' );
    ok(!defined $conn->{nextCursor}, 'nextCursor is null');
}

# Exact match filter
{
    my $res = gql('{ allBooks(filter: { author_id: 1 }) { total nodes { id } } }');

    ok(!$res->{errors}, 'filter exact match: no errors');
    is($res->{data}{allBooks}{total}, 5, 'exact filter returns 5 rows');
}

# LIKE filter
{
    my $res = gql('{ allBooks(filter: { title_like: "Book 1%" }) { total nodes { title } } }');

    ok(!$res->{errors}, 'filter like: no errors');
    is($res->{data}{allBooks}{total}, 2, 'LIKE filter returns 2 rows');
}

# Comparison filter
{
    my $res = gql('{ allBooks(filter: { id_gt: 7 }) { total nodes { id } } }');

    ok(!$res->{errors}, 'filter gt: no errors');
    is($res->{data}{allBooks}{total}, 3, 'id_gt:7 returns 3 rows (8,9,10)');
}

{
    my $res = gql('{ allBooks(filter: { id_lte: 3 }) { total nodes { id } } }');

    ok(!$res->{errors}, 'filter lte: no errors');
    is($res->{data}{allBooks}{total}, 3, 'id_lte:3 returns 3 rows');
}

# OR filter
{
    my $res = gql('{ allBooks(filter: {
        OR: [{ id: 1 }, { id: 2 }, { id: 3 }]
    }) { total nodes { id } } }');

    ok(!$res->{errors}, 'OR filter: no errors');
    is($res->{data}{allBooks}{total}, 3, 'OR filter returns 3 rows');
}

# AND filter
{
    my $res = gql('{ allBooks(filter: {
        AND: [{ author_id: 1 }, { id_gt: 5 }]
    }) { total nodes { id } } }');

    ok(!$res->{errors}, 'AND filter: no errors');
    is( $res->{data}{allBooks}{total}, 2, 'AND filter returns 2 rows');
}

# OrderBy ASC
{
    my $res = gql('{ allBooks(orderBy: { field: "id", direction: DESC }) {
        nodes { id }
    } }');

    ok(!$res->{errors}, 'orderBy DESC: no errors');
    my @ids = map { $_->{id} } @{ $res->{data}{allBooks}{nodes} };
    is($ids[0], 10, 'first id is 10 (DESC)');
    is($ids[-1], 1, 'last id is 1 (DESC)'  );
}

# Offset pagination
{
    my $res = gql('{ allBooks(page: { skip: 0, take: 3 }) {
        total nodes { id }
    } }');

    ok(!$res->{errors}, 'offset page 1: no errors');
    my $conn = $res->{data}{allBooks};
    is($conn->{total},           10, 'total still 10'  );
    is(scalar @{$conn->{nodes}},  3, '3 nodes returned');
    is($conn->{nodes}[0]{id},     1, 'first node id=1' );
}

{
    my $res = gql('{ allBooks(page: { skip: 3, take: 3 }) { nodes { id } } }');

    ok(!$res->{errors}, 'offset page 2: no errors');
    is($res->{data}{allBooks}{nodes}[0]{id}, 4, 'page 2 starts at id=4');
}

# Cursor pagination
{
    # First page
    my $res1 = gql('{ allBooks(cursor: { first: 4 }) {
        total hasNextPage nextCursor nodes { id }
    } }');

    ok(!$res1->{errors}, 'cursor page 1: no errors');
    my $conn1 = $res1->{data}{allBooks};
    is(scalar @{$conn1->{nodes}}, 4, '4 nodes on page 1'    );
    is($conn1->{hasNextPage},     1, 'hasNextPage true'     );
    ok(defined $conn1->{nextCursor}, 'nextCursor is set'    );
    is($conn1->{nodes}[0]{id},    1, 'page 1 starts at id=1');
    is($conn1->{nodes}[-1]{id},   4, 'page 1 ends at id=4'  );

    # Second page using the cursor
    my $cursor = $conn1->{nextCursor};
    my $res2 = gql(
        'query($c: String) { allBooks(cursor: { after: $c, first: 4 }) {
            hasNextPage nextCursor nodes { id }
        } }',
        { c => $cursor }
    );

    ok(!$res2->{errors}, 'cursor page 2: no errors')
       or diag explain $res2->{errors};
    my $conn2 = $res2->{data}{allBooks};
    is(scalar @{$conn2->{nodes}}, 4, '4 nodes on page 2'     );
    is($conn2->{nodes}[0]{id},    5, 'page 2 starts at id=5' );
    is($conn2->{nodes}[-1]{id},   8, 'page 2 ends at id=8'   );
    is($conn2->{hasNextPage},     1, 'hasNextPage still true');

    # Third (final) page
    my $cursor2 = $conn2->{nextCursor};
    my $res3 = gql(
        'query($c: String) { allBooks(cursor: { after: $c, first: 4 }) {
            hasNextPage nextCursor nodes { id }
        } }',
        { c => $cursor2 }
    );

    ok(!$res3->{errors}, 'cursor page 3: no errors');
    my $conn3 = $res3->{data}{allBooks};
    is(scalar @{$conn3->{nodes}}, 2,  '2 nodes on final page'         );
    is($conn3->{hasNextPage},     0,  'hasNextPage false on last page');
    ok(!defined $conn3->{nextCursor}, 'nextCursor null on last page'  );
}

# Filter + pagination combined
{
    my $res = gql('{ allBooks(
        filter: { author_id: 1 }
        page:   { skip: 0, take: 2 }
        orderBy: { field: "id", direction: ASC }
    ) { total nodes { id } } }');

    ok(!$res->{errors}, 'filter+page+orderBy: no errors');
    my $conn = $res->{data}{allBooks};
    is($conn->{total},           5, 'total=5 (filtered)'  );
    is(scalar @{$conn->{nodes}}, 2, '2 nodes returned'    );
    is($conn->{nodes}[0]{id},    1, 'first node is book 1');
}

done_testing;
