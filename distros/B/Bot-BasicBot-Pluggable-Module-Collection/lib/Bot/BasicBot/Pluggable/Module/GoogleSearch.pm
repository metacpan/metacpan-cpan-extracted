package Bot::BasicBot::Pluggable::Module::GoogleSearch;

use strict;
use warnings;
use URI;
use URI::Escape;
use Readonly;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.01';

Readonly my $GOOGLE_BASE_URL => 'http://www.google.co.jp/search';

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    return unless ( $pri == 2 );

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "google" ) {
        my $url     = $self->google_url($param);
        my $message = $self->_create_reply_message($url);
        $self->reply( $mess, $message );
    }
}

sub google_url {
    my ( $self, $term ) = @_;
    my $uri = new URI($GOOGLE_BASE_URL);
    $uri->query_form(
        q  => $term,
        lr => 'lang_ja',
        ie => 'utf-8',
        oe => 'utf-8',
        aq => 't'
    );
    $uri->as_string;
}

sub _create_reply_message {
    my ( $self, $url ) = @_;
    my $message = "\cC14" . $url;
    $message;
}

sub help {
    return "\cC14Commands: 'google <term>'";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::GoogleSearch- create a link to Google search results

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::GoogleSearch;

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::GoogleSearch module which creates a link to Google search results.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
