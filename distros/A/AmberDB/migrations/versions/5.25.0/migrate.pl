#!/usr/bin/perl
use strict;
use warnings;
use File::Spec;
use File::Path qw(make_path);
use File::Copy qw(move);

BEGIN {
    use File::Basename qw(dirname);
    use Cwd qw(abs_path);
    my $script_dir = dirname(abs_path(__FILE__));
    my $lib_dir = abs_path("$script_dir/../../../lib");
    unshift @INC, $lib_dir if -d $lib_dir;
}

use AmberDB;
use AmberDB::Tools;

sub migrate_5_25_0 {
    my %args = @_;
    my $target_dir = $args{target_dir} or die "Missing target_dir\n";
    my $force      = $args{force} // 0;
    my $tables_opt = $args{tables} // '';
    my $date_stamp = $args{date_stamp};
    if (!$date_stamp) {
        my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
        $date_stamp = sprintf("%04d-%02d-%02d", $year + 1900, $mon + 1, $mday);
    }

    print "  [v5.25.0] AmberDB v5.25.0 Migration Engine Initiated...\n";

    # 1. Rename/Merge 'tables' directory to 'table'
    my $tables_dir = File::Spec->catdir($target_dir, 'tables');
    my $table_dir  = File::Spec->catdir($target_dir, 'table');

    if (-d $tables_dir) {
        if (!-d $table_dir) {
            if (rename($tables_dir, $table_dir)) {
                print "  [v5.25.0] Renamed directory: '$tables_dir' -> '$table_dir'\n";
            }
            else {
                make_path($table_dir);
                opendir(my $dh, $tables_dir) or die "Cannot open $tables_dir: $!";
                my $moved = 0;
                while (my $f = readdir($dh)) {
                    next if $f eq '.' || $f eq '..';
                    move(File::Spec->catfile($tables_dir, $f), File::Spec->catfile($table_dir, $f));
                    $moved++;
                }
                closedir($dh);
                rmdir($tables_dir);
                print "  [v5.25.0] Moved $moved file(s) from '$tables_dir' -> '$table_dir'\n";
            }
        }
        else {
            opendir(my $dh, $tables_dir) or die "Cannot open $tables_dir: $!";
            my $moved = 0;
            while (my $f = readdir($dh)) {
                next if $f eq '.' || $f eq '..';
                my $src = File::Spec->catfile($tables_dir, $f);
                my $dst = File::Spec->catfile($table_dir, $f);
                if (!-e $dst) {
                    if (move($src, $dst)) {
                        $moved++;
                    }
                    else {
                        warn "  [!] Failed to move '$src' -> '$dst': $!\n";
                    }
                }
                else {
                    # Conflict: file already exists in table/. Append date stamp.
                    # e.g., catalog_product_2026-08-25.db, catalog_product_2026-08-25.inx
                    my ($base, $ext) = ( $f =~ /^(.*?)(\.[^.]+)$/ );
                    my $stamped_name = (defined $base && length $base)
                        ? "${base}_${date_stamp}${ext}"
                        : "${f}_${date_stamp}";

                    my $stamped_dst = File::Spec->catfile($table_dir, $stamped_name);
                    if (-e $stamped_dst) {
                        my $counter = 1;
                        while (-e $stamped_dst) {
                            my $suffixed = (defined $base && length $base)
                                ? "${base}_${date_stamp}_${counter}${ext}"
                                : "${f}_${date_stamp}_${counter}";
                            $stamped_dst = File::Spec->catfile($table_dir, $suffixed);
                            $counter++;
                        }
                    }

                    if (move($src, $stamped_dst)) {
                        $moved++;
                    }
                    else {
                        warn "  [!] Failed to move '$src' -> '$stamped_dst': $!\n";
                    }
                }
            }
            closedir($dh);
            rmdir($tables_dir);
            print "  [v5.25.0] Merged $moved file(s) from '$tables_dir' into existing '$table_dir'\n";
        }
    }
    else {
        make_path($table_dir) unless -d $table_dir;
        print "  [v5.25.0] Verified table directory '$table_dir'\n";
    }

    # 2. Convert legacy table records to native ABR v5 binary pack format
    # Always create fresh AmberDB instance after renaming directories
    my $adb = AmberDB->new( path => { dbase_dir => $target_dir } );
    my $tools = AmberDB::Tools->new($adb);

    my @tables;
    if ($tables_opt) {
        @tables = split /,/, $tables_opt;
    }
    else {
        @tables = $tools->all_tables();
    }

    my $migrated = 0;
    my $already_current = 0;

    if (@tables) {
        print "  [v5.25.0] Upgrading legacy table formats to native ABR v5...\n";
        for my $tbl (@tables) {
            $tbl =~ s/^\s+|\s+$//g;
            next unless $tbl;

            print "    - Migrating table '$tbl' ... ";
            my $res = $tools->update_table($tbl, force => $force);
            if (!$res || $res->{status} eq 'error') {
                my $err = $res->{error} // 'Unknown error';
                print "FAILED! ($err)\n";
            }
            elsif ($res->{status} eq 'already_current') {
                print "ALREADY CURRENT ABR v5 (" . ($res->{already_current} // 0) . " records)\n";
                $already_current++;
            }
            elsif ($res->{status} eq 'updated') {
                print "MIGRATED! ($res->{total} records, format: $res->{dominant_format})\n";
                $migrated++;
            }
            else {
                print "OK\n";
            }
        }

        # 3. Rebuild all secondary indexes
        print "  [v5.25.0] Rebuilding all derived secondary binary indexes (.inx, .fld, .unq, .fac, .slg, .srt)...\n";
        my $reindexed = 0;
        for my $tbl (@tables) {
            $tbl =~ s/^\s+|\s+$//g;
            next unless $tbl;
            eval {
                $tools->set_index($tbl);
                $reindexed++;
            };
            if ($@) {
                print "    [!] Re-indexing failed for '$tbl': $@\n";
            }
        }
        print "  [v5.25.0] Re-indexed $reindexed table(s) successfully.\n";
    }
    else {
        print "  [v5.25.0] No tables found to migrate in '$target_dir'.\n";
    }

    return {
        ok => 1,
        migrated => $migrated,
        already_current => $already_current,
    };
}

if (!caller) {
    use Getopt::Long;
    my $dbase_dir   = '';
    my $force       = 0;
    my $tables      = '';
    my $date_stamp  = '';
    GetOptions(
        'dbase_dir=s'   => \$dbase_dir,
        'force'         => \$force,
        'tables=s'      => \$tables,
        'date_stamp=s'  => \$date_stamp,
    );
    $dbase_dir ||= $ARGV[0] || '.';
    migrate_5_25_0(
        target_dir => $dbase_dir,
        force      => $force,
        tables     => $tables,
        ($date_stamp ? (date_stamp => $date_stamp) : ()),
    );
}

1;
