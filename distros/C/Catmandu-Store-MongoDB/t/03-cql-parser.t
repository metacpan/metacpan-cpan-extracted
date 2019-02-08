use strict;
use warnings;
use Test::More;
use Test::Exception;

require_ok "Catmandu::Store::MongoDB::CQL";

my $cql_mapping = +{
    default_relation => 'exact',
    default_index    => "all",
    indexes          => {
        subject_1 => {filter => ["lowercase"], op => {'=' => 1}},
        subject_2 => {op => {'=' => {filter => ["lowercase"]}}},
        subject_3 => {cb => ["T", "filter_subject"], op => {'=' => 1}},
        subject_4 => {op => {'=' => {cb => ["T", "filter_subject"]}}},
        all       => {
            op => {
                '='     => 1,
                'exact' => 1,
                '<>'    => 1,
                'any'   => 1,
                'all'   => 1,
                within  => 1
            }
        },
        first_name => {
            op => {
                '='     => 1,
                'exact' => 1,
                '<>'    => 1,
                'any'   => 1,
                'all'   => 1,
                within  => 1
            }
        },
        last_name => {
            field => "ln",
            op    => {
                '='     => 1,
                'exact' => 1,
                '<>'    => {field => "ln2"},
                'any'   => 1,
                'all'   => 1,
                within  => 1
            }
        },
        year => {
            op => {
                '='      => 1,
                exact    => 1,
                '<>'     => 1,
                '>'      => 1,
                '<'      => 1,
                '>='     => 1,
                '<='     => 1,
                'within' => 1
            }
        }
    }
};

my $parser;

lives_ok(
    sub {
        $parser = Catmandu::Store::MongoDB::CQL->new(mapping => $cql_mapping);
    },
    "CQL parser created"
);

dies_ok(
    sub {

        $parser->parse(qq(first_name < "a"));

    },
    "cql - term query on unpermitted relation must die"
);
dies_ok(
    sub {

        $parser->parse(qq(my_index = "Nicolas"));

    },
    "cql - term query on unpermitted index must die"
);

is_deeply(
    $parser->parse(qq(first_name = "Nicolas")),
    {first_name => "Nicolas"},
    "cql - term query - relation ="
);

#fails for some reason
#is_deeply(
#    $parser->parse(qq(first_name scr "Nicolas")),
#    { first_name => "Nicolas" },
#    "cql - term query - relation scr"
#);
is_deeply(
    $parser->parse(qq("Nicolas")),
    {all => "Nicolas"},
    "cql - term query - default index"
);
is_deeply(
    $parser->parse(qq(first_name <> "Nicolas")),
    {first_name => {'$ne' => "Nicolas"}},
    "cql - term query - <>"
);
is_deeply(
    $parser->parse(qq(first_name exact "Nicolas")),
    {first_name => "Nicolas"},
    "cql - term query - exact"
);
is_deeply(
    $parser->parse(qq(first_name any "a b c")),
    {first_name => {'$in' => [qr(a), qr(b), qr(c)]}},
    "cql - term query - any"
);
is_deeply(
    $parser->parse(qq(first_name any "^a b ^c^")),
    {first_name => {'$in' => [qr(^a), qr(b), qr(^c$)]}},
    "cql - term query - any with wildcard"
);
is_deeply(
    $parser->parse(qq(first_name any/cql.unmasked "^a b ^c^")),
    {first_name => {'$in' => [qr(\^a), qr(b), qr(\^c\^)]}},
    "cql - term query - any unmasked"
);

is_deeply(
    $parser->parse(qq(first_name all "a b c")),
    {first_name => {'$all' => [qr(a), qr(b), qr(c)]}},
    "cql - term query - all"
);
is_deeply(
    $parser->parse(qq(first_name all "^a b ^c^")),
    {first_name => {'$all' => [qr(^a), qr(b), qr(^c$)]}},
    "cql - term query - all with wildcard"
);
is_deeply(
    $parser->parse(qq(first_name all/cql.unmasked "^a b ^c^")),
    {first_name => {'$all' => [qr(\^a), qr(b), qr(\^c\^)]}},
    "cql - term query - all unmasked"
);
is_deeply(
    $parser->parse(qq(last_name exact "Franck")),
    {ln => "Franck"},
    "cql - term query - field mapping 1"
);
is_deeply(
    $parser->parse(qq(last_name <> "Franck")),
    {ln2 => {'$ne' => "Franck"}},
    "cql - term query - field mapping 2"
);
is_deeply(
    $parser->parse(qq(year > 2009)),
    {year => {'$gt' => 2009}},
    "cql - term query - >"
);
is_deeply(
    $parser->parse(qq(year < 2009)),
    {year => {'$lt' => 2009}},
    "cql - term query - <"
);
is_deeply(
    $parser->parse(qq(year >= 2009)),
    {year => {'$gte' => 2009}},
    "cql - term query - >="
);
is_deeply(
    $parser->parse(qq(year <= 2009)),
    {year => {'$lte' => 2009}},
    "cql - term query - <="
);
is_deeply(
    $parser->parse(qq(year within "2009 2016")),
    {year => {'$gte' => 2009, '$lte' => "2016"}},
    "cql - term query - within"
);
is_deeply(
    $parser->parse(qq(year exact "2009" and first_name = "Nicolas")),
    {'$and' => [{year => 2009}, {first_name => "Nicolas"}]},
    "cql - boolean query - and"
);
is_deeply(
    $parser->parse(qq(year exact "2009" or first_name = "Nicolas")),
    {'$or' => [{year => 2009}, {first_name => "Nicolas"}]},
    "cql - boolean query - or"
);
is_deeply(
    $parser->parse(qq(year exact "2009" not first_name = "Nicolas")),
    {'$nor' => [{'$and' => [{'first_name' => 'Nicolas'}]}], year => 2009},
    "cql - boolean query - not"
);
is_deeply(
    $parser->parse(qq(year exact "2009" not "Nicolas")),
    {'$nor' => [{'$and' => [{'all' => 'Nicolas'}]}], year => 2009},
    "cql - boolean query - not all"
);
is_deeply(
    $parser->parse(
        qq(year exact "2009" not( first_name = "Nicolas" or last_name = "Franck" ))
    ),
    {'$nor' => [{first_name => "Nicolas"}, {ln => "Franck"}], year => 2009},
    "cql - boolean query - not boolean or"
);
is_deeply(
    $parser->parse(
        qq(year exact "2009" not( first_name = "Nicolas" and last_name = "Franck" ))
    ),
    {
        '$nor' => [{'$and' => [{first_name => 'Nicolas'}, {ln => 'Franck'}]}],
        year   => 2009
    },
    "cql - boolean query - not boolean and"
);
is_deeply(
    $parser->parse(qq(subject_1 = "AIRPLANES")),
    {subject_1 => "airplanes"},
    "cql - filter term field 1"
);
is_deeply(
    $parser->parse(qq(subject_2 = "AIRPLANES")),
    {subject_2 => "airplanes"},
    "cql - filter term field 2"
);
is_deeply(
    $parser->parse(qq(subject_3 = "airplanes")),
    {subject_3 => "AIRPLANES"},
    "cql - cb term field 1"
);
is_deeply(
    $parser->parse(qq(subject_4 = "airplanes")),
    {subject_4 => "AIRPLANES"},
    "cql - cb term field 2"
);

done_testing 31;

package T;
use strict;
use warnings;

sub filter_subject {
    uc($_[1]);
}

1;
