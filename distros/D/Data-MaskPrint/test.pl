# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..119\n"; }
END {print "not ok 1\n" unless $loaded;}
use Data::MaskPrint
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $tst = Data::MaskPrint->new();

if ($tst->num_mask_print(0, '#####') eq '    0')
{
	print "ok 2\n";
}
else
{
	print "not ok 2\n";
}
if ($tst->num_mask_print(0, '&&&&&') eq '00000')
{
	print "ok 3\n";
}
else
{
	print "not ok 3\n";
}
if ($tst->num_mask_print(0, '$$$$$') eq '   $0')
{
	print "ok 4\n";
}
else
{
	print "not ok 4\n";
}
if ($tst->num_mask_print(0, '*****') eq '****0')
{
	print "ok 5\n";
}
else
{
	print "not ok 5\n";
}
if ($tst->num_mask_print(12345, '##,###') eq '12,345')
{
	print "ok 6\n";
}
else
{
	print "not ok 6\n";
}
if ($tst->num_mask_print(1234, '##,###') eq ' 1,234')
{
	print "ok 7\n";
}
else
{
	print "not ok 7\n";
}
if ($tst->num_mask_print(123, '##,###') eq '   123')
{
	print "ok 8\n";
}
else
{
	print "not ok 8\n";
}
if ($tst->num_mask_print(12, '##,###') eq '    12')
{
	print "ok 9\n";
}
else
{
	print "not ok 9\n";
}
if ($tst->num_mask_print(1, '##,###') eq '     1')
{
	print "ok 10\n";
}
else
{
	print "not ok 10\n";
}
if ($tst->num_mask_print(-1, '##,###') eq '    -1')
{
	print "ok 11\n";
}
else
{
	print "not ok 11\n";
}
if ($tst->num_mask_print(0, '##,###') eq '     0')
{
	print "ok 12\n";
}
else
{
	print "not ok 12\n";
}
if ($tst->num_mask_print(12345, '&&,&&&') eq '12,345')
{
	print "ok 13\n";
}
else
{
	print "not ok 13\n";
}
if ($tst->num_mask_print(1234, '&&,&&&') eq '01,234')
{
	print "ok 14\n";
}
else
{
	print "not ok 14\n";
}
if ($tst->num_mask_print(123, '&&,&&&') eq '000123')
{
	print "ok 15\n";
}
else
{
	print "not ok 15\n";
}
if ($tst->num_mask_print(12, '&&,&&&') eq '000012')
{
	print "ok 16\n";
}
else
{
	print "not ok 16\n";
}
if ($tst->num_mask_print(1, '&&,&&&') eq '000001')
{
	print "ok 17\n";
}
else
{
	print "not ok 17\n";
}
if ($tst->num_mask_print(0, '&&,&&&') eq '000000')
{
	print "ok 18\n";
}
else
{
	print "not ok 18\n";
}
if ($tst->num_mask_print(12345, '$$,$$$') eq '******')
{
	print "ok 19\n";
}
else
{
	print "not ok 19\n";
}
if ($tst->num_mask_print(1234, '$$,$$$') eq '$1,234')
{
	print "ok 20\n";
}
else
{
	print "not ok 20\n";
}
if ($tst->num_mask_print(123, '$$,$$$') eq '  $123')
{
	print "ok 21\n";
}
else
{
	print "not ok 21\n";
}
if ($tst->num_mask_print(12, '$$,$$$') eq '   $12')
{
	print "ok 22\n";
}
else
{
	print "not ok 22\n";
}
if ($tst->num_mask_print(1, '$$,$$$') eq '    $1')
{
	print "ok 23\n";
}
else
{
	print "not ok 23\n";
}
if ($tst->num_mask_print(0, '$$,$$$') eq '    $0')
{
	print "ok 24\n";
}
else
{
	print "not ok 24\n";
}
if ($tst->num_mask_print(12345, '**,***') eq '12,345')
{
	print "ok 25\n";
}
else
{
	print "not ok 25\n";
}
if ($tst->num_mask_print(1234, '**,***') eq '*1,234')
{
	print "ok 26\n";
}
else
{
	print "not ok 26\n";
}
if ($tst->num_mask_print(123, '**,***') eq '***123')
{
	print "ok 27\n";
}
else
{
	print "not ok 27\n";
}
if ($tst->num_mask_print(12, '**,***') eq '****12')
{
	print "ok 28\n";
}
else
{
	print "not ok 28\n";
}
if ($tst->num_mask_print(1, '**,***') eq '*****1')
{
	print "ok 29\n";
}
else
{
	print "not ok 29\n";
}
if ($tst->num_mask_print(0, '**,***') eq '*****0')
{
	print "ok 30\n";
}
else
{
	print "not ok 30\n";
}
if ($tst->num_mask_print(12345.67, '##,###.##') eq '12,345.67')
{
	print "ok 31\n";
}
else
{
	print "not ok 31\n";
}
if ($tst->num_mask_print(1234.56, '##,###.##') eq ' 1,234.56')
{
	print "ok 32\n";
}
else
{
	print "not ok 32\n";
}
if ($tst->num_mask_print(123.45, '##,###.##') eq '   123.45')
{
	print "ok 33\n";
}
else
{
	print "not ok 33\n";
}
if ($tst->num_mask_print(12.34, '##,###.##') eq '    12.34')
{
	print "ok 34\n";
}
else
{
	print "not ok 34\n";
}
if ($tst->num_mask_print(1.23, '##,###.##') eq '     1.23')
{
	print "ok 35\n";
}
else
{
	print "not ok 35\n";
}
if ($tst->num_mask_print(0.12, '##,###.##') eq '     0.12')
{
	print "ok 36\n";
}
else
{
	print "not ok 36\n";
}
if ($tst->num_mask_print(0.01, '##,###.##') eq '     0.01')
{
	print "ok 37\n";
}
else
{
	print "not ok 37\n";
}
if ($tst->num_mask_print(-0.01, '##,###.##') eq '    -0.01')
{
	print "ok 38\n";
}
else
{
	print "not ok 38\n";
}
if ($tst->num_mask_print(-1, '##,###.##') eq '    -1.00')
{
	print "ok 39\n";
}
else
{
	print "not ok 39\n";
}
if ($tst->num_mask_print(12345.67, '&&,&&&.&&') eq '12,345.67')
{
	print "ok 40\n";
}
else
{
	print "not ok 40\n";
}
if ($tst->num_mask_print(1234.56, '&&,&&&.&&') eq '01,234.56')
{
	print "ok 41\n";
}
else
{
	print "not ok 41\n";
}
if ($tst->num_mask_print(123.45, '&&,&&&.&&') eq '000123.45')
{
	print "ok 42\n";
}
else
{
	print "not ok 42\n";
}
if ($tst->num_mask_print(0.01, '&&,&&&.&&') eq '000000.01')
{
	print "ok 43\n";
}
else
{
	print "not ok 43\n";
}
if ($tst->num_mask_print(12345.67, '$$,$$$.$$') eq '*********')
{
	print "ok 44\n";
}
else
{
	print "not ok 44\n";
}
if ($tst->num_mask_print(1234.56, '$$,$$$.$$') eq '$1,234.56')
{
	print "ok 45\n";
}
else
{
	print "not ok 45\n";
}
if ($tst->num_mask_print(0, '$$,$$$.##') eq '    $0.00')
{
	print "ok 46\n";
}
else
{
	print "not ok 46\n";
}
if ($tst->num_mask_print(1234, '$$,$$$.##') eq '$1,234.00')
{
	print "ok 47\n";
}
else
{
	print "not ok 47\n";
}
if ($tst->num_mask_print(0, '$$,$$$.&&') eq '    $0.00')
{
	print "ok 48\n";
}
else
{
	print "not ok 48\n";
}
if ($tst->num_mask_print(1234, '$$,$$$.&&') eq '$1,234.00')
{
	print "ok 49\n";
}
else
{
	print "not ok 49\n";
}
if ($tst->num_mask_print(-12345.67, '-##,###.##') eq '-12,345.67')
{
	print "ok 50\n";
}
else
{
	print "not ok 50\n";
}
if ($tst->num_mask_print(-123.45, '-##,###.##') eq '-   123.45')
{
	print "ok 51\n";
}
else
{
	print "not ok 51\n";
}
if ($tst->num_mask_print(-12.34, '-##,###.##') eq '-    12.34')
{
	print "ok 52\n";
}
else
{
	print "not ok 52\n";
}
if ($tst->num_mask_print(-12.34, '--#,###.##') eq ' -   12.34')
{
	print "ok 53\n";
}
else
{
	print "not ok 53\n";
}
if ($tst->num_mask_print(-12.34, '---,###.##') eq '   - 12.34')
{
	print "ok 54\n";
}
else
{
	print "not ok 54\n";
}
if ($tst->num_mask_print(-12.34, '---,-##.##') eq '    -12.34')
{
	print "ok 55\n";
}
else
{
	print "not ok 55\n";
}
if ($tst->num_mask_print(-1, '---,--#.##') eq '     -1.00')
{
	print "ok 56\n";
}
else
{
	print "not ok 56\n";
}
if ($tst->num_mask_print(12345.67, '-##,###.##') eq ' 12,345.67')
{
	print "ok 57\n";
}
else
{
	print "not ok 57\n";
}
if ($tst->num_mask_print(1234.56, '-##,###.##') eq '  1,234.56')
{
	print "ok 58\n";
}
else
{
	print "not ok 58\n";
}
if ($tst->num_mask_print(123.45, '-##,###.##') eq '    123.45')
{
	print "ok 59\n";
}
else
{
	print "not ok 59\n";
}
if ($tst->num_mask_print(12.34, '-##,###.##') eq '     12.34')
{
	print "ok 60\n";
}
else
{
	print "not ok 60\n";
}
if ($tst->num_mask_print(12.34, '--#,###.##') eq '     12.34')
{
	print "ok 61\n";
}
else
{
	print "not ok 61\n";
}
if ($tst->num_mask_print(12.34, '---,###.##') eq '     12.34')
{
	print "ok 62\n";
}
else
{
	print "not ok 62\n";
}
if ($tst->num_mask_print(12.34, '---,-##.##') eq '     12.34')
{
	print "ok 63\n";
}
else
{
	print "not ok 63\n";
}
if ($tst->num_mask_print(1, '---,---.##') eq '      1.00')
{
	print "ok 64\n";
}
else
{
	print "not ok 64\n";
}
if ($tst->num_mask_print(-0.01, '---,---.--') eq '     -0.01')
{
	print "ok 65\n";
}
else
{
	print "not ok 65\n";
}
if ($tst->num_mask_print(-0.01, '---,---.&&') eq '     -0.01')
{
	print "ok 66\n";
}
else
{
	print "not ok 66\n";
}
if ($tst->num_mask_print(-12345.67, '-$$,$$$.&&') eq '**********')
{
	print "ok 67\n";
}
else
{
	print "not ok 67\n";
}
if ($tst->num_mask_print(-1234.56, '-$$,$$$.&&') eq '-$1,234.56')
{
	print "ok 68\n";
}
else
{
	print "not ok 68\n";
}
if ($tst->num_mask_print(-123.45, '-$$,$$$.&&') eq '  -$123.45')
{
	print "ok 69\n";
}
else
{
	print "not ok 69\n";
}
if ($tst->num_mask_print(-12345.67, '--$,$$$.&&') eq '**********')
{
	print "ok 70\n";
}
else
{
	print "not ok 70\n";
}
if ($tst->num_mask_print(-1234.56, '--$,$$$.&&') eq '-$1,234.56')
{
	print "ok 71\n";
}
else
{
	print "not ok 71\n";
}
if ($tst->num_mask_print(-123.45, '--$,$$$.&&') eq '  -$123.45')
{
	print "ok 72\n";
}
else
{
	print "not ok 72\n";
}
if ($tst->num_mask_print(-12.34, '--$,$$$.&&') eq '   -$12.34')
{
	print "ok 73\n";
}
else
{
	print "not ok 73\n";
}
if ($tst->num_mask_print(-1.23, '--$,$$$.&&') eq '    -$1.23')
{
	print "ok 74\n";
}
else
{
	print "not ok 74\n";
}
if ($tst->num_mask_print(-12345.67, '----,--$.&&') eq '-$12,345.67')
{
	print "ok 75\n";
}
else
{
	print "not ok 75\n";
}
if ($tst->num_mask_print(-1234.56, '----,--$.&&') eq ' -$1,234.56')
{
	print "ok 76\n";
}
else
{
	print "not ok 76\n";
}
if ($tst->num_mask_print(-123.45, '----,--$.&&') eq '   -$123.45')
{
	print "ok 77\n";
}
else
{
	print "not ok 77\n";
}
if ($tst->num_mask_print(-12.34, '----,--$.&&') eq '    -$12.34')
{
	print "ok 78\n";
}
else
{
	print "not ok 78\n";
}
if ($tst->num_mask_print(-1.23, '----,--$.&&') eq '     -$1.23')
{
	print "ok 79\n";
}
else
{
	print "not ok 79\n";
}
if ($tst->num_mask_print(-0.12, '----,--$.&&') eq '     -$0.12')
{
	print "ok 80\n";
}
else
{
	print "not ok 80\n";
}
if ($tst->num_mask_print(12345.67, '$***,***.&&') eq '$*12,345.67')
{
	print "ok 81\n";
}
else
{
	print "not ok 81\n";
}
if ($tst->num_mask_print(1234.56, '$***,***.&&') eq '$**1,234.56')
{
	print "ok 82\n";
}
else
{
	print "not ok 82\n";
}
if ($tst->num_mask_print(123.45, '$***,***.&&') eq '$****123.45')
{
	print "ok 83\n";
}
else
{
	print "not ok 83\n";
}
if ($tst->num_mask_print(12.34, '$***,***.&&') eq '$*****12.34')
{
	print "ok 84\n";
}
else
{
	print "not ok 84\n";
}
if ($tst->num_mask_print(1.23, '$***,***.&&') eq '$******1.23')
{
	print "ok 85\n";
}
else
{
	print "not ok 85\n";
}
if ($tst->num_mask_print(0.12, '$***,***.&&') eq '$******0.12')
{
	print "ok 86\n";
}
else
{
	print "not ok 86\n";
}
if ($tst->num_mask_print(-12345.67, '($$$,$$$.&&)') eq '($12,345.67)')
{
	print "ok 87\n";
}
else
{
	print "not ok 87\n";
}
if ($tst->num_mask_print(-1234.56, '($$$,$$$.&&)') eq '( $1,234.56)')
{
	print "ok 88\n";
}
else
{
	print "not ok 88\n";
}
if ($tst->num_mask_print(-123.45, '($$$,$$$.&&)') eq '(   $123.45)')
{
	print "ok 89\n";
}
else
{
	print "not ok 89\n";
}
if ($tst->num_mask_print(-12345.67, '(($$,$$$.&&)') eq '($12,345.67)')
{
	print "ok 90\n";
}
else
{
	print "not ok 90\n";
}
if ($tst->num_mask_print(-1234.56, '(($$,$$$.&&)') eq '($1,234.56)')
{
	print "ok 91\n";
}
else
{
	print "not ok 91\n";
}
if ($tst->num_mask_print(-123.45, '(($$,$$$.&&)') eq '(  $123.45)')
{
	print "ok 92\n";
}
else
{
	print "not ok 92\n";
}
if ($tst->num_mask_print(-12.34, '(($$,$$$.&&)') eq '(   $12.34)')
{
	print "ok 93\n";
}
else
{
	print "not ok 93\n";
}
if ($tst->num_mask_print(-1.23, '(($$,$$$.&&)') eq '(    $1.23)')
{
	print "ok 94\n";
}
else
{
	print "not ok 94\n";
}
if ($tst->num_mask_print(-12345.67, '((((,(($.&&)') eq '($12,345.67)')
{
	print "ok 95\n";
}
else
{
	print "not ok 95\n";
}
if ($tst->num_mask_print(-1234.56, '((((,(($.&&)') eq '($1,234.56)')
{
	print "ok 96\n";
}
else
{
	print "not ok 96\n";
}
if ($tst->num_mask_print(-123.45, '((((,(($.&&)') eq '( $123.45)')
{
	print "ok 97\n";
}
else
{
	print "not ok 97\n";
}
if ($tst->num_mask_print(-12.34, '((((,(($.&&)') eq '($12.34)')
{
	print "ok 98\n";
}
else
{
	print "not ok 98\n";
}
if ($tst->num_mask_print(-1.23, '((((,(($.&&)') eq '($1.23)')
{
	print "ok 99\n";
}
else
{
	print "not ok 99\n";
}
if ($tst->num_mask_print(-0.12, '((((,(($.&&)') eq '($0.12)')
{
	print "ok 100\n";
}
else
{
	print "not ok 100\n";
}
if ($tst->num_mask_print(12345.67, '($$$,$$$.&&)') eq '$12,345.67')
{
	print "ok 101\n";
}
else
{
	print "not ok 101\n";
}
if ($tst->num_mask_print(1234.56, '($$$,$$$.&&)') eq '$1,234.56')
{
	print "ok 102\n";
}
else
{
	print "not ok 102\n";
}
if ($tst->num_mask_print(123.45, '($$$,$$$.&&)') eq '$123.45')
{
	print "ok 103\n";
}
else
{
	print "not ok 103\n";
}
if ($tst->num_mask_print(12345.67, '(($$,$$$.&&)') eq '$12,345.67')
{
	print "ok 104\n";
}
else
{
	print "not ok 104\n";
}
if ($tst->num_mask_print(1234.56, '(($$,$$$.&&)') eq '$1,234.56')
{
	print "ok 105\n";
}
else
{
	print "not ok 105\n";
}
if ($tst->num_mask_print(123.45, '(($$,$$$.&&)') eq '$123.45')
{
	print "ok 106\n";
}
else
{
	print "not ok 106\n";
}
if ($tst->num_mask_print(12.34, '(($$,$$$.&&)') eq '$12.34')
{
	print "ok 107\n";
}
else
{
	print "not ok 107\n";
}
if ($tst->num_mask_print(1.23, '(($$,$$$.&&)') eq '$1.23')
{
	print "ok 108\n";
}
else
{
	print "not ok 108\n";
}
if ($tst->num_mask_print(12345.67, '((((,(($.&&)') eq '$12,345.67')
{
	print "ok 109\n";
}
else
{
	print "not ok 109\n";
}
if ($tst->num_mask_print(1234.56, '((((,(($.&&)') eq '$1,234.56')
{
	print "ok 110\n";
}
else
{
	print "not ok 110\n";
}
if ($tst->num_mask_print(123.45, '((((,(($.&&)') eq '$123.45')
{
	print "ok 111\n";
}
else
{
	print "not ok 111\n";
}
if ($tst->num_mask_print(12.34, '((((,(($.&&)') eq '$12.34')
{
	print "ok 112\n";
}
else
{
	print "not ok 112\n";
}
if ($tst->num_mask_print(1.23, '((((,(($.&&)') eq '$1.23')
{
	print "ok 113\n";
}
else
{
	print "not ok 113\n";
}
if ($tst->num_mask_print(0.12, '((((,(($.&&)') eq '$0.12')
{
	print "ok 114\n";
}
else
{
	print "not ok 114\n";
}
if ($tst->num_mask_print(0, '<<<<<') eq '0')
{
	print "ok 115\n";
}
else
{
	print "not ok 115\n";
}
if ($tst->num_mask_print(12345, '<<<,<<<') eq '12,345')
{
	print "ok 116\n";
}
else
{
	print "not ok 116\n";
}
if ($tst->num_mask_print(1234, '<<<,<<<') eq '1,234')
{
	print "ok 117\n";
}
else
{
	print "not ok 117\n";
}
if ($tst->num_mask_print(123, '<<<,<<<') eq '123')
{
	print "ok 118\n";
}
else
{
	print "not ok 118\n";
}
if ($tst->num_mask_print(12, '<<<,<<<') eq '12')
{
	print "ok 119\n";
}
else
{
	print "not ok 119\n";
}
