#!/usr/bin/env perl

# vim: tabstop=4 expandtab

###### PACKAGES ######

use Modern::Perl;
use Data::Printer alias => 'pdump';
use Module::Load;
use File::Basename;
use CLI::Driver;

use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
Getopt::Long::Configure('pass_through');
Getopt::Long::Configure('no_auto_abbrev');

###### CONSTANTS ######

use constant CLI_DRIVER_FILE => 'cli-driver.yml';

###### GLOBALS ######

use vars qw(
  $Action
  $Driver
);

###### MAIN ######

$|=1;

$Driver = CLI::Driver->new(file => CLI_DRIVER_FILE);

parse_cmd_line();

my $action = $Driver->get_action( name => $Action );

if ($action) {
    $action->do;
}
else {
    $Driver->fatal("failed to find action in config file");
}

###### END MAIN ######

sub parse_cmd_line {

    my $help;
    GetOptions( "help|?" => \$help );

    if ( !@ARGV ) {
        print_usage();
    }
    elsif (@ARGV) {
        $Action = shift @ARGV;
    }

    if ($help) {
        if ($Action) {
            help_action();
        }
        else {
            print_usage();
        }
    }
}

sub help_action {

    my $action = $Driver->get_action( name => $Action );
    $action->usage;
}

sub print_actions {

    my $actions = $Driver->get_actions;
    my @list;

    foreach my $action (@$actions) {

        next if $action->name =~ /dummy/i;
        my $display = $action->name;

        if ( $action->is_deprecated ) {
            $display .= " (deprecated)";
        }

        push @list, $display;
    }

    say "\tACTIONS:";

    foreach my $action ( sort @list ) {
        print "\t\t$action\n";
    }
}

sub print_usage {
    print STDERR "@_\n\n" if @_;

    my $basename = basename($0);

    printf "\nusage: %s <action> [opts] [-?]\n\n", basename($0);
    print_actions();
    print "\n";

    exit 1;
}

