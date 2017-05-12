#!perl

use 5.008001;
use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN
{
    use_ok('AnyData2') || BAIL_OUT "Couldn't load AnyData2";
}

diag("Testing AnyData2 $AnyData2::VERSION, Perl $], $^X");

my @modules = (
    qw(AnyData2::Storage::File AnyData2::Storage::File::Linewise AnyData2::Storage::File::Blockwise AnyData2::Storage::FileSystem),
    qw(AnyData2::Format::CSV),
);

foreach my $module (@modules)
{
    use_ok($module);
}

done_testing;
