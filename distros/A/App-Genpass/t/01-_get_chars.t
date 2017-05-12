#!perl

use strict;
use warnings;

use App::Genpass;
use Test::More tests => 2;
use Test::Deep 'cmp_bag';

my %default_opts = (
    lowercase  => ['a'],
    uppercase  => ['A'],
    numerical  => [ 2 ],
);

my %options = (
    'testing all with readable flag' => {
        specials => ['!'],
        readable => 1,
        result   => [ qw( a A 2 ) ],
    },

    'testing all without readable flag' => {
        specials => ['!'],
        readable => 0,
        result   => [ qw( a A 2 ! ) ],
    },
);

while ( my ( $opt_name, $opt_data ) = ( each %options ) ) {
    my $res = delete $opt_data->{'result'};
    my $app = App::Genpass->new(
        %{$opt_data},
        %default_opts,
    );

    my ( $types, @chars ) = @{ $app->_get_chars() };
    cmp_bag( \@chars, $res, $opt_name );
}

