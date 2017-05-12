#!/usr/bin/perl -w


## TODO add cool options and make this script nice
## * changeable diffing format

use strict;
use DBI;
use DB::Introspector;
use Text::Diff;
use Carp qw( confess );
use IO::File;

STDOUT->autoflush(1);

my ($datasource_0, $username_0, $password_0,
    $datasource_1, $username_1, $password_1) = @ARGV;

unless( defined $username_1 ) {
    print STDERR "USAGE: $0 <datasource_0> <username_0> <password_0> <datasource_1> <username_1> <password_1>\n";
    exit;

}

my $db_0 = DBI->connect($datasource_0, $username_0, $password_0);
my $db_1 = DBI->connect($datasource_1, $username_1, $password_1);

my $introspector_0 = DB::Introspector->get_instance($db_0);
my $introspector_1 = DB::Introspector->get_instance($db_1);

my @tables_0 = $introspector_0->find_all_tables();
my @tables_1 = $introspector_1->find_all_tables();

use Text::Diff::Table;
Text::Diff::Table->file_header(
    FILENAME_A  => $username_0.'@'.$datasource_0,
    FILENAME_B  => $username_1.'@'.$datasource_1,
    MTIME_A => time,
    MTIME_B => time 
);

# figure out how to make this data come out naturally in the table

print "##############TABLE EXISTENCE DIFF##############\n";
print "Column0:".$username_0.'@'.$datasource_0."\n";
print "Column1:".$username_1.'@'.$datasource_1."\n";
print diff( [ sort map {$_->name;} @tables_0 ], 
            [ sort map {$_->name;} @tables_1 ],
            { STYLE => 'Text::Diff::Table' } );


print "\nDiffing tables now\n";

foreach my $table_0 (@tables_0) {
    my $table_1 = $introspector_1->find_table($table_0->name) || next;

    print "Table: ".$table_0->name."\n";

    #next if( ($table_0->name cmp 'ew') < 0 );

    my @diffs;

    # diff the primary key
    my $primary_key_diff = diff([$table_0->primary_key_names], 
                                [$table_1->primary_key_names],
                                { STYLE => 'Text::Diff::Table' } );
    $primary_key_diff = ( $primary_key_diff ) ? "\n$primary_key_diff" : "NONE\n"; 
    push(@diffs, "primary key: $primary_key_diff");


    # diff the columns
    my $column_diff = diff(
                [ sort map { $_->name.':'.ref($_); } $table_0->columns ],
                [ sort map { $_->name.':'.ref($_); } $table_1->columns ],
                { STYLE => 'Text::Diff::Table' } );
    $column_diff = ( $column_diff ) ? "\n$column_diff" : "NONE\n"; 
    push(@diffs, "column: $column_diff");

    # diff the foreign keys

    # should we diff on the names of the foreign keys too?
    my $foreign_key_diff = diff(
                [ sort map { 
                        '('.join(",", $_->local_column_names).')->'
                        .$_->foreign_table->name
                            .'('.join(",", $_->foreign_column_names).')'; 
                       } $table_0->foreign_keys ],
                [ sort map { 
                        '('.join(",", $_->local_column_names).')->'
                        .$_->foreign_table->name
                            .'('.join(",", $_->foreign_column_names).')'; 
                       } $table_1->foreign_keys ],
                { STYLE => 'Text::Diff::Table' } );
    $foreign_key_diff = ( $foreign_key_diff ) ? "\n$foreign_key_diff" : "NONE\n"; 
    push(@diffs, "foreign_key: $foreign_key_diff");



    print join( "", @diffs )."\n\n";
}




