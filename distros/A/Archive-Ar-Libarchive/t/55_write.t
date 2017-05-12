use strict;
use warnings;

use Test::More tests => 2;
use strict;

use Archive::Ar::Libarchive;

my $ar;

$ar = Archive::Ar::Libarchive->new();
$ar->add_data("test.txt", "here\n");
my $content = $ar->write();
ok length($content) == 74, 'odd size archive padded';

$ar = new Archive::Ar::Libarchive();
$ar->add_data("test.txt", "here1\n");
$content = $ar->write();
ok length($content) == 74, 'even size archive not padded';
