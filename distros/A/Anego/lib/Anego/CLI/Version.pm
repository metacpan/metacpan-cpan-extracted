package Anego::CLI::Version;
use strict;
use warnings;
use utf8;

use Anego;

sub run {
    print "Anego: $Anego::VERSION\n";
}

1;
