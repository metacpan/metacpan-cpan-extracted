package BatchSystem::SBS::ScriptsCommon;

=head1 NAME

BatchSystem::SBS::ScriptsCommon - common function & var for BatchSystem::SBS scripts

=head1 DESCRIPTION

main declaration + common parsing of comman line argument

=head1 SYNOPSIS

=head1 EXPORT

=head3 $sbs

the simple batch system

=head1 FUNCTIONS

=head3 init()

parse commandline argument for

=over 4

=item --config=sbsconfig.xml [compulsory]

=item --workingdir=/path/to/dir [optional]

overwrites the working directory configures into the config file.

=back

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

use Getopt::Long;
use BatchSystem::SBS;
require Exporter;
our @ISA=qw(Exporter);
our @EXPORT=qw(&init $sbs);
our $sbs;
sub init{
  my $p=new Getopt::Long::Parser;
  $p->configure("pass_through");
  my($configfile, $workingDir);
  if (!$p->getoptions(
		  "config=s"=>\$configfile,
		  "workingdir=s"=>\$workingDir,
		 )
     ){
  }
  die "no --config=file.xml was passed" unless $configfile;
  $sbs=BatchSystem::SBS->new();
  $sbs->readConfig(file=>$configfile);
  $sbs->workingDir($workingDir) if $workingDir;
  $sbs->scheduler->__joblist_pump();
  $sbs->scheduler->resourcesStatus_init();
  $sbs->scheduler->queuesStatus_init();
}
1;
