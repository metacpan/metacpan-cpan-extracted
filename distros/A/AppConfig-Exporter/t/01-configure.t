#!perl -T

package Test::Config;

use Test::More tests => 2;

BEGIN {
	use_ok( 'AppConfig::Exporter' );
	use base q(AppConfig::Exporter);
}

ok(__PACKAGE__->configure(Config_File => 't/config.test'), 'Configure');
