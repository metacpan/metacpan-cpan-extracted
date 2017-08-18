use strict;
use warnings;
package App::bovespa;

use LWP::UserAgent;
use JSON;

my $agent_string = "Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0";

sub new {
    my ( $class ) = @_;

    bless {
    }, $class;
}

sub stock {
    my ( $self, $stock ) = @_;

    return $self->yahoo( $stock );

}

sub yahoo {
    my ( $self, $stock ) = @_;

    my $url = "https://query.yahooapis.com/v1/public/yql";

    #$stock = uc $stock . ".sa";
    $stock = uc $stock;
    my $yahoo_query = "select * from yahoo.finance.quotes where symbol in ( \"$stock\" )";

    my $ua = LWP::UserAgent->new();
    $ua->ssl_opts( verify_hostname => 0 );
    $ua->timeout( 10 );

    $DB::single = 1;

    my %url_params = (
        q           => $yahoo_query,
        format      => "json",
        env         => "store://datatables.org/alltableswithkeys", 
        callback    => undef,
    );


    my $query_params = "?";
    while ( my ( $key, $value ) = each( %url_params ) ) {
        $query_params .=  "$key=" . ( $value ? $value : '' ). "\&";
    }

    my $response = $ua->get( $url . $query_params );

    my $raw_html;
    if ( $response->is_success ){
        $raw_html = $response->decoded_content;
    }else{
        die;
    }

    my $data = decode_json $raw_html;
    return $data->{ query }{ results }{ quote }{ Bid };

}

=head1 NAME

App::bovespa - Simple tool to follow up your stocks at Bovespa Stock Exchange

=head1 VERSION

Version 0.003

=head1 SYNOPSIS

This module is a crawler to get the cotation of the Bovespa Stock Exchange. Now
it gets information one of the main portals.

This module is just for follow up, really, nothing realtime, nothing too serious.
I wrote it to keep my eyes on my own stocks. It is easier run a script that login
on my homebroker agent, with tokens and etc just to see the cotation.

To get a stock cotation is plain simple:

    use App::bovespa;

    my $exchange = App::bovespa->new();
    my $cotation = $exchange->stock( "PETR4.SA" );

Also inside this distribution, comes a small tool called bovespa_report, it has
a wrapper for cotation and a parser for a file with a list of cotations and prices to
compare.

    bovespa_report --help

Will display all options related with the tool

=head1 SUBROUTINES/METHODS

=head2 stock

Receives a stock name and returns it cotation. The name must the symbol name for the stock and the type digit.
Like "PETR4.SA" or "PETR3.SA"

=head1 AUTHOR

RECSKY, C<< recsky at cpan.org >>

=head1 BUGS

In case of one of providers change it page or something like that, the lib may broke. In this case
contact me at recsky@cpan.org

=head1 LICENSE AND COPYRIGHT

Copyright 2015

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
=cut

1;
