#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use Cwd;
use Bio::Tools::GFF;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::AutomatedAnnotation::External::Cmscan');
}

my $cwd = getcwd();
my $obj;

 ok($obj = Bio::AutomatedAnnotation::External::Cmscan->new(
   cmdb       => 'database/cm/Bacteria',
   input_file => 'dummy.fa',
   exec       => $cwd.'/t/bin/dummy_cmscan',
 ),'initialise object');

my @sequence_names = sort keys %{$obj->features};
is_deeply(\@sequence_names, [ 'Z123_00215','Z123_00341', 'Z123_00358','Z123_02089',], 'Sequences all identified');
is(@{$obj->features->{'Z123_00215'}},3 , 'One of the sequences has 3 features');

# We should be able to write out the features to GFF format
my @features = sort @{$obj->features->{'Z123_00341'}};
my $gff_factory = Bio::Tools::GFF->new( -gff_version => 3 );
is($features[0]->gff_string($gff_factory), 'Z123_00341	Infernal:1.1	ncRNA	123	159	.	-	0	inference=COORDINATES:profile:Infernal:1.1;product=NrrF', 'Feature turned into GFF string');

# Add the features into the existing structure
my %existing_struture;
ok($obj->add_features_to_prokka_structure(\%existing_struture) , 'Add features to existing structure');
@sequence_names = sort keys %existing_struture;
is_deeply(\@sequence_names, [ 'Z123_00215','Z123_00341', 'Z123_00358','Z123_02089',], 'Sequence names should be identified');
is(@{$existing_struture{'Z123_00215'}->{FEATURE}}, 3, 'Should have 3 features for 215');
ok($obj->add_features_to_prokka_structure(\%existing_struture) , 'Add features a second time should duplicatie them');
is(@{$existing_struture{'Z123_00215'}->{FEATURE}}, 6, 'Should have 6 features for 215');

done_testing();
