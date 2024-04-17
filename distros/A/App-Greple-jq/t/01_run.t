use v5.14;
use warnings;

use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

$ENV{NO_COLOR} = "1";

is(jq(qw(--IN date 2021 t/hash.json))->run->{result}, 0, "hash.json");

line(jq(qw(--glob t/hash.json  -o            --IN author utashiro))->run->{stdout}, 108, "author");
line(jq(qw(--glob t/array.json -o            --IN author utashiro))->run->{stdout}, 108, "author (array)");

line(jq(qw(--glob t/hash.json  -o            --IN commit.author utashiro))->run->{stdout}, 24, "commit.author");
line(jq(qw(--glob t/array.json -o            --IN commit.author utashiro))->run->{stdout}, 24, "commit.author (array)");

line(jq(qw(--glob t/hash.json -o --blockend= --IN  commit.author.email utashiro))->run->{stdout}, 4, "commit.author.email");
line(jq(qw(--glob t/hash.json -o --blockend= --IN .commit.author.email utashiro))->run->{stdout}, 4, ".commit.author.email");

line(jq(qw(--glob t/hash.json -o             --IN parents github))->run->{stdout}, 8 * 4, "parents github");

line(jq(qw(--glob t/hash.json -o --blockend= --IN name Utashiro)          )->run->{stdout}, 8, "name");
line(jq(qw(--glob t/hash.json -o --blockend= --IN author.name Utashiro)   )->run->{stdout}, 4, "author.name");
like(jq(qw(--glob t/hash.json -o --blockend= --IN author.name Utashiro)   )->run->{stdout}, qr/author/, "author.name match");
line(jq(qw(--glob t/hash.json -o --blockend= --IN committer.name Utashiro))->run->{stdout}, 4, "committer.name");
like(jq(qw(--glob t/hash.json -o --blockend= --IN committer.name Utashiro))->run->{stdout}, qr/committer/, "committer.name match");

line(jq(qw(--glob t/hash.json -o --blockend= --IN email .)              )->run->{stdout}, 8, "email");
line(jq(qw(--glob t/hash.json -o --blockend= --IN commit.email .)       )->run->{stdout}, 0, "commit.email");
line(jq(qw(--glob t/hash.json -o --blockend= --IN commit.author.email .))->run->{stdout}, 4, "commit.author.email");
like(jq(qw(--glob t/hash.json -o --blockend= --IN commit.author.email .))->run->{stdout}, qr/author/, "commit.author.email match");
line(jq(qw(--glob t/hash.json -o --blockend= --IN commit..email .)      )->run->{stdout}, 4, "commit..email");
like(jq(qw(--glob t/hash.json -o --blockend= --IN commit..email .)      )->run->{stdout}, qr/author/, "commit..email match");

line(jq(qw(--glob t/hash.json -o --blockend= --IN .commit.name .)       )->run->{stdout}, 0, ".commit.name");
line(jq(qw(--glob t/hash.json -o --blockend= --IN .commit..name .)      )->run->{stdout}, 4, ".commit..name");
line(jq(qw(--glob t/hash.json -o --blockend= --IN commit.name .)        )->run->{stdout}, 0, "commit.name");
line(jq(qw(--glob t/hash.json -o --blockend= --IN commit..name .)       )->run->{stdout}, 4, "commit..name");

done_testing;

__DATA__
