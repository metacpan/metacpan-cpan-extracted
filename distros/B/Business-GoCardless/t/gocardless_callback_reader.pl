#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use JSON qw/ encode_json /;
use FindBin qw/ $Bin /;

my $tmp_dir = "$Bin/end_to_end";

get '/merchants/:mid/confirm_resource' => sub {
    my ( $c ) = @_;

    my %output;

    foreach ( qw/
        resource_uri
        resource_id
        resource_type
        signature
        state
    / ) {
        $output{$_} = $c->param( $_ )
            if defined $c->param( $_ );
    }

    my $json = encode_json( \%output );

    my $file = "$tmp_dir/" . $output{resource_type} . ".json";
    open( my $fh,'>',$file ) || warn "Can't open $file for write: $!";
    print $fh $json;
    close( $fh );

    $c->render(
        text   => "Success<br />" . join( "<br />",values( %output ) ),
        status => 200,
    );
};

any '/webhook' => sub {
    my ( $c ) = @_;

    $c->render(
        status => 200,
        json   => {},
    );
};

app->start;

# vim: ts=4:sw=4:et
