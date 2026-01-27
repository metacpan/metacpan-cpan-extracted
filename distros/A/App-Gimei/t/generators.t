use v5.40;

use App::Gimei::Generator;
use App::Gimei::Generators;

use Test2::Bundle::More;

# test
{
    my $generators = App::Gimei::Generators->new();

    my $g = App::Gimei::Generator->new( word_class => "Data::Gimei::Name" );
    $generators->add_generator($g);

    my @list = $generators->to_list();
    is( scalar @list, 1, "to_list returns one generator" );
}

# test
{
    my $generators = App::Gimei::Generators->new();

    my $g = App::Gimei::Generator->new( word_class => "Data::Gimei::Name" );
    $generators->add_generator($g);

    $generators->execute();
}

done_testing();
