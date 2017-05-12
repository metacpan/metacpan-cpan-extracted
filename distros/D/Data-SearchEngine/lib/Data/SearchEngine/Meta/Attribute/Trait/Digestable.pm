package Data::SearchEngine::Meta::Attribute::Trait::Digestable;
{
  $Data::SearchEngine::Meta::Attribute::Trait::Digestable::VERSION = '0.33';
}
use Moose::Role;

# ABSTRACT: Digest flag & configuration


has digest_value => (
    is => 'ro',
    isa => 'CodeRef',
    predicate => 'has_digest_value'
);

no Moose::Role;
1;
__END__
=pod

=head1 NAME

Data::SearchEngine::Meta::Attribute::Trait::Digestable - Digest flag & configuration

=head1 VERSION

version 0.33

=head1 DESCRIPTION

If a L<Data::SearchEngine::Query> attribute has this meta-attribute, then it
will be added to the digest that identifies the uniqueness of a Query.

If the attribute is a scalar, you do not need to specify a C<digest_value>.
The scalar value can just be added to the digest.

For example, if your Query subclass allows the choice of a particular
category to search within, you would obviously want queries with different
categories (or lack thereof) to have different digests.

    has 'category' => (
        traits      => [qw(Digestable)],
        is          => 'rw',
        isa         => 'MyApp::Category',
        digest_value=> sub { $self->category->name }
    );

When computing it's digest, your query will now add the value of the category
to the computation, thereby guaranteeing uniqueness!

=head1 ATTRIBUTES

=head2 digest_value

A coderef that will return a string identifying the value of this attribute
for adding to the Query's digst.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

