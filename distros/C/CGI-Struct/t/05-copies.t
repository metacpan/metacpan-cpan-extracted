#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 4;
use Test::Deep::NoTest;
use Storable qw(dclone);
use CGI::Struct;

# Test that all inputs are deep-copied, so the original struct never gets
# touched.

my %_inp = (
	'x'      => 'y',
	'ar'     => [ 'ab', 'cd' ],
	'hr'     => { 'qw' => 'er', 'ty' => { 'ui' => 'op' } },
	'tl.lt'  => [ 'zx', 'cv' ],
);
my %inp = %{dclone(\%_inp)};

my @errs;
my $hval;

# Handy func to do our frobbing
sub adjhval
{
	push @{$hval->{ar}}, 'ef';
	$hval->{hr}{as} = 'df';
	push @{$hval->{tl}{lt}}, 'bn';

	return;
}


# OK, start translating
$hval = build_cgi_struct \%inp, \@errs;

# Should have no problems
is(@errs, 0, "No errors");

# Overwrite some stuff in the returned struct
adjhval();

# Make sure we didn't change the original
is_deeply(\%inp, \%_inp, 'The same');


# Start over, but this time _don't_ deep-clone
$hval = build_cgi_struct \%inp, \@errs, {dclone => 0};

# Should have no problems
is(@errs, 0, "No errors");

# Try overwriting now
adjhval();

# Original _should_ have changed
ok(!eq_deeply(\%inp, \%_inp), 'Changed with dclone=0');
