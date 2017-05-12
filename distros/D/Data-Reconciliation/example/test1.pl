#!/usr/local/bin/perl -w

use lib qw(../lib);

use Data::Table;

use Data::Reconciliation;
use Data::Reconciliation::Rule;

my $file1 = new Data::Table
    ([['1234',  0,  '123,45', 'FRF'],
      ['1234',  1, '-123,45', 'FRF'],
      ['1235',  0,  '122,45', 'FRF'],
      ['1236',  0,  '121,50', 'FRF'],
      ['1237',  0,  '121,50', 'FRF'],
      ['1237',  0,  '50,121', 'CHF']],
     ['dealnb', 'leg', 'amt',     'ccy']);
my $file2 = new Data::Table
    ([['1234-0',  123.45, 'FRF'],
      ['1234-1', -123.45, 'FRF'],
      ['1235-0',  122.47, 'FRF'],
      ['1236-0',  121.50, 'DEM'],
      ['1239-0',  50.121, 'CHF']],
     ['external-key', 'Amount',    'ccy']);

my $rule = new Data::Reconciliation::Rule($file1, $file2);

$rule->identification(['dealnb', 'leg'], sub{ join '-', @_ },
		      ['external-key'], undef);
$rule->add_comparison(['amt'], sub {(my $v = shift) =~ tr/,/./; $v},
		      ['Amount'], undef,
		      undef);
$rule->add_comparison(['ccy'], undef,
		      ['ccy'], undef,
		      undef);

my $r = new Data::Reconciliation($file1,
			         $file2,
				 -rules => [$rule]);

$r->build_signatures(0);

#my($dup_keys_from_1,
#   $dup_keys_from_2) = $r->duplicate_signatures;

my($dup_signs_from_1,
   $dup_signs_from_2) = $r->delete_dup_signatures;

#my($widow_1,
#   $widow_2) = $r->widow_signatures;

my($widow_signs_1,
   $widow_signs_2) = $r->delete_wid_signatures;

print "The following signatures in Table1 leads to multiple entries :\n\t[",
    join('][', sort keys %$dup_signs_from_1), "]\n"
    if keys %$dup_signs_from_1;

print "The following signatures in Table2 leads to multiple entries :\n\t[",
    join('][', sort keys %$dup_keys_from_2), "]\n"
    if keys %$dup_keys_from_2;

print "The following entries in Table1 have no correspondant in Table 2 :\n\t[",
    join('][', sort keys %$widow_signs_1), "]\n"
    if keys %$widow_signs_1;

print "The following entries in Table2 have no correspondant in Table 1 :\n\t[",
    join('][', sort keys %$widow_signs_2), "]\n"
    if keys %$widow_signs_2;

@diffs = $r->reconciliate(0);
print "The following entries were found to be different :\n\t",
    join("\n\t", map {$_->[0] . ': ' .  $_->[3]} @diffs), "\n"
    if @diffs;
