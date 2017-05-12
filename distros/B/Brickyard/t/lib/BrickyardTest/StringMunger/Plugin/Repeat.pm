use 5.010;
use warnings;
use strict;

package BrickyardTest::StringMunger::Plugin::Repeat;
use Brickyard::Accessor rw => [qw(times)];
use Role::Basic 'with';
with qw(
    Brickyard::Role::Plugin
    BrickyardTest::StringMunger::Role::StringMunger
);

sub run {
    my ($self, $text) = @_;
    $text x $self->times;
}
1;
