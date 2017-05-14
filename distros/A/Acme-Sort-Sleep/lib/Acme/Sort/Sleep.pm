# ABSTRACT: IO::Async timer based sorting algorithm

package Acme::Sort::Sleep;

use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Timer::Countdown;
use Scalar::Util qw( looks_like_number );

use base 'Exporter';
our @EXPORT_OK = qw( sleepsort );

use constant ERROR_STR => "Only positive numbers accepted.";

sub sleepsort {

    my @unsorted = @_;
    my @sorted   = ();

    # handle empty list
    return () unless @unsorted;

    my $loop = IO::Async::Loop->new;

    for my $num ( @unsorted ) {

	# only allow positive numbers
	die ERROR_STR unless defined $num;
	die ERROR_STR unless looks_like_number $num;
	die ERROR_STR unless $num >= 0;

	my $timer = IO::Async::Timer::Countdown->new(
	    delay            => $num,
	    remove_on_expire => 1,
	    on_expire        => sub {
		
		push @sorted, $num;

		# no more timers/numbers left to sort
		$loop->stop unless $loop->notifiers;
	    },
	);

	$timer->start;
	$loop->add( $timer );
    }

    $loop->run;

    return @sorted;
}

1;
