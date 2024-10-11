[![Actions Status](https://github.com/kaz-utashiro/greple-stripe/actions/workflows/test.yml/badge.svg)](https://github.com/kaz-utashiro/greple-stripe/actions)
# NAME

App::Greple::stripe - Greple zebra stripe module

# SYNOPSIS

    greple -Mstripe [ module options -- ] ...

# VERSION

Version 1.00

# DESCRIPTION

[App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) is a module for [greple](https://metacpan.org/pod/App%3A%3AGreple) to show
matched text in zebra striping fashion.

The following command matches two consecutive lines.

    greple -E '(.+\n){1,2}' --face +E

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/normal.png">
    </p>
</div>

However, each matched block is colored by the same color, so it is not
clear where the block breaks.  One way is to explicitly display the
blocks using the `--blockend` option.

    greple -E '(.+\n){1,2}' --face +E --blockend=--

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/blockend.png">
    </p>
</div>

Using the stripe module, blocks matching the same pattern are colored
with different colors of the similar color series.

    greple -Mstripe -E '(.+\n){1,2}' --face +E

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/stripe.png">
    </p>
</div>

By default, two color series are prepared. Thus, when multiple
patterns are searched, an even-numbered pattern and an odd-numbered
pattern are assigned different color series.

    greple -Mstripe -E '.*[02468]$' -E '.*[13579]$' --need=1

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/random.png">
    </p>
</div>

When multiple patterns are specified as in the above example, only
lines matching all patterns will be output.  So the `--need=1` option
is required to relax this condition.

If you want to use different color series for three or more patterns,
specify `step` count when calling the module.  The number of series
can be increased up to 6.

    greple -Mstripe::set=step=3 --need=1 -E p1 -E p2 -E p3 ...

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/step-3.png">
    </p>
</div>

# MODULE OPTIONS

There are options specific to the **stripe** module.  They can be
specified either at the time of module declaration or as options
following the module declaration and ending with `--`.

The following two commands have exactly the same effect.

    greple -Mstripe=set=step=3

    greple -Mstripe --step=3 --

- **-Mstripe::set**=**step**=_n_
- **--step**=_n_

    Set the step count to _n_.

- **-Mstripe::set**=**darkmode**
- **--darkmode**

    Use dark background colors.

    <div>
            <p>
            <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/darkmode.png">
            </p>
    </div>

    Use `--face` option to set foreground color for all colormap.  The
    following command sets the foreground color to white and fills the
    entire line with the background color.

        greple -Mstripe --darkmode -- --face +WE

    <div>
            <p>
            <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/dark-white.png">
            </p>
    </div>

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright ©︎ 2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
