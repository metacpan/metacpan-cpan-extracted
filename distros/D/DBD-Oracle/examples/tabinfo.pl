#!/usr/bin/env perl
#
# tabinfo
#
#  Usage:   tabinfo base user password table
#
# Displays the structure of the specified table.
# Note that the field names are restricted to the length of the field.
# This is mainly to show the use of &ora_lengths, &ora_titles and &ora_types.
#
use DBI;

use strict;

# Set trace level if '-# trace_level' option is given
DBI->trace( shift ) if 1 < @ARGV && $ARGV[0] =~ /^-#/ && shift;

# read the compulsory arguments
die "syntax: $0 base user password table ...\n" if 4 > @ARGV;
my ( $base, $user, $pass, @table ) = @ARGV;

my ( $table, @name, @length, @type, %type_name, $i );
format STDOUT_TOP =
Structure of @<<<<<<<<<<<<<<<<<<<<<<<
$table

Field name                                    | Length | Type | Type Name
----------------------------------------------+--------+------+-----------------
.

format STDOUT =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | @>>>>> | @>>> | @<<<<<<<<<<<<<<<
$name[$i], $length[$i], $type[$i], $type_name{$type[$i]}
.

# Connect to database
my $dbh = DBI->connect( "dbi:Oracle:$base", $user, $pass,
   { AutoCommit => 0, RaiseError => 1, PrintError => 0 } )
   or die $DBI::errstr;

# Associate type names to types
{
    my $type_info_all = $dbh->type_info_all;
    my $iname = $type_info_all->[0]{TYPE_NAME};
    my $itype = $type_info_all->[0]{DATA_TYPE};
    my $rtype;
    shift @$type_info_all;
    foreach $rtype ( @$type_info_all ) {
        $type_name{$$rtype[$itype]} = $$rtype[$iname]
            if ! exists $type_name{$$rtype[$itype]};
    }
}

my $sth;
foreach $table ( @table ) {
    $sth = $dbh->prepare( "SELECT * FROM $table WHERE 1 = 2");
    @name   = @{$sth->{NAME}};
    @length = @{$sth->{PRECISION}};
    @type   = @{$sth->{TYPE}};

    foreach $i ( 0 .. $#name ) {
        write;
    }
    $- = 0;
    $sth->finish;
}

$dbh->disconnect;
