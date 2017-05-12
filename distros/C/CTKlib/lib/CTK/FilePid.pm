package CTK::FilePid; # $Id: FilePid.pm 192 2017-04-28 20:40:38Z minus $
use strict;

=head1 NAME

CTK::FilePid - File::Pid patched interface

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

  use CTK::FilePid;

  my $pidfile = new CTK::FilePid ({
    file => '/some/file.pid',
  });

  if ( my $num = $pidfile->running ) {
      die "Already running: $num\n";
  } else {
      $pidfile->write;

      # ...
      # blah-blah-blah
      # ...

      $pidfile->remove;
  }



=head1 DESCRIPTION

This software manages a pid file for you. It will create a pid file,
query the process within to discover if it's still running, and remove
the pid file.

See L<File::Pid> for details

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2012 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

use vars qw/$VERSION/;
$VERSION = 1.02;

use base qw/File::Pid/;

sub running {
    #print "\n\n!!!!!!! THIS !!!!!!\n\n";
    my $self = shift;
    my $pid  = $self->_get_pid_from_file;

    return   kill(0, $pid || 0)
           ? $pid
           : undef;
}


1;
__END__
