# NAME

**Assert::Refute** - unified testing, assertion, and design-by-contract tool

# SYNOPSIS

This module allows to create snippets of code called *contracts*
that behave just as a unit test would,
but do not require the enclosing code to be a unit test:

    use Assert::Refute qw(:all) { on_fail => 'croak' };

    # deep in the production code
    my $data = Some::Module->bloated_untestable_sub;
    try_refute {
        like $data->{foo}, qr/f?o?r?m?a?t/;
        is $data->{bar}, 42;
        can_ok $data->{baz}, qw(do_this do_that frobnicate);
    }; # this dies if conditions are not met

This can be transferred *verbatim* into a unit-test,
allowing to find the sweet spot on the `speed <---> accuracy` scale.

# WHY REFUTE

Communicating a passing test/check requires 1 bit of information:
exerything is fine.
When something's not right, however, the more details, the better.

Thus `refute`, an inverted assertion, is the central building block
of this module.

# INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

# CONTENT OF THIS PACKAGE

* `Changes` - change log
* `examples` - really simple scripts demonstrating usage
* `lib` - modules
* `elib` - experimental modules that don't get released to CPAN
* `Makefile.PL`
* `README.md`/`README` - this file
* `t` - tests required for installation
* `TODO` - approximate roadmap
* `et` - tests required for development only
* `.githooks` - author's default pre-commit hooks

The modules include:

* `Assert::Refute` - the main frontend with a lot of exports.
It also handles runtime assertions.

* `Assert::Refute::Build` - helper module to build more test conditions
(those would also work fine under Test::More).

* `Assert::Refute::Contract` - implementations of contract *specification*.

* `Assert::Refute::Report` - implementation of contract execution *report*.
This is where `refute` is implemented.

* `Assert::Refute::Driver::*` - assertion/testing protocol implementations
(currently only Test::More compatibility layer there).

* `Assert::Refute::T::*` - extra conditions and checks.

# SUPPORT AND DOCUMENTATION

See https://metacpan.org/pod/Assert::Refute

This package is under heavy development.
Bugs may be lurking!

Please report bugs and ask for features here:

    https://github.com/dallaylaen/assert-refute-perl/issues

# LICENSE AND COPYRIGHT

Copyright (C) 2017-2018 Konstantin S. Uvarin `khedin@cpan.org`

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

