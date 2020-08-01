[![Build Status](https://travis-ci.org/worthmine/Caller-Easy.svg?branch=master)](https://travis-ci.org/worthmine/Caller-Easy)
# NAME

Caller::Easy - less stress to remind returned list from CORE::caller()

# SYNOPSIS

    use Caller::Easy; # Module name is temporal

    # the way up to now
    sub foo {
       my $subname = (caller(0))[3];
    }

    # with OO
    sub foo {
       my $subname = Caller::Easy->new(0)->subroutine();
    }

    # like a function imported
    sub foo {
       my $subname = caller(0)->subroutine();
    }

All the above will return 'main::foo'

Now you can choise the way you much prefer

# DESCRIPTION

Caller::Easy is the easiest way for using functions of `CORE::caller()`

it produces the easier way to get some info from `caller()`
with no having to care about namespace.

# ATTENTION

We can NOT write like below:

    my $subname = caller1->subroutine; # like (caller1)[3];

This would be considered a Bareword.

## Constructor and initialization

### new()

You can set no argument then it returns the object reference in scalar context.

In list context, you can get just only ( $package, $filename, $line ).

if you set depth(level) like `new(1)`, you can get more info from caller
( $package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext,
$is\_require, $hints, $bitmask, $hinthash )
directly with same term for `CORE::caller()`

To be strictly, you can set `depth` parameter like `new( depth => 1 )`
but we can forget it, just set the natural number you want to set.

## Methods (All of them is read-only)

### caller()

It is implemented to be alias of `new()` but it doesn't matter.

this method is imported to your packages automatically when you `use Caller::Easy;`

So you can use much freely this method like if there is no module imported.

### package()

You can get package name instead of `(caller(n))[0]`

### filename()

You can get file name instead of `(caller(n))[1]`

### line()

You can get the line called instead of `(caller(n))[2]`

### subroutine()

You can get the name of subroutine instead of `(caller(n))[3]`

### hasargs(), wantarray(), evaltext(), is\_require(), hints(), bitmask(), hinthash()

Please read [CORE::caller](http://perldoc.perl.org/functions/caller.html)

**Don't ask me**

### args()

You can get the arguments of targeted subroutine instead of `@DB::args`

This method is the **unique** point of this module.

### depth()

You can get what you set.

# TODO

- using Moose is a bottle-neck

    I made this module in a few days with Moose because it's the easiest way.
    It will be too heavy for some environments.

    To abolish Moose is a TODO if this module will be popular.

- rewite the tests

    I don't know well about [CORE::caller](http://perldoc.perl.org/functions/caller.html)!

    Why I have written this module is
    Just only I can't remember what I wanna get with something number from caller()
    without some reference.

    So some of tests may not be appropriate.

- rename the module

    I have to find the name that deserve it.

- rewite the POD

    I know well that my English is awful.

# SEE ALSO

- [CORE::caller](http://perldoc.perl.org/functions/caller.html)

    If you are confused with this module, Please read this carefully.

- [Perl6::Caller](http://search.cpan.org/~ovid/Perl6-Caller/lib/Perl6/Caller.pm)

    One of better implements for using something like this module.

    The reason why I reinvent the wheel is that this module has no github repository.

- [Safe::Caller](https://metacpan.org/pod/Safe::Caller)

    The newest implement for something like this module.

    It has github repository but usage is limited.

# LICENSE

Copyright (C) Yuki Yoshida(worthmine).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

[Yuki Yoshida(worthmine)](https://github.com/worthmine)
