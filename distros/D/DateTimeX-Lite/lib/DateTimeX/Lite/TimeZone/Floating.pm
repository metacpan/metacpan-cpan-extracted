# $Id: Floating.pm 27589 2008-12-29 23:51:35Z daisuke $

package DateTimeX::Lite::TimeZone::Floating;
use strict;
use base qw(DateTimeX::Lite::TimeZone::OffsetOnly);

sub new {
    my $class = shift;
    bless {name => 'floating', offset => 0}, $class;
}

sub is_floating { 1 };

1;