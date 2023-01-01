[![Actions Status](https://github.com/TakeAsh/p-Data-HTML-TreeDumper/actions/workflows/test.yml/badge.svg)](https://github.com/TakeAsh/p-Data-HTML-TreeDumper/actions)
# NAME

[Data::HTML::TreeDumper](https://metacpan.org/pod/Data%3A%3AHTML%3A%3ATreeDumper) - dumps perl data as HTML5 open/close tree

# SYNOPSIS

    use Data::HTML::TreeDumper;
    my $td = Data::HTML::TreeDumper->new(
        ClassKey    => 'trdKey',
        ClassValue  => 'trdValue',
        MaxDepth    => 8,
    );
    my $obj = someFunction();
    print $td->dump($obj);

There are [some samples](https://raw.githack.com/TakeAsh/p-Data-HTML-TreeDumper/master/examples/output/sample1.html).

# DESCRIPTION

Data::HTML::TreeDumper dumps perl data as HTML5 open/close tree.

# CLASS METHODS

## new(\[option => value, ...\])

Creates a new Data::HTML::TreeDumper instance.
This method can take a list of options.
You can set each options later as the properties of the instance.

### ClassKey, ClassValue, ClassOrderedList, ClassUnorderedList

CSS class names for each items.
OrderedList is for arrays.
UnorderedList is for hashes.

### StartOrderedList

An integer to start counting from for arrays.
Default is 0.

### MaxDepth

Stops following object tree at this level, and show "..." instead.
Default is 8.
Over 32 is not acceptable to prevent memory leak.

# INSTANCE METHODS

## dump($object)

Dumps perl data as a HTML5 open/close tree.

# SOURCE

Source repository is at [p-Data-HTML-TreeDumper](https://github.com/TakeAsh/p-Data-HTML-TreeDumper) .

# SEE ALSO

## Similar CPAN modules:

[Data::HTMLDumper](https://metacpan.org/pod/Data%3A%3AHTMLDumper), [Data::Dumper::HTML](https://metacpan.org/pod/Data%3A%3ADumper%3A%3AHTML), [Data::Format::Pretty::HTML](https://metacpan.org/pod/Data%3A%3AFormat%3A%3APretty%3A%3AHTML)

# LICENSE

Copyright (C) TakeAsh.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

[TakeAsh](https://github.com/TakeAsh/)
