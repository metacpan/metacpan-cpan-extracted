# $Revision: 1.1 $
use strict;

use Test::More 'no_plan';

use Business::ISBN qw(:all);

my @isbns = qw(
	91-7119-704-4
	978-91-7119-810-5	
	978-0-911910-00-1
	978-0-88264-180-5
	);
	
foreach my $isbn ( @isbns )
	{
	( my $stripped = $isbn ) =~ s/-//g;
	
	my $object = Business::ISBN->new( $stripped );
	my $pretty = $object->as_string;
	
	is( $pretty, $isbn, "[$isbn] comes out right" );
	}
	



__END__
Hi Ed and Brian,

Is the following a known problem, and is there any fix?

I'm having great fun with the CPAN package Business::ISBN,
but it's odd that as_string() produces different results for
10-digit and 13-digit ISBNs.

For example, it correctly suggests 91-7119-704-4 but then wrongly
978-91-711-9810-5. In both cases, 91-7 should be followed by
three digits (91-7119-) before the next hyphen.

The file Business/ISBN/Data.pm correctly states:

91 => [ 'Sweden', [ '0' => 1, 20 => 49,
500 => 649, 7000 => 7999,
85000 => 94999, 970000 => 999999 ] ],

This works perfectly fine ISBN-10 and for 978-91-[0-6], but [789]
are followed by just two more digits (e.g. -711-) before the next
hyphen. It also wrongly suggests 978-0-8826-4180-5 (should be
0-88264-) and 978-0-9119-1000-1 (should be 0-911910-).

It is as if it never puts the middle hyphen after the 8:th digit,
which is a reasonable thing to do in an ISBN-10, but not in
ISBN-13. Maybe the Perldoc line "Positions less than 1 and
greater than 9 are silently ignored" for as_string() is the key to
the problem? When we're dealing with ISBN-13s, these positions
should be counted from the end of the string, not from the
beginning.

Here's my program:

#!/usr/bin/perl -w

use Business::ISBN;
use strict;

my $isbn = Business::ISBN->new("9789171198105");
my $pretty = $isbn->as_string;
print "$pretty\n";