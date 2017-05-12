use Test::More tests => 3;

use strict;
use warnings;

use Dancer qw(:tests);
use Dancer::Plugin::Passphrase;

my $secret = "Super Secret Squirrel";
my $two_a  = '{CRYPT}$2a$04$MjkMhQxasFQod1qq56DXCOvWu6YTWk9X.EZGnmSSIbbtyEBIAixbS';
my $two_x  = '{CRYPT}$2x$04$MjkMhQxasFQod1qq56DXCOvWu6YTWk9X.EZGnmSSIbbtyEBIAixbS';
my $two_y  = '{CRYPT}$2y$04$MjkMhQxasFQod1qq56DXCOvWu6YTWk9X.EZGnmSSIbbtyEBIAixbS';

ok(passphrase($secret)->matches($two_a),  'Matches $2a$ (ambiguous bcrypt)');
ok(passphrase($secret)->matches($two_x),  'Matches $2x$ (broken bcrypt)');
ok(passphrase($secret)->matches($two_a),  'Matches $2y$ (new standard bcrypt)');
