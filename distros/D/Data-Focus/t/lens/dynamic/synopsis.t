use strict;
use warnings FATAL => "all";
use Test::More;

###########

package Blessed::Data;

sub new {
    my ($class) = @_;
    return bless {
        secret_data => "hoge",
        accessible_by_lens => {
            a => "a for Blessed::Data"
        },
    }, $class;
}

sub Lens {
    my ($self, $param) = @_;
    require Data::Focus::Lens::HashArray::Index;
    return (
        Data::Focus::Lens::HashArray::Index->new(index => "accessible_by_lens", allow_blessed => 1)
        . Data::Focus::Lens::HashArray::Index->new(index => $param)
    );
}


package main;
use Data::Focus qw(focus);
use Data::Focus::Lens::Dynamic;

my $plain_data = { a => "a for plain_data" };
my $blessed_data = Blessed::Data->new;

my $lens = Data::Focus::Lens::Dynamic->new("a");
is focus($plain_data)->get($lens), "a for plain_data";
is focus($blessed_data)->get($lens), "a for Blessed::Data";

$plain_data->{a} = $blessed_data;
is focus($plain_data)->get($lens, $lens), "a for Blessed::Data";


#########

done_testing;
