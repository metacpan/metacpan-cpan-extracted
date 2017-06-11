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

get '/rflow/confirm/:type/:amount/:currency/:interval_unit/:interval/:start_at'
    => {
        interval_unit => undef,
        interval      => undef,
        start_at      => undef,
    }
    => sub {
    my ( $c ) = @_;

    my %output;

    foreach ( qw/
        redirect_flow_id
        type
        amount
        currency
        interval_unit
        interval
        start_at
    / ) {
        $output{$_} = $c->param( $_ )
            if defined $c->param( $_ );
    }

    my $json = encode_json( \%output );

    my $file = "$tmp_dir/redirect_flow.json";
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
