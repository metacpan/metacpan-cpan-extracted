package Data::DPath::Attrs;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Abstraction for internal attributes attached to a point
$Data::DPath::Attrs::VERSION = '0.58';
use strict;
use warnings;

use Class::XSAccessor # ::Array
    chained     => 1,
    constructor => 'new',
    accessors   => [qw( key idx )];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::DPath::Attrs - Abstraction for internal attributes attached to a point

=head1 INTERNAL METHODS

=head2 new

Constructor.

=head2 key

Attribute / accessor.

The key actual hash key under which the point is located in case it's
the value of a hash entry.

=head2 idx

Attribute / accessor.

The key actual array index under which the point is located in case it's
the value of a array entry.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
