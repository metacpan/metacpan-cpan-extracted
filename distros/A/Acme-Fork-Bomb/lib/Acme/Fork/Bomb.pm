package Acme::Fork::Bomb;
use strict;
use warnings;

our $VERSION = '2.0';

=head1 NAME

Acme::Fork::Bomb - crashes your program and probably your system

=head1 SYNOPSIS

  use Acme::Fork::Bomb;

=head1 DESCRIPTION

B<WARNING:> Using this will crash your system. You have been warned.

Steps to use:

=over

=item 1

Install.

=item 2

Add C<use Acme::Fork::Bomb> to your program.

=item 3

Run your program.

=item 4

Reboot.

=back

=head1 METHODS

None. All you need is C<use Fork::Bomb>. You won't need anything else after
that. In fact, you probably won't be able to do anything else on your computer
after that.

=head1 SPECIAL THANKS

Special thanks to Michael Flickinger and Michael Aquilina and the staff and
sponsors of YAPC::NA 2012 for allowing us to meet together in the Expo Hall.

=head1 COPYRIGHT AND LICENSE

Copyright 2012 Sterling Hanenkamp. This software is available under the same
license as Perl itself.

=cut

sub import {
    fork while (fork) or not fork;
}

1;
