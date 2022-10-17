# NAME

Data::Page::Nav - Module for pages navigation

# SYNOPSIS

    my $page = Data::Page::Nav->new;
    $page->total_entries(110);
    $page->entries_per_page(10);
    $page->current_page(4);
    $page->number_of_pages(5);

    # join all pages
    print join '-', $page->pages_nav; # 2-3-4-5-6

    # first navigation page 
    print $page->first_nav_page; # 2

    # last navigation page 
    print $page->last_nav_page; # 6  

Or

    my $total_entries = 110;
    my $entries_per_page = 10;
    my $current_page = 4;
    my $number_of_pages = 5;

    my $page = Data::Page::Nav->new(
        $total_entries, 
        $entries_per_page, 
        $current_page, 
        $number_of_pages
    );

    # join all pages
    print join '-', $page->pages_nav; # 2-3-4-5-6

    # first navigation page 
    print $page->first_nav_page; # 2

    # last navigation page 
    print $page->last_nav_page; # 6 

# DESCRIPTION

This module simply provides methods for you to create navigation of pages, using as a base the module Data::Page.

# METHODS

## pages_nav

This method returns the numbers in an array or arrayref depending on the context, too it can set the number of pages, but is optional:

    # if the current page is 7
    print join '-', $page->pages_nav;    # 3-4-5-6-7-8-9-10-11-12
    print join '-', $page->pages_nav(3); # 6-7-8
    print join '-', $page->pages_nav(7); # 4-5-6-7-8-9-10
    
## first_nav_page

This method returns the first value in the list returned by pages_nav, too it can set the number of pages, but is optional:

    # if the current page is 7
    print $page->first_nav_page;    # 3
    print $page->first_nav_page(3); # 6
    print $page->first_nav_page(7); # 4
    
## last_nav_page

This method returns the last value in the list returned by pages_nav, too it can set the number of pages, but is optional:

    # if the current page is 7
    print $page->last_nav_page;    # 12
    print $page->last_nav_page(3); # 8
    print $page->last_nav_page(7); # 10
    
## More methods

The other methods are the same as the Data::Page, and you can see them in [Data::Page METHODS](https://metacpan.org/pod/Data::Page#METHODS)

# SEE ALSO
 
[Data::Page](https://metacpan.org/pod/Data::Page)
 
# AUTHOR
 
Lucas Tiago de Moraes `lucastiagodemoraes@gmail.com`
 
# COPYRIGHT AND LICENSE
 
This software is copyright (c) 2022 by Lucas Tiago de Moraes.
 
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
