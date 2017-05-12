#!/usr/bin/perl

use strict;
use lib './blib/lib';
use Bio::Das;

my $das = Bio::Das->new(15);
my @request = $das->types(-dsn     => 'http://www.wormbase.org/db/das/elegans',
			  -segment => ['I:1,10000',
				       'I:10000,20000'
				      ],
			  -enumerate => 1,
			 );
for my $r (@request) {
  next unless $r->is_success;
  my $results = $r->results;
  for my $seg (keys %$results) {
    my @types = @{$results->{$seg}};
    for my $type (@types) {
      print join "\t",$seg,$type,$type->count,"\n";
    }
  }
}
