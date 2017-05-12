package Data::Riak::Result::Object;
{
  $Data::Riak::Result::Object::VERSION = '2.0';
}
# ABSTRACT: A result containing a full object

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::WithLocation',
     'Data::Riak::Result::WithLinks',
     'Data::Riak::Result::MaybeWithVClock';


has etag => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_etag',
);


has last_modified => (
    is        => 'ro',
    isa       => 'HTTP::Headers::ActionPack::DateHeader',
    predicate => 'has_last_modified',
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Result::Object - A result containing a full object

=head1 VERSION

version 2.0

=head1 DESCRIPTION

A result class representing a full object retrieved from Riak. This composes the
roles

=over 4

=item * L<Data::Riak::Result::WithLocation>

=item * L<Data::Riak::Result::WithLinks>

=item * L<Data::Riak::Result::MaybeWithVClock>

=back

=head1 ATTRIBUTES

=head2 etag

ETag header as provided by Riak. May or may not be present, as indicated by the
C<has_etag> predicate method.

=head2 last_modified

A L<HTTP::Headers::ActionPack::DateHeader> describing the time the object was
last modified in Riak. May or may not be present, as indicated by the
C<has_last_modified> predicate method.

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
