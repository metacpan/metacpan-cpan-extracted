package Data::Pagination;

use strict;

our $VERSION = '0.44';

# {{{ new()

# Constructor.
# Making all calculations and storing results at class properties.
# Param int $total_entries Total number of entries (>= 1)
# Param int $entries_per_page Number of entries per page (>= 1)
# Param int $pages_per_set Number of pages per set (>= 1)
# Param int $current_page Current number of page

sub new {
    my ($class, $total_entries, $entries_per_page, $pages_per_set, $current_page) = @_;

    my $self = bless {} => $class;

    # total number of entries (>= 1) (copied from arguments)
    $self->{total_entries} = $total_entries;

    # number of entries per page (>= 1) (copied from arguments)
    $self->{entries_per_page} = $entries_per_page;

    # number of pages per set (>= 1) (copied from arguments)
    $self->{pages_per_set} = $pages_per_set;

    # total number of pages (>= 1)
    $self->{total_pages} = int(($self->{total_entries} - 1) / $self->{entries_per_page}) + 1;

    # current number of page (>= 1) (corrected)
    $self->{current_page} = $current_page;
    if ($self->{current_page} < 1) {
        $self->{current_page} = 1;
    } elsif ($self->{current_page} > $self->{total_pages}) {
        $self->{current_page} = $self->{total_pages};
    }

    # previous number of page (>= 1 or undef)
    $self->{prev_page} = $self->{current_page} - 1;
    if ($self->{prev_page} < 1) {
        $self->{prev_page} = undef;
    }

    # next number of page (>= 1 or undef)
    $self->{next_page} = $self->{current_page} + 1;
    if ($self->{next_page} > $self->{total_pages}) {
        $self->{next_page} = undef;
    }

    # start position of current set (>= 1)
    $self->{start_of_set} = int(($self->{current_page} - 1) / $self->{pages_per_set}) * $self->{pages_per_set} + 1;

    # end position of current set (>= 1)
    $self->{end_of_set} = $self->{start_of_set} + $self->{pages_per_set} - 1;
    if ($self->{end_of_set} > $self->{total_pages}) {
        $self->{end_of_set} = $self->{total_pages};
    }

    # numbers of set (one or more numbers in array)
    $self->{numbers_of_set} = [];
    for (my $i = $self->{start_of_set}; $i <= $self->{end_of_set}; ++$i) {
        push(@{$self->{numbers_of_set}}, $i);
    }

    # nearest page number of the previous set (>= 1 or undef)
    $self->{page_of_prev_set} = $self->{start_of_set} - 1;
    if ($self->{page_of_prev_set} < 1) {
        $self->{page_of_prev_set} = undef;
    }

    # nearest page number of the next set (>= 1 or undef)
    $self->{page_of_next_set} = $self->{end_of_set} + 1;
    if ($self->{page_of_next_set} > $self->{total_pages}) {
        $self->{page_of_next_set} = undef;
    }

    # starting position of the slice (>= 0)
    $self->{start_of_slice} = ($self->{current_page} - 1) * $self->{entries_per_page};

    # ending position of the slice (>= 0)
    $self->{end_of_slice} = $self->{start_of_slice} + $self->{entries_per_page} - 1;
    if ($self->{end_of_slice} > $self->{total_entries} - 1) {
        $self->{end_of_slice} = $self->{total_entries} - 1;
    }

    # length of the slice (>= 1)
    $self->{length_of_slice} = $self->{end_of_slice} - $self->{start_of_slice} + 1;

    return $self;
}

# }}}

1;

__END__

=head1 NAME

Data::Pagination - Paginal navigation on some data

