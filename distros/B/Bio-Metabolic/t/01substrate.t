use strict;
use warnings;

#use Test::More skip_all => 'testing only networks';
use Test::More tests => 20;

use_ok('Bio::Metabolic');

my $s1 = Bio::Metabolic::Substrate->new('s1');
ok( ref($s1) eq 'Bio::Metabolic::Substrate', 'Substrate creation' );
ok( $s1->name() eq 's1', 'name()' );

my $s2 = $s1->new( 's2', { 'c' => 6 } );
ok( ref($s2) eq 'Bio::Metabolic::Substrate' && $s2->name eq 's2',
    'Substrate creation and name()' );

my $attr = $s2->attributes();
ok( ref($attr) eq 'HASH' && $attr->{c} == 6, 'Substrate attributes' );
ok( $s2->get_attribute('c') == 6, 'attributes()' );
ok( !defined $s2->get_attribute('d'), 'attributes()' );

#my $var = $s1->var();
#ok( ref($var) eq 'Math::Symbolic::Variable', 'var()' );
#ok( $var->name() eq $s1->name(), 'name of variable' );
#ok( !defined $var->value(), 'value of variable initially undefined' );
#$s1->fix(2.1);
#ok( $var->value == 2.1, 'fix substrate concentration' );
#$s1->release;
#isnt( defined $var->value(), 'release substrate concentration' );

my $s3 = Bio::Metabolic::Substrate->new('s1');
my $s4 = Bio::Metabolic::Substrate->new('s4');
my $s5 = Bio::Metabolic::Substrate->new( 's5', { c => 5 } );
my $s6 = Bio::Metabolic::Substrate->new( 's5', { c => 6 } );
ok( $s1 == $s3, 'equality of substrates without attributes' );
ok( $s1 != $s4, 'inequality of substrates without attributes' );
ok( $s2 == $s6, 'equality of substrates with attributes' );
ok( $s2 != $s5, 'inequality of substrates with attributes' );
ok( $s5 != $s6, 'inequality of substrates with attributes but same name' );

ok( $s1->is_empty, 'is_empty() for empty substrate' );
ok( !$s2->is_empty, 'is_empty() for non-empty substrate' );

is( $s1 cmp $s3, 0,  'compare names' );
is( $s1 cmp $s2, -1, 'compare names' );
is( $s5 cmp $s3, 1,  'compare names' );
ok( $s4 eq 's4', 'compare object with name' );

my $c = $s5->copy;
ok( ref($c) eq 'Bio::Metabolic::Substrate', 'copy()' );
ok( $c == $s5, 'copy same as original' );
