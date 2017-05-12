# NAME

Acme::LookOfDisapproval - send warnings with ಠ\_ಠ

# VERSION

version 0.006

# SYNOPSIS

    use Acme::LookOfDisapproval;
    ಠ_ಠ 'you did something dumb';

# DESCRIPTION

Use `ಠ_ಠ` whenever you would use `warn`, to express your profound
disapproval.

# FUNCTIONS

## `ಠ_ಠ`

Behaves identically to ["warn" in perlfunc](https://metacpan.org/pod/perlfunc#warn).

# BACKGROUND

I wrote this as an exercise in using unicode in code, not just in a string.
Then, it became an interesting learning experience in how to cleanly map to a
core function, and re-exporting symbols.

The first draft did this:

    use Carp 'carp';
    sub ಠ_ಠ { local $Carp::CarpLevel = $Carp::CarpLevel + 1; carp @_; }

And then it became:

    BEGIN {
        no strict 'refs';
        *{__PACKAGE__ . '::ಠ_ಠ'} = *CORE::warn;
    }

But this is even nicer:

    sub ಠ_ಠ { goto &CORE::warn }

I also played around with [Import::Into](https://metacpan.org/pod/Import::Into) to manage the export of both the
[utf8](https://metacpan.org/pod/utf8) pragma and the `ಠ_ಠ` symbol. However, that's just silly when we can
call `import` directly on [utf8](https://metacpan.org/pod/utf8) (it's a pragma, so the caller doesn't
matter -- only when it is called: during the caller's compilation cycle),
and then we can export our symbol by using [goto](https://metacpan.org/pod/goto) to jump to [Exporter](https://metacpan.org/pod/Exporter).

I also discovered while writing this distribution that [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) is not
able to munge files with utf8 characters, therefore I had to switch to packaging
this distribution with vanilla [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker); also, a number of the
author and release tests that would have been added by dzil automatically
didn't work either (for example, see `t/00-compile.t` -- `qx(^$X "require $_")`
both needs the `:binmode` or `:encoding(UTF-8)` layer applied to `STDOUT`, and
requires the [utf8](https://metacpan.org/pod/utf8) pragma applied in the sub-perl (leading to more patches).

# SUPPORT

Bugs may be submitted through [the RT bug tracker](https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-LookOfDisapproval)
(or [bug-Acme-LookOfDisapproval@rt.cpan.org](mailto:bug-Acme-LookOfDisapproval@rt.cpan.org)).
I am also usually active on irc, as 'ether' at `irc.perl.org`.

# SEE ALSO

- [the Look of Disapproval Meme](http://knowyourmeme.com/memes/%E0%B2%A0_%E0%B2%A0-look-of-disapproval)
- [lambda](https://metacpan.org/pod/lambda) - another example of unicode sub names

# AUTHOR

Karen Etheridge <ether@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
