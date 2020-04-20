use strict;
use warnings;
use Test::More;

use Catmandu;
use Catmandu::Fix;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::pica_map';
    use_ok $pkg;
}

require_ok $pkg;

sub get_record {
    return {
        record => [
            [ '005A', '', '0', '1234-5678' ],
            [ '005A', '', '0', '1011-1213' ],
            [   '009Q', '', 'u', 'http://example.org/', 'x', 'A', 'z', 'B',
                'z', 'C'
            ],
            [ '021A', '', 'a', 'Title', 'd', 'Supplement' ],
            [   '031N', '',     'j', '1600', 'k', '1700',
                'j',    '1800', 'k', '1900', 'j', '2000'
            ],
            [ '045F', '01', 'a', '001' ],
            [ '045F', '02', 'a', '002' ],
            [ '045U', '', 'e', '003', 'e', '004' ],
            [ '045U', '', 'e', '005' ]
        ],
        _id => 1234
    };
}

note('Single field, no subfield repetition');

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(021A, title)', 'retain_field(title)' ] );
    my $record = $fixer->fix( get_record() );
    is( $record->{'title'}, "TitleSupplement",
        'pica_map(021A, title) -> "TitleSupplement"' );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(021Aa, title)', 'retain_field(title)' ] );
    my $record = $fixer->fix( get_record() );
    is( $record->{'title'}, 'Title', 'pica_map(021Aa, title) -> "Title"' );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(021Aad, title)', 'retain_field(title)' ] );
    my $record = $fixer->fix( get_record() );
    is( $record->{'title'}, "TitleSupplement",
        'pica_map(021Aad, title) -> "TitleSupplement"' );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(021Ada, title)', 'retain_field(title)' ] );
    my $record = $fixer->fix( get_record() );
    is( $record->{'title'}, "TitleSupplement",
        'pica_map(021Ada, title) -> "TitleSupplement"' );
}

{
    my $fixer = Catmandu::Fix->new( fixes =>
            [ 'pica_map(021Ada, title, pluck:1)', 'retain_field(title)' ] );
    my $record = $fixer->fix( get_record() );
    is( $record->{'title'}, "SupplementTitle",
        'pica_map(021Ada, title, pluck:1) -> "SupplementTitle"' );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [
            'pica_map(021Ada, title, pluck:1, join:" ")',
            'retain_field(title)'
        ]
    );
    my $record = $fixer->fix( get_record() );
    is( $record->{'title'},
        "Supplement Title",
        'pica_map(021Ada, title, pluck:1, join:" ") -> "Supplement Title"'
    );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(021A, title.$append)', 'retain_field(title)' ] );
    my $record = $fixer->fix( get_record() );
    is_deeply( $record->{'title'}, ["TitleSupplement"],
        'pica_map(021A, title.$append) -> ["TitleSupplement"]' );
}

{
    my $fixer
        = Catmandu::Fix->new(
        fixes => [ 'pica_map(021Aa, title.$append)', 'retain_field(title)' ]
        );
    my $record = $fixer->fix( get_record() );
    is_deeply( $record->{'title'}, ["Title"],
        'pica_map(021Aa, title.$append) -> ["Title"]' );
}

{
    my $fixer
        = Catmandu::Fix->new(
        fixes => [ 'pica_map(021A, title, split:1)', 'retain_field(title)' ]
        );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'title'},
        [ "Title", "Supplement" ],
        'pica_map(021A, title, split:1) -> ["Title","Supplement"]'
    );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [
            'pica_map(021A, title.$append, split:1)',
            'retain_field(title)'
        ]
    );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'title'},
        [ [ "Title", "Supplement" ] ],
        'pica_map(021A, title.$append, split:1) -> [["Title","Supplement"]]'
    );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [
            'pica_map(021A, title, split:1, nested_arrays:1)',
            'retain_field(title)'
        ]
    );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'title'},
        [ [ "Title", "Supplement" ] ],
        'pica_map(021A, title, split:1, nested_arrays:1) -> [["Title","Supplement"]]'
    );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [
            'pica_map(021A, title.$append, split:1, nested_arrays:1)',
            'retain_field(title)'
        ]
    );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'title'},
        [ [ [ "Title", "Supplement" ] ] ],
        'pica_map(021A, title.$append, split:1, nested_arrays:1) -> [[["Title","Supplement"]]]'
    );
}

note('Single field, repeated subfields');

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(009Q, url)', 'retain_field(url)' ] );
    my $record = $fixer->fix( get_record() );
    is( $record->{'url'}, "http://example.org/ABC",
        'pica_map(009Q, url) -> "http://example.org/ABC"' );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(009Qz, url)', 'retain_field(url)' ] );
    my $record = $fixer->fix( get_record() );
    is( $record->{'url'}, "BC", 'pica_map(009Qz, url) -> "BC"' );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(009Q, url.$append)', 'retain_field(url)' ] );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'url'},
        ["http://example.org/ABC"],
        'pica_map(009Q, url.$append) -> ["http://example.org/ABC"]'
    );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(009Qz, url.$append)', 'retain_field(url)' ] );
    my $record = $fixer->fix( get_record() );
    is_deeply( $record->{'url'}, ["BC"],
        'pica_map(009Qz, url.$append) -> ["BC"]' );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(009Q, url, split:1)', 'retain_field(url)' ] );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'url'},
        [ "http://example.org/", "A", "B", "C" ],
        'pica_map(009Q, url, split:1) -> ["http://example.org/", "A", "B", "C"]'
    );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(009Qz, url, split:1)', 'retain_field(url)' ] );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'url'},
        [ "B", "C" ],
        'pica_map(009Qz, url, split:1) -> ["B", "C"]'
    );
}

