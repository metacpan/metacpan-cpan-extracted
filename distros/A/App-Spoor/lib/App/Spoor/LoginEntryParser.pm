package App::Spoor::LoginEntryParser;

use v5.10;
use strict;
use warnings;

=head1 NAME

App::Spoor::LoginEntryParser

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This package contains the necessary functionality to parse CPanel error log entries.

=head1 SUBROUTINES/METHODS

=head2 parse

This subroutine accepts a single line from a CPanel login log (as a string) and returns a reference to a hash 
representation of that entry.

The hash representation contains the following elements:

=over 2

=item * type: This is hardcoded to 'login'

=item * event: This is hardcoded to 'login'.

=item * log_time: A DateTime instance representing the time of the log entry.

=item * context: The context within which the operation is being performed can be either 'mailbox', 'domain' or 'system'.

=item * scope: Can be one of 'webmaild', 'cpaneld' or 'whostmgrd'.

=item * ip: The ip logging in.

=item * status: Can be one of 'success', 'deferred' or 'failed'. 

=item * credential: The credential (email address/username) presented.

=item * possessor: In the case of an email address being provided, the domain user to which it belongs.

=item * message: This is only set if the entry contained additional info (generally on a non-successful login), e.g. "security token missing".

=item * endpoint: HTTP-related information, only present on a non-successful login.

=back

=cut

sub parse {
  use DateTime::Format::Strptime;

  my $log_entry = shift;
  my $date_parser = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d %H:%M:%S %z', on_error => 'croak');
  my %response;
  if ($log_entry =~ /
    \A
    \[(?<timestamp>[^\]]+)\]\s
    info\s
    \[(?<scope>[^\]]+)\]\s
    (?<ip>\S+)\s
    -\s(?<credential_string>[^-]+)\s-\s
    SUCCESS
  /x) {

    %response = (
      type => 'login',
      event => 'login',
      log_time => $date_parser->parse_datetime($+{timestamp})->epoch(),
      scope => $+{scope},
      ip => $+{ip},
      status => 'success',
    );

    if ($+{credential_string} =~ /\A(?<credential>\S+)\s\(possessor: (?<possessor>[^\)]+)\)/) {
      $response{credential} = $+{credential};
      $response{possessor} = $+{possessor};
    } else {
      $response{credential} = $+{credential_string};
    }
  } elsif ($log_entry =~ /
    \A
    \[(?<timestamp>[^\]]+)\]\s
    info\s
    \[(?<scope>[^\]]+)\]\s
    (?<ip>\S+)\s
    -\s(?<credential>[^-]+)\s
    "(?<endpoint>[^"]+)"\s
    (?<status>[A-Z]+)\s
    [^:]+:\s(?<message>.+)
    \Z
  /x) {
    %response = (
      type => 'login',
      event => 'login',
      log_time => $date_parser->parse_datetime($+{timestamp})->epoch(),
      scope => $+{scope},
      ip => $+{ip},
      status => lc($+{status}),
      credential => $+{credential},
      message => $+{message},
      endpoint => $+{endpoint}
    );
  }

  if ($response{scope} eq 'webmaild' && $response{credential} =~ /@/) {
    $response{context} = 'mailbox';
  } elsif ($response{scope} eq 'webmaild') {
    $response{context} = 'domain';
  } elsif ($response{scope} eq 'cpaneld') {
    $response{context} = 'domain';
  } elsif ($response{scope} eq 'whostmgrd') {
    $response{context} = 'system';
  }

  return \%response;
}

=head1 AUTHOR

Rory McKinley, C<< <rorymckinley at capefox.co> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-spoor at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Spoor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Spoor::LoginEntryParser


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

1; # End of App::Spoor::LoginEntryParser
