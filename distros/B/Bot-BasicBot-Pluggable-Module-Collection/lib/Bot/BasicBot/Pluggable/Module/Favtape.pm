package Bot::BasicBot::Pluggable::Module::Favtape;

use strict;
use warnings;
use URI::Escape;
use Readonly;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.01';

Readonly my $FAVTAPE_BASE_URL => 'http://favtape.com/search/';

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    return unless ( $pri == 2 );

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "favtape" ) {
        my $url     = $self->favtape_artist_url($param);
        my $message = $self->_create_reply_message($url);
        $self->reply( $mess, $message );
    }
}

sub favtape_artist_url {
    my ( $self, $term ) = @_;
    my $url = $FAVTAPE_BASE_URL . URI::Escape::uri_escape_utf8($term);
    $url;
}

sub _create_reply_message {
    my ( $self, $url ) = @_;
    my $message = "\cC14" . $url;
    $message;
}

sub help {
    return "\cC14Commands: 'favtape <artist name>'";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Favtape- create a link to

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::Favtape;

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::Favtape module which creates a link to .

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
