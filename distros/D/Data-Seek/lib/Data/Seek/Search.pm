# ABSTRACT: Data::Seek Search Class
package Data::Seek::Search;

use Data::Object::Class;
use Data::Object::Signatures;

with 'Data::Object::Role::Throwable';

use Data::Object qw(
    reify
);

use Data::Object::Library qw(
    HashObj
    NumObj
);

use Data::Seek::Search::Result;

our $VERSION = '0.09'; # VERSION

# ATTRIBUTES

has ignore => (
    is       => 'ro',
    isa      => NumObj,
    coerce   => method { reify($self) },
    default  => 0,
    required => 0,
);

has criteria => (
    is       => 'ro',
    isa      => HashObj,
    coerce   => method { reify($self) },
    default  => method { {} },
    required => 0,
    lazy     => 1,
);

has data => (
    is       => 'ro',
    isa      => HashObj,
    coerce   => method { reify($self) },
    default  => method { {} },
    required => 0,
    lazy     => 1,
);

# METHODS

method perform () {

    my $criteria = $self->criteria->reverse;
    my $orders   = $criteria->keys->sort;
    my $dataset  = $self->data->fold;

    my $results = reify [];

    for my $order ($orders->list) {

        my $criterion = $criteria->get($order);
        my $regexp    = quotemeta $criterion;

        # array selector
        $regexp =~ s/\\\.\\\@\\\./\:\\d+\./g;

        # trailing tail array selector
        $regexp =~ s/([\w\\\*]*(?:\w|\*))\\[\@\%]\B/$1:\\d+/g;
        # trailing step array selector
        $regexp =~ s/([\w\\\*]*(?:\w|\*))\\[\@\%]\\\./$1:\\d+\\\./g;

        # leading head array selector
        $regexp =~ s/\A\\[\@\%]([\w\\\*]*(?:\w|\*))/$1:\\d+/g;
        # leading step array selector
        $regexp =~ s/\\\.\\[\@\%]([\w\\\*]*(?:\w|\*))/\\\.$1:\\d+/g;

        # greedy wildcard selector
        $regexp =~ s/\\\*\\\*/[\\w\\:\\.]+/g;
        # wildcard selector
        $regexp =~ s/\\\*/\\w+/g;

        my $pattern = sub { shift =~ /^$regexp$/ };
        my $nodes   = $dataset->keys->sort->grep($pattern);

        $self->throw("search for '$criterion' failed")
            unless $nodes->count or $self->ignore;

        next unless $nodes->count;

        my $result = { nodes => $nodes->sort, criterion => $criterion };

        $results->push($result);

    }

    my $output = reify [];

    for my $result ($results->list) {

        my $nodes = $result->get('nodes');
        my $data  = { map { $_ => $dataset->get($_) } $nodes->list };

        $result->set(dataset => $data);
        $output->push($result);

    }

    return $output;

}

method result () {

    return Data::Seek::Search::Result->new( search => $self );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Seek::Search - Data::Seek Search Class

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use Data::Seek::Search;

=head1 DESCRIPTION

Data::Seek::Search is a class within L<Data::Seek> which provides the search
mechanism for introspecting data structures.

=head1 ATTRIBUTES

=head2 criteria

    $search->criteria;
    $search->criteria({
        '*'                      => 0,
        'person.name.first'      => 1,
        'person.name.last'       => 2,
        'person.@settings.name'  => 3,
        'person.@settings.type'  => 4,
        'person.@settings.value' => 5,
    });

A collection of criterion which will be used to match nodes within the data
structure when introspected, in the order registered. This attribute must be a
hash reference, which is coerced into a L<Data::Object::Hash> object.

=head2 data

    $seeker->data;
    $seeker->data({...});

The data structure to be introspected, must be a hash reference, which is
coerced into a L<Data::Object::Hash> object.

=head2 ignore

    $search->ignore;
    $search->ignore(1);

Bypass exceptions thrown when a criterion is invalid or no data matches can be
found. This attribute must be an integer, which is coerced into a
L<Data::Object::Integer> object.

=head1 METHODS

=head2 perform

    my $dataset = $search->perform;

Introspect the data structure using the registered criteria and settings, and
return a result set of operations and matching data nodes. This result set is
returned as a L<Data::Object::Array> object.

=head2 result

    my $result = $search->result;

Return a search result object, L<Data::Seek::Search::Result>, based on the
current search object.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
