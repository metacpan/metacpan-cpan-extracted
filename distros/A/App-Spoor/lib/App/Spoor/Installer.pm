package App::Spoor::Installer;

use v5.10;
use strict;
use warnings;

use YAML::Tiny;

use App::Spoor::LoginUnitFile;
use App::Spoor::AccessUnitFile;
use App::Spoor::ErrorUnitFile;
use App::Spoor::TransmitterUnitFile;
use App::Spoor::CpanelHookFile;

=head1 NAME

App::Spoor::Installer

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Creates directories, config file, systemd unit files as well as the package that will be added to forward-related hooks in CPanel.

=head1 SUBROUTINES

=head2 install

  my %installation_config =(
    login_log_path => '/var/log/login',
    access_log_path => '/var/log/access',
    error_log_path => '/var/log/error',
    api_identifier => 'ABC123',
    api_secret => 'secret456'
  );

  App::Spoor::Installer::install(\%installation_config);

  # Optionally, you can pass in an alternative to the root path '/' which is used when building the path
  # to the config file. In the code snippet below, the method will create any directories and files relative to the
  # provided root path. For example, in the snippet below, the method will create the spoor config file in 
  # /tmp/etc/spoor rather than /etc/spoor. This is primarily used to support testing.

  App::Spoor::Installer::install(\%installation_config, '/tmp');
=cut

sub install {
  my $install_parameters = shift;
  my $root_path = shift @_ // '/';
  mkdir("$root_path/etc/spoor", 0700);

  my $config = YAML::Tiny->new({
      followers => {
        login => {
          name => $install_parameters->{'login_log_path'},
          maxinterval => 10,
          debug => 1,
          transformer => 'bin/login_log_transformer.pl',
        },
        access => {
          name => $install_parameters->{'access_log_path'},
          maxinterval => 10,
          debug => 1,
          transformer => 'bin/login_log_transformer.pl',
        },
        error => {
          name => $install_parameters->{'error_log_path'},
          maxinterval => 10,
          debug => 1,
          transformer => 'bin/login_log_transformer.pl',
        },
      },
      transmission => {
        credentials => {
          api_identifier => $install_parameters->{'api_identifier'},
          api_secret => $install_parameters->{'api_secret'},
        },
        host => 'https://spoor.capefox.co',
        endpoints => {
          report => '/api/reports',
        }
      }
    });

  $config->write("$root_path/etc/spoor/spoor.yml");
  chmod(0600, "$root_path/etc/spoor/spoor.yml");

  mkdir("$root_path/var/lib/spoor", 0700);
  mkdir("$root_path/var/lib/spoor/parsed", 0700);
  mkdir("$root_path/var/lib/spoor/transmitted", 0700);
  mkdir("$root_path/var/lib/spoor/transmission_failed", 0700);

  open(my $login_handle, '>:encoding(UTF-8)', "$root_path/etc/systemd/system/spoor-login-follower.service") or die("Could not open: $!");
  print $login_handle App::Spoor::LoginUnitFile::contents();
  close $login_handle;
  chmod(0644, "$root_path/etc/systemd/system/spoor-login-follower.service");

  open(my $access_handle, '>:encoding(UTF-8)', "$root_path/etc/systemd/system/spoor-access-follower.service") or die("Could not open: $!");
  print $access_handle App::Spoor::AccessUnitFile::contents();
  close $access_handle;
  chmod(0644, "$root_path/etc/systemd/system/spoor-access-follower.service");

  open(my $error_handle, '>:encoding(UTF-8)', "$root_path/etc/systemd/system/spoor-error-follower.service") or die("Could not open: $!");
  print $error_handle App::Spoor::ErrorUnitFile::contents();
  close $error_handle;
  chmod(0644, "$root_path/etc/systemd/system/spoor-error-follower.service");

  open(my $transmitter_handle, '>:encoding(UTF-8)', "$root_path/etc/systemd/system/spoor-transmitter.service") or die("Could not open: $!");
  print $transmitter_handle App::Spoor::TransmitterUnitFile::contents();
  close $transmitter_handle;
  chmod(0644, "$root_path/etc/systemd/system/spoor-transmitter.service");

  mkdir("$root_path/var/cpanel/perl5", 0755);
  mkdir("$root_path/var/cpanel/perl5/lib", 0755);
  open(my $hook_file_handle, '>:encoding(UTF-8)', "$root_path/var/cpanel/perl5/lib/SpoorForwardHook.pm") or die("Could not open; $!");
  print $hook_file_handle App::Spoor::CpanelHookFile::contents();
  close $hook_file_handle;
  chmod(0644,  "$root_path/var/cpanel/perl5/lib/SpoorForwardHook.pm");
}

=head1 AUTHOR

Rory McKinley, C<< <rorymckinley at capefox.co> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Spoor::Installer


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

1; # End of App::Spoor::Installer
