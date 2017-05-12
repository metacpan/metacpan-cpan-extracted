package Data::Riak::MapReduce::Phase;
{
  $Data::Riak::MapReduce::Phase::VERSION = '2.0';
}

use Moose::Role;


has keep => (
    is        => 'ro',
    isa       => 'Bool',
    predicate => 'has_keep',
);

requires 'pack';

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Data::Riak::MapReduce::Phase

=head1 VERSION

version 2.0

=head1 DESCRIPTION

The Phase role contains common code used by all the Data::Riak::MapReduce
phase classes.

=head1 ATTRIBUTES

=head2 keep

Flag controlling whether the results of this phase are included in the final
result of the map/reduce.

=head1 METHODS

=head2 pack

The C<pack> method is required to be implemented by consumers of this role.

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
