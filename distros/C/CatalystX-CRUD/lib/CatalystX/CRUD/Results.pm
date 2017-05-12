package CatalystX::CRUD::Results;
use Moose;
with 'MooseX::Emulate::Class::Accessor::Fast';
use Carp;
use Data::Dump qw( dump );
use MRO::Compat;
use mro 'c3';

#use overload
#    '""'     => sub { return dump( $_[0]->serialize ) . "" },
#    'bool'   => sub {1},
#    fallback => 1;

__PACKAGE__->mk_ro_accessors(qw( count pager query results ));

our $VERSION = '0.57';

=head1 NAME

CatalystX::CRUD::Results - search results class

=head1 SYNOPSIS

 # in .tt file
 Your search returned [% results.count %] total hits.
 Your query was [% results.query %].
 You are on page [% results.pager.current_page %].
 [% FOREACH r IN results.results %]
  [% loop.count %]: [% r.name %]
 [% END %]

=head1 DESCRIPTION

CatalystX::CRUD::Results is a class for search results from a
CatalystX::CRUD::Controller.  See the do_search() method
in CatalystX::CRUD::Controller.

=head1 METHODS

The following read-only accessors are available:

=head2 count

Returns total number of results.

=head2 pager

Returns Data::Pageset object for paging through results.

=head2 query

Returns the search query.

=head2 results

Returns array ref of current found objects.

=cut

=head2 next

Returns next result. If results() is an arrayref, shift() is used.
Otherwise, the results() value is assumed to act like a 
CatalystX::CRUD::Iterator and its next() method will be called.

=cut

sub next {
    my $self = shift;
    return unless defined $self->results;

    if ( ref( $self->results ) eq 'ARRAY' ) {
        return shift @{ $self->{results} };
    }
    else {
        return $self->results->next;
    }
}

=head2 TO_JSON

Hook for the L<JSON> module so that you can pass a Results object
directly to encode_json(). Calls serialize() internally.

=cut

sub TO_JSON {
    my $self = shift;
    return $self->serialize();
}

=head2 serialize

Returns object as a hash ref. Objects are overloaded to call
Data::Dump::dump( $results->serialize ) in string context.

=cut

sub serialize {
    my $self = shift;

    #dump $self;
    my $r = { count => $self->count };

    # what might query be?
    my $q = $self->query;
    if ( blessed($q) ) {
        $r->{query} = "$q";
    }
    elsif ( ref $q eq 'CODE' ) {
        $r->{query} = $q->();
    }
    else {
        # stringify the Query object, overwrite 'query'.
        # we do this because some internal objects do not serialize.
        delete $q->{query};
        $q->{where} = delete $q->{query_obj};
        $q->{where} .= '';
        $r->{query} = $q;
    }

    my @results;
    if ( ref( $self->results ) eq 'ARRAY' ) {
        @results = @{ $self->{results} };
    }
    else {
        while ( my $i = $self->results->next ) {
            push @results, $i;
        }
    }

    # serialize results
    my @serialized;
    for my $i (@results) {
        my $s;
        if ( blessed($i) and $i->can('serialize') ) {
            $s = $i->serialize;
        }
        else {
            $s = "$i";
        }
        push @serialized, $s;
    }
    $r->{results} = \@serialized;

    return $r;
}

1;

__END__


=head1 AUTHOR

Peter Karman, C<< <perl at peknet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD

You can also look for information at:

=over 4

=item * Mailing List

L<https://groups.google.com/forum/#!forum/catalystxcrud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
