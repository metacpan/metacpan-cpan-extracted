#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;

my $vcardtidy = path( 't', 'vcardtidy' );
my $dirty     = path( 't', 'dirty.vcf' );
my $tmp       = Path::Tiny->tempfile;
my $want      = path( 't', 'clean.vcf' );

$dirty->copy($tmp);

diag "$vcardtidy $tmp";
system( $vcardtidy, $tmp ) == 0 or die "$vcardtidy $tmp failed: " . ( $? >> 8 );

my $dirty_vcf = $dirty->slurp_utf8;
my $clean_vcf = $tmp->slurp_utf8;
my $want_vcf  = $want->slurp_utf8;

isnt $dirty_vcf, $clean_vcf, 'not equal to original';
isnt $clean_vcf, $want_vcf,  'not tidy yet';
$clean_vcf =~ s/^REV:.*Z\015\012//m;
is $clean_vcf, $want_vcf, 'but tidy without REV change';

done_testing();
