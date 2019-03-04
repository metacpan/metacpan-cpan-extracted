use strict;
use Test::More 0.98;
use Acme::KemonoFriends::Color;

my $color_code      = Acme::KemonoFriends::Color::_get_color_code();
ok( $color_code =~ /1;38;5;\d*/, '_get_color_code');

my $escaped_message = Acme::KemonoFriends::Color::_escaped_message('test');
ok( $escaped_message =~ /\e\[1;38;5;\d* m test \e\[m/xms , '_escaped_message');

done_testing;

