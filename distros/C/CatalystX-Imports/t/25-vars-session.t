use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 6;

use Test::WWW::Mechanize::Catalyst 'TestApp';

my $ua = Test::WWW::Mechanize::Catalyst->new;

$ua->get_ok('http://localhost/vars/set_session/23');
$ua->get_ok('http://localhost/vars/test_session');
$ua->content_is('23');

$ua->get_ok('http://localhost/vars/set_flash/42');
$ua->get_ok('http://localhost/vars/test_flash');
$ua->content_is('42');
