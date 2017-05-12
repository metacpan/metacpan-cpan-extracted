#!/usr/bin/perl -w

use strict;
use blib;

use Test::More tests => 2;
use File::Spec;

BEGIN { use_ok( 'Biblio::Isis' ); }

my $path = File::Spec->catfile('data', 'winisis', 'BIBL');

my $object = Biblio::Isis->new (
	isisdb => $path,
);

isa_ok ($object, 'Biblio::Isis');


