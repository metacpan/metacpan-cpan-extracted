use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community::IO;

use_ok($_) for qw(
    Bio::Community::Meta::Gamma
);


my ($gamma, $meta);


# Metacommunity for which to measure gamma diversity

$meta = Bio::Community::IO->new(
   -file => test_input_file('generic_table.txt'),
)->next_metacommunity;


# Basic object

$gamma = Bio::Community::Meta::Gamma->new( -metacommunity => $meta, -type => 'observed' );
isa_ok $gamma, 'Bio::Community::Meta::Gamma';


# Get/set type of gamma diversity

is $gamma->type('observed'), 'observed';
delta_ok $gamma->get_gamma, 3.0;

is $gamma->type('menhinick'), 'menhinick';
delta_ok $gamma->get_gamma, 0.0722965031388601;


# Just test a few metrics check that we can use the same metrics as in Bio::Community::Alpha

delta_ok Bio::Community::Meta::Gamma->new( -metacommunity => $meta, -type => 'observed'  )->get_gamma, 3.0;
delta_ok Bio::Community::Meta::Gamma->new( -metacommunity => $meta, -type => 'menhinick' )->get_gamma, 0.0722965031388601;
delta_ok Bio::Community::Meta::Gamma->new( -metacommunity => $meta, -type => 'heip'      )->get_gamma, 0.686161833891381;
delta_ok Bio::Community::Meta::Gamma->new( -metacommunity => $meta, -type => 'shannon'   )->get_gamma, 0.863869925360591;


# Gamma-specific metrics
delta_ok Bio::Community::Meta::Gamma->new( -metacommunity => $meta, -type => 'chao2'     )->get_gamma, 3.25;
delta_ok Bio::Community::Meta::Gamma->new( -metacommunity => $meta, -type => 'jack1_i'   )->get_gamma, 4.0;
delta_ok Bio::Community::Meta::Gamma->new( -metacommunity => $meta, -type => 'jack2_i'   )->get_gamma, 4.0;
delta_ok Bio::Community::Meta::Gamma->new( -metacommunity => $meta, -type => 'ice'       )->get_gamma, 8.0;


done_testing();

exit;
