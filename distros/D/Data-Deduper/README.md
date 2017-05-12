# NAME

Data::Deduper - remove duplicated item from array

# SYNOPSIS

    use Data::Deduper;
    my @data = (1, 2, 3);
    my $dd = Data::Deduper->new(
        expr => sub { my ($a, $b) = @_; $a eq $b },
        size => 3,
        data => \@data,
    );
    # show only 4. because 4 is newer.
    for ($dd->dedup(3, 4)) {
        print $_;
    }
    # show 2 3 4 in whole items. max size of items is 3.
    for ($dd->data) {
        print $_;
    }

# DESCRIPTION

Data::Deduper removes duplicated items in array. This is useful for fetching RSS/Atom feed continual.

# INTERFACE

## `Data::Deduper->new( expr => $expr, size => $size, data => $data )`

Creates a deduper instance.
$expr is specified as expr of grep. $size mean max size of array. $data is
initial array.

## `$deduper->init( \\@data )`

Reset items. return whole items.

## `$deduper->deup( \\@data )`

Dedup items. each item in @data will be checked whether is duplicate item. And if the item is not duplicated, it add to the items.
Return items added only. Note that return ignore duplicated items.

## `$deduper->data()`

Return whole items.

# AUTHOR

Yasuhiro Matsumoto <mattn.jp@gmail.com>

# SEE ALSO

[XML::Feed::Deduper](http://search.cpan.org/perldoc?XML::Feed::Deduper)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
