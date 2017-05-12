#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use File::Basename;
use File::Spec;
use Algorithm::Diff::HTMLTable;

my @files = map{ File::Spec->catfile( dirname( __FILE__ ), 'files', "01_$_.txt" ) }qw/a b/;

my $diff = Algorithm::Diff::HTMLTable->new;
my $html = $diff->diff( @files );

my $check = do{ local $/; <DATA> };
chomp $check;

$check =~ s{__files0__}{$files[0]};
$check =~ s{__files1__}{$files[1]};

$check =~ s{\\}{\\\\}g;

like_string( $html, qr/$check/ );

#diag $html;

done_testing();

__DATA__

        <table  style="border: 1px solid;">
            <thead>
                <tr>
                    <th colspan="2"><span id="diff_old_info">__files0__<br />.{24}</span></th>
                    <th colspan="2"><span id="diff_new_info">__files1__<br />.{24}</span></th>
                </tr>
            </thead>
            <tbody>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">1</td>
            <td style="color: red;">a
</td>
            <td style="background-color: gray"></td>
            <td ></td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">2</td>
            <td >b
</td>
            <td style="background-color: gray">1</td>
            <td >b
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">3</td>
            <td >c
</td>
            <td style="background-color: gray">2</td>
            <td >c
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray"></td>
            <td ></td>
            <td style="background-color: gray">3</td>
            <td style="color: green;">d
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">4</td>
            <td >e
</td>
            <td style="background-color: gray">4</td>
            <td >e
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">5</td>
            <td style="color: red;">h
</td>
            <td style="background-color: gray">5</td>
            <td style="color: green;">f
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">6</td>
            <td >j
</td>
            <td style="background-color: gray">6</td>
            <td >j
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray"></td>
            <td ></td>
            <td style="background-color: gray">7</td>
            <td style="color: green;">k
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">7</td>
            <td >l
</td>
            <td style="background-color: gray">8</td>
            <td >l
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">8</td>
            <td >m
</td>
            <td style="background-color: gray">9</td>
            <td >m
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">9</td>
            <td style="color: red;">n
</td>
            <td style="background-color: gray">10</td>
            <td style="color: green;">r
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">10</td>
            <td style="color: red;">p
</td>
            <td style="background-color: gray">11</td>
            <td style="color: green;">s
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">11</td>
            <td style="color: red;"></td>
            <td style="background-color: gray">12</td>
            <td style="color: green;">t
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">12</td>
            <td >
</td>
            <td style="background-color: gray">13</td>
            <td >
</td>
        </tr>
    
            </tbody>
        </table>
    
