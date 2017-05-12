#!perl

use strict;
use warnings;
use lib qw/./;

use vars qw/@Share/;

BEGIN {
    @Share = qw/verbose/;
}

use Test::More qw/no_plan/;

use t::Pack qw/verbose/;

eval {
    &t::Pack::A::a;
};
is($@, <<_END_);
Carp::Clan::__ANON__(): Break! at t/Pack/B.pm line 10
\tt::Pack::B::b() called at t/Pack/A.pm line 9
\tt::Pack::A::a() called at $0 line 18
\teval {...} called at $0 line 17
_END_

eval {
    &t::Pack::A::b;
};
is($@, <<_END_);
Carp::Clan::__ANON__(): Break! at t/Pack/A.pm line 13
\tt::Pack::A::b() called at $0 line 28
\teval {...} called at $0 line 27
_END_
