#!/usr/bin/env perl

# vim: tabstop=4 expandtab

=head1 NAME

app-sharedir.pl - a CLI::Driver example using File::ShareDir

Quickstart:  
  - cd to your project dir (typically where the Makefile.PL lives)
  - create bin/ dir
  - copy this to bin/<yournewcliname.pl> 
  - create 'share/' dir
  - create 'share/cli-driver.yml' file (you can use the cli-driver.yml example
    included with this distro)
  - find the TODO(s) in this file and update those section(s) appropriately
  
  - Dist::Zilla users:
    - add [ExecDir] to your dist.ini (assuming you want to bundle your new cli)
    - add [ShareDir] to your dist.ini
    
  - ExtUtils::MakeMaker users:
    - add EXE_FILES => ['bin/yournewcliname.pl'] to your Makefile.PL
    - refer to File::ShareDir docs for remaining config

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

###### MAIN ######

$OUTPUT_AUTOFLUSH = 1;

my $cli_driver = CLI::Driver->new(
    use_file_sharedir       => 1,
    file_sharedir_dist_name => DIST_NAME
);

$cli_driver->run;

###### END MAIN ######



