#!/usr/bin/env perl

# vim: tabstop=4 expandtab

=head1 NAME

clidriver.pl - utilities for CLI::Driver

=cut

###### PACKAGES ######

use Modern::Perl;
use English;
use CLI::Driver;

###### CONSTANTS ######

use constant DIST_NAME => 'CLI-Driver';

###### MAIN ######

$OUTPUT_AUTOFLUSH = 1;

my $cli_driver = CLI::Driver->new(
    use_file_sharedir       => 1,
    file_sharedir_dist_name => DIST_NAME
);

$cli_driver->run;

###### END MAIN ######
