package Data::SearchEngine::Results::Faceted;
{
  $Data::SearchEngine::Results::Faceted::VERSION = '0.33';
}
use Moose::Role;

# ABSTRACT: Facet role for Results


has facets => (
    traits => [ 'Hash' ],
    is => 'rw',
    isa => 'HashRef[Any]',
    default => sub { {} },
    handles => {
        facet_names=> 'keys',
        get_facet => 'get',
        set_facet => 'set',
    }
);

1;
__END__
=pod

=head1 NAME

Data::SearchEngine::Results::Faceted - Facet role for Results

=head1 VERSION

version 0.33

=head1 SYNOPSIS

    my $results = Data::SearchEngine::Results->new;

    $results->set_facet('foo', 'bar');

=head1 DESCRIPTION

Provides storage and methods for retrieving facet information.

=head1 ATTRIBUTES

=head2 facets

HashRef of facets for this query.  The HashRef is keyed by the name of the
facet and the values are the facet's value.

=head1 METHODS

=head2 facet_names

Returns an array of all the keys of C<facets>.

=head2 get_facet

Gets the facet with the specified name.  Returns undef if one does not exist.

=head2 set_facet

Sets the facet with the specified name.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

