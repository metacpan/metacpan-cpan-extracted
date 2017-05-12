use 5.010;
use warnings;
use strict;

package BrickyardTest::StringMunger::Plugin::Increment;
use Role::Basic 'with';
with qw(
    Brickyard::Role::Plugin
    BrickyardTest::StringMunger::Role::NumberMunger
);

sub run {
    my ($self, $value) = @_;
    $value + 1;
}

1;
