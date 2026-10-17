use v5.42;

use App::Gimei::Parser;

use Test2::V1 -utf8;
use Test2::Tools::Spec;
use Test2::Tools::Exception qw/dies/;

describe "App::Gimei::Parser" => sub {

    it "parse(): no args" => sub {
        my @gs = App::Gimei::Parser::parse([])->to_list;
        T2->is( scalar @gs, 0, "contains no generator" );
    };

    it "_parse_arg(): word_type(name|male|female)" => sub {
        my $g = App::Gimei::Parser::parse(['name', 'male', 'female']);
        my @l = $g->to_list;

        T2->is( scalar @l,         3, "contains 3 generator" );
        T2->is( $l[0]->word_class, 'Data::Gimei::Name' );
        T2->is( $l[0]->gender,     undef );
        T2->is( $l[1]->word_class, 'Data::Gimei::Name' );
        T2->is( $l[1]->gender,     'male' );
        T2->is( $l[2]->word_class, 'Data::Gimei::Name' );
        T2->is( $l[2]->gender,     'female' );
    };

    it "_parse_arg(): word_type(address)" => sub {
        my $g = App::Gimei::Parser::parse(['address']);
        my @l = $g->to_list;

        T2->is( scalar @l,         1 );
        T2->is( $l[0]->word_class, 'Data::Gimei::Address' );
    };

    it "_parse_arg(): unknown word_type" => sub {
        T2->like( dies { App::Gimei::Parser::parse(['unknown']) },
            qr/unknown word_type/ );
    };

    it "_parse_arg(): unknown subtype/rendering" => sub {
        T2->like( dies { App::Gimei::Parser::parse(['name:unknown']) },
            qr/unknown subtype/ );
        T2->like( dies { App::Gimei::Parser::parse(['name:family:unknown']) },
            qr/unknown rendering/ );
    };

    it "_subtype_name()" => sub {
        my @args = (
            'name:family', 'name:last', 'name:given', 'name:first',
            'name:gender', 'name:sex',  'name:kanji', 'name'
        );
        my @l = App::Gimei::Parser::parse(\@args)->to_list;

        T2->is( scalar @l,           8 );
        T2->is( $l[0]->word_subtype, 'surname' );
        T2->is( $l[1]->word_subtype, 'surname' );
        T2->is( $l[2]->word_subtype, 'forename' );
        T2->is( $l[3]->word_subtype, 'forename' );
        T2->is( $l[4]->word_subtype, 'gender' );
        T2->is( $l[5]->word_subtype, 'gender' );
        T2->is( $l[6]->word_subtype, undef );
        T2->is( $l[7]->word_subtype, undef );
    };

    it "_subtype_address()" => sub {
        my @args = (
            'address:prefecture', 'address:city',
            'address:town',       'address:kanji',
            'address'
        );
        my @l = App::Gimei::Parser::parse(\@args)->to_list;

        T2->is( scalar @l,           5 );
        T2->is( $l[0]->word_subtype, 'prefecture' );
        T2->is( $l[1]->word_subtype, 'city' );
        T2->is( $l[2]->word_subtype, 'town' );
        T2->is( $l[3]->word_subtype, undef );
        T2->is( $l[4]->word_subtype, undef );
    };

    it "_rendering(): " => sub {
        my @args =
          ( 'name:kanji', 'name:hiragana', 'name:katakana', 'name:romaji', 'name' );
        my @l = App::Gimei::Parser::parse(\@args)->to_list;

        T2->is( scalar @l,        5 );
        T2->is( $l[0]->rendering, 'kanji' );
        T2->is( $l[1]->rendering, 'hiragana' );
        T2->is( $l[2]->rendering, 'katakana' );
        T2->is( $l[3]->rendering, 'romaji' );
        T2->is( $l[4]->rendering, 'kanji' );
    };
};

T2->done_testing;
