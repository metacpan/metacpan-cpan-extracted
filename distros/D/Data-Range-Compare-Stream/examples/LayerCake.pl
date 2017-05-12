#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);
use Data::Range::Compare::Stream::Iterator::File;
use Data::Range::Compare::Stream;
use Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn;
use Data::Range::Compare::Stream::Iterator::Compare::LayerCake;

my $lk=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake(ignore_empty=>1);

foreach my $file (qw(source_a.src source_b.src source_c.src source_d.src)) {
    my $iterator=Data::Range::Compare::Stream::Iterator::File->new(filename=>$file);

    my $cmp=new  Data::Range::Compare::Stream::Iterator::Compare::LayerCake(ignore_empty=>1);

    my $con=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($iterator,$cmp);
    $cmp->add_consolidator($con);

    $lk->add_consolidator($cmp);
}

while($lk->has_next) {
  print $lk->get_next,"\n";
}
