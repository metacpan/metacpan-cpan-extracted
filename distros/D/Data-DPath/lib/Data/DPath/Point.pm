package Data::DPath::Point;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Abstraction for a single reference (a "point") in the datastructure
$Data::DPath::Point::VERSION = '0.58';
use strict;
use warnings;

use Class::XSAccessor # ::Array
    chained     => 1,
    constructor => 'new',
    accessors   => [qw( parent
                        attrs
                        ref
                     )];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::DPath::Point - Abstraction for a single reference (a "point") in the datastructure

=head1 ABOUT

Intermediate steps during execution are lists of currently covered
references in the data structure, i.e., lists of such B<Point>s. The
remaining B<Point>s at the end just need to be dereferenced and form
the result.

=head1 INTERNAL METHODS

=head2 new

Constructor.

=head2 parent

Attribute / accessor.

=head2 ref

Attribute / accessor.

=head2 attrs

Attribute / accessor.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
