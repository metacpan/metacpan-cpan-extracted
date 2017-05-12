use strict;
use warnings;

use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

BEGIN {
    use_ok 'Badge::Depot::Plugin::Gratipay';
}

my $badge = Badge::Depot::Plugin::Gratipay->new(user => 'testuser');

is $badge->to_html,
   '<a href="https://gratipay.com/testuser"><img src="https://img.shields.io/gratipay/testuser.svg" alt="Gratipay" /></a>',
   'Correct standard image';

my $custom_badge = Badge::Depot::Plugin::Gratipay->new(user => 'testuser', custom_image_url => 'https://img.example.com/gratipay/%s.svg');

is $custom_badge->to_html,
   '<a href="https://gratipay.com/testuser"><img src="https://img.example.com/gratipay/testuser.svg" alt="Gratipay" /></a>',
   'Correct custom image';

done_testing;
