use 5.010;
use warnings;
use strict;

package BrickyardTest::StringMunger::Plugin::Reporter;
use Role::Basic 'with';
with qw(
    Brickyard::Role::Plugin
    BrickyardTest::StringMunger::Role::StringMunger
);

sub run {
    my ($self, $text) = @_;
    1 while chomp $text;
    $text .= "\n";
    my @plugins = $self->plugins_with(-StringMunger);
    $text .= "$_\n" for map { $_->name } @plugins;
    $text;
}

1;
