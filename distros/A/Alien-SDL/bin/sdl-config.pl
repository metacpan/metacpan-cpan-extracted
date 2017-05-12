#! perl
use strict;
use warnings;
use Alien::SDL;
use Getopt::Long;

my $libs; my $cflags; my $prefix;

my $result = GetOptions ( "libs" => \$libs,
                          "cflags" => \$cflags,
                          "prefix" => \$prefix );


print Alien::SDL->config('libs') if $libs;
print Alien::SDL->config('cflags') if $cflags;
print Alien::SDL->config('prefix') if $prefix;


