package Bot::BasicBot::Pluggable::Module::LivedoorFortune;

use strict;
use warnings;
use URI;
use Web::Scraper;
use Carp;
use utf8;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.01';

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    return unless ( $pri == 2 );

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "fortune" ) {
        eval {
            my $fortune = $self->get_fortune_of_today($param);
            my $message = $self->_create_reply_message($fortune);
            $self->reply( $mess, $message );
        };
    }
}

sub get_fortune_of_today {
    my ( $self, $asterism ) = @_;
    my $url      = $self->_asterism2url($asterism);
    my $response = $self->_scrape_fortune($url);
    $response->{today_total};
}

sub _asterism2url {
    my ( $self, $asterism ) = @_;

    my $url = '';
    if ( $asterism =~ m/(?:おひつじ|牡羊)座/x ) {
        $url = 'http://fortune.livedoor.com/free/daily/aries/';
    }
    elsif ( $asterism =~ m/(?:おうし|牡牛)座/x ) {
        $url = 'http://fortune.livedoor.com/free/daily/taurus/';
    }
    elsif ( $asterism =~ m/(?:ふたご|双子)座/x ) {
        $url = 'http://fortune.livedoor.com/free/daily/gemini/';
    }
    elsif ( $asterism =~ m/(?:かに|蟹)座/x ) {
        $url = 'http://fortune.livedoor.com/free/daily/cancer/';
    }
    elsif ( $asterism =~ m/(?:しし|獅子)座/x ) {
        $url = 'http://fortune.livedoor.com/free/daily/leo/';
    }
    elsif ( $asterism =~ m/(?:おとめ|乙女)座/x ) {
        $url = 'http://fortune.livedoor.com/free/daily/virgo/';
    }
    elsif ( $asterism =~ m/(?:てんびん|天秤)座/x ) {
        $url = 'http://fortune.livedoor.com/free/daily/libra/';
    }
    elsif ( $asterism =~ m/(?:さそり|蠍)座/x ) {
        $url = 'http://fortune.livedoor.com/free/daily/scorpio/';
    }
    elsif ( $asterism =~ m/(?:いて|射手)座/x ) {
        $url = 'http://fortune.livedoor.com/free/daily/sagittarius/';
    }
    elsif ( $asterism =~ m/(?:やぎ|山羊)座/x ) {
        $url = 'http://fortune.livedoor.com/free/daily/capricorn/';
    }
    elsif ( $asterism =~ m/(?:みずがめ|水瓶)座/x ) {
        $url = 'http://fortune.livedoor.com/free/daily/aquarius/';
    }
    elsif ( $asterism =~ m/(?:うお|魚)座/x ) {
        $url = 'http://fortune.livedoor.com/free/daily/pisces/';
    }
    $url;
}

sub _scrape_fortune {
    my ( $self, $url ) = @_;
    my $uri     = new URI($url);
    my $scraper = scraper {
        process '.description', 'today_total' => 'TEXT';
    };
    my $res = $scraper->scrape($uri);
}

sub _create_reply_message {
    my ( $self, $url ) = @_;
    my $message = "\cC14" . $url;
    $message;
}

sub help {
    return "\cC14Commands: 'fortune <asterism>'";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::LivedoorFortune- get today fortune.

=head1 SYNOPSIS



=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::LivedoorFortune module which creates a link to .

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
