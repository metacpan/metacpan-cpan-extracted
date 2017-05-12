package Bot::BasicBot::Pluggable::Module::PathtraqPageCounter;

use strict;
use warnings;
use Readonly;
use URI;
use JSON;
use LWP::UserAgent;
use Data::Dumper;

use base qw(Bot::BasicBot::Pluggable::Module);

Readonly my $API_BASE_URL => 'http://api.pathtraq.com';

our $VERSION = '0.01';

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    return unless ( $pri == 2 );

    my ( $command, $url ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "pathtraq" ) {
        my $rank = $self->get_page_counter($url);
        my $message = $self->_create_reply_message($rank);
        $self->reply( $mess, $message );
    }
}

sub get_page_counter {
    my ( $self, $url ) = @_;
    my $res = $self->_get($url);
    my $content = $res->is_success ? from_json( $res->content ) : undef;
    return $content->{count} if $content;
}

sub _get {
    my ( $self, $url ) = @_;
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy();
    my $uri = $self->_build_api_uri($url);
    my $res = $ua->get($uri);
    $res;
}

sub _build_api_uri {
    my ( $self, $url ) = @_;
    my $uri = URI->new( $API_BASE_URL . '/page_counter' );
    my $params = {};
    $params->{api} = 'json';
    $params->{url} = $url;
    $uri->query_form($params);
    $uri;
}

sub _create_reply_message {
    my ( $self, $rank ) = @_;
    my $message = "\cC14" . $rank;
    $message;
}

sub help {
    return "\cC14Commands: 'pathtrac <url>'";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::PathtraqPageCounter - Page counter from Pathtraq

=head1 SYNOPSIS



=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::PathtraqPageCounter is module which gets traffic rank from Pathtraq.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
