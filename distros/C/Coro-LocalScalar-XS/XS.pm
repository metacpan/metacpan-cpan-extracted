package Coro::LocalScalar::XS;
require DynaLoader;
use Coro;
use Exporter 'import';
our @EXPORT = qw/localize/;

$Coro::LocalScalar::XS = '0.2';
DynaLoader::bootstrap Coro::LocalScalar::XS $Coro::LocalScalar::XS;

=head1 NAME

Coro::LocalScalar::XS - Different scalar values in coroutines

=head1 ABOUT

This is optimized XS version of L<Coro::LocalScalar>. It's almost two times faster and has simplier api - only one function. 
This module destroys all local data(and DESTROYs are called) when coroutine get destroyed. This is useful for example if you want to have global variable $request with different object in each coro. 

Coro::LocalScalar::XS keeps reference to localized variable, so localize only variables, that will persist all execution time. Localizing hundreds of variables is also bad idea, because each variable adds little overhead when each coro is destroyed

=head1 SYNOPSIS

	use Coro;
	use Coro::EV;


	my $scalar;

	use Coro::LocalScalar::XS;
	localize($scalar); # $scalar is now different in all coros. Current value of $scalar is deleted.

	# $hash{element} = undef; # hash element MUST exist if you want to localize it correctly
	# localize($hash{element}); 
	# localizing arrays or hashes unsupported, use refs
	
	# or
	# use Coro::LocalScalar::XS qw//; # don't export localize
	# Coro::LocalScalar::XS->localize($scalar);

	async {
			$scalar = "thread 1";
			print "1 - $scalar\n";
			cede;
			print "3 - $scalar\n";
			cede;
			print "5 - $scalar\n";
			
	};

	async {
			$scalar = "thread 2";
			print "2 - $scalar\n";
			cede;
			print "4 - $scalar\n";
			cede;
			print "6 - $scalar\n";
	};

	EV::loop;
	

	
	1 - thread 1
	2 - thread 2
	3 - thread 1
	4 - thread 2
	5 - thread 1
	6 - thread 2
	

=head1 BENCHMARK

	 t/benchmark.pl
	
							Rate Coro::LocalScalar Coro::LocalScalar::XS Coro::Localize
	Coro::LocalScalar     10000/s                --                  -45%           -52%
	Coro::LocalScalar::XS 18282/s               83%                    --           -12%
	Coro::Localize        20661/s              107%                   13%             --
	

L<Coro::Localize> is little bit faster, but Coro::LocalScalar::XS allows localizing hash elements

=cut


sub _set_ondestroy_cb {
	my $coro = $Coro::current;
	
	$coro->on_destroy(sub {
		# when i use magick to store local copy of var for each coroutine the current value is stored in localized scalar itself
		# sv_setsv(sv, &PL_sv_undef ); from XS has no effect and value is still stored in scalar
		# so if value in scalar is object, then when coroutine gets destroyed Coro::LocalScalar::XS destroys it's internal storage, 
		# but one reference persists in scalar itself and object destructor will not be called till scalar will be reassigned
		
		Coro::LocalScalar::XS::cleanup($coro); # clean internal storage and disable magick
		
		$$_ = undef for @Coro::LocalScalar::XS::localized; # reassign all localized scalar to call destructors
		
		Coro::LocalScalar::XS::reenable_magick(); # enable magick
		
		$coro = undef ; 
	});
	
	undef;
}


our @localized;

sub localize($) {
	shift if $_[0] eq __PACKAGE__;
	
	push @localized, \$_[0];
	Coro::LocalScalar::XS::_init($_[0]);
}



sub dl_load_flags {0};
1;