#!/usr/bin/perl -w

use strict;
use blib;

use Biblio::Isis;
use OpenIsis;
use MARC::File::USMARC;

use Benchmark qw( timethese cmpthese ) ;

my $isisdb = shift @ARGV || '/data/isis_data/ps/LIBRI/LIBRI';

my $isis = Biblio::Isis->new (
	isisdb => $isisdb,
	debug => shift @ARGV,
);

my $isis_filter = Biblio::Isis->new (
	isisdb => $isisdb,
	debug => shift @ARGV,
	hash_filter => sub {
		my $v = shift;
		return lc($v);
	}
);

my $rows = $isis->count;

my $db = OpenIsis::open( $isisdb );

print "rows: $rows\n\n";

my $mfn = 1;

my $r = timethese( -5, {
	Isis => sub {
		$isis->fetch( $mfn++ % $rows + 1 );
	},
	Isis_hash => sub {
		$isis->to_hash( $mfn++ % $rows + 1 );
	},
	Isis_hash_filter => sub {
		$isis_filter->to_hash( $mfn++ % $rows + 1 );
	},

	OpenIsis => sub {
		OpenIsis::read( $db, $mfn++ % $rows + 1 );
	},

	OpenIsis_hash => sub {
		my $row = OpenIsis::read( $db, $mfn++ % $rows + 1 );
		my $rec;
		no strict 'refs';
		foreach my $f (keys %{$row}) {
			foreach my $v (@{$row->{$f}}) {
				push @{$rec->{$f}}, OpenIsis::subfields($v);
			}
		}
		
	},
} );
cmpthese $r;

