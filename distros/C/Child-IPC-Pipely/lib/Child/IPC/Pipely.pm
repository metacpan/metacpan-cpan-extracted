package Child::IPC::Pipely;

use strict;
use warnings;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

use base 'Child::IPC::Pipe';

use IO::Pipely qw/pipely/;

sub shared_data {
  my ( $ain, $aout ) = pipely;
  my ( $bin, $bout ) = pipely;
  return [
    [ $ain, $aout ],
    [ $bin, $bout ],
  ];
}

1;

=head1 NAME

Child::IPC::Pipely - use Child with IO::Pipely for more portable IPC

=head1 SYNOPSIS

 use Child;
 my $child = Child->new( sub { ... }, pipely => 1 );

=head1 DESCRIPTION

L<Child> is a great way to manage forking, but its default IPC uses C<pipe> which sadly isn't as portable as it could be in places.
L<IO::Pipely> provides a better solution (and indeed describes the problem better than I can).
Read more there.

=head1 SEE ALSO

=over

=item L<Child>

=item L<IO::Pipely>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Child-IPC-Pipely> 

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
