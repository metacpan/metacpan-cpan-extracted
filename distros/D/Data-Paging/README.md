[![Build Status](https://travis-ci.org/ainame/p5-Data-Paging.png?branch=master)](https://travis-ci.org/ainame/p5-Data-Paging)
# NAME

Data::Paging - pagination helper for view

# SYNOPSIS

    use Data::Paging;
    

    my $paging = Data::Paging->create({
        entries      => $entries,
        total_count  => 100,
        per_page     => 30,
        current_page => 1,
    });
    

    $paging->has_next;    #=> TRUE
    $paging->has_prev;    #=> FALSE
    $paging->prev_page;   #=> 0
    $paging->next_page;   #=> 2
    $paging->begin_count; #=> 30
    $paging->end_count;   #=> 30
    ...
    

    # If you use simple template engine like HTML::Template,
    # you should use Data::Paging with renderer.
    my $paging = Data::Paging->create({
        entries      => $entries,
        total_count  => 100,
        per_page     => 30,
        current_page => 1,
    }, '-NeighborLink');  # NeighborLink is the bundled renderer. You can load renderer like Plack::Middleware.
    

    $paging->render #=> output HASHREF value

# DESCRIPTION

Data::Paging = Data::Page + Data::Page::Navigation + Data::Page::NoTotalEntries

Data::Paging is the helper library for implementation of paging.
Especialy, Data::Paging class is the factory class of Data::Paging::Collection.

Data::Paging::Collection is the accessor of many pagination parameters like Data::Page, and then, that contain other Data::Page's brother features.

In addition, Data::Paging has renderer mechanism. That is convenience feature, when the application use rigid template engine like HTML::Template. Data::Paging bundle two default renderer to create common paging UI, also Data::Paging make application be able to define original renderer and load it as you like.

A point to notice is Data::Paging always has next or prev page number. This feature difference from Data::Page' one. You should use has\_next/has\_prev method, when check whether next\_page/prev\_page exist or not.

# LICENSE

Copyright (C) ainame.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ainame <s.namai.2012@gmail.com>
