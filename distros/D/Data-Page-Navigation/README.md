# NAME

Data::Page::Navigation - adds methods for page navigation link to Data::Page

# SYNOPSIS

    use Data::Page::Navigation;
    my $total_entries=180;
    my $entries_per_page = 10;
    my $pages_per_navigation = 10;
    my $current_page = 1;

    my $pager = Data::Page->new(
        $total_entries,
        $entries_per_page,
        $current_page
    );
    $pager->pages_per_navigation($pages_per_navigation);
    @list = $pager->pages_in_navigation($pages_per_navigation);
    #@list = qw/1 2 3 4 5 6 7 8 9 10/;

    $pager->current_page(9);
    @list = $pager->pages_in_navigation($pages_per_navigation);
    #@list = qw/5 6 7 8 9 10 11 12 13 14/;

# DESCRIPTION

Using this module instead of, or in addition to Data::Page, adds a few methods to Data::Page.

This modules allow you to get the array where page numbers of the number that you set are included.
The array is made so that a current page may come to the center as much as possible in the array. 

# METHODS

## pages\_per\_navigation

Setting the number of page numbers displayed on one page. default is 10

## pages\_in\_navigation(\[pages\_per\_navigation\])

This method returns an array (or array-ref in scalar context) where page numbers of the number that you set with pages\_per\_navigation are included.

## first\_navigation\_page

Returns the first page in the list returned by pages\_in\_navigation().

## last\_navigation\_page

Returns the last page in the list returned by pages\_in\_navigation().

# SEE ALSO

[Data::Page](https://metacpan.org/pod/Data%3A%3APage)

# AUTHOR

Masahiro Nagano &lt;kazeburo {at} gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
