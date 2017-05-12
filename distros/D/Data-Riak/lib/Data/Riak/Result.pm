package Data::Riak::Result;
{
  $Data::Riak::Result::VERSION = '2.0';
}
# ABSTRACT: A result of a Riak query

use Moose;
use MooseX::StrictConstructor;

with 'Data::Riak::Role::HasRiak';


has status_code => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);


has content_type => (
    is       => 'ro',
    isa      => 'HTTP::Headers::ActionPack::MediaType',
    required => 1,
);


has value => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=head1 NAME

Data::Riak::Result - A result of a Riak query

=head1 VERSION

version 2.0

=head1 SYNOPSIS

  my $result = $bucket->get('key');
  $result->value;

=head1 DESCRIPTION

This class represents the result of a query to Riak.

Note that different kinds of requests can result in different kinds of
results. For a listing of different request kinds and their corresponding result
classes, see L<Data::Riak::Request>. This document only describes attributes
common to all result classes.

=head1 ATTRIBUTES

=head2 status_code

A code describing the result of the query that produced this result. Currently
this is an HTTP status code.

=head2 content_type

The result's content type.

=head2

The result's value.

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
