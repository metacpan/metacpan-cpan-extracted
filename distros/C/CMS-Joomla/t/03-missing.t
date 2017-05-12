#!perl -w

use Test::Simple tests => 1;

use CMS::Joomla;

my ($joomla) = CMS::Joomla->new('t/noexist.php');

ok( !defined($joomla) );				
