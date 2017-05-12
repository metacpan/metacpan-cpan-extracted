use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

my $exit_chained;

sub CORE::GLOBAL::exit (;$) {
    $exit_chained = 1;
}

use CGI::Compile;

eval "exit";

is $exit_chained, 1, 'exit chained to CORE::GLOBAL::exit';
