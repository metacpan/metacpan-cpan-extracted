use strict;
use warnings;

use Test::More tests => 3;
use B::Utils qw( walkallops_filtered opgrep );

ok(defined &walkallops_filtered, "defined &walkallops_filtered");
ok(defined &opgrep, "defined &opgrep");

my $lived;
eval {
    walkallops_filtered(
        sub { opgrep( {name => "exec",
                    next => {
                                name    => "nextstate",
                                sibling => { name => [qw(! exit warn die)] }
                            }
                    }, @_)},
        sub {
            warn("Statement unlikely to be reached");
            warn("\t(Maybe you meant system() when you said exec()?)\n");
        }
    );
    $lived = 1;
};
ok($lived, "Successfully called walkallops_filtered");
