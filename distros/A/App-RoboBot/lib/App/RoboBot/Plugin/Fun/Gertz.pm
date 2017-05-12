package App::RoboBot::Plugin::Fun::Gertz;
$App::RoboBot::Plugin::Fun::Gertz::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

extends 'App::RoboBot::Plugin';

=head1 fun.gertz

This module exports no functions. It inserts a pre-hook into the message
processing pipeline as part of an old inside joke. A hook which is disabled by
default anyway, because there are probably half a dozen people in the world who
remember what it was about and find it amusing.

=cut

has '+name' => (
    default => 'Fun::Gertz',
);

has '+description' => (
    default => 'Gertz Alertz!',
);

has '+before_hook' => (
    default => 'gertz_alert',
);

sub gertz_alert {
    my ($self, $message) = @_;

return; # no gertz alertz for the time being
    return if $message->has_expression;

    if ($message->raw =~ m{\b(gertz)\b}oi) {
        # do not respond if we matched on another bot's gertz alertz
        $message->response->unshift('GERTZ ALERTZ!')
            unless $message->raw =~ m{gertz\s+alertz}oi;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
