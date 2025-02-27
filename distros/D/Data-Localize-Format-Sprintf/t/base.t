use Test2::V0;
use Data::Localize::Format::Sprintf;
use utf8;

################################################################################
# This tests whether this (simple) module works
################################################################################

my $formatter = Data::Localize::Format::Sprintf->new;

is $formatter->format('pl', 'zażółć %s jaźń', 'gęślą'), 'zażółć gęślą jaźń', 'formatting ok';

done_testing;

