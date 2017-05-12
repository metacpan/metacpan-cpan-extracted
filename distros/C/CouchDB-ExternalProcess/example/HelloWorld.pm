package HelloWorld;

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";
use base qw/CouchDB::ExternalProcess/;

use Data::Dumper;

sub _before {
    my ($self, $request) = @_;
    print STDERR "HelloWorld Request: ".Dumper($request);
    return $request;
}

sub hello_world :Action {
    my ($self, $req) = @_;
    my $target = ($req->{query}->{greeting_target} || "World");
    my $response = {
        body => "Hello, $target!"
    };
    return $response;
}

sub _after {
    my ($self,$response) = @_;
    print STDERR "HelloWorld Response: ".Dumper($response);
    return $response;
}

1;
