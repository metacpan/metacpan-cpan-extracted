package Data::DPath::Step;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Abstraction for a single Step through a Path
$Data::DPath::Step::VERSION = '0.58';
use strict;
use warnings;

use Class::XSAccessor::Array
    chained     => 1,
    constructor => 'new',
    accessors   => {
                    kind   => 0,
                    part   => 1,
                    filter => 2,
                   };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::DPath::Step - Abstraction for a single Step through a Path

=head1 ABOUT

When a DPath is evaluated it executes these B<Step>s of a B<Path>.

=head1 INTERNAL METHODS

=head2 new

Constructor.

=head2 kind

Attribute / accessor.

=head2 part

Attribute / accessor.

=head2 filter

Attribute / accessor.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
