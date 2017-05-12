use Test::More tests => 2;
use strict;
use warnings;

use Dancer::Plugin::Formatter;

my $sub = Dancer::Plugin::Formatter::format_date();

ok( $sub->('') eq '',            'empty argument' );
ok( !defined($sub->(undef)), 'undefined argument' );
