use strict;
use warnings;
use Test::More 'no_plan';
use File::Basename qw< dirname >;

use App::RecordStream::Test::Tester;
use App::RecordStream::Test::OperationHelper;

use App::RecordStream::Operation::fromgff3;

my $tester = App::RecordStream::Test::Tester->new('fromgff3');
my ($input, $output) = map {
    open my $fh, '<', dirname(__FILE__) . "/data/fromgff3-$_"
        or die "error opening t/data/fromgff3-$_: $!";
    local $/;
    scalar <$fh>;
} qw[input output];

diag "basic input";
$tester->test_input([], $input, $output);
