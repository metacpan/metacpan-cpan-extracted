#!/usr/bin/env perl

use strict;
use warnings;

use FindBin::libs;
use Data::AMF::Packet;

use HTTPEx::Declare;
use List::Util ();
use Path::Class;

interface ServerSimple => {
    host => '0.0.0.0',
    port => 3000,
};

run {
    my $c = shift;

    if ($c->req->path eq 'gateway') {
        my $fh   = $c->req->body;
        my $body = do { local $/; <$fh> };

        my $request = Data::AMF::Packet->deserialize($body);

        my @result;
        for my $message (@{ $request->messages }) {
            my $method = __PACKAGE__->can($message->target_uri);

            if ($method) {
                my $result = $method->( $message->value );

                push @result, $message->result($result);
            }
        }

        my $response = Data::AMF::Packet->new(
            version  => $request->version,
            headers  => [],
            messages => \@result,
        );

        $c->res->content_type('application/x-amf');
        $c->res->body($response->serialize)
    }
    else {
        $c->res->content_type('application/x-shockwave-flash');
        $c->res->body( scalar file('./examples/simple_flash_remoting.swf')->slurp );
    }
};

sub echo {
    return $_[0];
}

sub sum {
    return List::Util::sum(@{ $_[0] });
}

sub dump {
    use YAML;
    warn Dump $_[0];
}
