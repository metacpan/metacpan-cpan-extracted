package Alien::Thrust;

our $VERSION = '0.101';

use File::ShareDir;

our $thrust_shell_binary;

if ($^O =~ /darwin/i) {
  $thrust_shell_binary = File::ShareDir::dist_dir('Alien-Thrust') . "/ThrustShell.app/Contents/MacOS/ThrustShell";
} else {
  $thrust_shell_binary = File::ShareDir::dist_dir('Alien-Thrust') . "/thrust_shell";
}

1;


__END__


=head1 NAME

Alien::Thrust - Download and install the Thrust cross-platform GUI framework

=head1 DESCRIPTION

This package will download a zip file containing the L<Thrust cross-platform, cross-language GUI toolkit|https://github.com/breach/thrust> and will then install it into its private distribution share directory.

The location of the binary is stored in the C<$Alien::Thrust::thrust_shell_binary> variable:

    $ perl -MAlien::Thrust -E 'say $Alien::Thrust::thrust_shell_binary'
    /usr/local/share/perl/5.18.2/auto/share/dist/Alien-Thrust/thrust_shell

Note however that you probably want to use the L<Thrust> module instead of accessing the binary directly.

=head1 SEE ALSO

L<Alien::Thrust github repo|https://github.com/hoytech/Alien-Thrust>

L<Thrust> perl interface

L<Official Thrust website|https://github.com/breach/thrust>

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

Justin Pacheco

=head1 COPYRIGHT & LICENSE

Copyright 2014 Doug Hoyte.

This module is licensed under the same terms as perl itself.

This perl distribution downloads compiled binaries of the Thrust project which is copyright Stanislas Polu and licensed under the MIT license.


=cut
