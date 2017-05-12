#!/usr/bin/env perl 

use strict;
use warnings;

use DBI;

my $db = DBI->connect( 'dbi:Oracle:mydb', 'username', 'password' );

my $table = 'TABLE';
my %clauses;
my %attrib;
my @types;
my $longrawtype;
my @row;

# Assuming the existence of @row and an associative array (%clauses) containing the 
# column names and placeholders, and an array @types containing column types ...

my $ih = $db->prepare("INSERT INTO $table ($clauses{names})
                VALUES ($clauses{places})")
                or  die "prepare insert into $table: " . $db->errstr;		  

$attrib{'ora_type'} = $longrawtype;  # $longrawtype == 24

##-- bind the parameter for each of the columns
for my $i ( 0..$#types ) { 

    ##-- long raw values must have their type attribute explicitly specified
    if ($types[$i] == $longrawtype) {
        $ih->bind_param($i+1, $row[$i], \%attrib)
            || die "binding placeholder for LONG RAW " . $db->errstr;
    }
    ##-- other values work OK with the default attributes
    else {
        $ih->bind_param($i+1, $row[$i])
            || die "binding placeholder" . $db->errstr;
    }
}

$ih->execute || die "execute INSERT into $table: " . $db->errstr;


