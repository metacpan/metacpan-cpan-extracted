# NAME

**Assert::Refute** - unified testing, assertion, and design-by-contract tool

# DESCRIPTION

This module allows to create snippets of code called *contracts*
that behave just as a unit test would,
but do not require the enclosing code to be a unit test.

A **refutation** is an inverted form of assertion:

    refute( $condition, $message );

Succeeds silently if the condition is *false*, but fails loudly if it is *true*
and asumes the condition value itself to be the *reason* of failure.

Such inversion simplifies building and composition of tests a lot.
Normal `is`, `like` etc can easily be built on top of that:

    sub my_is($$;$) {
        my ($got, $exp, $message) = @_;
        refute( $got ne $exp && "$got != $exp", $message );
        # no diag() needed!
    };

A **contract** is a group of assertions that is saved for later execution:

    # once, at start up
    use Assert::Refute;
    my $spec = contract {
        my ($foo, $bar) = @_;
        # insert checks here
    };

    # much later
    $spec->apply( $real_foo, $real_bar );
    $spec->is_passing; # true of false
    $spec->count;      # number of tests performed
    $spec->as_tap;     # summary in Test::More's format

A **subcontract** is an application of a preexisting contract
to the data at hand as a single check.

These three elements allow for creation of arbitarily complex checks
applicable uniformly in production code or test scripts.

# INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Assert::Refute

Please report bugs and ask for features here:

    https://github.com/dallaylaen/assert-refute-perl/issues

# LICENSE AND COPYRIGHT

Copyright (C) 2017 Konstantin S. Uvarin `khedin@gmail.com`

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

