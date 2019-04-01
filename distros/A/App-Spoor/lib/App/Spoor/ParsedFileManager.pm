package App::Spoor::ParsedFileManager;

use v5.10;
use strict;
use warnings;

use File::Spec;
use File::Copy qw(move);
use Path::Tiny qw(path);
use JSON;

=head1 NAME

App::Spoor::ParsedFileManager

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module is responsible for looping through the contents of the parsed files directory and passing them to the
transmitter.

=head1 SUBROUTINES

=head2 process_parsed_files

Loops through all files in the /var/lib/spoor/parsed directory. If a file passes a rudimentary security check the
contents of the file are passed to the transmitter. If the file fails the security check or does not match the expected
naming convention, it is left where it is.


If the file is successfully transmitted, it is moved into /var/lib/spoor/transmitted. If not, it is moved into 
/var/lib/spoor/transmission_failed - for transmission to be reattempted, it must be manually moved into
/var/lib/spoor/parsed once more.


  my $application_config = App::Spoor::Config::get_application_config();
  my $transmission_config = App::Spoor::Config::get_transmission_config();
  $transmission_config->{'reporter'} = hostname;

  sub transmitter {
    App::Spoor::EntryTransmitter::transmit(
      App::Spoor::TransmissionFormatter::format(shift, $transmission_config),
      LWP::UserAgent->new,
      $transmission_config
    );
  }

  sub parsed_file_security_check {
    App::Spoor::Security::check_file(shift, $>, 0600);
  }

  while(1) {
    App::Spoor::ParsedFileManager::process_parsed_files(
      $application_config, \&parsed_file_security_check, \&transmitter
    );
    sleep 5;
  }

=cut

sub process_parsed_files {
  my $config = shift;
  my $file_security_check = shift;
  my $transmitter = shift;

  my ($source_file_path, $file_contents);
  opendir my $parsed_entries_dir, $config->{parsed_entries_path};

  while(readdir $parsed_entries_dir) {
    next if (/\A\.{1,2}\z/);

    my ( $sanitised_file_name ) = $_ =~ /\A((error|access|login)\.\d+\.\d+\.json)\z/;

    next unless $sanitised_file_name;

    $source_file_path = File::Spec->catfile($config->{parsed_entries_path}, $sanitised_file_name);
    if ($file_security_check->($source_file_path)) {
      $file_contents = from_json(path($source_file_path)->slurp_utf8());

      if ($transmitter->($file_contents)) {
        move($source_file_path, $config->{transmitted_entries_path});
      } else {
        move($source_file_path, $config->{transmission_failed_entries_path});
      }
    }
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

    perldoc App::Spoor::ParsedFileManager


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

1; # End of App::Spoor::ParsedFileManager
