package App::Spoor::AccessEntryParser;

use v5.10;
use strict;
use warnings;
use utf8;

=head1 NAME

App::Spoor::AccessEntryParser

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This package contains the necessary functionality to parse CPanel access log entries.

=head1 SUBROUTINES/METHODS

=head2 parse

This subroutine accepts a single line from a CPanel access log (as a string) and returns a reference to a hash 
representation of that entry.

The hash representation contains the following elements:

=over 2

=item * type: This is hardcoded to 'access'

=item * log_time: A DateTime instance representing the time of the log entry

=item * event: A description of the event that the entry refers to - can be one of forward_added_partial_ip, forward_removed, unrecognised.

=item * ip: The IP address listed in the entry

=item * credential: The user performing the request

=item * context: The context within which the operation is being performed can be either 'mailbox' or 'unrecognised'

=item * status: The status of the request can be one of 'success' or 'failed'

=back

=cut

sub parse {
  use DateTime::Format::Strptime;
  use URI::Escape qw( uri_unescape );

  my $log_entry = shift; 
  my $level;
  my $event;
  my $status;
  my $forward_recipient;
  my $date_parser = DateTime::Format::Strptime->new(pattern => '%m/%d/%Y:%H:%M:%S %z', on_error => 'croak');

  $log_entry =~ /
    \A
    (?<ip>\S+)\s
    -\s
    (?<username>.+)\s
    \[(?<timestamp>[^\]]+)\]\s
    "(?<http_request>[^"]+)"\s
    (?<response_code>\d{3})\s
  /x;

  my $log_time = $date_parser->parse_datetime($+{timestamp})->epoch();
  my $credential = uri_unescape($+{username});
  my $ip = $+{ip};
  my $http_request = $+{http_request};
  my $response_code = $+{response_code};

  if ($credential =~ /@/) {
    $level = 'mailbox';
  } else {
    $level = 'unrecognised';
  }

  if ($response_code eq '200') {
    $status = 'success';
  } else {
    $status = 'failed';
  }

  if ($credential =~ /@/ && $http_request =~ /\APOST.+doaddfwd.html/) {
    $event = 'forward_added_partial_ip';
  } elsif (
    $credential =~ /@/ &&
    $http_request =~ /\AGET.+dodelfwd.html\?.*emaildest=(?<forward_recipient>[^\s?]+)/
  ) {
    $event = 'forward_removed';
    $forward_recipient = uri_unescape($+{forward_recipient});
  } else {
    $event = 'unrecognised';
  }

  my %result = (
    type => 'access',
    log_time => $log_time,
    event => $event,
    ip => $ip,
    credential => $credential,
    context => $level,
    status => $status,
  );

  $result{forward_recipient} = $forward_recipient if($forward_recipient);

  \%result;
}

=head1 AUTHOR

Rory McKinley, C<< <rorymckinley at capefox.co> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-spoor at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Spoor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Spoor::AccessEntryParser

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Spoor>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Spoor>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-Spoor>

=item * Search CPAN

L<https://metacpan.org/release/App-Spoor>

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

1; # End of App::Spoor::AccessEntryParser
