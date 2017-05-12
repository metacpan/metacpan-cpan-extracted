#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);
use Data::Range::Compare::Stream::Iterator::File;


my $break="  +-----------+\n";
my $format="  | %-9s |\n";
my %map=(qw(
source_a.src A
source_b.src B
source_c.src C
source_d.src D
));

foreach my $file (qw(source_a.src source_b.src source_c.src source_d.src)) {
    my $iterator=Data::Range::Compare::Stream::Iterator::File->new(filename=>$file);
    print $break;
    printf $format,"Set $map{$file}",$map{$file};
    print $break;
    while($iterator->has_next) {
      printf $format,$iterator->get_next;
      print $break
    }
    print "\n";
}
