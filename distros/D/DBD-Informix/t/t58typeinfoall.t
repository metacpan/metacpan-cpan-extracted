#!/usr/bin/perl
#
#   @(#)$Id: t58typeinfoall.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test type_info_all
#
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

# NB: Cannot determine the number of tests a priori.

my $dbh = connect_to_test_database();
stmt_ok;

my $arr = $dbh->type_info_all;

stmt_fail("invalid return from type_info_all") unless defined $arr;
stmt_ok;

my @tia = @$arr;
my %map = %{$tia[0]};
shift @tia;     # Remove the mapping reference.

my %dbi_map =
    (
        TYPE_NAME          =>  0,
        DATA_TYPE          =>  1,
        COLUMN_SIZE        =>  2,
        LITERAL_PREFIX     =>  3,
        LITERAL_SUFFIX     =>  4,
        CREATE_PARAMS      =>  5,
        NULLABLE           =>  6,
        CASE_SENSITIVE     =>  7,
        SEARCHABLE         =>  8,
        UNSIGNED_ATTRIBUTE =>  9,
        FIXED_PREC_SCALE   => 10,
        AUTO_UNIQUE_VALUE  => 11,
        LOCAL_TYPE_NAME    => 12,
        MINIMUM_SCALE      => 13,
        MAXIMUM_SCALE      => 14,
        SQL_DATA_TYPE      => 15,
        SQL_DATETIME_SUB   => 16,
        NUM_PREC_RADIX     => 17,
        INTERVAL_PRECISION => 18,
    );

stmt_note "# map:\n";
my %inv;
foreach (sort keys %map)
{
    stmt_note("# $_ => $map{$_}\n");
    (!defined $dbi_map{$_} || $map{$_} == $dbi_map{$_}) ? stmt_ok : stmt_nok("$map{$_} != $dbi_map{$_}");
    $inv{$map{$_}} = $_;
}
stmt_note "# inv:\n";
my ($min, $max) = (9999999999, -1);
foreach (sort { $a <=> $b } keys %inv)
{
    stmt_note "# $_ => $inv{$_}\n";
    $min = $_ if $_ < $min;
    $max = $_ if $_ > $max;
}
($min == 0) ? stmt_ok : stmt_nok("Minimum index not zero in map ($min)");
($max > 13) ? stmt_ok : stmt_nok("Maximum index not big enough in map ($max)");

stmt_note "# type info:\n";
for (my $i = 0; $i <= $#tia; $i++)
{
    my @info = @{$tia[$i]};
    my $pad = "$i => ";
    my $str = "";
    for (my $j = 0; $j <= $#info; $j++)
    {
        my $val = $info[$j];
        if (!defined $val)
        {
            $val = "undef"
        }
        elsif ($val !~ m/^[-+]?\d+$/)
        {
            $val =~ s/"/\\"/g;
            $val = qq{"$val"};
        }
        $str .= "$pad$val";
        $pad = ", ";
    }
    stmt_note "# $str\n";
}

$dbh->disconnect or stmt_fail;

my $n = stmt_counter();
print "1..$n\n";

all_ok;
