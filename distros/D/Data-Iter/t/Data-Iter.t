# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
#BEGIN { plan tests => 5 };
use Data::Iter qw(:all);
use IO::Extended qw(:all);
use Data::Dump qw(dump);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use strict;

my @days = qw/Mon Tue Wnd Thr Fr Su So/;
	
	foreach ( iter \@days )
	{		
		printf "Day: %s [%s] last %d\n", VALUE, counter, LAST_COUNTER;
		
		printf "End.\n" if COUNTER == LAST_COUNTER;	
	}

	foreach my $i ( iter \@days )
	{		
		printf "Day: %s [%s]\n", $i->VALUE, $i->counter;
	}

	foreach my $i ( iter \@days )
	{		
		printfln q{Day: %s [%s].  Next is %s     returned by $i->getnext()}, $i->VALUE, $i->counter, 
		$i->getnext ? $i->getnext->VALUE : 'undef';
	}

	foreach ( iter [qw(one 1 two 2 three 3)] )
	{		
 	    if( COUNTER() % 2 == 0 )
	    {
		printfln q{%s => %s}, VALUE, GETNEXT->VALUE;
	    }
	}

my %numbers = ( 1 => 'one', 2 => 'two', 3 => 'three', 4 => 'four' );

	foreach ( iter \%numbers )
	{	
		printf "%10s [%10s] %10d\n", key, value, counter;
	}

	foreach my $i ( iter \%numbers )
	{	
		printf "%10s [%10s] %10d\n", $i->key, $i->value, $i->counter;
	}

print "\nagain..\n\n";

	foreach ( iter \%numbers )
	{	
		printf "%10s [%10s] %10d\n", KEY, VALUE, counter;
	}

print "#\nsetting values..\n\n";

	my @obj  = iter \%numbers;
	
	foreach ( @obj )
	{	
		printf "%10s [%10s] %10d\n", $_->KEY, $_->VALUE( $_->VALUE." ah yeah" ), counter;
	}

	foreach ( iter \@days )
	{		
		printf "Day: %s [%s]\n", $_->VALUE( $_->VALUE()." ah yeah" ), COUNTER;
	}

	@obj  = iter \%numbers;
	
	foreach ( @obj )
	{	
		printf "%10s [%10s] %10d\n", KEY, VALUE( VALUE()." oh no" ), counter;
	}

	foreach ( iter \@days )
	{		
		printf "Day: %s [%s]\n", VALUE( VALUE()." oh no" ), COUNTER;
	}




my $cfs =
  [
   tcf1 => 28.44,
   tcf1 => 28.13,
   tcf3 => 26.92,
   tcf3 => 26.09,
   gapdh => 17.08,
   gapdh => 16.1
  ];

my $cfs_to_hash = Data::Iter::transform_array_to_hash( $cfs );

println Data::Dump::dump( $cfs_to_hash );

ok( keys %$cfs_to_hash == 3 );


println "";

$numbers{a} = "alpha";
$numbers{b} = "beta";

my $str1;

$Data::Iter::Sort = "sort_alpha";

	foreach ( iter \%numbers )
	{	
		$str1.=key;
	}

println $str1;

ok($str1 eq '1234ab');


my $str2;

%numbers = ( 1 => 'eins', 2 => 'zwei' );

$Data::Iter::Sort = "sort_num";

	foreach ( iter \%numbers )
	{	
		$str2.=key;
	}

#diag( "STRING ".$str2 );

ok($str2 eq '12');

my $str3;

sub sort_wild($$) { $_[0]+$_[1] <=> $_[1] }

$Data::Iter::Sort = "::sort_wild";

	foreach ( iter \%numbers )
	{	
		$str3.=key;
	}

#diag( $str3 );

ok($str3 eq '21');


    foreach my $r ( iter [qw(b red a white)] )
    {
       my ( $key, $value ) = $r->PAIR();

       if( $key )
       {
          println "PAIR: $key => $value";
       }
    }
