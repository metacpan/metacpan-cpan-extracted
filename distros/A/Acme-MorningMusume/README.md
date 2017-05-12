# NAME

Acme::MorningMusume - All about Japanese pop star "Morning Musume"

# SYNOPSIS

    use Acme::MorningMusume;

    my $musume = Acme::MorningMusume->new;

    # retrieve the members on their activities
    my @members              = $musume->members;             # retrieve all
    my @active_members       = $musume->members('active');
    my @graduate_members     = $musume->members('graduate');
    my @at_some_time_members = $musume->members(DateTime->now->subtract(years => 5));

    # retrieve the members under some conditions
    my @sorted_by_age        = $musume->sort('age', 1);
    my @sorted_by_class      = $musume->sort('class', 1);
    my @selected_by_age      = $musume->select('age', 18, '>=');
    my @selected_by_class    = $musume->select('class', 5, '==');

# DESCRIPTION

"Morning Musume" is one of highly famous Japanese pop stars.

It consists of many pretty girls and has been known as a group which
members change one after another so frequently that people can't
completely tell who is who in the group.

This module, Acme::MorningMusume, provides an easy method to catch up
with Morning Musume.

# METHODS

## new

>     my $musume = Acme::MorningMusume->new;
>
> Creates and returns a new Acme::MorningMusume object.

## members ( $type )

>     # $type can be one of the values below:
>     #  + active              : active members
>     #  + graduate            : graduate members
>     #  + DateTime object     : members at the time passed in
>     #  + undef               : all members
>
>     my @members = $musume->members('active');
>
> Returns the members as a list of the [Acme::MorningMusume::Base](https://metacpan.org/pod/Acme::MorningMusume::Base)
> based object represents each member. See also the documentation of
> [Acme::MorningMusume::Base](https://metacpan.org/pod/Acme::MorningMusume::Base) for more details.

## sort ( $type, $order \[ , @members \] )

>     # $type can be one of the values below:
>     #  + age   :  sort by age
>     #  + class :  sort by class
>     #
>     # $order can be a one of the values below:
>     #  + something true value  :  sort in descending order
>     #  + something false value :  sort in ascending order
>
>     my @sorted_members = $musume->sort('age', 1); # sort by age in descending order
>
> Returns the members sorted by the _$type_ field.

## select ( $type, $number, $operator \[, @members\] )

>     # $type can be one of the same values above:
>     my @selected_members = $musume->select('age', 18, '>=');
>
> Returns the members satisfy the given _$type_ condition. _$operator_
> must be a one of '==', '>=', '<=', '>', and '<'. This method compares
> the given _$type_ to the member's one in the order below:
>
>     $number $operator $member_value

# SEE ALSO

- MORNING MUSUME -Hello! Project-

    [http://www.helloproject.com/](http://www.helloproject.com/)

- Morning Musume - Wikipedia

    [http://en.wikipedia.org/wiki/Morning\_Musume](http://en.wikipedia.org/wiki/Morning_Musume)

- [Acme::MorningMusume::Base](https://metacpan.org/pod/Acme::MorningMusume::Base)

# AUTHOR

- Kentaro Kuribayashi <kentaro@cpan.org>
- Kaneko Tatsuya [https://github.com/catatsuy](https://github.com/catatsuy)

# COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) 2005 - 2013, Kentaro Kuribayashi
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