=head1 SYNOPSIS

  use Data::Pagination;

  # previously needs to check total number of entries. it can be
  # count of SQL records or length of array or something other.
  #
  # example: SELECT count(*) ...
  #
  # note: if no records exists, then no needs to continue processing.
  #       enough to tell the user about that.

  my $pg = Data::Pagination->new(
     $total_entries,    # - total number of entries (>= 1)
                        #
     $entries_per_page, # - how much records (>= 1) maximum you want
                        #   to see on one page.
                        #
     $pages_per_set,    # - how much pages you want to see in pages
                        #   set. if you don't want to use this
                        #   feature, then don't use, but some number
                        #   (>= 1) must be presented here.
                        #
     $current_page      # - user specified number of page from
                        #   request. must contain some integer
                        #   number (don't forget to check this).
  );

  # now, for getting slice of data, use properties from
  # "slice params" group.
  #
  # example: SELECT ...
  #          LIMIT $pg->{length_of_slice} OFFSET $pg->{start_of_slice}

  # all properties from "statistics" group are copied from arguments,
  # and with some properties from other groups can be used for
  # shown some statistic information to user.
  #
  # example:
  #
  #                 $pg->{total_pages}
  #                /   $pg->{total_entries}
  # Total pages: 20   /
  # Total records: 200
  # Shown from 61 to 70 records
  #              \     \
  #               \     $pg->{start_of_slice} + 1
  #                $pg->{end_of_slice} + 1
  #

  # properties from "pages control" and "pages set control" intended
  # for construction paginal navigation panel.
  #
  # example (simple):
  #
  #                   <-- previous page | next page -->
  #                         /                   \
  #                 $pg->{prev_page}       $pg->{next_page}
  #
  # example (advanced):
  #
  #                      $pg->{current_page}
  #                               |
  #         $pg->{prev_page}      |         $pg->{next_page}
  #                   \           |                /
  #           <<       <       6 [7] 8 9 10       >       >>
  #           /               /           \                \
  # $pg->{page_of_prev_set}  /             \  $pg->{page_of_next_set}
  #                         /               \
  #             $pg->{start_of_set}     $pg->{end_of_set}
  #                        |                 |
  #                     [ $pg->{numbers_of_set} ]
  #

=head1 DESCRIPTION

This class intended for organization of paginal navigation on
some data. Basically intended for construction of paginal navigation
panels on web sites.

=head1 METHODS

=over 4

=item B<$pg = Data::Pagination-E<gt>new($total_entries, $entries_per_page, $pages_per_set, $current_page)>

Making all calculations and storing results at class properties.

Arguments:

=over 4

=item *

B<$total_entries> - total number of entries (>= 1)

=item *

B<$entries_per_page> - number of entries per page (>= 1)

=item *

B<$pages_per_set> - number of pages per set (>= 1)

=item *

B<$current_page> - current number of page

=back

Note: all arguments are required and must contains only integer
numbers.

=back

=head1 PROPERTIES

Slice params:

=over 4

=item *

B<$pg-E<gt>{start_of_slice}> - start position of the slice (>= 0)

=item *

B<$pg-E<gt>{end_of_slice}> - end position of the slice (>= 0)

=item *

B<$pg-E<gt>{length_of_slice}> - length of the slice (>= 1)

=back

Statistics:

=over 4

=item *

B<$pg-E<gt>{total_entries}> - total number of entries (>= 1)
(copied from arguments)

=item *

B<$pg-E<gt>{entries_per_page}> - number of entries per page (>= 1)
(copied from arguments)

=item *

B<$pg-E<gt>{pages_per_set}> - number of pages per set (>= 1)
(copied from arguments)

=back

Pages control:

=over 4

=item *

B<$pg-E<gt>{total_pages}> - total number of pages (>= 1)

=item *

B<$pg-E<gt>{current_page}> - current number of page (>= 1)
(corrected)

=item *

B<$pg-E<gt>{prev_page}> - previous number of page  (>= 1)
or undefined, if haven't place to be

=item *

B<$pg-E<gt>{next_page}> - next number of page (>= 1)
or undefined, if haven't place to be

=back

Pages set control:

=over 4

=item *

B<$pg-E<gt>{start_of_set}> - start position of current set (>= 1)

=item *

B<$pg-E<gt>{end_of_set}> - end position of current set (>= 1)

=item *

B<$pg-E<gt>{page_of_prev_set}> - nearest page number of the previous
set (>= 1) or undefined, if haven't place to be

=item *

B<$pg-E<gt>{page_of_next_set}> - nearest page number of the next set
(>= 1) or undefined, if haven't place to be

=item *

B<$pg-E<gt>{numbers_of_set}> - numbers of set (one or more numbers in array)

=back

=head1 NOTES

=over 4

=item *

Most simple way to check, needs to show navigation panel or not, is
checking $pg-E<gt>{total_pages} property. Needs only, if this
property more then 1.

=item *

$pg-E<gt>{prev_page}, $pg-E<gt>{next_page},
$pg-E<gt>{page_of_prev_set} and $pg-E<gt>{page_of_next_set}
properties must be checked for undefined value before using.

=item *

All results are in numbers, and you can construct paginal navigation
panels with any design and can use templates processors
(as TT and others). For that you only needs to transfer class object
to template processor params.

=back

=head1 SEE ALSO

L<Data::Page|Data::Page>
L<Data::Paginate|Data::Paginate>
L<Data::Paginated|Data::Paginated>
L<HTML::Paginator|HTML::Paginator>
L<Data::SimplePaginator|Data::SimplePaginator>

=head1 AUTHOR

Andrian Zubko E<lt>ondr@mail.ruE<gt>

=cut
