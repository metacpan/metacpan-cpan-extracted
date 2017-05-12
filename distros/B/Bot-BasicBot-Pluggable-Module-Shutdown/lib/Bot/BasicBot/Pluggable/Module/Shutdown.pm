package Bot::BasicBot::Pluggable::Module::Shutdown;

use warnings;
use strict;
use parent 'Bot::BasicBot::Pluggable::Module';

our $VERSION = '0.03';


sub help {
    return
"Disconnects from IRC and shuts down bot process gracefully. Command must be issued as a private message or query in IRC. Requires !auth. Usage: !shutdown";
}

sub said {
    my ( $self, $mess ) = @_;
    my $body = $mess->{body};
    my $who  = $mess->{who};
    my $address = $mess->{address};

    # we don't care unless in /query
    return unless defined $address && $address eq "msg";

    # we don't care unless command is '!shutdown'
    return 0 unless defined $body;
    return 0 unless $body =~ /^!shutdown/;

    # we don't care about unauthed commands
    return "Requires !auth" unless $self->authed( $who );

    # quit irc and shutdown bot
    $self->bot->shutdown( $self->bot->quit_message() );
}

1;

__END__


=head1 NAME

Bot::BasicBot::Pluggable::Module::Shutdown - Disconnects from IRC and shuts down bot process gracefully.

=head1 DESCRIPTION

Disconnects from IRC and shuts down bot process gracefully. Command must be issued as a private message or query in IRC. Requires !auth. See 
L<Bot::BasicBot::Pluggable::Module::Auth> for more.

=head1 IRC USAGE

    !shutdown

=head1 AUTHOR

Michael Alexander, <omni@cpan.org>

=head1 ACKNOWLEDGEMENTS

Jess Robinson, <castaway@desert-island.me.uk>

=head1 COPYRIGHT

Copyright 2012, Michael Alexander

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Bot::BasicBot::Pluggable::Module::Auth>

=cut

