package App::plackbench::test_app;

use strict;
use warnings;

# Sometimes this file gets loaded multiple times. Silence the "subroutine
# redefined" warning when it is.
no warnings 'redefine';

use HTTP::Response;

sub ok {
    return HTTP::Response->new(200, 'OK', [], 'ok');
}

sub slow {
    my $req = shift;
    sleep 1;
    return HTTP::Response->new(200, 'OK', [], 'slow');
}

sub fail {
    my $req = shift;
    return HTTP::Response->new(500, 'Internal Server Error', [], 'Danger!');
}

my @requests;
sub _get_requests {
    my $app = shift;
    return \@requests;
}

sub _clear_requests {
    my $app = shift;
    @requests = ();
}

my $app = sub {
    my $request = shift;

    my $method = $request->{PATH_INFO};
    $method =~ s#^/|/$##g;
    $method =~ s#/#_#g;

    my $response = HTTP::Response->new(404, 'Not Found', [], 'Not Found');
    if (my $sub = __PACKAGE__->can($method)) {
        $response = $sub->($request);
    }

    push @requests, $request;

    my @headers = map { $_ => $response->header($_) } $response->header_field_names();

    my $return = [$response->code(), \@headers, [ $response->decoded_content() ]];
    return $return;
};

bless($app, __PACKAGE__);

# Make sure this is the last statement in the file:
$app;

# vi: set ft=perl :
