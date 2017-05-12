package Bot::BasicBot::Pluggable::Module::Wikipedia;

use strict;
use warnings;
use URI::Escape;
use Readonly;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.01';

Readonly my $WIKIPEDIA_BASE_URL => 'http://ja.wikipedia.org/wiki/';

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    return unless ( $pri == 2 );

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "wikipedia" ) {
        my $url     = $self->wikipedia_url($param);
        my $message = $self->_create_reply_message($url);
        $self->reply( $mess, $message );
    }
}

sub wikipedia_url {
    my ( $self, $term ) = @_;
    my $url = $WIKIPEDIA_BASE_URL . URI::Escape::uri_escape_utf8($term);
    $url;
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

Bot::BasicBot::Pluggable::Module::Wikipedia- create a link to Japanese Wikipedia

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::Wikipedia;

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::Wikipedia module which creates a link to Japanese Wikipedia.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
