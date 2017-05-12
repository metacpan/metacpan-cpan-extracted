package App::RoboBot::Plugin::Fun::Fortune;
$App::RoboBot::Plugin::Fun::Fortune::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

extends 'App::RoboBot::Plugin';

=head1 fun.fortune

Exports functions for displaying random selections from the ``fortune`` program
commonly found on Un*x-y systems.

The fortunes displayed are generally limited to those under a couple hundred
characters.

=cut

has '+name' => (
    default => 'Fun::Fortune',
);

has '+description' => (
    default => 'Exports functions for displaying various types of quotes and fortunes.',
);

=head2 bofh

=head3 Description

Returns fortunes from just the BOFH Excuses collection. Useful when production
just went down hard and laughter is all you have left before being shown the
door.

=head2 fortune

=head3 Description

Selects at random a collection from a relatively non-offensive list of fortune
databases, and returns a random fortune. None of the fortune collections
overlap with the more specific functions also exported by this module.

=head2 startrek

=head3 Description

Returns a random Star Trek quote from the fortune database.

=head2 zippy

=head3 Description

Returns a random Zippy the Pinhead quote from the fotune database.

=cut

has '+commands' => (
    default => sub {{
        'bofh' => { method      => 'bofh',
                    description => 'Returns a random BOFH quote.',
                    usage       => '' },

        'fortune' => { method      => 'fortune',
                       description => 'Returns a random fortune from one of several collections.',
                       usage       => '' },

        'startrek' => { method      => 'startrek',
                        description => 'Returns a random Star Trek quote.',
                        usage       => '' },

        'zippy' => { method      => 'zippy',
                     description => 'Returns a random Zippy the Pinhead quote.',
                     usage       => '' },
    }},
);

# TODO make this auto-discover path, or at least move it to a configuration option
has 'bin_path' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/usr/games/fortune',
);

has 'max_len' => (
    is      => 'ro',
    isa     => 'Num',
    default => '200',
);

sub bofh {
    my ($self, $message, $command, $rpl, @args) = @_;

    return $self->get_fortune($message, 'bofh-excuses');
}

sub fortune {
    my ($self, $message, $command, $rpl, @args) = @_;

    return $self->get_fortune($message, qw( people miscellaneous wisdom paradoxum fortunes humorists computers cookie pets ));
}

sub startrek {
    my ($self, $message, $command, $rpl, @args) = @_;

    return $self->get_fortune($message, 'startrek');
}

sub zippy {
    my ($self, $message, $command, $rpl, @args) = @_;

    return $self->get_fortune($message, 'zippy');
}

sub get_fortune {
    my ($self, $message, @dicts) = @_;

    unless (-x $self->bin_path) {
        $message->response->raise('Fortune program is not installed.');
        return;
    }

    my $dictlist = lc(join(' ', @dicts));
    unless ($dictlist =~ m{^[a-z -]+$}o) {
        $message->response->raise('Invalid dictionary name provided.');
        return;
    }

    my $cmd = $self->bin_path . ' -n ' . $self->max_len . ' -s ' . $dictlist;

    return $self->cleanup_fortune($message, scalar(`$cmd`));
}

sub cleanup_fortune {
    my ($self, $message, $fortune) = @_;

    $fortune =~ s{\s+}{ }ogs;
    $fortune =~ s{(^\s+|\s+$)}{}ogs;

    return $fortune;
}

__PACKAGE__->meta->make_immutable;

1;
