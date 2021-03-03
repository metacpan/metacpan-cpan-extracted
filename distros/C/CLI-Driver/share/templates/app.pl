#!/usr/bin/env perl

# vim: tabstop=4 expandtab

=head1 NAME

app.pl - a CLI::Driver basic example

=cut

###### PACKAGES ######

use Modern::Perl;
use English;
use CLI::Driver;

###### CONSTANTS ######

# TODO: change to your distribution name (using hyphens)
use constant DIST_NAME => 'YOUR-DIST-NAME';

# TODO: change to your cli-driver filename IF it differs
use constant CLI_DRIVER_FILE => 'cli-driver.yml';

###### GLOBALS ######

use vars qw(
  $CliDriver
);

###### MAIN ######

$OUTPUT_AUTOFLUSH = 1;

$CliDriver = CLI::Driver->new(
    path => get_cli_driver_path(),
    file => CLI_DRIVER_FILE
);

$CliDriver->run;

###### END MAIN ######

sub get_cli_driver_path {

    # TODO: add logic to find your dir with the driver file
    my $path;
    return $path;
}

