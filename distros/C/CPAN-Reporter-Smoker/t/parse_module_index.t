use strict;
use warnings;

use Test::More;

use CPAN::Reporter::Smoker;

plan tests => 9;

my $list = CPAN::Reporter::Smoker::_parse_module_index('t/parse_module_index/02packages.details.txt', 't/parse_module_index/find-ls', 0);
is(scalar(@$list), 10);
ok((grep {$_ eq 'PETDANCE/Test-Harness-2.62_02.tar.gz'} @$list), 'Test-Harness-2.62_02 present');
ok(!(grep {$_ eq 'PETDANCE/Test-Harness-2.62_01.tar.gz'} @$list), 'Test-Harness-2.62_01 not present');

ok(!(grep {$_ eq 'DAGOLDEN/Bundle-Fake-1.00.tar.gz'} @$list), 'bundle module not present');

ok((grep {$_ eq 'TEST/Test-Test-1.01.tar.gz'} @$list), 'Test-Test-1.01 present');
ok(!(grep {$_ eq 'TEST/Test-Test-1.00_01.tar.gz'} @$list), 'Test-Test-1.00_01 not present');

my $list1 = CPAN::Reporter::Smoker::_parse_module_index('t/parse_module_index/02packages.details.txt', 't/parse_module_index/find-ls', 1);
is(scalar(@$list1), 7, 'correct amount without trial versions');

my $list2 = CPAN::Reporter::Smoker::_parse_module_index('t/parse_module_index/t_02packages.details.txt', 't/parse_module_index/t_find-ls', 0, '20080101');
is(scalar(@$list2), 4, 'correct amount with date');
@$list2 = sort @$list2;
is_deeply($list2, [
    'TEST/Test-Test-1.01_02.tar.gz',
    'TEST/Test-Test2-1.02.tar.gz',
    'TEST/Test-Test2-1.03_01.tar.gz',
    'TEST/Test-Test3-1.03_02.tar.gz'
], 'correct distributions');
