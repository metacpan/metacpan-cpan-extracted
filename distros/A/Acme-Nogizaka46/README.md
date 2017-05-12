# NAME

Acme::Nogizaka46 - All about "Nogizaka46"

# SYNOPSIS

    use Acme::Nogizaka46;

    my $nogizaka = Acme::Nogizaka46->new;

    # retrieve the members on their activities
    my @members              = $nogizaka->members;             # retrieve all
    my @active_members       = $nogizaka->members('active');
    my @graduate_members     = $nogizaka->members('graduate');
    my @at_some_time_members = $nogizaka->members(DateTime->now->subtract(years => 5));

    # retrieve the members under some conditions
    my @sorted_by_age        = $nogizaka->sort('age', 1);
    my @sorted_by_class      = $nogizaka->sort('class', 1);
    my @selected_by_age      = $nogizaka->select('age', 18, '>=');
    my @selected_by_class    = $nogizaka->select('class', 5, '==');

# DESCRIPTION

"Nogizaka46" is a Japanese female idol group.

This module, Acme::Nogizaka46, provides an easy method to catch up
with Nogizaka46.

# METHODS

## new

>     my $nogizaka = Acme::Nogizaka46->new;
>
> Creates and returns a new Acme::Nogizaka46 object.

## members ( $type )

>     # $type can be one of the values below:
>     #  + active              : active members
>     #  + graduate            : graduate members
>     #  + DateTime object     : members at the time passed in
>     #  + undef               : all members
>
>     my @members = $nogizaka->members('active');
>
> Returns the members as a list of the [Acme::Nogizaka46::Base](https://metacpan.org/pod/Acme::Nogizaka46::Base)
> based object represents each member. See also the documentation of
> [Acme::Nogizaka46::Base](https://metacpan.org/pod/Acme::Nogizaka46::Base) for more details.

## sort ( $type, $order \[ , @members \] )

>     # $type can be one of the values below:
>     #  + age   :  sort by age
>     #  + class :  sort by class
>     #
>     # $order can be a one of the values below:
>     #  + something true value  :  sort in descending order
>     #  + something false value :  sort in ascending order
>
>     my @sorted_members = $nogizaka->sort('age', 1); # sort by age in descending order
>
> Returns the members sorted by the _$type_ field.

## select ( $type, $number, $operator \[, @members\] )

>     # $type can be one of the same values above:
>     my @selected_members = $nogizaka->select('age', 18, '>=');
>
> Returns the members satisfy the given _$type_ condition. _$operator_
> must be a one of '==', '>=', '<=', '>', and '<'. This method compares
> the given _$type_ to the member's one in the order below:
>
>     $number $operator $member_value

# SEE ALSO

- Nogizaka46

    [http://www.nogizaka46.com/](http://www.nogizaka46.com/)

- Nogizaka46 - Wikipedia

    [https://en.wikipedia.org/wiki/Nogizaka46](https://en.wikipedia.org/wiki/Nogizaka46)

# AUTHOR

- Takaaki TSUJIMOTO <2gmon.t@gmail.com>

# COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) 2015, Takaaki TSUJIMOTO <2gmon.t@gmail.com>

Original Copyright (c) 2005 - 2013, Kentaro Kuribayashi
<kentaro@cpan.org>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
