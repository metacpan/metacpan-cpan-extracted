use Test::More qw( no_plan );
use Test::Deep;

use Data::Dumper;
use strict;
use English;

use Cluster::Similarity;

my $class1 = [ { a => 1, b => 1, c => 1 }, { d => 1, e => 1, f => 1 } ];
my $class2 = [ { a => 1, b => 1 }, { c => 1, d => 1, e => 1 }, { f => 1 } ];

my $sim = Cluster::Similarity->new();

$sim->load_data($class1, $class2);

my $contingency = $sim->contingency();

my $exp_contingency = {
		       'c_1' => {
				 'c_1' => 2,
				 'c_2' => 0
				},
		       'c_2' => {
				 'c_1' => 1,
				 'c_2' => 2
				},
		       'c_3' => {
				 'c_1' => 0,
				 'c_2' => 1
				}
		      };


cmp_deeply($contingency, $exp_contingency, 'contingency table');

my $pairs_cont = $sim->pairs_contingency();

print Dumper($pairs_cont);

my $exp_pairs = {
		 'c_1' => {
			   'c_1' => 1,
			   'c_2' => 0,
			  },
		 'c_3' => {
			   'c_1' => 0,
			   'c_2' => 0,
			  },
		 'c_2' => {
			   'c_1' => 0,
			   'c_2' => 1,
			  }	 
		};


cmp_deeply($pairs_cont, $exp_pairs, 'pairs contingency table');

1;
