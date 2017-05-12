package Bot::BasicBot::Pluggable::Module::DomainHacks;
use strict;
use warnings;
use HTTP::Request::Common;
use LWP::UserAgent;
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

    if ( $command eq "domainhacks" ) {
        my $domainnames = $self->get_domain_names($param);
        my $message     = $self->_create_reply_message($domainnames);
        $self->reply( $mess, $message );
    }
}

sub get_domain_names {
    my ( $self, $text ) = @_;
    utf8::encode($text) if utf8::is_utf8($text);
    my $ua       = LWP::UserAgent->new;
    my $response = $ua->request( POST 'http://xona.com/domainhacks/search',
        [ q => $text ] );

    # FIXME fix later
    my $scraper = scraper {
        process '.domainnameresults', 'domains[]' => 'TEXT';
    };
    my $res = $scraper->scrape( $response->content );
    $res->{domains};
}

sub _create_reply_message {
    my ( $self, $domain_names ) = @_;
    my $message = join ', ', @{$domain_names};
    $message = "\cC14" . $message;
    $message;
}

sub help {
    return "\cC14Commands: 'domainhacks <domain name>'";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::DomainHacks- create a link to

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::DomainHacks;

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::DomainHacks module which creates a link to .

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
