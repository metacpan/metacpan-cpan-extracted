package Data::Page::Pagination; ## no critic (TidyCode)

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Int ArrayRef);
use List::Util qw(min max);
use namespace::autoclean;
use syntax qw(method);

our $VERSION = '0.006';

subtype IntGreaterThan2 => (
    as Int,
    where { $_ > 2 },
);

subtype IntGreaterThan0 => (
    as Int,
    where { $_ > 0 },
);

class_type DataPage => {
    class => 'Data::Page',
};

has page => (
    is       => 'ro',
    isa      => 'DataPage',
    required => 1,
);

# methods that call page only
method current_page          { return $self->page->current_page }
method first_page            { return $self->page->first_page }
method last_page             { return $self->page->last_page }
method visible_previous_page { return defined $self->page->previous_page }
method visible_next_page     { return defined $self->page->next_page }

method previous_page {
    return
        $self->page->previous_page
        || $self->current_page;
}

method next_page {
    return
        $self->page->next_page
        || $self->current_page;
}

has page_numbers => (
    is       => 'ro',
    isa      => 'IntGreaterThan2',
    required => 1,
);

has max_list_length => (
    is       => 'rw',
    isa      => Int,
    init_arg => undef,
    lazy     => 1,
    default  => method {
        return int +( $self->page_numbers - 1 ) / 2
    },
);

has previous_pages => (
    is       => 'rw',
    isa      => ArrayRef['IntGreaterThan0'],
    init_arg => undef,
    lazy     => 1,
    default  => method {
        return [
            max(
                $self->first_page + 1,
                $self->current_page - $self->max_list_length
            ) .. $self->current_page - 1
        ];
    },
);

has next_pages => (
    is       => 'rw',
    isa      => ArrayRef['IntGreaterThan0'],
    init_arg => undef,
    lazy     => 1,
    default  => method {
        return [
            $self->current_page + 1
            .. min(
                $self->last_page - 1,
                $self->current_page + $self->max_list_length
            )
        ];
    },
);

method visible_first_page {
    return
        $self->current_page == $self->first_page + 1
        || !! @{ $self->previous_pages };
}

method visible_last_page {
    return
        $self->current_page == $self->last_page - 1
        || !! @{ $self->next_pages };
}

method visible_hidden_previous {
    return
        $self->visible_previous_page
        && @{ $self->previous_pages }
        && $self->previous_pages->[0] != $self->first_page + 1;
}

method visible_hidden_next {
    return
        $self->visible_next_page
        && @{ $self->next_pages }
        && $self->next_pages->[-1] != $self->last_page - 1;
}

method render_plaintext {
    return join q{ },
        $self->visible_previous_page   ? $self->previous_page . q{<} : (),
        $self->visible_first_page      ? $self->first_page           : (),
        $self->visible_hidden_previous ? q{..}                       : (),
        @{ $self->previous_pages },
        q{[} . $self->current_page . q{]},
        @{ $self->next_pages },
        $self->visible_hidden_next     ? q{..}                       : (),
        $self->visible_last_page       ? $self->last_page            : (),
        $self->visible_next_page       ? q{>} . $self->next_page     : ();
}

__PACKAGE__->meta->make_immutable;

# $Id$

1;

__END__

=head1 NAME

Data::Page::Pagination - calculates the pagination view

=head1 VERSION

0.006

=head1 SYNOPSIS

    require Data::Page::Pagination;
    require Data::Page;

    my $p = Data::Page::Pagination->new(
        page         => Data::Page->new(110, 10, 6),
        page_numbers => 11,
    );

    $p->visible_previous_page;    # 5<    ( $p->previous_page )
    $p->visible_first_page;       # 1     ( $p->first_page )
    $p->visible_hidden_previous;  # ..
    @{ $p->previous_pages };      # 3 4 5 ( max_length = $p->max_list_length )
    $p->page->current_page;       # 6     ( $p->current_page )
    @{ $p->next_pages };          # 7 8 9 ( max_length = $p->max_list_length )
    $p->visible_hidden_next,      # ..
    $p->visible_last_page;        # 11    ( $p->last_page )
    $p->visible_next_page;        # >7    ( $p->next_page )

    $p->render_plaintext eq '5< 1 .. 3 4 5 [6] 7 8 9 .. 11 >7';

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 DESCRIPTION

This module calculates the pagination view using a Date::Page object.
The provided methods are simple enough to use them in a template system.

=head1 SUBROUTINES/METHODS

=head2 method new

"page_numbers" is the count of pages for directly access.

    my $pagination = Data::Page::Pagination->new(
        page         => Data::Page->new(...),
        page_numbers => $integer_greater_than_2,
    );

=head2 method current_page

Returns the number of the current page

    $positive_integer = $pagination->current_page;

=head2 method max_list_length

Returns the maximal length of the list
that can be left or right of the current page.

    $positive_integer_or_zero = $pagination->max_list_length;

=head2 method visible_previous_page, visible_last_page

Returns boolean true if there is a previous/last page.

    $boolean = $pagination->visible_previous_page;
    $boolean = $pagination->visible_last_page;

=head2 method previous_page, last_page

Returns the number of the previous/last page.

    $positive_integer = $pagination->previous_page;
    $positive_integer = $pagination->last_page;

=head2 method visible_first_page, visible_last_page

Returns boolean true if the current page is not the fist/last page.

    $boolean = $pagination->visible_first_page;
    $boolean = $pagination->visible_last_page;

=head2 method first_page, last_page

Returns the number of the first/last page.

    $positive_integer = $pagination->first_page;
    $positive_integer = $pagination->last_page;

=head2 method visible_hidden_previous, visible_hidden_next

Returns boolean true if more pages then max_list_length pages
are between first/last page and current page.

    $boolean = $pagination->visible_hiddden_previous;
    $boolean = $pagination->visible_hiddden_next;

=head2 method previous_pages, next_pages

Returns the page numbers before/after the current page,
not more then max_list_length.

    $array_ref = $pagination->previous_pages;
    $array_ref = $pagination->next_pages;

=head2 method render_plaintext

Returns the test output.

    $string = $pagination->render_plaintext;

=head1 DIAGNOSTICS

Moose exceptions

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<Moose|Moose>

L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>

L<MooseX::StrictConstructor|MooseX::StrictConstructor>

L<MooseX::Types::Moose|MooseX::Types::Moose>

L<List::Util|List::Util>

L<namespace::autoclean|namespace::autoclean>

L<syntax|syntax>

L<Syntax::Feature::Method|Syntax::Feature::Method>

=head1 INCOMPATIBILITIES

none

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<Data::Page|Data::Page>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 - 2015,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
