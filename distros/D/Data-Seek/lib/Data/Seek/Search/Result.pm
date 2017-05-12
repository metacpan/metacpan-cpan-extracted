# ABSTRACT: Data::Seek Search Result Class
package Data::Seek::Search::Result;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object qw(
    reify
);

use Data::Object::Library qw(
    ArrayObj
    InstanceOf
);

use Data::Seek::Search;

our $VERSION = '0.09'; # VERSION

# ATTRIBUTES

has datasets => (
    is       => 'ro',
    isa      => ArrayObj,
    coerce   => method { reify($self) },
    default  => method { $self->search->perform },
    required => 0,
    lazy     => 1,
);

has search => (
    is       => 'ro',
    isa      => InstanceOf['Data::Seek::Search'],
    default  => method { Data::Seek::Search->new },
    required => 1,
    lazy     => 1,
);

# METHODS

method data () {

    my $sets = $self->datasets;
    my $data = reify {};

    for my $set ($sets->list) {

        for my $node ($set->get('nodes')->list) {

            $data->set($node => $set->lookup("dataset.$node"));

        }

    }

    return $data->unfold;

}

method nodes () {

    my $sets = $self->datasets;
    my $keys = reify [];

    for my $set ($sets->list) {

        my $nodes = $set->get('nodes');

        $keys->push($nodes->sort->list);

    }

    return $keys;

}

method values () {

    my $sets = $self->datasets;
    my $vals = reify [];

    for my $set (@$sets) {

        my $nodes = $set->get('nodes');

        $vals->push($set->lookup("dataset.$_")) for $nodes->sort->list;

    }

    return $vals;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Seek::Search::Result - Data::Seek Search Result Class

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use Data::Seek::Search::Result;

=head1 DESCRIPTION

Data::Seek::Search::Result is a class within L<Data::Seek> which provides access
to the search results produced by L<Data::Seek::Search>.

=head1 ATTRIBUTES

=head2 datasets

    my $datasets = $result->datasets;

Perform the search and introspection using the search object,
L<Data::Seek::Search>, and cache the resulting data set. This attribute returns
a L<Data::Object::Array> object.

=head2 search

    my $search = $result->search;

Reference the search object, L<Data::Seek::Search>, which the resulting data set
is derived from.

=head1 METHODS

=head2 data

    my $data = $result->data;

Produce a L<Data::Object::Hash> object, i.e. a hash reference, comprised of
only the nodes matching the criteria used in the search.

=head2 nodes

    my $nodes = $result->nodes;

Produce a L<Data::Object::Array> object, comprised of only the node keys/paths
matching the criteria used in the search.

=head2 values

    my $values = $result->values;

Produce a L<Data::Object::Array> object, comprised of only the values matching
the criteria used in the search.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
