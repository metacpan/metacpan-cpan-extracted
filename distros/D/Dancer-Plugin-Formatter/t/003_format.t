use Test::More tests => 1;
use strict;
use warnings;

use Dancer::Plugin::Formatter;

$Dancer::Plugin::Formatter::default_date_format = '%D';

my $sub = Dancer::Plugin::Formatter::format_date();

ok( $sub->('1995:01:24') eq '01/24/95', 'parsing and formatting' );
#diag( 'Formatted date = ' . Dancer::Plugin::Formatter::format_date('1995:01:24')() );
