package BatchSystem::SBS::Common;
use warnings;
use strict;
require Exporter;
use English;

=head1 NAME

BatchSystem::SBS::Common - Common tools Simple Batch System

=head1 DESCRIPTION



=head1 SYNOPSIS



=head1 EXPORT


=head1 FUNCTIONS

=head3 lockFile($file)

call a locker on the file (File::Flock or Lockfile::Simple)

=head3 unlockFile($file)



=head1 AUTHOR

Alexandre Masselot, C<< <alexandre.masselot@genebio.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-batchsystem-sbs@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=BatchSystem-SBS>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (C) 2004-2006  Geneva Bioinformatics (www.genebio.com) & Jacques Colinge (Upper Austria University of Applied Science at Hagenberg)

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


=cut

our @ISA=qw(Exporter);
our @EXPORT_OK=qw(&lockFile &unlockFile);

our $simpleLocker;

eval{
  require File::Flock;
};
if($@){
  require LockFile::Simple;
  warn "$@\nUsing LockFile::Simple";
  $simpleLocker=LockFile::Simple->make(-format => '%f.lck',
				       -max => 20,
				       -delay => 1,
				       -nfs => 1,
				       -autoclean => 1
				      );
}

sub lockFile{
  my $f=shift or CORE::die  "must pass an argument to lockFile";
  if($simpleLocker){
    return $simpleLocker->trylock($f) or CORE::die  "cannot lock [$f]: $!";
  }else{
    File::Flock::lock("$f.flck", (($OSNAME=~/win/i)?'shared':'')) or CORE::die  "cannot lock ($f): $!";
  }
}

sub unlockFile{
  my $f=shift or CORE::die  "must pass an argument to lockFile";
  if($simpleLocker){
    return $simpleLocker->unlock($f) or CORE::die  "cannot lock [$f]: $!";
  }else{
    File::Flock::unlock("$f.flck") or CORE::die  "cannot lock ($f): $!";
  }
}

1; # End of BatchSystem::SBS
