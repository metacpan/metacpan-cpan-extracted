# ABSTRACT: Search Complex Data Structures
package Data::Seek;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object qw(
    reify
);

use Data::Object::Library qw(
    HashObj
    NumObj
);

use Data::Seek::Search;

our $VERSION = '0.09'; # VERSION

# ATTRIBUTES

has data => (
    is       => 'ro',
    isa      => HashObj,
    coerce   => method { reify($self) },
    default  => method { {} },
    required => 1,
);

has ignore => (
    is       => 'rw',
    isa      => NumObj,
    coerce   => method { reify($self) },
    default  => 0,
    required => 0,
);

# METHODS

method search (Str @criteria) {

    my $data   = $self->data;
    my $ignore = $self->ignore;

    my $place  = 0;
    my $search = Data::Seek::Search->new(
        criteria => { map { $_ => $place++ } @criteria },
        data     => $data,
        ignore   => $ignore,
    );

    return $search->result;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Seek - Search Complex Data Structures

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use Data::Seek;

    my $hash   = {...};
    my $seeker = Data::Seek->new(data => $hash);
    my $result = $seeker->search(...);
    my $data   = $result->data;

=head1 DESCRIPTION

Data::Seek is used for querying complex data structures. This module allows you
to select and return specific node(s) in a hierarchical data structure using a
simple and intuitive query syntax. The results can be returned as a list of
values, or as a hash object in the same shape as the original.

=head1 ENCODING

During the processing of flattening a data structure with nested data, the
following data structure would be converted into a collection of endpoint/value
pairs.

    {
        'id' => 12345,
        'patient' => {
            'name' => {
                'first' => 'Bob',
                'last'  => 'Bee'
            }
        },
        'medications' => [{
            'aceInhibitors' => [{
                'name'      => 'lisinopril',
                'strength'  => '10 mg Tab',
                'dose'      => '1 tab',
                'route'     => 'PO',
                'sig'       => 'daily',
                'pillCount' => '#90',
                'refills'   => 'Refill 3'
            }],
            'antianginal' => [{
                'name'      => 'nitroglycerin',
                'strength'  => '0.4 mg Sublingual Tab',
                'dose'      => '1 tab',
                'route'     => 'SL',
                'sig'       => 'q15min PRN',
                'pillCount' => '#30',
                'refills'   => 'Refill 1'
            }],
        }]
    }

Given the aforementioned data structure, the following would be the resulting
flattened structure comprised of endpoint/value pairs.

    {
        'id'                                      => 12345,
        'medications:0.aceInhibitors:0.dose'      => '1 tab',
        'medications:0.aceInhibitors:0.name'      => 'lisinopril',
        'medications:0.aceInhibitors:0.pillCount' => '#90',
        'medications:0.aceInhibitors:0.refills'   => 'Refill 3',
        'medications:0.aceInhibitors:0.route'     => 'PO',
        'medications:0.aceInhibitors:0.sig'       => 'daily',
        'medications:0.aceInhibitors:0.strength'  => '10 mg Tab',
        'medications:0.antianginal:0.dose'        => '1 tab',
        'medications:0.antianginal:0.name'        => 'nitroglycerin',
        'medications:0.antianginal:0.pillCount'   => '#30',
        'medications:0.antianginal:0.refills'     => 'Refill 1',
        'medications:0.antianginal:0.route'       => 'SL',
        'medications:0.antianginal:0.sig'         => 'q15min PRN',
        'medications:0.antianginal:0.strength'    => '0.4 mg Sublingual Tab',
        'patient.name.first'                      => 'Bob'
        'patient.name.last'                       => 'Bee',
    }

This structure provides the endpoint strings which will be matched against using
the querying strategy.

=head1 QUERYING

During the processing of querying the data structure, the criteria (query
expressions) are converted into a series of regular expressions to be applied
sequentially, filtering/reducing the endpoints and producing a data set of
matching nodes or throwing an exception explaining the search failure.

=over 4

=item * B<Node Expression>

    my $result = $seeker->search(...);

    # given "id"
    { id => 12345 }

The node expression is a part of a criterion, which preforms an exact match
against a node in the data structure. It is a string which can contain letters,
numbers, and/or underscores.

=item * B<Step Expression>

    my $result = $seeker->search(...);

    # given "patient.name.first"
    { patient => { name => { first => "Bob" } } }

    # given "patient.name.last"
    { patient => { name => { last => "Bee" } } }

The step expression is a criterion, or part of a criterion, made up of one or
more node expressions separated using the period character, which matches
against nodes in the data structure. It is a string which can contain letters,
numbers, and/or underscores, separated using periods.

=item * B<Index Expression>

    my $result = $seeker->search(...);

    # given "medications:0.aceInhibitors:0.dose"
    { medications => [{ aceInhibitors => [{ dose => "1 tab" }] }] }

    # given "medications:0.aceInhibitors:0.name"
    { medications => [{ aceInhibitors => [{ name => "lisinopril" }] }], }

    # given "medications:0.aceInhibitors:0.pillCount"
    { medications => [{ aceInhibitors => [{ pillCount => "#90" }] }] }

The index expression is a criterion, or part of a criterion, having a node
expressions suffixed with a colon followed by a number denoting that it should
only match an array which has an index corresponding to the numeric portion of
the suffix. It is a string which can contain letters, numbers, and/or
underscores, suffixed with a semi-colon followed by a number.

=item * B<Iterator Expression>

    my $result = $seeker->search(...);

    # given "@medications.@aceInhibitors.dose"
    { medications => [{ aceInhibitors => [{ dose => "1 tab" }] }] }

    # given "@medications.@aceInhibitors.name"
    { medications => [{ aceInhibitors => [{ name => "lisinopril" }] }], }

    # given "@medications.@aceInhibitors.pillCount"
    { medications => [{ aceInhibitors => [{ pillCount => "#90" }] }] }

The iteration expression is a criterion, or part of a criterion, having a node
expressions preceded by an "at" character denoting that the node expression
should match all nodes in the data structure which are mapped to array objects.
It is a string which can contain letters, numbers, and/or underscores, preceded
by a single ampersand character.

=item * B<Wildcard Expression>

    my $result = $seeker->search(...);

    # given "*"
    { id => 12345 }

    # given "*.*.first"
    { patient => { name => { first => "Bob" } } }

    # given "*.*.last"
    { patient => { name => { last => "Bee" } } }

    # given "patient.*.first"
    { patient => { name => { first => "Bob" } } }

    # given "patient.*.last"
    { patient => { name => { last => "Bee" } } }

    # given "@*.@*.pillCount"
    {
        medications => [{
            aceInhibitors => [{ pillCount => "#90" }],
            antianginal   => [{ pillCount => "#30" }],
        }],
    }

The wildcard expression is a criterion, or part of a criterion, which matches
against a single node having a single "star" character match and represent one
node expression. It is a string which can contain letters, numbers, underscores,
and/or a single star character.

=item * B<Greedy-Wildcard Expression>

    my $result = $seeker->search(...);

    # given "**.first"
    { patient => { name => { first => "Bob" } } }

    # given "**.last"
    { patient => { name => { last => "Bee" } } }

    # given "patient.**"
    { patient => { name => { first => "Bob", last => "Bee" } } }

    # given "medications**.pillCount"
    {
        medications => [{
            aceInhibitors => [{ pillCount => "#90" }],
            antianginal   => [{ pillCount => "#30" }],
        }],
    }

The greedy-wildcard expression is a criterion, or part of a criterion, which
matches against any multitude of nodes having a double "star" character match
and represent one or more of any character. It is a string which can contain
letters, numbers, underscores, and/or a double star character.

=back

=head1 ATTRIBUTES

=head2 data

    $seeker->data;
    $seeker->data({...});

The data structure to be introspected, must be a hash reference, which is
coerced into a L<Data::Object::Hash> object.

=head2 ignore

    $seeker->ignore;
    $seeker->ignore(1);

Bypass exceptions thrown when a criterion is invalid or no data matches can be
found. This attribute must be an integer, which is coerced into a
L<Data::Object::Integer> object.

=head1 METHODS

=head2 search

    my $search = $seeker->search('id', 'person.name.*');

Prepare a search object to use the supplied criteria and return a search
object. Introspection is triggered when the result method is enacted. See
L<Data::Seek::Search> for usage information.

=head1 CONCEPT

The follow is a short and simple overview of the strategy and syntax used by
Data::Seek to query complex data structures. The overall idea behind Data::Seek
is to flatten/fold the data structure, reduce it by applying a series patterns,
then, unflatten/unfold and operate on the new data structure. The introspection
strategy is to flatten the data structure producing a non-hierarchical data
structure where its keys represent endpoints (using dot-notation and colons to
separate (and denote) nested hash keys and array indices respectively) within
the structure.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
