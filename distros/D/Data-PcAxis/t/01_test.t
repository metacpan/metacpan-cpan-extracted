#!/usr/bin/env perl

#use 5.010;
use strict;
use warnings;
use autodie;
use feature 'say';
use Test::More;
use JSON;
use POSIX 'floor';
use match::smart;

BEGIN { use_ok 'Data::PcAxis'; }

my $testData;
{
    my $filepath = 't/testData.json';
    open my $testJSON_fh, '<', $filepath;
    local $/;
    $testData = decode_json(<$testJSON_fh>);
    close $testJSON_fh;
}

sub run_tests {
    my ($pxfile, $i) = @_;

    # Construction
    my $px = new_ok('Data::PcAxis' => [$pxfile]);

    # Keyword access (title)
    my $title = $testData->[$i]->{title};
    is($px->keyword('TITLE'), $title, 'Title: ' . $title);

    # Basic metadata access
    my $numkeys = $testData->[$i]->{numKeywords};
    is(ref($px->metadata), 'HASH', 'Hashref returned on metadata request');
    is(scalar keys %{$px->metadata}, $numkeys, "Number of metadata keys: $numkeys");
    is(scalar $px->keywords, $numkeys, "Keywords array length: $numkeys");

    # Variable access (All)
    my $numvars = $testData->[$i]->{numVars};
    is(scalar $px->variables, $numvars, "Number of variables: $numvars");
    is($px->variables, @{$testData->[$i]->{varNames}}, 'Variable names array');

    # Value counts
    my $valcounts = $testData->[$i]->{numVals};
    is_deeply($px->val_counts, $valcounts, 'Array of value counts for each variable correctly returned');

    # Accessing Values and Codes for particular variables
    for my $idx (0 .. $numvars-1) {

        # Variable access by index
        my $varname = $testData->[$i]->{varNames}[$idx];
        is($px->var_by_idx($idx), $varname, "Variable by index: $idx---$varname");

        # Variable access by regex
        my @chars = (substr($varname, 0, 1), substr($varname, -1, 1));
        my $re = qr/^$chars[0].*$chars[1]$/;
        like($px->var_by_idx($px->var_by_rx($re)), $re, "Variable by regex: $re---$varname");

        # Accessing value and code arrays by variable name and index
        ## Check for correct number of elements
        my $numvals = $testData->[$i]->{numVals}[$idx];
        is(scalar @{$px->vals_by_idx($idx)}, $numvals, "Number of values for variable at index $idx: $numvals");
        is(scalar @{$px->vals_by_name($varname)}, $numvals, "Number of values for variable $varname: $numvals");
        is(scalar @{$px->codes_by_idx($idx)}, $numvals, "Number of codes for variable at index $idx: $numvals");
        is(scalar @{$px->codes_by_name($varname)}, $numvals, "Number of codes for variable $varname: $numvals");

        ## Check array contents (Values by index)
        my @vals = @{$testData->[$i]->{firstMidLastVals}->[$idx]};
        is($px->vals_by_idx($idx)->[0], $vals[0], "First value for variable at index $idx: $vals[0]");
        is($px->vals_by_idx($idx)->[floor($numvals/2)], $vals[1], "Middle value for variable at index $idx: $vals[1]");
        is($px->vals_by_idx($idx)->[-1], $vals[2], "Last value for variable at index $idx: $vals[2]");

        ## Check array contents (Values by name)
        is($px->vals_by_name($varname)->[0], $vals[0], "First value for variable $varname: $vals[0]");
        is($px->vals_by_name($varname)->[floor($numvals/2)], $vals[1], "Middle value for variable $varname: $vals[1]");
        is($px->vals_by_name($varname)->[-1], $vals[2], "Last value for variable $varname: $vals[2]");

        ## Check array contents (Codes by index)
        my @codes = @{$testData->[$i]->{firstMidLastCodes}->[$idx]};
        is($px->codes_by_idx($idx)->[0], $codes[0], "First code for variable at index $idx: $codes[0]");
        is($px->codes_by_idx($idx)->[floor($numvals/2)], $codes[1], "Middle code for variable at index $idx: $codes[1]");
        is($px->codes_by_idx($idx)->[-1], $codes[2], "Last code for variable at index $idx: $codes[2]");

        ## Check array contents (Codes by name)
        is($px->codes_by_name($varname)->[0], $codes[0], "First code for variable $varname: $codes[0]");
        is($px->codes_by_name($varname)->[floor($numvals/2)], $codes[1], "Middle code for variable $varname: $codes[1]");
        is($px->codes_by_name($varname)->[-1], $codes[2], "Last code for variable $varname: $codes[2]");

        # Accessing value-by-code and code-by-value
        for (0..2) {
            is($px->val_by_code($varname, $codes[$_]), $vals[$_], "Value $vals[$_] returned for code $codes[$_]");
            is($px->code_by_val($varname, $vals[$_]), $codes[$_], "Code $codes[$_] returned for value $vals[$_]");
        }
    }

    # Accessing data
    ## Count number of data points
    my $num_data = $testData->[$i]->{numData};
    is(scalar @{$px->data}, $num_data, "Number of data points: $num_data");

    ## Accessing individual datums
    my @first = (0) x $numvars;
    my @mid = map { floor($_ / 2) } @$valcounts;
    my @last = map { $_ - 1 } @$valcounts;
    my $first_datum = $testData->[$i]->{firstDatum};
    my $mid_datum = $testData->[$i]->{midDatum};
    my $last_datum = $testData->[$i]->{lastDatum};

    cmp_ok($px->datum(\@first), 'eq', $first_datum, "First datum is $first_datum");
    cmp_ok($px->datum(\@mid), 'eq', $mid_datum, "Middle datum is $mid_datum");
    cmp_ok($px->datum(\@last), 'eq', $last_datum, "Last datum is $last_datum");

    ## Accessing columns of data

    for my $var_idx (0..$numvars-1) {
        my $varname = $testData->[$i]->{varNames}[$var_idx];
        my @zero_based = (0) x $numvars;
        my @max_based = map { $_ - 1 } @$valcounts;

        splice @zero_based, $var_idx, 1, '*';
        splice @max_based, $var_idx, 1, '*';
        my $zero_datacol = $px->datacol(\@zero_based);
        my $max_datacol = $px->datacol(\@max_based);

        my $numvals = $valcounts->[$var_idx];
        my $mid_idx = floor($numvals / 2);

        is(scalar @$zero_datacol, $numvals, "Number of values for zero-based datacol on variable $varname = $valcounts->[$var_idx]");
        is(scalar @$max_datacol, $numvals, "Number of values for max-based datacol on variable $varname = $valcounts->[$var_idx]");

        my $zero_first = $testData->[$i]->{firstMidLastZeroData}->[$var_idx]->[0];
        my $zero_middle = $testData->[$i]->{firstMidLastZeroData}->[$var_idx]->[1];
        my $zero_last = $testData->[$i]->{firstMidLastZeroData}->[$var_idx]->[2];
        cmp_ok($zero_datacol->[0], 'eq', $zero_first, "First value on zero-based datacol = $zero_first");
        cmp_ok($zero_datacol->[$mid_idx], 'eq', $zero_middle, "Middle value on zero-based datacol = $zero_middle");
        cmp_ok($zero_datacol->[-1], 'eq', $zero_last, "Last value on zero-based datacol = $zero_last");

        my $max_first = $testData->[$i]->{firstMidLastMaxData}->[$var_idx]->[0];
        my $max_middle = $testData->[$i]->{firstMidLastMaxData}->[$var_idx]->[1];
        my $max_last = $testData->[$i]->{firstMidLastMaxData}->[$var_idx]->[2];
        cmp_ok($max_datacol->[0], 'eq', $max_first, "First value on max-based datacol = $max_first");
        cmp_ok($max_datacol->[$mid_idx], 'eq', $max_middle, "Middle value on max-based datacol = $max_middle");
        cmp_ok($max_datacol->[-1], 'eq', $max_last, "Last value on max-based datacol = $max_last");
    }
}

for my $i (0..$#$testData) {
    my $pxfile = 't/testData/' . $testData->[$i]->{filename};
    run_tests($pxfile, $i);
}

done_testing();

