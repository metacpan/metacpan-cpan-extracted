use strict;
use warnings;
use CGI::ExceptionManager;
use IO::Scalar;
use Test::More tests => 4;

tie *STDERR, 'IO::Scalar', \my $err;
tie *STDOUT, 'IO::Scalar', \my $out;
CGI::ExceptionManager->run(
    callback => sub {
        local $@;
        eval {
            $_[999]->(); # raise an error
        };
        die $@
            if $@;
    },
    powered_by => 'menta',
);
like $out, qr/Status: 500/;
like $out, qr/ERROR/;
like $out, qr/Powered by menta/;
like $out, qr/Can&#39;t use /;
