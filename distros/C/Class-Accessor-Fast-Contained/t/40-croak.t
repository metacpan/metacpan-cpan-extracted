use strict;
use Test::More tests => 2;
require Class::Accessor::Fast::Contained;

@Frog::ISA = ('Class::Accessor::Fast::Contained');
my $croaked = 0;
sub Frog::_croak { ++$croaked }
Frog->mk_ro_accessors('test_ro');
Frog->mk_wo_accessors('test_wo');

my $frog = Frog->new;

eval {
    $croaked = 0;
    $frog->test_ro("foo");
    is $croaked, 1, "we croaked for ro";

    $croaked = 0;
    $frog->test_wo;
    is $croaked, 1, "we croaked for wo";
};

fail "We really croaked: $@" if $@;

