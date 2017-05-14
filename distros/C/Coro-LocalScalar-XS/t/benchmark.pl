use Benchmark qw(:all);
use strict;
use Coro;

use Coro::LocalScalar;
use Coro::LocalScalar::XS;
use Coro::Localize;

our $cscalar = '';

cmpthese(10000, {
        'Coro::LocalScalar' => sub { 
			my $scalar;
			Coro::LocalScalar->new->localize($scalar);
			
				async {
						$scalar = "thread 1";
						cede;
						die unless $scalar eq "thread 1";
						$scalar = "thread 1 rewrite";
						cede;
						die unless $scalar eq "thread 1 rewrite";
						
				};
				
				async {
						$scalar = "thread 2";
						cede;
						die unless $scalar eq "thread 2";
						$scalar = "thread 2 rewrite";
						cede;
						die unless $scalar eq "thread 2 rewrite";
				};
				
				cede;
				cede;
				cede;
		},
		
		'Coro::LocalScalar::XS' => sub { 
			my $scalar;
			Coro::LocalScalar::XS->localize($scalar);
			
				async {
						$scalar = "thread 1";
						cede;
						die unless $scalar eq "thread 1";
						$scalar = "thread 1 rewrite";
						cede;
						die unless $scalar eq "thread 1 rewrite";
						# warn 1;
				};
				
				async {
						$scalar = "thread 2";
						cede;
						die unless $scalar eq "thread 2";
						$scalar = "thread 2 rewrite";
						cede;
						die unless $scalar eq "thread 2 rewrite";
				};
				
				cede;
				cede;
				cede;
		},
		
        'Coro::Localize' => sub { 
				
				async {
						corolocal $cscalar = "thread 1";
						cede;
						die unless $cscalar eq "thread 1";
						$cscalar = "thread 1 rewrite";
						cede;
						die unless $cscalar eq "thread 1 rewrite";
						# warn 1;
				};
				
				async {
						corolocal $cscalar = "thread 2";
						cede;
						die unless $cscalar eq "thread 2";
						$cscalar = "thread 2 rewrite";
						cede;
						die unless $cscalar eq "thread 2 rewrite";
				};
				
				cede;
				cede;
				cede;
		},
    });

