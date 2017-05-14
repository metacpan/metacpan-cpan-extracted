use Coro::LocalScalar::XS;
use Coro;

my %hash;
$hash{1} = 1;

Coro::LocalScalar::XS->localize($hash{1});


while(1){
				
			
			
				async {
						$hash{1} = "thread 1";
						cede;
						die unless $hash{1} eq "thread 1";
						$hash{1} = "thread 1 rewrite";
						cede;
						die unless $hash{1} eq "thread 1 rewrite";
						# warn 1;
				};
				
				async {
						$hash{1} = "thread 2";
						cede;
						die unless $hash{1} eq "thread 2";
						$hash{1} = "thread 2 rewrite";
						cede;
						die unless $hash{1} eq "thread 2 rewrite";
				};
				
				cede;
				cede;
				cede;

}