package Bot::BasicBot::Pluggable::Module::Spotify;

use warnings;
use strict;

use Net::Spotify ();
use XML::TreePP ();

use base 'Bot::BasicBot::Pluggable::Module::Base';

our $VERSION = '0.01';

my $spotify = Net::Spotify->new();
my $tpp = XML::TreePP->new();

sub help {
    return 'Will parse those cryptic Spotify URIs showing the interesting information :)';
}

sub said {
    my ($self, $mess, $pri) = @_;

    return unless $pri == 2;

    my @data = $self->parse_spotify_uris($mess->{body});

    if (! scalar @data) {
        return;
    }

    foreach my $info (@data) {
        $self->tell($mess->{channel}, $info)
    }

    return;
}

sub parse_spotify_uris {
    my ($self, $text) = @_;

    my @data = ();

    while ($text =~ m{ \b (spotify:(artist|album|track):\w+) \b }gmx) {
        my ($uri, $type) = ($1, $2);

        my $xml = $spotify->lookup(uri => $uri);

        if (my $tree = $tpp->parse($xml)) {
            if ($type eq 'artist') {
                push @data, sprintf(
                    '%s -> Artist: %s',
                    $uri,
                    $tree->{artist}->{name},
                );
            }
            elsif ($type eq 'album') {
                push @data, sprintf(
                    '%s -> Album: %s, Artist: %s, Year: %s',
                    $uri,
                    $tree->{album}->{name}, $tree->{album}->{artist}->{name},
                    $tree->{album}->{released}
                );
            }
            elsif ($type eq 'track') {
                push @data, sprintf(
                    '%s -> Track: %s, Album: %s, Artist: %s',
                    $uri,
                    $tree->{track}->{name},
                    $tree->{track}->{album}->{name},
                    $tree->{track}->{artist}->{name},
                );
            }
        }
    }

    return @data;
}

1;

__END__

=pod

=head1 NAME

Bot::BasicBot::Pluggable::Module::Spotify - Show relevant information when a Spotify URI is detected in a channel

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Simply load this plugin in your C<Bot::BasicBot::Pluggable>-based IRC bot.
When someone writes a Spotify URI in an IRC channel, the plugin does a lookup
for that URI and shows back the relevant information.

Example:

    <user1> check out this song, man! spotify:track:7sOBuRK26Ov7CR5fRSR7Om
    <bot> spotify:track:7sOBuRK26Ov7CR5fRSR7Om -> Track: Surf Rider - LP Version, \
    Album: Surf Rider!, Artist: The Lively Ones
    <user2> i know that one, me <3

=head1 METHODS

=head2 help

Returns the string sent to the channel when someone asks the bot C<help Spotify>.

=head2 said

Listens for every message in the channel and detects Spotify URIs.
If the URIs are valid, a lookup is performed and the relevant information
are sent back in the channel.

=head2 parse_spotify_uris

Extracts the Spotify URIs from the message, performs the lookup using
L<Net::Spotify> and extracts the relevant information from the XML response.
The message sent back in the channel is formatted depending on the URI type.

=head1 SEE ALSO

L<Bot::BasicBot::Pluggable>, L<Net::Spotify>, L<XML::TreePP>

=head1 AUTHOR

Edoardo Sabadelli, C<< <edoardo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bot-basicbot-pluggable-module-spotify at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-Spotify>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::Spotify

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-Spotify>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-Spotify>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-Spotify>

=item * Search CPAN

L<http://search.cpan.org/dist/Bot-BasicBot-Pluggable-Module-Spotify/>

=back

=head1 ACKNOWLEDGEMENTS

This product uses a SPOTIFY API but is not endorsed, certified or otherwise
approved in any way by Spotify.
Spotify is the registered trademark of the Spotify Group.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Edoardo Sabadelli, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
