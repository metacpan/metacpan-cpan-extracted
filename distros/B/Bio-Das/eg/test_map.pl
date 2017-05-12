#!/usr/bin/perl

use strict;
use lib '../blib/lib';
use Bio::Das::Map;

my $m = Bio::Das::Map->new('my_map');

print $m->name,"\n";
$m->add_segment(['chr1',100,1000],['c1.1',1,901]);
$m->add_segment(['chr1',1001,2000],['c1.2',501,10501]);
$m->add_segment(['chr1',2001,4000],['c1.1',3000,4999]);
$m->add_segment(['c1.1',4000,4999],['c1.1.1',1,1000]);
$m->add_segment(Bio::Location::Simple->new(-seq_id=>'chr1',-start=>4001,-end=>5000),
		Bio::Location::Simple->new(-seq_id=>'c1.3',-start=>10,-end=>1009));
$m->add_segment(['chr5',1 => 100],['c1.3',1501 => 1600,-1]);
$m->add_segment(['chr1',8000 => 9000],['c1.3',1000 => 2000,-1]);

my @s = $m->lookup_segments('chr1',200,1500);
print_location(@s);

print_location($m->lookup_segments(Bio::Location::Simple->new(-seq_id=>'c1.2',-start=>500,-end=>502)));
print_location($m->lookup_segments(Bio::Location::Simple->new(-seq_id=>'c1.2',-start=>499,-end=>500)));
print_location($m->lookup_segments(Bio::Location::Simple->new(-seq_id=>'c1.2',-start=>499,-end=>501)));
print_location($m->lookup_segments(Bio::Location::Simple->new(-seq_id=>'c1.2',-start=>10501,-end=>10510)));
print_location($m->lookup_segments(Bio::Location::Simple->new(-seq_id=>'c1.2',-start=>10502,-end=>10510)));
print_location($m->lookup_segments('c1.3',20=>40));

print_location($m->resolve('c1.1',3000,3010));
print_location($m->resolve('c1.1',4000,4999));
print_location($m->resolve('c1.1',5000,8999));
print_location($m->resolve('c1.1.1',10,20));

# minus strand alignments
print_location($m->lookup_segments(['c1.3',1500=>1599]));
print_location($m->resolve('c1.3',1500=>1599));

# project tests
print_location($m->project(['c1.3',1500=>1599],'chr5'));
print_location($m->project(['c1.1.1',10,20],'chr1'));
print_location($m->project(['c1.1.1',10,20],'c1.1'));
print_location($m->project(['c1.1.1',10,20],'chr5'));
print_location($m->project(['chr5',10,20],'c1.3'));

# segment tests
print_location($m->super_segments('c1.1',4500=>4600));
print_location($m->sub_segments('c1.1',4500=>4600));
print_location($m->expand_segments('c1.1',4500=>4600));

1;

sub print_location {
  print $_->seq_id,':',$_->start,'..',$_->end," (",$_->strand,")\n" foreach @_;
}
