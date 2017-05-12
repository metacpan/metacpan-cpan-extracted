#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use lib qw(./ ../lib);

# custom package from FILE_EXAMPLE.pl
use MyIterator; 


use Data::Range::Compare::Stream;
use Data::Range::Compare::Stream::Iterator::Consolidate;
use Data::Range::Compare::Stream::Iterator::Compare::Asc;

my $source_a=MyIterator->new(filename=>'source_a.src');
my $source_b=MyIterator->new(filename=>'source_b.src');
my $source_c=MyIterator->new(filename=>'source_c.src');

my $consolidator_a=new Data::Range::Compare::Stream::Iterator::Consolidate($source_a);
my $consolidator_b=new Data::Range::Compare::Stream::Iterator::Consolidate($source_b);
my $consolidator_c=new Data::Range::Compare::Stream::Iterator::Consolidate($source_c);


my $compare=new  Data::Range::Compare::Stream::Iterator::Compare::Asc();

my $src_id_a=$compare->add_consolidator($consolidator_a);
my $src_id_b=$compare->add_consolidator($consolidator_b);
my $src_id_c=$compare->add_consolidator($consolidator_c);


print qq{<html><head></head><body>
<table border="1">
<thead>
<th colspan="3">Legend</th>
</thead>
<tbody>
<td bgcolor="white">Range Shared by data found</td>
<td bgcolor="lightgreen">Column Data Matched common Range with this value</td>
<td bgcolor="pink">Column Data Did not match</td>
</tbody>
</table>
<br />
<table border="1"><thead><th>Common Range</th><th>source_a.src</th></th><th>source_b.src</th></th><th>source_c.src</th></thead><tbody>\n};

while($compare->has_next) {
  my $result=$compare->get_next;
  my $string=$result->to_string;
  print "<tr>\n";
  print qq{<td align="center">},$result->get_common,"</td>";
  for(0 .. 2) {
    my $column=$result->get_column_by_id($_);
    my $color="lightgreen";
    unless(defined($column)) {
      $color="pink";
      $column="No Data";
    } else {
      $column=$column->get_common;
    }
    print qq{<td align="center" bgcolor="$color">$column</td>\n};

  }
  print "</tr>\n";
}
print "</tbody></table></body></html>";
