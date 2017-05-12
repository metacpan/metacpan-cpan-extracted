# test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Carp::Diagnostics qw(cluck carp croak confess) ; 

{
local $Plan = {'single argument' => 4} ;

warning_like
	{
	cluck('message') ;
	} qr/message at t\/005_arguments\.t line 20/, "cluck" ;

warning_like
	{
	carp('message') ;
	} qr/message at t\/005_arguments\.t line 25/, "carp" ;

throws_ok
	{
	croak('message') ;
	} qr/message at t\/005_arguments\.t line 30/, "croak" ;

throws_ok
	{
	confess('message') ;
	} qr/message at t\/005_arguments\.t line 35/, "confess" ;
}


{
local $Plan = {'no argument' => 4} ;

warning_like
	{
	cluck() ;
	} qr/^ at t\/005_arguments\.t line 45/, "cluck" ;

warning_like
	{
	carp() ;
	} qr/^ at t\/005_arguments\.t line 50/, "carp" ;

throws_ok
	{
	croak() ;
	} qr/^ at t\/005_arguments\.t line 55/, "croak" ;

throws_ok
	{
	confess() ;
	} qr/^ at t\/005_arguments\.t line 60/, "confess" ;
}

{
local $Plan = {'podify single argument' => 2} ;

throws_ok
	{
	croak
		(
		<<END_OF_POD
=head1 TEST POD TO TEXT CONVERSION

=cut

END_OF_POD
		) ;
	} qr/^TEST POD TO TEXT CONVERSION/, "pod is converted to text for single argument" ;


#--------------------------------------------------------------

my $non_pod = <<END_OF_POD ;
x=head1 TEST POD TO TEXT CONVERSION

=cut

END_OF_POD

throws_ok
	{
	croak($non_pod) ;
	} qr/$non_pod/, "non pod is used verbatime" ;
	
}

