#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use lib qw(./ ../lib);

# custom package from FILE_EXAMPLE.pl
use Data::Range::Compare::Stream::Iterator::File; 


use Data::Range::Compare::Stream;
use Data::Range::Compare::Stream::Iterator::Consolidate;
use Data::Range::Compare::Stream::Iterator::Compare::Asc;

my $source_a=Data::Range::Compare::Stream::Iterator::File->new(filename=>'source_a.src');
my $source_b=Data::Range::Compare::Stream::Iterator::File->new(filename=>'source_b.src');
my $source_c=Data::Range::Compare::Stream::Iterator::File->new(filename=>'source_c.src');

my $consolidator_a=new Data::Range::Compare::Stream::Iterator::Consolidate($source_a);
my $consolidator_b=new Data::Range::Compare::Stream::Iterator::Consolidate($source_b);
my $consolidator_c=new Data::Range::Compare::Stream::Iterator::Consolidate($source_c);


my $compare=new  Data::Range::Compare::Stream::Iterator::Compare::Asc();

my $src_id_a=$compare->add_consolidator($consolidator_a);
my $src_id_b=$compare->add_consolidator($consolidator_b);
my $src_id_c=$compare->add_consolidator($consolidator_c);



print "  +--------------------------------------------------------------------+
  | Common Range | Numeric Range A | Numeric Range B | Numeric Range C |
  +--------------------------------------------------------------------+\n";

my $format='  | %-12s |   %-13s |   %-13s |   %-13s |'."\n";
while($compare->has_next) {
  my $result=$compare->get_next;
  my $string=$result->to_string;
  my @data=($result->get_common);
  next if $result->is_empty;
  for(0 .. 2) {
    my $column=$result->get_column_by_id($_);
    unless(defined($column)) {
      $column="No Data";
    } else {
      $column=$column->get_common->to_string;
    }
    push @data,$column;


  }
  printf $format,@data;
  
}
print "  +--------------------------------------------------------------------+\n";
