package Bot::R9K;

use warnings;
use strict;
use 5.010;

use POE;
use POE::Component::IRC::Plugin qw(:ALL);

use List::MoreUtils qw(any);

our $VERSION = 0.01;

=head1 NAME 

Bot::R9K

=head1 SYNOPSIS

    use POE qw(Component::IRC);
    use Bot::R9K;

    my $irc = POE::Component::IRC->spawn(
        nick        => 'Bot-R9K',
        server      => 'irc.botnet.org',
        port        => 6667,
        ircname     => 'R9K',
        username    => 'r9k',
        debug       => 1,
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start irc_001) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );
        
        $irc->plugin_add(
            'R9K' =>
                Bot::R9K->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[kernel]->post( $_[sender] => join => '#channel' );
    }

=head1 DESCRIPTION

Bot::R9K is a PoCo::IRC plugin that runs an R9K bot for you. The R9K bot watches
for repeated messages and silences anyone who says something that has been said
before. The more times it has been said, the longer the silence.

Remember to op your bot when it joins.

=head1 METHODS

=head2 new

Create a new bot: see L<SYNOPSIS>.

=head3 Options

=over 

=item ignore

An array ref of regexes to ignore. They are tested against the full nick (with
the ! and the @ and everything).

=item exceptions

An array ref of regexes defining exempt messages.

=item punishment

A subref. This will be passed [c]$self[/c], [c]$nick[/c] and [c]$chan[/c]. Do
what you want; the default is to remove voice and ban (but not kick).

=item unpunishment

A subref. Receives the same info as [c]punishment[/c]. Use this to reverse the
punishment. By default it removes the ban and sets voice, regardless of whether
the user originally had voice (the point of the bot is rather that you can
silence people, so everyone who is not silenced should have voice).

=back

=cut

sub new {
    my $package = shift;

    my $options = shift // {};

    my %default = (
        ignore => [],
        exceptions => [],
        punishment => sub {
            my ($self, $nick, $chan) = @_;
            my $smallnick = (split /!/, $nick)[0];

            say "Punishing $nick in $chan";
            $self->{irc}->yield(mode => "$chan -v+b $smallnick $nick");
        },
        unpunishment => sub {
            my ($self, $nick, $chan) = @_;
            my $smallnick = (split /!/, $nick)[0];

            say "Pardoning $nick in $chan";
            $self->{irc}->yield(mode => "$chan +v-b $smallnick $nick");
        },
        f => sub {
            return shift() ** 2;
        }
    );
    $options = { %default, %$options };
    return bless $options, $package;
}

sub PCI_register {
    my ($self, $irc) = @_;

    $irc->plugin_register($self, 'SERVER', 'public');
    $self->{irc} = $irc;
    return 1;
}

sub PCI_unregister { 1 }

sub S_public {
    my $self = shift;
    my $irc = shift;

    my $nick = ${ $_[0] };
    my $chan = ${ $_[1] }->[0];
    my $msg  = ${ $_[2] };

    return PCI_EAT_NONE if any { $nick =~ $_ } @{ $self->{ignore} };
    return PCI_EAT_NONE if any { $msg =~ $_ } @{ $self->{exceptions} };

    my $penalty = $self->{channel}->{$chan}->{message}->{$msg}++;
    return PCI_EAT_NONE unless $penalty;

    say "punishing $nick in $chan for saying -- $msg --";

    $self->punish($nick, $chan, $penalty);
    return PCI_EAT_NONE;
}

sub punish {
    my ($self, $nick, $chan, $penalty) = @_;

    my $timeout = int($self->{f}->($penalty));
    my $punishment = $self->{punishment};

    $self->$punishment($nick, $chan);

    POE::Session->create(
        inline_states => {
            _start => sub {
                $_[KERNEL]->alarm(unpunish => int(time + $timeout));
            },
            unpunish => sub {
                $self->unpunish($nick, $chan);
            },
        },
    );
}

sub unpunish {
    my ($self, $nick, $chan) = @_;
    my $unpunishment = $self->{unpunishment};

    $self->$unpunishment($nick, $chan);
}

1;

__END__

=head1 DO WHAT, SON?

R9K is short for ROBOT9000 and that is a thing that enforces originality by
punishing you for saying something that someone else has said before.

Here is an xkcd blog post explaining what the R9K bot does.
http://blog.xkcd.com/2008/01/14/robot9000-and-xkcd-signal-attacking-noise-in-chat/

=head1 BUGS

Dunno.

Report bugs at http://github.com/Altreus/Bot-R9K/issues

=head1 AUTHOR

Alastair McGowan-Douglas (Altreus)

=head1 LICENCE

This module is released under the X11/MIT licence, as found here
http://www.opensource.org/licenses/mit-license.php

=cut
