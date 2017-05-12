package Alien::Microsoft::Outlook;

use strict;
use warnings;
use Carp;
use 5.006;

use Win32::OLE;
use Win32::OLE::Const 'Microsoft Outlook';

=head1 NAME

Alien::Microsoft::Outlook

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

This module contains code abstracted from Mail::Outlook. It will not install (without force)
unless Microsoft Outlook can be detected.

It does the detection by using Win32::OLE::Const to load "Microsoft Outlook" and then checking
that the constants olFolderInbox, olFolderOutbox, olFolderSentMail, olFolderDrafts, olFolderDeletedItems,
and olMailItem are all defined.

It does not attempt to install Microsoft::Outlook.

=head1 EXPORT

None

=head1 SUBROUTINES/METHODS

=head2 run_or_croak

=cut

sub run_or_croak {

    my $hr = Win32::OLE::Const->Load('Microsoft Outlook');
    croak "No constants found for 'Microsoft Outlook'"
      if !( $hr && keys(%$hr) );

    croak "Not all constants found for 'Microsoft Outlook'"
      if test_constants($hr);

    return 1;
}

=head2 test_constants

=cut

sub test_constants {
    my ($hr) = shift;
    my $missing = 0;

    # olMailItem is 0, so test for defined.
    foreach my $k (
        qw/ olFolderInbox
        olFolderOutbox
        olFolderSentMail
        olFolderDrafts
        olFolderDeletedItems
        olMailItem
        /
      )
    {
        if ( !defined( $hr->{$k} ) ) {
            $missing++;
            warn "OLE constant $k not found";
        }
        return $missing;
    }
}

=head1 AUTHOR

Duncan Garland, C<< <duncan at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-alien-microsoft-outlook at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-Microsoft-Outlook>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Alien::Microsoft::Outlook


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-Microsoft-Outlook>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Alien-Microsoft-Outlook>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Alien-Microsoft-Outlook>

=item * Search CPAN

L<http://search.cpan.org/dist/Alien-Microsoft-Outlook/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Duncan Garland.

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


=cut

1;    # End of Alien::Microsoft::Outlook
