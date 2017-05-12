use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 10 }

use FileHandle;
use Data::Table;

use Data::Reconciliation;
use Data::Reconciliation::Rule;

## Test 1
ok(1);

my $fh1 = new FileHandle(">test1.dat") || die;
my $fh2 = new FileHandle(">test2.dat") || die;

print $fh1 <<"EOF";
Key,F1,F2,F3
0,a,,
1,b,,
2,c,,
3,d,,
4,e,,
5,f,,
EOF
close $fh1;

print $fh2 <<"EOF";
key,Field2,Field1,Field3
1,,b,
2,,c,
3,,d,
4,,e,
4,,f,
5,,g,
EOF
close $fh2;

my $source_1 = Data::Table::fromCSV('test1.dat');
my $source_2 = Data::Table::fromCSV('test2.dat');

my $rule = new Data::Reconciliation::Rule($source_1, $source_2);
$rule->identification(['Key'], undef,
		      ['key'], undef);
$rule->add_comparison(['F1'], undef,
		      ['Field1'], undef,
		      undef);

my $r = new Data::Reconciliation($source_1,
				 $source_2,
				 -rules => [$rule]);

## Test 02
ok(eval {$r->isa('Data::Reconciliation')});

## Test 03
$r->build_signatures(0);
my($dup_keys_from_1,
   $dup_keys_from_2) = $r->duplicate_signatures;
ok(((keys %$dup_keys_from_1) == 0) &&
   ((keys %$dup_keys_from_2) == 1) &&
   ((sort keys %$dup_keys_from_2)[0] eq '4'));

## Test 04
($dup_keys_from_1,
 $dup_keys_from_2) = $r->delete_dup_signatures;
ok(((keys %$dup_keys_from_1) == 0) &&
   ((keys %$dup_keys_from_2) == 1));

## Test 05
($dup_keys_from_1,
 $dup_keys_from_2) = $r->duplicate_signatures;
ok(((keys %$dup_keys_from_1) == 0) &&
   ((keys %$dup_keys_from_2) == 0));

## Test 06
my($miss_keys_from_1,
   $miss_keys_from_2) = $r->widow_signatures;

ok(((keys %$miss_keys_from_1) == 2) &&
   ((sort keys %$miss_keys_from_1)[0] eq '0') &&
   ((sort keys %$miss_keys_from_1)[1] eq '4') &&
   ((keys %$miss_keys_from_2) == 0));

## Test 07
($miss_keys_from_1,
 $miss_keys_from_2) = $r->delete_wid_signatures;

ok(((keys %$miss_keys_from_1) == 2) &&
   ((keys %$miss_keys_from_2) == 0));

## Test 08
($miss_keys_from_1,
 $miss_keys_from_2) = $r->widow_signatures;

ok(((keys %$miss_keys_from_1) == 0) &&
   ((keys %$miss_keys_from_2) == 0));

## Test 09
my @diffs = $r->reconciliate(0);
ok(@diffs == 1);

## Test 10
my @signs = $r->signatures();
ok( (keys %{$signs[0]} == 4) && 
    (keys %{$signs[1]} == 4));

