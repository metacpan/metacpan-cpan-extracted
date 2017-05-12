package App::RoboBot::Plugin::Fun::Zalgo;
$App::RoboBot::Plugin::Fun::Zalgo::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Acme::Zalgo;

extends 'App::RoboBot::Plugin';

has '+name' => (
    default => 'Fun::Zalgo',
);

has '+description' => (
    default => 'Zalgo filter.',
);

has '+commands' => (
    default => sub {{
        zalgo => { method      => 'filter_zalgo',
                   description => 'Filters input argument text through a Zalgo generator.',
                   usage       => '<text>' }
    }}
);

sub filter_zalgo {
    my ($self, $message, $filter, $rpl, @args) = @_;

    return unless @args && @args > 0;

    return zalgo(join(' ', @args));
}

__PACKAGE__->meta->make_immutable;

1;
