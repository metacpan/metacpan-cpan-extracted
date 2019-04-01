package App::Spoor::Security;

use v5.10;
use strict;
use warnings;

=head1 NAME

App::Spoor::Security

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Performs rudimentary permission and ownership checks of Spoor-related files and directories

=head1 SUBROUTINES

=head2 check_config_file

Checks that the spoor config file is owner by the specified user and has permissions '0600'.

  App::Spoor::Security::check_config_file($<) || die("blah blah blah");

  # Optionally, you can pass in an alternative to the root path '/' which is used when building the path
  # to the config file. In the code snippet below, the code will look for the config file in
  # /tmp/etc/spoor/ instead of /etc/spoor. This is primarily used to support testing.
  App::Spoor::Security::check_config_file($<, '/tmp') || die("blah blah blah");

=cut

sub check_config_file {
  my $required_user_id = shift;
  my $root_path = shift @_ // '/';

  my @file_stat = stat "$root_path/etc/spoor/spoor.yml";
  my $file_user_id = $file_stat[4];
  my $file_permissions = $file_stat[2] & 07777;
  
  $file_user_id == $required_user_id && $file_permissions == 0600;
}

=head2 check_file

Checks that a given file is owned by the specified user and has the permissions specified.

  App::Spoor::Security::check_file(shift, $>, 0600) || die("blah blah blah");

=cut

sub check_file {
  my $path = shift;
  my $required_user_id = shift;
  my $required_permissions = shift;

  my @stat = stat $path;
  my $user_id = $stat[4];
  my $permissions = $stat[2] & 07777;
  
  $user_id == $required_user_id && $permissions == $required_permissions;
}

=head2 check_config_directory

Checks that the spoor config directory is owned by the specified user and has permissions '0700'.

  App::Spoor::Security::check_config_directory($<) || die("blah blah blah");

  # Optionally, you can pass in an alternative to the root path '/' which is used when building the path
  # to the config file. In the code snippet below, the code will look for the config directory in
  # /tmp/etc/ instead of /etc. This is primarily used to support testing.
  App::Spoor::Security::check_config_directory($<, '/tmp') || die("blah blah blah");

=cut

sub check_config_directory {
  my $required_user_id = shift;
  my $root_path = shift @_ // '/';

  my @stat = stat "$root_path/etc/spoor";
  my $user_id = $stat[4];
  my $permissions = $stat[2] & 07777;
  
  $user_id == $required_user_id && $permissions == 0700;
}

=head2 check_persistence_directory

Checks that the spoor persistence directory is owned by the specified user and has permissions '0700'.

  App::Spoor::Security::check_persistence_directory($<) || die("blah blah blah");

  # Optionally, you can pass in an alternative to the root path '/' which is used when building the path
  # to the config file. In the code snippet below, the code will look for the persistence directory in
  # /tmp/var/lib instead of /var/lib. This is primarily used to support testing.
  App::Spoor::Security::check_persistence_directory($<, '/tmp') || die("blah blah blah");

=cut

sub check_persistence_directory {
  my $required_user_id = shift;
  my $root_path = shift @_ // '/';

  my @stat = stat "$root_path/var/lib/spoor";
  my $user_id = $stat[4];
  my $permissions = $stat[2] & 07777;
  
  $user_id == $required_user_id && $permissions == 0700;
}

=head2 check_parsed_persistence_directory

Checks that the spoor parsed persistence directory is owned by the specified user and has permissions '0700'.

  App::Spoor::Security::check_persistence_directory($<) || die("blah blah blah");

  # Optionally, you can pass in an alternative to the root path '/' which is used when building the path
  # to the config file. In the code snippet below, the code will look for the parsed items directory in
  # /tmp/var/lib/spoor instead of /var/lib/spoor. This is primarily used to support testing.
  App::Spoor::Security::check_persistence_directory($<, '/tmp') || die("blah blah blah");

=cut

sub check_parsed_persistence_directory {
  my $required_user_id = shift;
  my $root_path = shift @_ // '/';

  my @stat = stat "$root_path/var/lib/spoor/parsed";
  my $user_id = $stat[4];
  my $permissions = $stat[2] & 07777;
  
  $user_id == $required_user_id && $permissions == 0700;
}

=head1 AUTHOR

Rory McKinley, C<< <rorymckinley at capefox.co> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Spoor::Security


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

1; # End of App::Spoor::Security
