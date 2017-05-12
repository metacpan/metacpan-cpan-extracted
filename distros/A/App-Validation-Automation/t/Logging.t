#!perl -T

use strict;
use warnings;
use Carp;
use Test::More tests => 1;
use App::Validation::Automation;
use English qw(-no_match_vars);

#Check if App::Validation::Automation is able to compile
open my $log_handle,">>", "/var/tmp/log.log"
    or croak "Could not create /var/tmp/log.log : $OS_ERROR";

#Check if App::Validation::Automation is able to compile
my $obj = App::Validation::Automation->new(
    config          => {},
    log_file_handle => $log_handle,
);

#Check what all App::Validation::Automation::Logging can log
can_ok($obj, 'log');

close $log_handle;
