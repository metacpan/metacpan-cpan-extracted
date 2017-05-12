#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use lib qw(./ ../lib);

# custom package from FILE_EXAMPLE.pl
use Data::Range::Compare::Stream::Iterator::File; 


use Data::Range::Compare::Stream;
use Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn;
use Data::Range::Compare::Stream::Iterator::Compare::Asc;

my $source_a=Data::Range::Compare::Stream::Iterator::File->new(filename=>'source_a.src');
my $source_b=Data::Range::Compare::Stream::Iterator::File->new(filename=>'source_b.src');
my $source_c=Data::Range::Compare::Stream::Iterator::File->new(filename=>'source_c.src');
my $source_d=Data::Range::Compare::Stream::Iterator::File->new(filename=>'source_d.src');

my $compare=new  Data::Range::Compare::Stream::Iterator::Compare::Asc();

my $consolidator_a=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($source_a,$compare);
my $consolidator_b=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($source_b,$compare);
my $consolidator_c=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($source_c,$compare);
my $consolidator_d=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($source_d,$compare);



my $src_id_a=$compare->add_consolidator($consolidator_a);
my $src_id_b=$compare->add_consolidator($consolidator_b);
my $src_id_c=$compare->add_consolidator($consolidator_c);
my $src_id_d=$compare->add_consolidator($consolidator_d);



my %map=(
  0=>[0],
  1=>[1],
  2=>[2],
  3=>[3],
);

my %keys=qw(
  0 A
  1 B
  2 C
  3 D
);

my $total=keys(%map);

while($compare->has_next) {

  my $result=$compare->get_next;

  my $common=$result->get_common;

  for(my $id=0;$id<$compare->get_column_count_human_readable;++$id) {
    my $iterator=$compare->get_iterator_by_id($id);
    if(($id + 1)>$total) {
      my $column=$iterator;
      while($column->is_child) {
        $column=$column->get_root;
      }
      ++$total;
      push @{$map{$column->get_column_id}},$id;
    }
  }
  if($result->is_empty) {
    next;
  }

  print "Common Range: $common\n";
  for my $id (0 .. 3) {
    my $ref=$result->get_all_containers;

    my @columns;
    foreach my $result (@$ref[@{$map{$id}}]) {
      next unless  defined($result);
      push @columns,$result->get_common;
    }

    next unless @columns;
    print "Column $keys{$id}: [";
    print join("],[",@columns),"]\n";
  }

  print "\n" if $compare->has_next;
}
