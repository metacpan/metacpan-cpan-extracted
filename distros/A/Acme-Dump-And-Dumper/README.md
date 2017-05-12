# NAME

Acme::Dump::And::Dumper - dump data structures without seeing any object guts

# SYNOPSIS

    use Acme::Dump::And::Dumper;

    my $data = {
        foo => 'bar',
        ber => {
            beer => [qw/x y z/],
            obj  => bless([], 'Foo::Bar'),
        },
    };

    print DnD $data;

    ## Prints:
    ## $VAR1 = {
    ##      'ber' => {
    ##                 'obj' => 'obj[Foo::Bar]',
    ##                 'beer' => [
    ##                             'x',
    ##                             'y',
    ##                             'z'
    ##                           ]
    ##               },
    ##      'foo' => 'bar'
    ## };

    # All the Data::Dumper stuff is still there...
    $Data::Dumper::Useqq = 1;
    print DnD "Foo\nBar";

    # ... even the original Dumper()
    print Dumper "Foo\nBar";

# DESCRIPTION

A [Data::Dumper](https://metacpan.org/pod/Data::Dumper), with an additional sub that's like `Dumper()`
but doesn't dump the contents of object refs.

# EXPORTS

In addition to all the stuff available for export in [Data::Dumper](https://metacpan.org/pod/Data::Dumper),
this module provides `DnD()` function (pneumonic: "Dump'n'Dumper").

## `DnD`

    print DnD $data;

    # Data::Dumper's vars are still available:
    $Data::Dumper::Useqq = 1;
    print DnD "Foo\nBar";

Takes the same stuff and returns the same output as
`Data::Dumper::Dumper()`, except all of the
objects will be replaced with `obj[Foo::Bar]`, where `Foo::Bar` is
object's class. **See caveats section below**.

# CAVEATS

Whenever possible, the module will try to deep clone the structure
before messing with it and dumping it. **However**, since not everything
is deep clonable, if the deep clone fails, the module will modify the
original data structure, and method call on what **used to be** objects
will obviously fail.

# HISTORY

This module arose from my frustration of trying to get rid of object
guts in my dumped data (e.g. dumping `Foo::Bar` that is a blessed
hashref, would also dump all the contents of that hashref).
Subsequently, during a conversation on IRC, `tm604` came up with
a hack using `$Data::Dumper::Freezer`, and the following comment
from `hoelzro` made me decide to release a module I could actually
use, when I don't want to see any object guts.

    <hoelzro> Data::Dumper::And::Dumper
    * hoelzro ducks
    <hoelzro> s/Dumper/Dump/ # ruined my own awful joke

P.S.: eventually I ended up using [Data::Rmap](https://metacpan.org/pod/Data::Rmap) instead of the Freezer.

<div>
    <img src="http://zoffix.com/CPAN/Acme-Dump-and-Dumper.jpg"
        style="border: 2px solid #aaa!important; display: block!important; margin: 20px 0!important;"
        alt="Dumb and Dumber">
</div>

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/Acme-Dump-And-Dumper](https://github.com/zoffixznet/Acme-Dump-And-Dumper)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/Acme-Dump-And-Dumper/issues](https://github.com/zoffixznet/Acme-Dump-And-Dumper/issues)

If you can't access GitHub, you can email your request
to `bug-Acme-Dump-And-Dumper at rt.cpan.org`

# AUTHOR

Zoffix Znet <zoffix at cpan.org>
([http://zoffix.com/](http://zoffix.com/), [http://haslayout.net/](http://haslayout.net/))

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
