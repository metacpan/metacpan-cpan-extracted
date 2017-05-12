use strict;
use warnings;
use utf8;
use lib 't/lib';
use Test::More;
use Data::Dumper;
use Data::Dumper::OneLine;
use Test::Exception;

is(
    Dumper({ foo => { bar => 1 }}),
    '{foo => {bar => 1}}',
);

for my $stuff (sub {}, Foo->new) {
    lives_ok {
        Dumper($stuff);
    } Dumper($stuff);
};

done_testing;

package Foo;
sub new { bless {}, shift }
