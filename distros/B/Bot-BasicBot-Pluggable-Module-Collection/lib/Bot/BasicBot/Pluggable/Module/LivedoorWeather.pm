package Bot::BasicBot::Pluggable::Module::LivedoorWeather;

use strict;
use warnings;
use WebService::Livedoor::Weather;
use Encode;
use Data::Dumper;
use utf8;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.04';

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};

    return unless ( $pri == 2 );

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "weather" ) {
        my $message;
        eval {
            my $weather = $self->_get_weather($param);
            $message = $self->_create_reply_message($weather);
        };
        if ($@) {
            $message = "Can't find a such city: " . $param;
        }
        $self->reply( $mess, $message );
    }
}

sub trim {
    my ( $self, $string, $width, $marker ) = @_;

    my $jcode_ins = new Jcode( $string, 'utf8' );
    $jcode_ins->jfold( $width * 2 );
    $string = $jcode_ins->utf8;

    if ( $string =~ /\n/ ) {
        $string = ( split( /\n/, $string ) )[0] . $marker;
    }
    Encode::_utf8_on($string) unless Encode::is_utf8($string);
    $string;
}

sub _create_reply_message {
    my ( $self, $weather ) = @_;
    Encode::_utf8_on($weather->{telop}) unless Encode::is_utf8($weather->{telop});
    my $message
        = "\cC14"
        . "天気: "
        . $weather->{telop}
        . ' 気温: '
        . $weather->{temperature}->{max}->{celsius} . "(最高) "
        . $weather->{temperature}->{min}->{celsius} . "(最低)";

    #$message = $self->trim( $message, 200, '...' );
    $message =~ s/(?:\\n|\\r)+//g;
    $message;
}

sub _get_weather {
    my ( $self, $cityname ) = @_;
    my $api = WebService::Livedoor::Weather->new;

    # TODO: need to parametarize date?
    my $response = $api->get( $cityname, 'today' );
    $response;
}

sub help {
    return "Commands: 'weather <area>'";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::LivedoorWeather - Get weather information from livedoor Weather

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::LivedoorWeather;

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::LivedoorWeather is module which fetches weather information from livedoor Weather.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
