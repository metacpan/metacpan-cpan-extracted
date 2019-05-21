package CTK::FilePid; # $Id: FilePid.pm 250 2019-05-09 12:09:57Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::FilePid - File::Pid patched interface

=head1 VERSION

Version 1.03

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

=head2 running

Patched method. See L<File::Pid/"running">

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<File::Pid>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<File::Pid>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = 1.03;

use base qw/File::Pid/;

sub running {
    my $self = shift;
    my $pid  = $self->_get_pid_from_file;

    return   kill(0, $pid || 0)
           ? $pid
           : undef;
}

1;

__END__
