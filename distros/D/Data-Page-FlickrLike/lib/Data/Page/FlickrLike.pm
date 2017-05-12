package Data::Page::FlickrLike;

use warnings;
use strict;
use 5.008_001;

use Exporter::Lite;
use Data::Page;

our $VERSION = '2.03';

our @EXPORT = qw( navigations );

our $InnerWindow = 3;
our $OuterWindow = 2;
our $MinLength   = 7;
our $GlueLength  = 2;


sub _get_min_fill {
    my ($page, $first_page, $last_page, $min) = @_;
    my $length = $last_page - $first_page + 1 < $min
               ? $last_page - $first_page + 1
               : $min;

    my $current_length = scalar @$page;
    return $length - $current_length;
}

sub Data::Page::navigations {
    my ($self, $args) = @_;
    my $nav;
    my $prev_skip = 1;
    my $next_skip = 1;

    my $inner = exists $args->{inner_window}
      ? $args->{inner_window}
      : $Data::Page::FlickrLike::InnerWindow;
    my $outer = exists $args->{outer_window}
      ? $args->{outer_window}
      : $Data::Page::FlickrLike::OuterWindow;
    my $min = exists $args->{min_length}
      ? $args->{min_length}
      : $Data::Page::FlickrLike::MinLength;
    my $glue_length = exists $args->{glue_length}
      ? $args->{glue_length}
      : $Data::Page::FlickrLike::GlueLength;

    my $current_page = $self->current_page;
    my $last_page    = $self->last_page;
    my $first_page   = $self->first_page;

    ## build the pages around current_page to begin with
    for (my $i = $current_page - $inner; $i <= $current_page + $inner ; $i++) {
        push @$nav, $i if $i >= $first_page && $i <= $last_page;
    }

    ## shortcut if we already take all the room
    if ($nav->[0] == $first_page && $nav->[-1] == $last_page) {
        return wantarray ? @$nav : $nav;
    }

    ## NOTE: there are some extra operations in there just in case $first_page != 1
    ## but, this shouldn't really be necessary...

    if ($nav->[0] == $first_page && $nav->[-1] != $last_page) {
        ## we're stuck at the beginning, check for $min_lengh
        my $min_fill = _get_min_fill($nav, $first_page, $last_page, $min);
        my $last = $nav->[-1];
        push @$nav, map { $last + $_ } (1 .. $min_fill);
    }

    ## stuck at the end: fill the beginning using $min_length
    elsif ($nav->[0] != $first_page && $nav->[-1] == $last_page) {
        my $min_fill = _get_min_fill($nav, $first_page, $last_page, $min);
        my $first = $nav->[0];
        unshift @$nav, reverse map { $first - $_ } (1 .. $min_fill);
    }

    ## now, care about extremities specifically
    my (@begin, @end);
    for (0 .. ($outer - 1)) {
        push @begin, $first_page + $_;
        push @end,   $last_page  - $_;
    }
    @end = reverse @end;

    ## we might need some glue
    if ($begin[-1] < $nav->[0] - 1) {
        my $to_glue = $nav->[0] - $begin[-1] - 1;
        if ($to_glue <= $glue_length) {
            ## we can glue!
            my $last = $begin[-1];
            push @begin, map { $last + $_ } (1 .. $to_glue);

        }
        else {
            push @begin, 0;
        }
    }
    if ($end[0] > $nav->[-1] + 1) {
        my $to_glue = $end[0] - $nav->[-1] - 1;
        if ($to_glue <= $glue_length) {
            ## we can glue!
            my $first = $end[0];
            unshift @end, reverse map { $first - $_ } (1 .. $to_glue);
        }
        else {
            unshift @end, 0;
        }
    }

    ## trim redundant items if they exist
    while (@begin && $begin[-1] >= $nav->[0]) {
        pop @begin;
    };
    while (@end && $end[0] && $end[0] <= $nav->[-1]) {
        shift @end;
    };

    $nav = [ @begin, @$nav, @end ];

    return wantarray ? @$nav : $nav;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Data::Page::FlickrLike - Generates flickr-like navigation links

=head1 SYNOPSIS

    use Data::Page;
    use Data::Page::FlickrLike;

    my $page = Data::Page->new();
    $page->total_entries($total_entries);
    $page->entries_per_page($entries_per_page);
    $page->current_page($current_page);
   
    print join (" ",
            map { $_ == 0
              ? q{<span>...</span>}
              : qq{<a href="/page/$_">$_</a>}
            } $page->navigations);  

    # 1*2 3 4 5 6 7 ... 76 77
    # 1 2 ... 10 11 12 13*14 15 16 ... 76 77
    # 1 2 ... 71 72 73 74 75 76 77*
    # Note: * means the current page

=head1 DESCRIPTION

Data::Page::FlickrLike is an extension to Data::Page to generate flickr-like
navigation links.

=head1 METHODS 

=over 4

=item navigations (Data::Page)

This method returns an array reference consisting of the the pages to display.

   $nav = $page->navigations

It calculates: how many pages should be displayed after the first and before 
the last page, whether or not there's a big enough gap between the first page
and the current page to put an ellipsis and more.
As the name of this modules says, the array ref should make it easy to generate
a "Flickr-Like" navigation.

This methods uses "0" to represent an ellipsis between two sets of page numbers.
For example, if you have enough pages, navigations() returns like this:

  [ 1, 2, 3, 4, 5, 6, 7, 0, 76, 77 ] 

So, to display an ellipsis(...) you would write:

    for my $num ($page->navigations) {
        if ($num == 0 ) {
            print "...";
        } else {
            print qq{<a href="/page/$_">$_</a>};
        }
    }

=back

=head1 CONFIGURATION VARIABLES

By default, navigation() generates an array reference to create the same pagination
than Flickr.com. But if you do not like this behavior, you can tweak the following
configuration variables:

=over 4

=item $Data::Page::FlickrLike::InnerWindow or $page->navigations({inner_window => $val})

Customises the minimum number of pages before and after the current page.

=item $Data::Page::FlickrLike::OuterWindow or $page->navigations({outer_window => $val}) 

Customises the number of pages at the start and end of the pager.

=item $Data::Page::FlickrLike::MinLength or $page->navigations({min_length => $val})

If current page is adjacent to an edge, the number of pages returned around current
page will be extended to meet c<$Data::Page::FlickrLike::MinLength>

=item $Data::Page::FlickrLike::GlueLength or $page->navigations({glue_length => $val})

Customises the glue capability of the page. "Gluing" means that if the set
containing the current page is isolated of an edge, we merge the two sets
together by adding the interleaved pages to form a bigger set. This variable defines
the maximum distance between two sets required to glue them together.

For example, these "3g" and "4g" are displayed because of the glue length (= 2).

 1   2   3   4   5   6*  7   8   9     ...   21   22
 1   2   3g  4   5   6   7*  8   9   10     ...   21   22
 1   2   3g  4g  5   6   7   8*  9   10   11     ...  21   22 
 1   2     ...   5   6   7   8   9*  10   11   12     ...   21   22

 (* represents the current page)

=back

=head1 AUTHOR

Masayoshi Sekimura E<lt>sekimura@cpan.orgE<gt>
Yann Kerherve E<lt>yannk@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Data::Page>, L<Data::Page::Navigation>, http://flickr.com/

