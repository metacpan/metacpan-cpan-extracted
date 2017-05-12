use strict;
use DateTime;
use Acme::Nogizaka46;
use Test::More tests => 7;

my $nogizaka  = Acme::Nogizaka46->new;

is scalar($nogizaka->members),             51, " members(undef) retrieved all";
is scalar($nogizaka->members('active')),   35, " members('active')";
is scalar($nogizaka->members('graduate')), 16, " members('graduate')";
is scalar($nogizaka->members(DateTime->new(year => 2011, month => 8, day => 20))), 0, " members('date_simple_object')";
is scalar($nogizaka->members(DateTime->new(year => 2011, month => 8, day => 21))), 36, " members('date_simple_object')";
is scalar($nogizaka->members(DateTime->new(year => 2014, month => 8, day => 21))), 43, " members('date_simple_object')";
is scalar($nogizaka->members(DateTime->new(year => 2016, month => 3, day => 23))), 36, " members('date_simple_object')";
