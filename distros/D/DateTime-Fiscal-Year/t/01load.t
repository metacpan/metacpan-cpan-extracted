use Test::More tests => 1;

use DateTime;
use DateTime::Fiscal::Year;

use strict;

{
my $dt = DateTime->new(year => 2003, month=> 02, day=>01);
my $dt2 = DateTime->new(year => 2003, month=> 03, day=>01);

my $fiscal = DateTime::Fiscal::Year->new( start => $dt );

isa_ok( $fiscal, 'DateTime::Fiscal::Year' );
}
