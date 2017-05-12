# -*- perl -*-

# t/02_list.t -- check view/list

use Test::More tests => 5;

use lib qw(t/);

use testutils;

# initialize db
testutils::initialize();

my $dbh = testutils::test_dbh;

my @output1 = testutils::run_command('list');
my $output1 = join ("\n",@output1);

shift(@output1)
    if $output1[0] !~ /^Index/;

like($output1[0],qr/^Index\s*\|Imported/,'Includes heading');
like($output1[1],qr/^-+\+-+/,'Includes rule');
like($output1[2],qr/1\s+|20\d\d\//,'Includes date');
is(scalar(@output1),7,'Includes correct number of lines');

my @output2 = testutils::run_command('info',index => 1);

like(join("\n",@output2),qr/00000001/,'Tan is included');