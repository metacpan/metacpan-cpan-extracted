#!perl -T

use strict;
use warnings;
use Carp;
use Test::More tests => 1;
use English qw(-no_match_vars);
use App::Validation::Automation;

#Check if App::Validation::Automation::Purging is able to compile
open my $log_handle,">>", "/var/tmp/log.log"
    or croak "Could not create /var/tmp/log.log : $OS_ERROR";

my $obj = App::Validation::Automation->new(
    config          => {},
    log_file_handle => $log_handle,
);

#Check what all App::Validation::Automation can Purge
can_ok($obj, 'purge');

close $log_handle;

