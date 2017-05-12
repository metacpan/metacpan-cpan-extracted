package App::RunCron::Reporter::Stdout;
use strict;
use warnings;
use utf8;

use parent 'App::RunCron::Reporter';

sub run {
    my ($self, $runner) = @_;
    print STDOUT $runner->report;
}

1;
