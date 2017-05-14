#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use File::Slurp;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
}

opendir( my $dh, './bin' ) || die "can't bin directory: $!";
my @available_scripts = grep { /^[^\.]/ } readdir($dh);
closedir $dh;

for my $script_name (  @available_scripts ) {
    my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
    my $destination_directory = $destination_directory_obj->dirname();

    system("./bin/$script_name -c $destination_directory >/dev/null 2>&1");
    ok( -e $destination_directory . '/command_line.log', "log file has been created for $script_name" );
    open(my $fh, $destination_directory . '/command_line.log');
    ok((<$fh> =~ /^[\d]+ .+ \.\/bin\/$script_name -c $destination_directory$/), 'correct format of log file' );

}

done_testing();

