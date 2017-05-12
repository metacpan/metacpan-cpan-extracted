package Bot::BasicBot::Pluggable::Module::GoogleTranslate;

use strict;
use warnings;
use URI::Escape;
use Readonly;
use URI;
use URI::QueryParam;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.01';

Readonly my $GOOGLE_TRANSLATE_URL => 'http://translate.google.com/translate';

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    return unless ( $pri == 2 );

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    # FIXME: modify interface later. looks ugly...
    if ( $command eq "j2e" ) {
        $self->reply_url( $mess, $param, 'ja', 'en' );
    }
    elsif ( $command eq "e2j" ) {
        $self->reply_url( $mess, $param, 'en', 'ja' );
    }
}

sub reply_url {
    my ( $self, $mess, $url, $from_lang, $to_lang ) = @_;
    my $translate_url
        = $self->build_google_translate_url( $url, $from_lang, $to_lang );
    my $reply_message = $self->_create_reply_message($translate_url);
    $self->reply( $mess, $reply_message );
}

sub build_google_translate_url {
    my ( $self, $url, $from_lang, $to_lang ) = @_;

    my $translate_url = URI->new($GOOGLE_TRANSLATE_URL);
    $translate_url->query_form_hash(
        u  => $url,
        hl => $to_lang,
        ie => 'UTF-8',
        sl => $from_lang,
        tl => $to_lang,
    );
    $translate_url;
}

sub _create_reply_message {
    my ( $self, $url ) = @_;
    my $message = "\cC14" . $url;
    $message;
}

sub help {
    return "\cC14Commands: 'j2e <url>'";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::GoogleTranslate-

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::GoogleTranslate;

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::GoogleTranslate is...

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
