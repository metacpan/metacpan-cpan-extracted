#This is a -*- perl -*- module file
#
# Copyright (c) 2007-2015 Salve J. Nilsen
#

use strict;

package Acme::Godot;

use version; our $VERSION = version->parse(0.1.10)->numify;

BEGIN {
    eval {
        sub _waiting_for_godot {
            sleep 60 * 60 * 24;          # Act 1 - the first day
            sleep 60 * 60 * 24 * 365;    # Intermission. Get your snacks!
            sleep 60 * 60 * 24;          # Act 2 - the second day
        }

        sub _godot_has_arrived {
            0;                           # Nowhere to be seen.
        }
    };

PLAY: while (!_godot_has_arrived()) {
        _waiting_for_godot();
        redo PLAY unless _godot_has_arrived();
    } continue {
        exit;    # Rejoice, Godot is here! Let's get outta here.
    }
}


1;               # End of Acme::Godot
__END__

=head1 NAME

Acme::Godot - Nothing to be done


=head1 VERSION

version 0.001010

=head1 SYNOPSIS

    use Acme::Godot;


=head1 DESCRIPTION

This module will make your program wait for Godot.


=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install


=head1 INTERFACE

Acme::Godot does not have an interface, and need only to be used
by another program in order to start waiting.


=head1 DIAGNOSTICS

=over

=item C<< (Program apparently hanging) >>

Everything is OK. Your program is successfully waiting for Godot.
He'll probably be here soon.

=item C<< (Program exited unexpectedly) >>

Godot may have arrived. Have you checked? If he's not here, start
your program again.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Acme::Godot requires no configuration files or environment variables,
but the end user of this program is advised to make use of available
assistive tools and methods in order to make the waiting for Godot
more pleasant.


=head1 DEPENDENCIES

You might want to warn people dependent on you that you're about to use
this module.


=head1 INCOMPATIBILITIES

None reported. We're still waiting for Godot to bring the test reports.


=head1 BUGS AND LIMITATIONS

No bugs have been reported. Where's Godot with the bug reports?


=head1 ACKNOWLEDGEMENTS

Thanks to mr. Rune Sandnes for the inspiration.


=head1 AUTHOR

Salve J. Nilsen  C<< <sjn@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2015, Salve J. Nilsen C<< <sjn@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
