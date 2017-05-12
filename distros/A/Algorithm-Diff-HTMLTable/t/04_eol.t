#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use File::Basename;
use File::Spec;
use Algorithm::Diff::HTMLTable;

my @files = map{ File::Spec->catfile( dirname( __FILE__ ), 'files', "04_$_.txt" ) }qw/a b/;

my $diff = Algorithm::Diff::HTMLTable->new( id => 'test_id', eol => "---\n" );
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

        <table id="test_id" style="border: 1px solid;">
            <thead>
                <tr>
                    <th colspan="2"><span id="diff_old_info">__files0__<br />.{24}</span></th>
                    <th colspan="2"><span id="diff_new_info">__files1__<br />.{24}</span></th>
                </tr>
            </thead>
            <tbody>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">1</td>
            <td style="color: red;">---
</td>
            <td style="background-color: gray">1</td>
            <td style="color: green;">----
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">2</td>
            <td style="color: red;"></td>
            <td style="background-color: gray">2</td>
            <td style="color: green;">asdfkjasldf
---
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">3</td>
            <td >test
asdfl
---
</td>
            <td style="background-color: gray">3</td>
            <td >test
asdfl
---
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">4</td>
            <td style="color: red;">kdjfkajs
jaksdfj
---
</td>
            <td style="background-color: gray">4</td>
            <td style="color: green;">kdjfkajs
jaksdfjud
---
</td>
        </tr>
    
        <tr style="border: 1px solid">
            <td style="background-color: gray">5</td>
            <td style="color: red;">
</td>
            <td style="background-color: gray">5</td>
            <td style="color: green;">dadd
asd
ad
ad
---
</td>
        </tr>
    
            </tbody>
        </table>
    
