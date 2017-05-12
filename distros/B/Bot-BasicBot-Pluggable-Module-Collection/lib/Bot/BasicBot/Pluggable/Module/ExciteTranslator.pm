package Bot::BasicBot::Pluggable::Module::ExciteTranslator;
use strict;
use warnings;
use HTTP::Request::Common;
use LWP::UserAgent;
use Data::Dumper;
use Web::Scraper;
use Encode;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.01';

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    return unless ( $pri == 2 );

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "translate" ) {
        my $url     = $self->translate($param);
        my $message = $self->_create_reply_message($url);
        $self->reply( $mess, $message );
    }
}

sub translate {
    my ( $self, $text ) = @_;
    utf8::encode($text) if utf8::is_utf8($text);
    Encode::from_to( $text, "utf8", "cp932" );
    my $ua       = LWP::UserAgent->new;
    my $response = $ua->request(
        POST 'http://www.excite.co.jp/world/english/',
        [ before => $text, wb_lp => 'JAEN' ]
    );

    my $scraper = scraper {
        process '//textarea[@name="after"]', 'text' => 'TEXT';
    };
    my $res = $scraper->scrape( $response->content );
    $res->{text};
}

sub _create_reply_message {
    my ( $self, $url ) = @_;
    my $message = "\cC14" . $url;
    $message;
}

sub help {
    return "\cC14Commands: 'wikipedia <term>'";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::ExciteTranslator- create a link to

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::ExciteTranslator;

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::ExciteTranslator module which creates a link to .

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
