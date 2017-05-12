#!perl

use Test::More tests => 2 * 6;
use CGI::Compile;

for my $var (qw/self VERSION data path dir self/) {
    my $sub = eval {
        my $script = 'use strict; $'.$var;
        CGI::Compile->compile(\$script);
    };

    my $exc = 'Global symbol "\$'.$var.'" requires explicit package name';
    like $@, qr/$exc/, 'exception '.$var;
    is $sub, undef, 'compilation failed '.$var;
}
