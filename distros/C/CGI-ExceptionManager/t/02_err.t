use strict;
use warnings;
use CGI::ExceptionManager;
use IO::Scalar;
use Test::More tests => 4;

tie *STDERR, 'IO::Scalar', \my $err;
tie *STDOUT, 'IO::Scalar', \my $out;
CGI::ExceptionManager->run(
    callback => sub {
        die "ERROR";
    },
    powered_by => 'menta',
);
like $out, qr/Status: 500/;
like $out, qr/ERROR/;
like $out, qr/Powered by menta/;
like $out, qr/callback =&gt; sub {/;

