use strict;
use warnings;
use CGI::ExceptionManager;
use IO::Scalar;
use Test::More tests => 1;

tie *STDERR, 'IO::Scalar', \my $err;
tie *STDOUT, 'IO::Scalar', \my $out;
CGI::ExceptionManager->run(
    callback => sub {
        die "ERROR";
    },
    renderer => sub {
        my $e = shift;
        "ERR: $e->{message}";
    },
);
like $out, qr/ERR: ERROR/;

