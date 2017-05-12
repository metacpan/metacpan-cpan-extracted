package AnyEvent::HTTPBenchmark;

use warnings;
use strict;

=head1 NAME

AnyEvent::HTTPBenchmark - The tool and library to make http benchmarking good and easy!

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 SYNOPSIS

The apache benchmark (ab) , siege, jmeter and etc, are sometimes awesome to make http-load testing. But if 
you want make some non-traditional test they are not good decision.This module try to help you in this case.
Currently implemented just test utility , not a library .Be patient ;)


	benchmark.pl --url http://example.com -n 100 -c 10 -verbose 1
	#show each connection
	benchmark.pl --url http://example.com -n 100 -c 10 
	#makes the silent test
	benchmark.pl --url http://example.com -n 100 -c 10 -verbose 2
	#more details - show the responce
   
=head1 EXPORT

Currently no export functions are implemented.

=head1 SUBROUTINES/METHODS

=head2 make_request
not implemented
=cut

sub make_request {
	#not implemented
}

=head2 function2

=cut

sub function2 {
	#under construction
}

=head1 AUTHOR

Naim Shafiev, C<< <naim at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-anyevent-httpbenchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-HTTPBenchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::HTTPBenchmark


You can also look for information at:

L<http://github.com/shafiev/AnyEvent-HTTPBenchmark>


=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-HTTPBenchmark>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyEvent-HTTPBenchmark>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AnyEvent-HTTPBenchmark>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyEvent-HTTPBenchmark/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Naim Shafiev.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut

1; # End of AnyEvent::HTTPBenchmark
