#!/usr/bin/perl

# bin/update_tables.pl - Automated Table Migration Utility for AmberDB
# Migrates historical tables (2003-2026 formats) to the latest ABR v1 binary format.
# Automatically creates timestamped backups with detected version tag:
#   catalog_product.db -> catalog_product-v3-2018-0315.db

use 5.016;
use strict;
use warnings;

$| = 1; # Autoflush STDOUT immediately
use Getopt::Long qw(GetOptions);
use FindBin;
BEGIN { require "$FindBin::Bin/../lib/init.pl"; }
use AmberDB;
use AmberDB::Tools;

my $opt_all;
my $opt_tables;
my $opt_dbase = "dbstore";
my $opt_force;
my $opt_help;

GetOptions(
    'all|a'        => \$opt_all,
    'table|tables|t=s' => \$opt_tables,
    'dbase|d=s'    => \$opt_dbase,
    'force|f'      => \$opt_force,
    'help|h'       => \$opt_help,
) or usage(1);

if ($opt_help || (!$opt_all && !$opt_tables && !@ARGV)) {
    usage(0);
}

my $adb = AmberDB->new(
    path => {
        dbase_dir => $opt_dbase,
    }
);
my $tools = AmberDB::Tools->new($adb);

print "=================================================================\n";
print " AmberDB Table Migration Utility (ABR v1 Upgrade Engine)        \n";
print "=================================================================\n";
print "Database Directory : $opt_dbase\n";

my @target_tables;
if ($opt_tables) {
    @target_tables = split /,/, $opt_tables;
}
elsif (@ARGV) {
    @target_tables = @ARGV;
}
else {
    @target_tables = $tools->all_tables();
}

if (!@target_tables) {
    print "No tables found to migrate in '$opt_dbase'.\n";
    exit 0;
}

print "Discovered Tables  : " . scalar(@target_tables) . "\n";
print "-----------------------------------------------------------------\n";

my $total_processed = 0;
my $total_updated   = 0;
my $total_current   = 0;
my $total_records   = 0;

for my $table (@target_tables) {
    $table =~ s/^\s+|\s+$//g;
    next unless $table;

    print "Processing table: $table ...\n";
    my $res = $tools->update_table( $table, force => $opt_force );

    if (!$res || $res->{status} eq 'error') {
        my $err = $res->{error} // 'Unknown error';
        print "  [ERROR] FAILED! ($err)\n";
        next;
    }

    $total_processed++;

    if ($res->{status} eq 'already_current') {
        print "  [OK] ALREADY ABR v1 (" . ($res->{already_current} // 0) . " records)\n";
        if ($res->{del_migrated}) {
            print "  - Archive (.del)   : $res->{del_migrated} records migrated (Backup: $res->{del_backup})\n";
        }
        elsif (defined $res->{del_status}) {
            print "  - Archive (.del)   : $res->{del_status}\n";
        }
        if ($res->{aut_migrated}) {
            print "  - Audit Log (.aut) : $res->{aut_migrated} entries migrated (Backup: $res->{aut_backup})\n";
        }
        elsif (defined $res->{aut_status}) {
            print "  - Audit Log (.aut) : $res->{aut_status}\n";
        }
        $total_current++;
    }
    elsif ($res->{status} eq 'updated') {
        print "  [OK] MIGRATED!\n";
        print "  - Records Migrated : $res->{total} (Legacy: $res->{updated}, ABR: $res->{already_current})\n";
        print "  - Dominant Format  : $res->{dominant_format}\n";
        print "  - Backup Created   : $res->{backup_file}\n";
        if ($res->{del_migrated}) {
            print "  - Archive (.del)   : $res->{del_migrated} records migrated (Backup: $res->{del_backup})\n";
        }
        elsif (defined $res->{del_status}) {
            print "  - Archive (.del)   : $res->{del_status}\n";
        }
        if ($res->{aut_migrated}) {
            print "  - Audit Log (.aut) : $res->{aut_migrated} entries migrated (Backup: $res->{aut_backup})\n";
        }
        elsif (defined $res->{aut_status}) {
            print "  - Audit Log (.aut) : $res->{aut_status}\n";
        }
        if ($res->{has_unq}) {
            print "  - Unique (.unq)    : Preserved (Backup: $res->{unq_backup})\n";
        }
        if ($res->{has_cnt}) {
            print "  - Counter (.cnt)   : Preserved (Backup: $res->{cnt_backup})\n";
        }
        $total_updated++;
        $total_records += $res->{total};
    }
    else {
        print "$res->{status}\n";
    }
}

print "=================================================================\n";
print " Migration Summary                                              \n";
print "=================================================================\n";
print "Tables Processed   : $total_processed\n";
print "Tables Upgraded    : $total_updated\n";
print "Tables Already v1  : $total_current\n";
print "Records Upgraded   : $total_records\n";
print "=================================================================\n";

sub usage {
    my ($exit_code) = @_;
    print <<"USAGE";
Usage: perl bin/update_tables.pl [options] [table1 table2 ...]

Options:
  -a, --all               Migrate all discovered tables in database directory
  -t, --table, --tables   Comma-separated list of table IDs to migrate
  -d, --dbase <dir>       Path to dbase_dir (default: 'dbstore')
  -f, --force             Force re-encoding even if table is already ABR v1
  -h, --help              Show this help message

Examples:
  perl bin/update_tables.pl --all
  perl bin/update_tables.pl --all --dbase=/data/amberdb
  perl bin/update_tables.pl --table=catalog_product,users
  perl bin/update_tables.pl catalog_product users
USAGE
    exit($exit_code);
}
