package Algorithm::Shape::RandomTree::Branch::Point;

use Moose;

has [ 'x', 'y' ] => ( is => 'ro', isa => 'Int' );

1;

__END__

=head1 NAME 

Algorithm::Shape::RandomTree::Branch::Point - Branch point - a 2D point on the geometrical path representing
a RandomTree's branch.

Meant to be used as part of the Algorithm::Shape::RandomTree module and
not really useful on it's own.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Algorithm::Shape::RandomTree::Branch::Point;

    # Create a point with (X,Y) coordinates of (1,3)

    my $branch_point = Algorithm::Shape::RandomTree::Branch::Point->new(
        x => 1,
        y => 3,
    );

=head1 Attributes

=head2 x

=head2 y

=head1 AUTHOR

Tamir Lousky, C<< <tlousky at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-algorithm-shape-randomtree at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Shape-RandomTree>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::Shape::RandomTree::Branch::Point


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-Shape-RandomTree>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Algorithm-Shape-RandomTree>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Algorithm-Shape-RandomTree>

=item * Search CPAN

L<http://search.cpan.org/dist/Algorithm-Shape-RandomTree/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Tamir Lousky.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
>>>>>>> a08ec105b87df4aaf8c1798ec6796e8621c4c0f8
