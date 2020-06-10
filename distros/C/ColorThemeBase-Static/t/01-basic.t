#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use ColorTheme::Test::Dynamic;
use ColorTheme::Test::Static;

subtest new => sub {
    dies_ok { ColorTheme::Test::Dynamic->new } "missing required arg";
    dies_ok { ColorTheme::Test::Dynamic->new(tone=>"red", foo=>1) } "unknown arg";
    lives_ok { ColorTheme::Test::Dynamic->new(tone=>"red") };
};

subtest list_items => sub {
    my $ct = ColorTheme::Test::Static->new;
    is_deeply([$ct->list_items]      , [qw/color1 color2 color3 color4 color5/]);
    is_deeply(scalar($ct->list_items), [qw/color1 color2 color3 color4 color5/]);
};

subtest get_item_color => sub {
    my $ct = ColorTheme::Test::Static->new;
    is_deeply($ct->get_item_color('color1'), 'ff0000');
    is_deeply($ct->get_item_color('color2'), '00ff00');
    is_deeply($ct->get_item_color('color3'), {bg=>'0000ff'});
    is_deeply($ct->get_item_color('color4'), {bg=>'ffffff', fg=>'000000'});
    ok(ref($ct->get_item_color('color5')), 'HASH');
    is_deeply([$ct->get_item_color('color99')], []);
};

subtest get_struct => sub {
    my $ct = ColorTheme::Test::Static->new;
    my $struct = $ct->get_struct;
    is(ref($struct), 'HASH');
    is(ref($struct->{items}), 'HASH');
};

subtest get_args => sub {
    my $ct = ColorTheme::Test::Static->new(foo=>1, bar=>2);
    is_deeply($ct->get_args, {foo=>1, bar=>2});
};

done_testing;
