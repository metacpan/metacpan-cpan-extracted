#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use File::Basename;
use File::Spec;
use Algorithm::Diff::HTMLTable;

my @files = map{ File::Spec->catfile( dirname( __FILE__ ), 'files', "07_$_.txt" ) }qw/a b/;

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
            <td >&lt;div&gt;html&nbsp;entities&lt;/div&gt;
</td>
            <td style="background-color: gray">1</td>
            <td >&lt;div&gt;html&nbsp;entities&lt;/div&gt;
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">2</td>
            <td style="color: red;">
</td>
            <td style="background-color: gray">2</td>
            <td style="color: green;">&lt;h2&gt;Test&lt;/h2&gt;
</td>
        </tr>
    
            </tbody>
        </table>
    
