package Data::Riak::Result::MaybeWithVClock;
{
  $Data::Riak::Result::MaybeWithVClock::VERSION = '2.0';
}
# ABSTRACT: Results with vector clock headers

use Moose::Role;
use namespace::autoclean;


has vector_clock => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_vector_clock',
);

1;

__END__

=pod

=head1 NAME

Data::Riak::Result::MaybeWithVClock - Results with vector clock headers

=head1 VERSION

version 2.0

=head1 ATTRIBUTES

=head2 vector_clock

The result's vector clock as returned by Riak's C<X-Riak-VClock> headers.

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
