[![Build Status](https://travis-ci.org/tokuhirom/Data-NestedParams.png?branch=master)](https://travis-ci.org/tokuhirom/Data-NestedParams)
# NAME

Data::NestedParams - entry\[title\]=foo&tags\[\]=art&tags\[\]=modern

# SYNOPSIS

    use Data::NestedParams;

    my $expanded = expand_nested_params(
        [
            'entry[title]' => 'foo',
            'tags[]' => 'art',
            'tags[]' => 'modern',
        ]
    );
    # $expanded = { entry => {title => 'foo'}, tags => ['art', 'modern'] };

# DESCRIPTION

Ruby on Rails has a nice feature to create nested parameters that help with the organization of data in a form - parameters can be an arbitrarily deep nested structure.

The way this structure is denoted is that when you construct a form the field names have a special syntax which is parsed.

# LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

# SEE ALSO

[Catalyst::Plugin::Params::Nested](https://metacpan.org/pod/Catalyst::Plugin::Params::Nested), [CGI::Expand](https://metacpan.org/pod/CGI::Expand)
[https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L90](https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L90)
