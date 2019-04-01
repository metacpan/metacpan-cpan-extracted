package App::Spoor::CpanelHookFile;

use v5.10;
use strict;
use warnings;

=head1 NAME

App::Spoor::CpanelHookFile

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Contains the contents used for populating the file that makes use of the CPanel standarized hook.

=head1 SUBROUTINES/METHODS

=head2 contents

Returns the contents of SpoorForwardHook.

=cut

sub contents {
  my $contents = <<'END_MESSAGE';
package SpoorForwardHook;

use strict;
use warnings;

use JSON;
use Cpanel::Logger;

my $logger = Cpanel::Logger->new();

sub describe {
  my $uapi_add = {
    'category' => 'Cpanel',
    'event' => 'UAPI::Email::add_forwarder',
    'stage' => 'post',
    'hook' => 'SpoorForwardHook::write_forward_added',
    'exectype' => 'module'
  };

  my $uapi_delete = {
    'category' => 'Cpanel',
    'event' => 'UAPI::Email::delete_forwarder',
    'stage' => 'post',
    'hook' => 'SpoorForwardHook::write_forward_removed',
    'exectype' => 'module'
  };

  return [ $uapi_add, $uapi_delete ];
}

sub write_forward_added {
  my ( $context, $data ) = @_;

  my %message = (
    message => to_json($data),
    service => 'spoor_forward_added',
    output => 1,
    backtrace => 0,
    level => 'info'
  );

  $logger->logger(\%message);
  return 0, 'Hook up successful';
}

sub write_forward_removed {
  my ( $context, $data ) = @_;

  my %message = (
    message => to_json($data),
    service => 'spoor_forward_removed',
    output => 1,
    backtrace => 0,
    level => 'info'
  );

  $logger->logger(\%message);
  return 0, 'Hook up successful';
}

1;
END_MESSAGE
}

=head1 AUTHOR

Rory McKinley, C<< <rorymckinley at capefox.co> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Spoor::CpanelHookFile


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=.>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/.>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/.>

=item * Search CPAN

L<https://metacpan.org/release/.>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Rory McKinley.

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

1; # End of App::Spoor::CpanelHookFile
