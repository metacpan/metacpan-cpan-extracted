use strict;
use warnings;
use 5.020;
use Archive::Libarchive;

my $text = "Hello World!\n";

my $e = Archive::Libarchive::Entry->new;
$e->set_pathname("hello.txt");
$e->set_filetype('reg');
$e->set_size(length $text);
$e->set_mtime(time);
$e->set_mode(oct('0644'));
