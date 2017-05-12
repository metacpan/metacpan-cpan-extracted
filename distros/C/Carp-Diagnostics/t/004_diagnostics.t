# test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Carp::Diagnostics qw(cluck carp croak confess UseLongMessage) ; 

{
local $Plan = {'Carping' => 4} ;

warning_like
	{
	cluck('short', 'long') ;
	} qr/long at t\/004_diagnostics\.t line 20/, "cluck" ;

warning_like
	{
	carp('short', 'long') ;
	} qr/long at t\/004_diagnostics\.t line 25/, "carp" ;

throws_ok
	{
	croak('short', 'long') ;
	} qr/long at t\/004_diagnostics\.t line 30/, "croak" ;

throws_ok
	{
	confess('short', 'long') ;
	} qr/long at t\/004_diagnostics\.t line 35/, "confess" ;
}
{
local $Plan = {'Carping' => 4} ;

UseLongMessage(0) ;

warning_like
	{
	cluck('short', 'long') ;
	} qr/short at t\/004_diagnostics\.t line 45/, "short cluck" ;

warning_like
	{
	carp('short', 'long') ;
	} qr/short at t\/004_diagnostics\.t line 50/, "short carp" ;

throws_ok
	{
	croak('short', 'long') ;
	} qr/short at t\/004_diagnostics\.t line 55/, "short croak" ;

throws_ok
	{
	confess('short', 'long') ;
	} qr/short at t\/004_diagnostics\.t line 60/, "short confess" ;
}

{
local $Plan = {'Carping' => 2} ;

UseLongMessage(1) ;

throws_ok
	{
	croak
		(
		'short',
		<<END_OF_POD
=head1 TEST POD TO TEXT CONVERSION

=cut

END_OF_POD
		) ;
	} qr/^TEST POD TO TEXT CONVERSION/, "pod is converted to text" ;

	my $non_pod = <<END_OF_POD ;
x=head1 TEST POD TO TEXT CONVERSION

=cut

END_OF_POD

throws_ok
	{
	croak('short', $non_pod) ;
	} qr/$non_pod/, "non pod is used verbatime" ;
	
}

=comment

{
local $Plan = {'' => } ;

is(result, expected, "message") ;

throws_ok
	{
	
	} qr//, "" ;

lives_ok
	{
	
	} "" ;

like(result, qr//, '') ;

warning_like
	{
	} qr//i, "";

is_deeply
	(
	generated,
	[],
	'expected values'
	) ;


use Directory::Scratch ;
my $temp = Directory::Scratch->new();
my $dir  = $temp->mkdir('foo/bar');
my @lines= qw(This is a file with lots of lines);
my $file = $temp->touch('foo/bar/baz', @lines);
}

=cut
