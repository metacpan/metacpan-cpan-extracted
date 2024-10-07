[![Actions Status](https://github.com/kaz-utashiro/greple-stiripe/actions/workflows/test.yml/badge.svg)](https://github.com/kaz-utashiro/greple-stiripe/actions)
# NAME

App::Greple::stripe - Greple zebra stripe module

# SYNOPSIS

    greple -Mstripe [ module options -- ] ...

# VERSION

Version 0.99

# DESCRIPTION

App::Greple::stripe is a module for **greple** to show matched text
in zebra striping fashion.

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
pattern are assigned different color series.  When multiple patterns
are specified, only lines matching all patterns will be output, so the
`--need=1` option is required to relax this condition.

    greple -Mstripe -E '.*[02468]$' -E '.*[13579]$' --need=1

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/random.png">
    </p>
</div>

If you want to use three series with three patterns, specify `step`
when calling the module.

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

- **-Mstep::set**=**step**=_n_
- **--step**=_n_

    Set the step count to _n_.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright ©︎ 2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
