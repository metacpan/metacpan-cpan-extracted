#! /usr/local/bin/perl -w

use Attribute::Handlers::Prospective;

sub Call : ATTR {
	use Data::Dumper 'Dumper';
	print Dumper [ @_ ];
}


sub x : Call('some','data') { };
