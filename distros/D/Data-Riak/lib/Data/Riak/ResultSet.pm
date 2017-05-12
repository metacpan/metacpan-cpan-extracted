package Data::Riak::ResultSet;
{
  $Data::Riak::ResultSet::VERSION = '2.0';
}

use strict;
use warnings;

use Moose;

has results => (
    is       => 'ro',
    isa      => 'ArrayRef[Data::Riak::Result]',
    required => 1
);

sub first { (shift)->results->[0] }

sub all { @{ (shift)->results } }

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=head1 NAME

Data::Riak::ResultSet

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
