#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);
use Data::Range::Compare::Stream::Iterator::File;
use Data::Range::Compare::Stream;
use Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn;
use Data::Range::Compare::Stream::Iterator::Compare::Asc;


my $break="  +---------------------+----------------------------+\n";
my $format="  | %-19s | %-26s |\n";
my %map=(qw(
source_a.src A
source_b.src B
source_c.src C
source_d.src D
));

foreach my $file (qw(source_a.src source_b.src source_c.src source_d.src)) {
    my $iterator=Data::Range::Compare::Stream::Iterator::File->new(filename=>$file);
    die unless $iterator->has_next;
    my $cmp=new  Data::Range::Compare::Stream::Iterator::Compare::Asc();
    my $con=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($iterator,$cmp);
    $cmp->add_consolidator($con);

    printf "$break$format$break","Set $map{$file} Common Ranges",'Duplicates and Overlaps';
    while($cmp->has_next) {
      my $result=$cmp->get_next;
      my @row=($result->get_common);

      next if $result->is_empty;

      my $columns=$result->get_root_results;
      push @row, join ', ',map { $_->get_common } @{$columns->[0]};

      printf $format,@row;

    }
    print $break."\n";

}
