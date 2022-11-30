#!perl -w
use strict;
use Archive::SevenZip;
use File::Basename;
use Test::More tests => 3;

$ENV{PERL_ARCHIVE_SEVENZIP_BIN} = 'set-from-environment';

my $sz = Archive::SevenZip->new(
    "7zip" => 'set-from-constructor',
);
is $sz->{"7zip"}, 'set-from-constructor', "We can set the binary in the constructor";

Archive::SevenZip->find_7z_executable();
my $sz2 = Archive::SevenZip->new();
is $sz2->{"7zip"}, 'set-from-environment', "The default is to take it from the environment if set";

my $sz3 = Archive::SevenZip->new(
    "7zip" => 'set-from-constructor-2',
);
is $sz3->{"7zip"}, 'set-from-constructor-2',
    "We can set the binary in the constructor even after finding the 7z binary in the path (or environment)";

done_testing(3);
