#! /usr/bin/perl

use strict;
use warnings;

use Archive::Tar::Builder ();

open my $fh, '>', '/dev/null' or die "Unable to open /dev/null for writing: $!";

my $builder = Archive::Tar::Builder->new(
    'gnu_extensions'     => 1,
    'ignore_sockets'     => 1,
    'preserve_hardlinks' => 1
);

$builder->set_handle($fh);
$builder->archive(@ARGV);

close $fh;
