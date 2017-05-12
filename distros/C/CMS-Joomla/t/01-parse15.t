#!perl -w

use Test::Simple tests => 3;

use CMS::Joomla;

my ($joomla) = CMS::Joomla->new('t/configuration-1.5.php');

ok( defined($joomla) );				
ok( defined($joomla->{'cfg'}->{'dbprefix'}) );				
ok( $joomla->dbprefix eq 'jos_' );

