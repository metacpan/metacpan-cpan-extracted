package Data::LUID;

use warnings;
use strict;

=head1 NAME

Data::LUID - Generate guaranteed unique local identifiers

=head1 VERSION

Version 0.014

=cut

our $VERSION = '0.014';

=head1 SYNOPSIS

    use Data::LUID::Table

    my $table = Data::LUID::Table->new( path => 'luid' )

    $luid = $table->make

A sample run:

    8bqwv1
    kb3c6e
    9tah65
    5fd7rd
    tss74z
    7rxk5s
    3mv3qb
    2ad9qj

=head1 DESCRIPTION

On each call to C<< ->make >>, Data::LUID::Table will generate a guaranteed unique local identifier. Guaranteed because once each
identifier is generated, it will be stored in a table for future lookup (collision avoidance)

The current backend is L<BerkeleyDB>

=head1 USAGE

=head2 $table = Data::LUID::Table->new( path => <path> )

Create a new Data::LUID::Table, saving the table to disk at the given <path>

The <path> argument (default: C<./luid>) is the location of the table on disk

=head2 $luid = $table->make

=head2 $luid = $table->next

Generate the next luid in the sequence

The current generator is L<Data::TUID>, so there is no real "sequence" per se

=head1 SEE ALSO

L<Data::TUID>

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-luid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-LUID>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::LUID


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-LUID>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-LUID>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-LUID>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-LUID/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Data::LUID
