package Data::Page::NoTotalEntries;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.02';
use Class::Accessor::Lite 0.05 (
    new => 1,
    rw => [qw/has_next entries_per_page current_page entries_on_this_page/]
);

sub next_page {
    my $self = shift;
    $self->has_next ? $self->current_page + 1 : undef;
}

sub previous_page { goto &prev_page }
sub prev_page {
    my $self = shift;
    $self->current_page > 1 ? $self->current_page - 1 : undef;
}

sub first {
    my $self = shift;
    Carp::croak("'first' method requires 'entries_on_this_page'") unless defined $self->entries_on_this_page;

    if ( $self->entries_on_this_page == 0 ) {
        return 0;
    }
    else {
        return ( ( $self->current_page - 1 ) * $self->entries_per_page ) + 1;
    }
}

sub last {
    my $self = shift;
    Carp::croak("'last' method requires 'entries_on_this_page'") unless defined $self->entries_on_this_page;

    if ( !$self->has_next ) {
        if ($self->entries_on_this_page == 0) {
            return 0;
        } else {
            return $self->first + $self->entries_on_this_page - 1;
        }
    }
    else {
        return ( $self->current_page * $self->entries_per_page );
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Data::Page::NoTotalEntries - help when paging through sets of results without total entries

=head1 SYNOPSIS

  use Data::Page::NoTotalEntries;

=head1 DESCRIPTION

Data::Page::NoTotalEntries is a generic pager object, so it's very similar with L<Data::Page>.
But so Data::Page::NoTotalEntries doesn't support C<< $pager->total_entries >> and other some methods.

In sometime, I don't want to count total entries, because counting total entries from database are very slow.

=head1 METHODS

=over 4

=item my $pager = Data::Page::NoTotalEntries->new(%args);

Create new instance of Data::Page::NoTotalEntries.
You can initialize attributes at constructor with C<< %args >>.

=item $pager->next_page()

This method returns the next page number, if one exists. Otherwise
it returns undefined:

    if ($page->next_page) {
        print "Next page number: ", $page->next_page, "\n";
    }

=item $pager->previous_page()

This method returns the previous page number, if one exists. Otherwise
it returns undefined:

    if ($page->previous_page) {
        print "Previous page number: ", $page->previous_page, "\n";
    }

=item $pager->prev_page()

This is a alias for C<< $pager->previous_page() >>

=item $pager->first()

This method returns the number of the first entry on the current page.

=item $pager->last()

This method returns the number of the last entry on the current page.

=back

=head1 ATTRIBUTES

=over 4

=item has_next: Bool

Does this page has a next page?

=item entries_per_page: Int

The number of entries in each page.

=item current_page : Int

This attribute is the current page number:

=item entries_on_this_page: Int

This attribute is the number of entries on the current page

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<Data::Page> is a pager component but requires the number of total entries.

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
