package Bot::BasicBot::Pluggable::Module::Join;
$Bot::BasicBot::Pluggable::Module::Join::VERSION = '1.20';
use base qw(Bot::BasicBot::Pluggable::Module);
use warnings;
use strict;

sub connected {
    my $self = shift;
    my $channels = $self->get("channels") || [];

    ## If we are not a array reference, we are problably the old
    ## string format ... trying to convert
    if ( not ref($channels) && $channels =~ 'ARRAY' ) {
        $channels = [ split( /\s+/, $channels ) ];
    }

    for ( @{$channels} ) {
        print "Joining $_.\n";
        $self->bot->join($_);
    }
}

sub help {
    return
"Join and leave channels. Usage: join <channel>, leave/part <channel>, channels. Requires direct addressing.";
}

sub told {
    my ( $self, $mess ) = @_;
    my $body = $mess->{body};
    return unless defined $body;
    return unless $mess->{address};

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);
    return unless $command =~ /^(join|leave|part|channels)$/;

    if (!$self->authed($mess->{who})) {
        return "Sorry, you must be authenticated to do that.";
    }

    if ( $command eq "join" ) {
        $self->add_channel($param);
        return "Ok.";

    }
    elsif ( $command eq "leave" or $command eq "part" ) {
        $self->remove_channel( $param || $mess->{channel} );
        return "Ok.";

    }
    elsif ( $command eq "channels" ) {
        my @channels    = $self->bot->channels;
        my $channel_num = scalar @channels;
        if ( $channel_num == 0 ) {
            return "I'm not in any channel.";
        }
        elsif ( $channel_num == 1 ) {
            return "I'm in " . $channels[0] . ".";
        }
        elsif ( $channel_num == 2 ) {
            return "I'm in " . $channels[0] . " and " . $channels[1] . ".";
        }
        else {
            return
                "I'm in "
              . join( ', ', @channels[ 0 .. $#channels - 1 ] )
              . " and $channels[-1].";
        }
    }
}

sub chanjoin {
    my ( $self, $mess ) = @_;
    if ( $mess->{who} eq $self->bot->nick ) {
        $self->set( channels => [ $self->bot->channels ] );
    }
}

sub chanpart {
    my ( $self, $mess ) = @_;
    if ( $mess->{who} eq $self->bot->nick ) {
        $self->set( channels => [ $self->bot->channels ] );
    }
}

sub add_channel {
    my ( $self, $channel ) = @_;
    $self->bot->join($channel);
}

sub remove_channel {
    my ( $self, $channel ) = @_;
    $self->bot->part($channel);
}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Join - join and leave channels; remembers state

=head1 VERSION

version 1.20

=head1 IRC USAGE

=over 4

=item join <channel>

=item part <channel>

=item channels

List the channels the bot is in.

=back

=head1 METHODS

=over 4

=item add_channel($channel)

=item remove_channel($channel)

=back

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
