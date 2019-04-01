package App::Spoor::ParsedEntryWriter;

use v5.10;
use strict;
use warnings;
use utf8;

use JSON;
use File::Touch;

=head1 NAME

App::Spoor::ParsedEntryWriter

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Writes a parsed log entry as json to a file in /var/lib/spoor/parsed.

=head1 SUBROUTINES/METHODS

=head2 write_parsed_entry

For parsed entries that meet the criteria, this subroutine writes the entry as JSON to a file located in /var/lib/spoor/parsed.

Currently the criteria only allows for parsed entries with the following characteristics to be written:

=over 2

=item * A successful login event with a mailbox context.

=item * A successful forward added partial entry (IP) with a mailbox context.

=item * A successful forward added partial entry (Recipient) with a mailbox context, that is forwarding to a email address.

=item * A successful forward removed entry with a mailbox context.

=back

The created filenames adhere to the pattern "type.timestamp.random_element.json", where 'type' would be the type of log
that produced the entry ('login', 'access', 'error'), 'timestamp' is the unix timestamp at the time of file creation and
the random element is a random integer between 1000000 and 1999999 (inclusive).

  my $entry = '[2018-09-19 16:02:36 +0000] info [webmaild] 10.10.10.10 ' . 
    '- rorymckinley@blah.capefox.co (possessor: blahuser) - SUCCESS LOGIN webmaild';

  $parsed_entry_ref = App::Spoor::LoginEntryParser::parse($entry);

  App::Spoor::ParsedEntryWriter::write_parsed_entry($parsed_entry_ref, App::Spoor::Config::get_application_config());

The subroutine does not return anything of significance.

=cut

sub write_parsed_entry {
  my $contents_ref = shift;
  my $path = (shift)->{'parsed_entries_path'};
  my $type = $contents_ref->{type};
  my $context = $contents_ref->{context};
  my $status = $contents_ref->{status};
  my $event = $contents_ref->{event};
  my $forward_type = $contents_ref->{forward_type};

  if (
    ($event eq 'login' && $status eq 'success' && $context eq 'mailbox') ||
    ($event eq 'forward_added_partial_ip' && $status eq 'success' && $context eq 'mailbox') ||
    (
      $event eq 'forward_added_partial_recipient' && $status eq 'success' && $forward_type eq 'email' &&
      $context eq 'mailbox'
    ) ||
    ($event eq 'forward_removed' && $status eq 'success' && $context eq 'mailbox') 
  ) {
    my $timestamp = time();
    my $random_element = int(rand(1000000)) + 1000000;
    my $filepath = File::Spec->catdir($path, "$type.$timestamp.$random_element.json");
    touch($filepath);
    chmod(0600, $filepath);

    open(my $file_handle, '>', $filepath) or die "Couldn't open: $!";
    print $file_handle JSON->new->encode($contents_ref);
    close $file_handle;

    return $filepath;
  } else {
    return;
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

    perldoc App::Spoor::ParsedEntryWriter


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

1; # End of App::Spoor::ParsedEntryWriter
