package Data::Paginator;
$Data::Paginator::VERSION = '0.08';
use Moose;

# ABSTRACT: Pagination with Moose

use Data::Paginator::Types qw(PositiveInt);
use MooseX::Types::Moose qw(Maybe);


has current_page => (
    is => 'ro',
    isa => 'Num',
    default => 1
);

has current_set => (
    is => 'ro',
    isa => Maybe[PositiveInt],
    lazy_build => 1
);


has entries_per_page => (
    is => 'ro',
    isa => PositiveInt,
    required => 1
);


has last_page => (
    is => 'ro',
    isa => PositiveInt,
    lazy_build => 1
);


has next_set => (
    is => 'ro',
    isa => Maybe[PositiveInt],
    lazy_build => 1
);


has pages_per_set => (
    is => 'ro',
    isa => Maybe[PositiveInt],
    predicate => 'has_pages_per_set'
);


has previous_set => (
    is => 'ro',
    isa => Maybe[PositiveInt],
    lazy_build => 1
);


has total_entries => (
    is => 'ro',
    isa => PositiveInt,
    required => 1
);

# This facilitates incorrect page numbers.
around 'current_page' => sub {
    my ($orig, $self) = @_;

    my $attr = $self->meta->find_attribute_by_name('current_page');
    my $val = $attr->get_value($self);
    if(!defined($val)) {
        $attr->set_value($self, 1);
        return 1
    } elsif($val < 1) {
        $attr->set_value($self, 1);
        return 1;
    } elsif($val > $self->last_page) {
        $attr->set_value($self, $self->last_page);
        return $self->last_page;
    }

    return $val;
};

sub _build_current_set {
    my ($self) = @_;

    return $self->set_for($self->current_page);
}

sub _build_last_page {
    my ($self) = @_;

    my $pages = $self->total_entries / $self->entries_per_page;
    my $last_page;

    if ($pages == int $pages) {
        $last_page = $pages;
    } else {
        $last_page = 1 + int($pages);
    }

    $last_page = 1 if $last_page < 1;
    return $last_page;
}

sub _build_next_set {
    my ($self) = @_;

    return undef unless $self->pages_per_set;

    my $next = $self->current_set * ($self->pages_per_set * $self->entries_per_page) + 1;
    return undef if $next > $self->total_entries;
    return $next;
}

sub _build_previous_set {
    my ($self) = @_;

    return undef unless $self->pages_per_set;
    my $cset = $self->current_set;
    return undef if $cset == 1;

    return ($cset - 2) * $self->pages_per_set * $self->entries_per_page + 1;
}


sub entries_on_this_page {
    my ($self) = @_;

    if ($self->total_entries == 0) {
        return 0;
    } else {
        return $self->last - $self->first + 1;
    }
}


sub first {
    my ($self) = @_;

    if ($self->total_entries == 0) {
        return 0;
    } else {
        return (($self->current_page - 1) * $self->entries_per_page) + 1;
    }
}


sub first_page {
    my ($self) = @_;
    return 1;
}


sub first_set {
    my ($self) = @_;

    if($self->has_pages_per_set) {
        return 1;
    }

    return undef;
}


sub last {
    my $self = shift;

    if ($self->current_page == $self->last_page) {
        return $self->total_entries;
    } else {
        return ($self->current_page * $self->entries_per_page);
    }
}


sub next_page {
    my $self = shift;

    $self->current_page < $self->last_page ? $self->current_page + 1 : undef;
}


sub page_for {
    my ($self, $num) = @_;

    return undef if $num > $self->total_entries || $num < 1;

    my $page = $num / $self->entries_per_page;
    if($page > int($page)) {
        return int($page) + 1;
    }

    return $page;
}


sub previous_page {
    my ($self) = @_;

    if ($self->current_page > 1) {
        return $self->current_page - 1;
    } else {
        return undef;
    }
}


sub set_for {
    my ($self, $num) = @_;

    return undef unless $self->has_pages_per_set;

    my $set = $num / $self->pages_per_set;
    if(int($set) != $set) {
        return int($set) + 1;
    }

    return $set;
}

sub skipped {
    my $self = shift;

    my $skipped = $self->first - 1;
    return 0 if $skipped < 0;
    return $skipped;
}


sub splice {
    my ($self, $array) = @_;

    my $top = @$array > $self->last ? $self->last : @$array;
    return () if $top == 0;    # empty
    return @{$array}[ $self->first - 1 .. $top - 1 ];
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Paginator - Pagination with Moose

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use Data::Paginator;

    my $pager = Data::Paginator->new(
        current_page => 1,
        entries_per_page => 10,
        total_entries => 100,
    );

    print "First page: ".$pager->first_page."\n";
    print "Last page: ".$pager->last_page."\n";
    print "First entry on page: ".$pager->first."\n";
    print "Last entry on page: ".$pager->last."\n";

=head1 DESCRIPTION

This is yet another pagination module.  It only exists because none of the
other pager modules are written using Moose.  Sometimes there is a Moose
feature – MooseX::Storage, in my case – that you need. It's a pain when
you can't use it with an existing module.  This module aims to be completely
compatible with the venerable L<Data::Page>.  In fact, it's a pretty blatant
copy of Data::Page, lifting code from some of it's methods.

=head1 SETS

This module provides behavior compatible with L<Data::PageSet>, allowing you
to break your pagination into sets.  For example, if you have a large number
of pages to show and would like to allow the user to 'jump' X pages at a time,
you can set the C<pages_per_set> attribute to X and populate the links in your
pagination control with the values from C<previous_set> and C<next_set>.

=head1 ATTRIBUTES

=head2 current_page

The current page.  Defaults to 1.  If you set this value to to a page number
lesser than or greater than the range of the pager, then 1 or the last_page
will be returned instead.  It is safe to pass this numbers like -1000 or 1000
when there are only 3 pages.

=head2 entries_per_page

The number of entries per page, required at instantiation.

=head2 last_page

Returns the number of the last page.  Lazily computed, so do not set.

=head2 next_set

Returns the number of the next set or undefined if there is no next.

=head2 pages_per_set

If you have a large number of pages to show and would like to allow the user
to 'jump' X pages at a time, you can set the C<pages_per_set> attribute to X
and populate the links in your pagination control with the values from
C<previous_set> and C<next_set>.

=head2 previous_set

Returns the set number of the previous set or undefined if there is no
previous set.

=head2 total_entries

The total number of entries this pager is covering.  Required at
instantiation.

=head2 first

Returns the number of the first entry on the current page.

=head2 first_page

Always returns 1.

=head1 METHODS

=head2 entries_on_this_page

Returns the number of entries on this page.

=head2 first_set

Returns 1 if this Paginator has pages_per_set.  Otherwise returns undef.

=head2 last

Returns the number of the last entry on the current page.

=head2 next_page

Returns the page number of the next page if one exists, otherwise returns
false.

=head2 page_for ($count)

Returns the page number that the $count item appears on.  Returns undef if
$count is outside the bounds of this Paginator.

=head2 previous_page

Returns the page number of the previous page if one exists, otherwise returns
undef.

=head2 set_for $page

Returns the set number of the specified page.  Returns undef if the page
exceeds the bounds of the Paginator.

=head2 splice

Takes in an arrayref and returns only the values which are on the current
page.

=head1 ACKNOWLEDGEMENTS

Léon Brocard and his work on L<Data::Page>.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
