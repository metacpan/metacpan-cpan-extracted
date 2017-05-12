#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Data::Kanji::Tomoe;
my $obj = Data::Kanji::Tomoe->new (
    tomoe_data_file => '/path/to/data/file',
    character_callback => \& user_callback,
    data_I_wish_to_send => {some => 'data'},
);

$obj->parse ();

sub user_callback
{
    my ($obj, $c) = @_;
    my $data = $obj->{data_I_wish_to_send};
}
