package Bot::BasicBot::Pluggable::Module::Alexa;

use strict;
use warnings;
use URI::Escape;
use WWW::Alexa::TrafficRank;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.01';

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    return unless ( $pri == 2 );

    my ( $command, $url ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "alexa" ) {
        my $rank    = $self->get_traffic_rank($url);
        my $message = $self->_create_reply_message($rank);
        $self->reply( $mess, $message );
    }
}

sub get_traffic_rank {
    my ( $self, $url ) = @_;
    my $api = WWW::Alexa::TrafficRank->new;
    $url =~ s{^(?:ht|f)tps?://|/+$}{}gi;
    my $rank = $api->get($url);
    $rank;
}

sub _create_reply_message {
    my ( $self, $rank ) = @_;
    my $message = "\cC14" . $rank;
    $message;
}

sub help {
    return "\cC14Commands: 'alexa <url>'";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Alexa - Traffic rank from Alexa

=head1 SYNOPSIS



=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::Alexa is module which gets traffic rank from Alexa.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
