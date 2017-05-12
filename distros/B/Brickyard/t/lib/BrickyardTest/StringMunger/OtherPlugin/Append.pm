use 5.010;
use warnings;
use strict;

package BrickyardTest::StringMunger::OtherPlugin::Append;
use Brickyard::Accessor rw => [qw(string)];
use Role::Basic 'with';
with qw(
    Brickyard::Role::Plugin
    BrickyardTest::StringMunger::Role::StringMunger
);

sub run {
    my ($self, $text) = @_;
    $text .= $_ for $self->normalize_param($self->string);
    "$text\n";
}

1;
