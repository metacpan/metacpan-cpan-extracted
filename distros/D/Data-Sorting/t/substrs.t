#!perl
use strict;
use Test::More tests => 8;
BEGIN { use_ok('Data::Sorting'); }
require 't/sort_tests.pl';

test_sort_cases (
  {
    values => [ 
	'Alpha:Sigma:On', 
	'Beta:Delta:Off', 
	'Gamma:Chi:On', 
	'Omega:Epsilon:Off',
    ],
    sorted => [],
  },
  {
    values => [ 
	'Gamma:Chi:On', 
	'Beta:Delta:Off', 
	'Alpha:Sigma:On', 
	'Omega:Epsilon:Off',
    ],
    sorted => [ -extract => 'substr', [1,3]  ],
  },
  {
    values => [ 
	'Alpha:Sigma:On', 
	'Beta:Delta:Off', 
	'Gamma:Chi:On', 
	'Omega:Epsilon:Off',
    ],
    sorted => [ -extract => 'split', [':', 0]  ],
  },
  {
    values => [ 
	'Gamma:Chi:On', 
	'Beta:Delta:Off', 
	'Omega:Epsilon:Off', 
	'Alpha:Sigma:On', 
    ],
    sorted => [ -extract => 'split', [':', 1]  ],
  },
  {
    values => [ 
	'Beta:Delta:Off', 
	'Omega:Epsilon:Off', 
	'Alpha:Sigma:On', 
	'Gamma:Chi:On', 
    ],
    sorted => [ -extract => 'split', [':', 2], [':', 0] ],
  },
  {
    values => [ 
	'Beta:Delta:Off', 
	'Gamma:Chi:On', 
	'Alpha:Sigma:On', 
	'Omega:Epsilon:Off', 
    ],
    sorted => [ -extract => 'compound', ['split'=>[':', 1], 'substr'=>[1,3] ] ],
  },
  {
    values => [ 
	'Beta:Delta:Off', 
	'Omega:Epsilon:Off', 
	'Alpha:Sigma:On', 
	'Gamma:Chi:On', 
    ],
    sorted => [ -extract => 'split', [':', 2]  ],
    okidxs => [ [ 1, 2, 3, 4 ], [ 2, 1, 3, 4 ], [ 1, 2, 4, 3 ], [ 2, 1, 4, 3 ] ]
  },
);
