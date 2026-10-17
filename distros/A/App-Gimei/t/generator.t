use v5.42;

use App::Gimei::Generator;

use Test2::V1 -utf8;
use Test2::Tools::Spec;

describe "App::Gimei::Generator" => sub {

    it "constructs with default options" => sub {
        my $g = App::Gimei::Generator->new( word_class => 'Data::Gimei::Name' );

        T2->is( $g->word_class,   'Data::Gimei::Name', "word_class is set correctly" );
        T2->is( $g->word_subtype, undef,               "word_subtype defaults to undef" );
        T2->is( $g->rendering,    'kanji',             "rendering defaults to 'kanji'" );
        T2->is( $g->gender,       undef,               "gender defaults to undef" );
    };

    it "constructs with all options set" => sub {
        my $g = App::Gimei::Generator->new(
            word_class   => 'Data::Gimei::Name',
            word_subtype => 'family',
            rendering    => 'hiragana',
            gender       => 'male'
        );

        T2->is( $g->word_class,   'Data::Gimei::Name', "word_class is set correctly" );
        T2->is( $g->word_subtype, 'family',            "word_subtype is set correctly" );
        T2->is( $g->rendering,    'hiragana',          "rendering is set correctly" );
        T2->is( $g->gender,       'male',              "gender is set correctly" );
    };

    it "Calling execute()for both cache hit/miss" => sub {
        my $cache      = {};
        my $word_class = 'Data::Gimei::Name';
        my $g          = App::Gimei::Generator->new( word_class => $word_class );

        my $previous = $g->execute($cache);    # first call, cache miss
        my $current  = $g->execute($cache);    # second call, cache hit

        T2->is( $current, $previous, "returns the same value if the cache hits" );
        T2->ok( $cache->{'Data::Gimei::Name'}->isa($word_class),
            "cached object is a $word_class" );
    };

    it "execute(): word_subtype => 'surname'" => sub {
        my $cache = {};
        my $g     = App::Gimei::Generator->new(
            word_class   => "Data::Gimei::Name",
            word_subtype => 'surname',
            rendering    => 'romaji'
        );

        my $word = $g->execute($cache);
        T2->like( $word, qr/^[A-Z][a-z]*$/, "returns a family name" );
    };

    it "execute(): word_subtype => 'gender'" => sub {
        my $cache = {};
        my $g     = App::Gimei::Generator->new(
            word_class   => "Data::Gimei::Name",
            word_subtype => 'gender',
            gender       => 'male'
        );

        my $word = $g->execute($cache);
        T2->is( $word, 'male', "returns 'male'" );
    };
};
T2->done_testing();
