package Bio::Tools::ProteinogenicAA::AAInfo;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'amino_acid' => (
	is	=>	'rw',
	isa	=>	'Str',
	);

has 'short_name' => (
	is	=>	'rw',
	isa	=>	'Str',
	);

has 'abbreviation' => (
	is	=>	'rw',
	isa	=>	'Str',
	);

has 'pI' => (
	is	=>	'rw',
	isa	=>	'Num',
	);

has 'pK1' => (
	is	=>	'rw',
	isa	=>	'Num',
	);

has	'pK2' => (
	is	=>	'rw',
	isa	=>	'Num',
	);

has 'side_chain' => (
	is	=>	'rw',
	isa	=>	'Str',
	);

has	'is_hydrophobic' => (
	is	=>	'rw',
	isa	=>	'Bool',
	);

has	'is_polar' => (
	is	=>	'rw',
	isa	=>	'Bool',
	);

has	'pH' => (
	is	=>	'rw',
	isa	=>	'Str',
	);

has	'van_der_waals_volume' => (
	is	=>	'rw',
	isa	=>	'Int',
	);

has	'codons' => (
	is	=>	'rw',
	isa	=>	'Str',
	);

has	'formula' => (
	is	=>	'rw',
	isa	=>	'Str',
	);

has	'monoisotopic_mass' => (
	is	=>	'rw',
	isa	=>	'Num',
	);

has 'avg_mass' => (
	is	=>	'rw',
	isa	=>	'Num',
	);

1;
