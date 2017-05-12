package Data::SearchEngine;
{
  $Data::SearchEngine::VERSION = '0.33';
}
use Moose::Role;

# ABSTRACT: A role for search engine abstraction.

requires qw(find_by_id search);



has debug => (
    is => 'rw',
    isa => 'Any',
    predicate => 'is_debug'
);


has defaults => (
    traits => [ 'Hash' ],
    is => 'ro',
    isa => 'HashRef',
    handles => {
        set_default => 'set',
        get_default => 'get'
    }
);


no Moose::Role;
1;

__END__
=pod

=head1 NAME

Data::SearchEngine - A role for search engine abstraction.

=head1 VERSION

version 0.33

=head1 SYNOPSIS

  package Data::SearchEngine::MySearch;
  use Moose;

  with 'Data::SearchEngine';

  sub search {
    my ($self, $query) = @_;

    # ... your internal search junk

    my $result = Data::SearchEngine::Results->new(
        query => $query,
        pager => # ... make a Data::Page
    );

    my @hits; # Populate with hits somehow

    foreach my $hit (@hits) {
        $result->add(Data::SearchEngine::Item->new(
            values => {
                name => $hit->name,
                description => $hit->description
            },
            score => $hit->score
        ));
    }

    return $result;
  }

=head1 DESCRIPTION

There are B<lots> of search engine libraries.  Each has a different interface.
The goal of Data::SearchEngine is to provide a simple, extensive set of
classes and roles that you can use to wrap a search implementation.  The net
result will be an easily swappable backend with a common set of features.

=head1 IMPLEMENTATION

B<NOTE:> You should avoid adding new attributes or subclassing
Data::SearchEngine classes unless otherwise noted. Doing so will break
compatability with future releases and obviate the whole reason that
Data::SearchEngine exists.  The only exception is the Results class (step 3
below) which should B<only> be a subclass with roles applied, no new attributes
or methods.

=head2 Step 1 - Wrap a search implementation

As shown in the SYNOPSIS, use the L<Data::SearchEngine> role in a class that
wraps your search implementation.  Implement a C<search> method that takes a
L<Data::SearchEngine::Query> object and returns a
L<Data::SearchEngine::Results> object.

=head2 Step 2 - Use Other Roles

If your library includes functionality other than searching, such as indexing
new documents or removing them, you may include the 
L<Data::SearchEngine::Modifiable> role.  If you have other suggestions for
roles please drop me a line!

=head2 Step 3 - Extend the Results

The results object may not have quite enough pieces for your implementation.
If not, you can C<extend> L<Data::SearchEngine::Results> and add some other
roles:

=over 4

=item Data::SearchEngine::Results::Faceted

For results that contain faceted data.

=item Data::SearchEngine::Results::Spellcheck

For results that contain spellcheck data.

=back

=head1 DIGESTS

Data::SearchEngine provides a Digestable trait that can be applied to
attributes of C<Query>.  Attributes with this trait will be added to
a base64 MD5 digest to produce a unique key identifying this query.  You can
then serialize the Result using L<MooseX::Storage> and store it under the
digest of the Query for caching.

=head1 ATTRIBUTES

=head2 debug

An attribute that signals the backend should operate in a debugging mode.
Please see the implementation module for specifics on how to use this.

=head2 defaults

The C<defaults> attribute is a simple HashRef that backends may use to get
default settings from the user.  The implementation of C<search> may then use
these defaults when setting up instances of a search.

=head1 METHODS

=head2 is_debug

Method for determining if the debug attribute has been set.

=head2 get_default ($key)

Returns the value from C<defaults> (if any) for the specified key.

=head2 set_default ($key, $value)

Sets the value in C<defaults>.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

