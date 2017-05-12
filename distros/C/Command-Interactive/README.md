**command-interactive**

Command::Interactive handles interactive (and non-interactive) process invocation through a reliable and easily configured interface.

[![Build Status](https://travis-ci.org/binary-com/perl-command-interactive.svg?branch=master)](https://travis-ci.org/binary-com/perl-command-interactive)
[![Coverage Status](https://coveralls.io/repos/binary-com/perl-command-interactive/badge.png?branch=master)](https://coveralls.io/r/binary-com/perl-command-interactive?branch=master)
[![Gitter chat](https://badges.gitter.im/binary-com/perl-command-interactive.png)](https://gitter.im/binary-com/perl-command-interactive)

SYNOPSIS

This module can be used to invoke both interactive and non-interactive commands with predicatable results.

    use Command::Interactive;
    use Carp;

    # Simple, non-interactive usage
    my $result1 = Command::Interactive->new->run("cp foo /tmp/");
    croak "Could not copy foo to /tmp/: $result!" if($result);

    # Interactive usage supports output parsing
    # and automated responses to discovered strings
    my $password_prompt = Command::Interactive::Interaction->new({
        expected_string => 'Please enter your password:',
        response        => 'secret',
    });

    my $command = Command::Interactive->new({
        echo_output    => 1,
        output_stream  => $my_logging_fh,
        interactions   => [ $password_prompt ],
    });
    my $restart_result = $command->run("ssh user@somehost 'service apachectl restart'");
    if($restart_result)
    {
        warn "Couldn't restart server!";
    }


SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Command::Interactive

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Command::Interactive

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Command::Interactive

    CPAN Ratings
        http://cpanratings.perl.org/d/Command::Interactive

    Search CPAN
        http://search.cpan.org/dist/Command::Interactive/


LICENSE AND COPYRIGHT

Copyright (C) 2014 binary.com

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

