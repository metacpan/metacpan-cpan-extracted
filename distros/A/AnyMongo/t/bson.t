use strict;
use warnings;
use Test::More tests => 2;
use Test::Deep;
use Data::Dumper;
use Devel::Peek;
use boolean;
use AnyMongo::BSON qw(bson_encode bson_decode);

{
    my $data = {
    i => 1,
    's' => 'test',
    'i' => 10,
    'f' => 1.1,
    };
    my $bson = bson_encode($data);
    my $data_check = bson_decode($bson);
    cmp_deeply($data,$data_check,'simple hash');
}
{
    $AnyMongo::BSON::use_boolean = 1;
    my $data = {
        i => [1,2,3],
        a => 5,
        d => boolean::true
    };
    my $bson = bson_encode($data);
    my $data_check = bson_decode($bson);
    cmp_deeply($data,$data_check,'complex hash');
}