{
    my $fixer
        = Catmandu::Fix->new( fixes =>
            [ 'pica_map(009Qz, url.$append, split:1)', 'retain_field(url)' ]
        );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'url'},
        [ [ "B", "C" ] ],
        'pica_map(009Qz, url.$append, split:1) -> [["B", "C"]]'
    );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [
            'pica_map(009Qz, url, split:1, nested_arrays:1)',
            'retain_field(url)'
        ]
    );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'url'},
        [ [ "B", "C" ] ],
        'pica_map(009Qz, url, split:1, nested_arrays:1) -> [["B", "C"]]'
    );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [
            'pica_map(009Qz, url.$append, split:1, nested_arrays:1)',
            'retain_field(url)'
        ]
    );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'url'},
        [ [ [ "B", "C" ] ] ],
        'pica_map(009Qz, url.$append, split:1, nested_arrays:1) -> [[["B", "C"]]]'
    );
}

note('Repeated Field, no subfield repetition');

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(005A, issn)', 'retain_field(issn)' ] );
    my $record = $fixer->fix( get_record() );
    is( $record->{'issn'}, "1234-56781011-1213",
        'pica_map(005A, issn) -> "1234-56781011-1213"' );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(005A0, issn)', 'retain_field(issn)' ] );
    my $record = $fixer->fix( get_record() );
    is( $record->{'issn'}, "1234-56781011-1213",
        'pica_map(005A0, issn) -> "1234-56781011-1213"' );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(005A, issn.$append)', 'retain_field(issn)' ] );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'issn'},
        [ "1234-5678", "1011-1213" ],
        'pica_map(005A, issn.$append) -> ["1234-5678", "1011-1213"]'
    );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [ 'pica_map(005A, issn, split:1)', 'retain_field(issn)' ] );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'issn'},
        [ "1234-5678", "1011-1213" ],
        'pica_map(005A, issn, split:1) -> ["1234-5678", "1011-1213"]'
    );
}

{
    my $fixer
        = Catmandu::Fix->new( fixes =>
            [ 'pica_map(005A, issn.$append, split:1)', 'retain_field(issn)' ]
        );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'issn'},
        [ [ "1234-5678", "1011-1213" ] ],
        'pica_map(005A, issn.$append, split:1) -> [["1234-5678", "1011-1213"]]'
    );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [
            'pica_map(005A, issn, split:1, nested_arrays:1)',
            'retain_field(issn)'
        ]
    );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'issn'},
        [ ["1234-5678"], ["1011-1213"] ],
        'pica_map(005A, issn, split:1, nested_arrays:1) -> [["1234-5678"], ["1011-1213"]]'
    );
}

{
    my $fixer = Catmandu::Fix->new(
        fixes => [
            'pica_map(005A, issn.$append, split:1, nested_arrays:1)',
            'retain_field(issn)'
        ]
    );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'issn'},
        [ [ ["1234-5678"], ["1011-1213"] ] ],
        'pica_map(005A, issn.$append, split:1, nested_arrays:1) -> [[["1234-5678"], ["1011-1213"]]]'
    );
}

note('Map several PICA fields to one field');

{
    my $fixer = Catmandu::Fix->new(
        fixes => [
            'pica_map(005A, multi.$append, split:1, nested_arrays:1)',
            'pica_map(009Q, multi.$append, split:1, nested_arrays:1)',
            'retain(multi)'
        ]
    );
    my $record = $fixer->fix( get_record() );
    is_deeply(
        $record->{'multi'},
        [   [ ["1234-5678"], ["1011-1213"] ],
            [ [ "http://example.org/", "A", "B", "C" ] ]
        ]
    );
}

note('Check for empty return values');

{
    my $fixer = Catmandu::Fix->new(
        fixes => [
            'pica_map(004A, string)',
            'pica_map(004A, array, split:1)',
            'remove_field(record)'
        ]
    );
    my $record = $fixer->fix( get_record() );
    ok( !exists $record->{string} );
    ok( !exists $record->{array} );
}

note('Repeated field split pluck');

{
    my $fixer = Catmandu::Fix->new(
        fixes => [
            'pica_map(099Aba, pluck, split:1, pluck:1)',
            'remove_field(record)'
        ]
    );
    my $record = $fixer->fix(
        {   record => [
                [ '099A', '', 'a', 'A', 'b', 'B' ],
                [ '099A', '', 'b', 'B', 'a', 'A' ]
            ]
        }
    );
    is_deeply( $record->{pluck}, [ 'B', 'A', 'B', 'A' ] )
}

done_testing();
