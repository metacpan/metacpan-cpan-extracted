package App::Spoor::ErrorEntryParser;

use v5.10;
use strict;
use warnings;

=head1 NAME

App::Spoor::ErrorEntryParser

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This package contains the necessary functionality to parse CPanel error log entries.

=head1 SUBROUTINES/METHODS

=head2 parse

This subroutine accepts a single line from a CPanel error log (as a string) and returns a reference to a hash 
representation of that entry.

The hash representation contains the following elements:

=over 2

=item * type: This is hardcoded to 'error'

=item * event: A description of the event that the entry refers to - can be one of forward_added_partial_recipient, unrecognised.

=item * log_time: A DateTime instance representing the time of the log entry. It is not set if the event is 'unrecognised'.

=item * context: The context within which the operation is being performed can be either 'mailbox' or 'domain'. It is not set if the event is 'unrecognised'.

=item * forward_type: Can be one of 'system_user', 'pipe' or 'email'. It is not set if the event is 'unrecognised'.

=item * forward_to: The recipient of the forwarded email. It is not set if the event is 'unrecognised'.

=item * email: The mailbox that the forward is being applied to. It is not set if the event is 'unrecognised'.

=item * status: The status of the request is hardcoded to success. It is not set if the event is 'unrecognised'.

=back

=cut

sub parse {
  use DateTime::Format::Strptime;
  use JSON;

  my $log_entry = shift;
  my $date_parser = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d %H:%M:%S %z', on_error => 'croak');
  my %response;
  my $data_ref;
  my $timestamp;
  my $forward_type;

  if ($log_entry =~ /
    \A
    \[(?<timestamp>[^\]]+)\]\s
    info\s
    \[spoor_forward_added\]\s
    (?<data>{.+})
    \Z
  /x) {
    $data_ref = from_json($+{data});
    $timestamp = $date_parser->parse_datetime($+{timestamp})->epoch();

    if ($data_ref->{args}{fwdopt} eq 'system') {
      $forward_type = 'system_user';
    } elsif ($data_ref->{args}{fwdopt} eq 'pipe') {
      $forward_type = 'pipe';
    } else {
      $forward_type = 'email';
    }
    %response = (
      type => 'error',
      event => 'forward_added_partial_recipient',
      context => ($data_ref->{args}{domain} eq '' ? 'mailbox' : 'domain'),
      forward_type =>$forward_type,
      forward_to => $data_ref->{result}[0]{forward},
      email => $data_ref->{result}[0]{email},
      log_time => $timestamp,
      status => 'success'
    );
  } else {
    %response = (
      type => 'error',
      event => 'unrecognised',
    );
  }

  return \%response;
}

=head1 AUTHOR

Rory McKinley, C<< <rorymckinley at capefox.co> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Spoor::ErrorEntryParser


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

1; # End of App::Spoor::ErrorEntryParser
