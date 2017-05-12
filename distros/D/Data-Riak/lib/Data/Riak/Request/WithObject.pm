package Data::Riak::Request::WithObject;
{
  $Data::Riak::Request::WithObject::VERSION = '2.0';
}

use Moose::Role;
use namespace::autoclean;

with 'Data::Riak::Request::WithBucket';

has key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has vector_clock => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_vector_clock',
);

has if_unmodified_since => (
    is        => 'ro',
    predicate => 'has_if_unmodified_since',
);

has if_match => (
    is        => 'ro',
    predicate => 'has_if_match',
);

1;

__END__

=pod

=head1 NAME

Data::Riak::Request::WithObject

=head1 VERSION

version 2.0

=head1 AUTHORS

=over 4

=item *

Andrew Nelson <anelson at cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
