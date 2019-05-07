package App::Spoor::OutputFormatter;

use v5.10;
use strict;
use warnings;
use JSON;
use Text::CSV;
use Date::Format;

=head1 NAME

App::Spoor::OutputFormatter

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

This module is used to convert structured data into a formagt suitable for staorage in a file or display on the terminal.

Quick summary of what the module does.

Perhaps a little code snippet.

    use App::Spoor::OutputFormatter;

    my $foo = App::Spoor::OutputFormatter->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 print

Returns a CSV representation of an array of report representations or mailbox event representations. It can optionally 
write this output to a file - if no filehandle is provided, output defaults to STDOUT.

  use App::Spoor::Formatter;

  # Write reports as csv to STDOUT
  @reports_data = (
    { ... },
    { ... },
  );

  App::Spoor::Formatter::print('report', \@reports_data);

  # Write mailbox events as csv to STDOUT
  @mailbox_events_data = (
    { ... },
    { ... },
  );

  App::Spoor::Formatter::print('mailbox_event', \@mailbox_events_data);

  # Write to a file instead
  open my $fh, '>', '/tmp/out.csv'

  App::Spoor::Formatter::print('mailbox_event', \@mailbox_events_data, $fh);

  close $fh
=cut

sub print {
  my $output_type = shift;

  if ($output_type eq 'report') {
    __print_reports(@_);
  } elsif ($output_type eq 'mailbox_event') {
    __print_mailbox_events(@_);
  }
}

sub __print_reports {
  my $records = shift;
  my $output_handle = shift // *STDOUT;
  my @transformed_record;
  my @headers = ('id', 'event time', 'host', 'event type', 'mailbox address');
  my $csv = Text::CSV->new({ eol => $/ });

  $csv->print($output_handle, \@headers);
  foreach my $record_hash (@{$records}) {
    @transformed_record = (
      $record_hash->{id},
      time2str('%Y-%m-%d %H:%M:%S %z', $record_hash->{event_time}, 'UTC'),
      $record_hash->{host},
      $record_hash->{type},
      $record_hash->{mailbox_address}
    );

    $csv->print($output_handle, \@transformed_record);
  }
}

sub __print_mailbox_events {
  my $records = shift;
  my $output_handle = shift // *STDOUT;
  my @transformed_record;
  my @headers = ('id', 'event time', 'host', 'event type', 'mailbox address', 'ip');
  my $csv = Text::CSV->new({ eol => $/ });

  $csv->print($output_handle, \@headers);
  foreach my $record_hash (@{$records}) {
    @transformed_record = (
      $record_hash->{id},
      time2str('%Y-%m-%d %H:%M:%S %z', $record_hash->{event_time}, 'UTC'),
      $record_hash->{host},
      $record_hash->{type},
      $record_hash->{mailbox_address},
      $record_hash->{ip}
    );

    $csv->print($output_handle, \@transformed_record);
  }
}

=head1 AUTHOR

Rory McKinley, C<< <rorymckinley at capefox.co> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Spoor::OutputFormatter


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

1; # End of App::Spoor::OutputFormatter
