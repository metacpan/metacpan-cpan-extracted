#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ state /;

use FindBin qw/ $Bin /;
use Template;
use Plack::Request;
use Plack::Response;

my $app = sub {
    my $req = Plack::Request->new( shift );
    my $res = Plack::Response->new( 200 );

    state $tt  = Template->new({
        INCLUDE_PATH => "$Bin/templates",
    });

    my $out;

    $tt->process(
        "example_form.html.tt",
        {
            result => $req->parameters->{'user_input'},
        },
        \$out,
    ) or die $tt->error;

    $res->body( $out );
    $res->finalize;
};
