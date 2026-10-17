use v5.42;

use App::Gimei::Generator;
use App::Gimei::Generators;

use Test2::V1 -utf8;
use Test2::Tools::Spec;

describe "App::Gimei::Generators" => sub {

    it "add_generator()" => sub {
        my $generators = App::Gimei::Generators->new();

        $generators->add_generator(
            App::Gimei::Generator->new( word_class => "Data::Gimei::Name" ) );

        my @list = $generators->to_list();
        T2->is( scalar @list, 1, "to_list returns one generator" );
    };

    it "execute()" => sub {
        my $word_class = "Data::Gimei::Name";
        my $generators = App::Gimei::Generators->new();

        $generators->add_generator(
            App::Gimei::Generator->new( word_class => $word_class ) );
        $generators->add_generator(
            App::Gimei::Generator->new( word_class => $word_class ) );

        my @words = $generators->execute();

        T2->is( scalar @words, 2, "contains two generators" );
        T2->ok( $words[0] eq $words[1], "contains same word" );
    };
};
T2->done_testing();
