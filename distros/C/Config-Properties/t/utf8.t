# -*- Mode: Perl -*-

use Test::More tests => 1;

use Config::Properties;

my $cfg = Config::Properties->new(encoding => 'UTF-8');
$cfg->load(\*DATA);

is ($cfg->getProperty('country'), "Espa\xf1a", 'country');

__DATA__

country = España
