#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

# Very ugly hack to get test suite working if the used perl binary is
# not the one which is found first in $PATH. See
# https://github.com/xtaran/CGI-Github-Webhook/issues/1
use File::Basename;
if (defined $ENV{PERL} and $ENV{PERL} ne $^X) {
    my $dir = dirname($0);
    $ENV{PERL5LIB} = "$ENV{PERL5LIB}:$dir/../../lib:$dir/../../blib";
    exec $ENV{PERL}, $0;
}

require CGI::Github::Webhook;

my $ghwh = CGI::Github::Webhook->new(
    trigger => 'echo foo',
    trigger_backgrounded => 0,
    secret => 'bar',
    log => '/dev/stdout',
    );
my $rc = $ghwh->run();

if ($rc) {
    exit 0
} else {
    exit 1
}
