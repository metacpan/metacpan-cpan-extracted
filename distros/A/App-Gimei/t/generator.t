use warnings;
use v5.22;

use App::Gimei::Generator;
use Test::More;

# test caching
{
    my $cache = {};
    my $g = App::Gimei::Generator->new(word_class => "Data::Gimei::Name");

    my $previous = $g->execute($cache);

    is $g->execute($cache), $previous;
}

# test gender('')
{
    my %params = ( word_class => 'Data::Gimei::Name' );
    my $gen = App::Gimei::Generator->new(%params);
    is $gen->gender(), '';
}

# test gender('male')
{
    my %params = ( word_class => 'Data::Gimei::Name',
		   word_subtype => 'gender',
                   gender => 'male' );
    my $gen = App::Gimei::Generator->new(%params);
    my $gender = $gen->execute();

    is $gen->gender(), 'male';
    is $gender, 'male';
}

done_testing();
