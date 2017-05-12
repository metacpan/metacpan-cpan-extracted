use strict;
use warnings;

use Test::More tests => 3;

package Date::Simple::Subclass;

use base qw(Date::Simple::ISO);

package main;

{
    my $date = Date::Simple::Subclass->today;
    is( ref $date, 'Date::Simple::Subclass' );
}

{
    my $date = Date::Simple::Subclass->d8('20000101');
    is( ref $date, 'Date::Simple::Subclass' );
}

{
    my $date = Date::Simple::Subclass->ymd(2000, 8, 1);
    is( ref $date, 'Date::Simple::Subclass' );
}
