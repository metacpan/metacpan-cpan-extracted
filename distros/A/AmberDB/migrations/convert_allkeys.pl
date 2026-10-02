#!/usr/bin/perl

# bin/convert_allkeys.pl - Table index key converter script for AmberDB database store
# Converts 'allkeys' index key to 'keys' in all table index files (.inx) in dbstore.


use 5.016;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Cwd qw(cwd);
use DB_File;
use Fcntl qw(O_RDWR);

print "=================================================================\n";
print " AmberDB Table Index Key Converter ('allkeys' -> 'keys')   \n";
print "=================================================================\n\n";

my $root_dir    = cwd();
my $dbstore_dir = -d "$root_dir/dbstore" ? "$root_dir/dbstore" : "$root_dir";
my $tables_dir  = -d "$dbstore_dir/table" ? "$dbstore_dir/table" : ( -d "$dbstore_dir/tables" ? "$dbstore_dir/tables" : $dbstore_dir );

unless ( -d $tables_dir ) {
    die "Error: Database tables directory '$tables_dir' does not exist.\n";
}

print "Database Directory  : $tables_dir\n\n";

opendir(my $dh, $tables_dir) or die "Cannot open directory '$tables_dir': $!\n";
my @files = sort readdir($dh);
closedir($dh);

my %tables;
my %side_files = ( del => 0, aut => 0, cnt => 0 );

foreach my $file ( sort @files ) {
    next if $file =~ /^\./; # skip . and .. and hidden files
    $file =~ s|\Q$tables_dir\E/?||i;
    next if $file =~ /^\_/; # skip temporary/hidden files
    next if $file =~ /\s/;  # skip backup filenames with spaces

    if ( $file =~ /^([a-z0-9_]+)\.(db|inx)$/i ) {
        $tables{$1} = 1;
    }
    elsif ( $file =~ /\.del$/i ) {
        $side_files{del}++;
    }
    elsif ( $file =~ /\.aut$/i ) {
        $side_files{aut}++;
    }
    elsif ( $file =~ /\.cnt$/i ) {
        $side_files{cnt}++;
    }
}

my @table_list = sort keys %tables;
print "Found " . scalar(@table_list) . " table index candidates to convert.\n";
print "Detected side files: " . $side_files{del} . " .del (archived deleted), "
    . $side_files{aut} . " .aut (audit logs), "
    . $side_files{cnt} . " .cnt (view counters).\n";
print "-----------------------------------------------------------------\n";

my $converted_count = 0;
my $already_count   = 0;
my $skipped_count   = 0;
my $error_count     = 0;

foreach my $tableid (@table_list) {
    print "Processing table [$tableid]... ";
    my $inx_file = "$tables_dir/$tableid.inx";

    unless ( -e $inx_file ) {
        print "SKIPPED (.inx file not found)\n";
        $skipped_count++;
        next;
    }

    eval {
        my %db;
        my $db_obj = tie( %db, 'DB_File', $inx_file, O_RDWR );
        if ($db_obj) {
            if ( exists $db{'allkeys'} ) {
                $db{'keys'} = $db{'allkeys'};
                delete $db{'allkeys'};
                undef $db_obj;
                untie %db;
                print "OK (renamed 'allkeys' => 'keys')\n";
                $converted_count++;
            }
            elsif ( exists $db{'keys'} ) {
                undef $db_obj;
                untie %db;
                print "SKIPPED (already using 'keys')\n";
                $already_count++;
            }
            else {
                undef $db_obj;
                untie %db;
                print "SKIPPED (no 'allkeys' key found)\n";
                $skipped_count++;
            }
        }
        else {
            print "ERROR (cannot open .inx file: $!)\n";
            $error_count++;
        }
    };
    if ($@) {
        print "ERROR: $@\n";
        $error_count++;
    }
}

print "-----------------------------------------------------------------\n";
print "Conversion Summary:\n";
print "  - Tables converted ('allkeys' -> 'keys') : $converted_count\n";
print "  - Tables already using 'keys'           : $already_count\n";
print "  - Skipped (no .inx or no 'allkeys')     : $skipped_count\n";
print "  - Errors                                : $error_count\n";
print "=================================================================\n";
print "Key conversion completed successfully!\n";
