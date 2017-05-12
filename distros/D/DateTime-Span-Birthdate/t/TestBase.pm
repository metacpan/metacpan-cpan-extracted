package t::TestBase;
use Test::Base -base;

filters { on => 'date', start => 'date', end => 'date', expected => 'regexp' };

package t::TestBase::Filter;
use Test::Base::Filter -Base;

sub date {
    my @ymd = split /-/, shift;
    return DateTime->new(year => $ymd[0], month => $ymd[1], day => $ymd[2]);
}

1;
