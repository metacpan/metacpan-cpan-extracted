#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2021 -- leonerd@leonerd.org.uk

package App::sourcepan;

use strict;
use warnings;

our $VERSION = '0.05';

use CPAN;
use File::Basename qw( basename );
use File::Copy qw( copy );
use IPC::Run qw();

=head1 NAME

C<App::sourcepan> - modulino implementation of F<soucepan>

=head1 SYNOPSIS

This module contains the code to implement the F<sourcepan> command.

See L<sourcepan(1)> for usage information.

=cut

# TODO: damnit does CPAN::Shell not have a method for this??
sub _split_version
{
   shift =~ m/^(.*?)(?:-(\d+[[:digit:].]*))?$/;
}

sub run
{
   shift;
   my ( $opts, @items ) = @_;

   my $type = $opts->{type};

   my %dists;
   if( $type eq "module" ) {
      foreach my $module ( CPAN::Shell->expand( Module => @items ) ) {
         my $dist = $module->distribution;
         $dists{$dist->pretty_id} = $dist;
      }
   }
   else {
      # Dists have full names; search by regexp to match on dist base name
      foreach ( @items ) {
         my ( $basename, $ver ) = _split_version( $_ );

         # CPAN::Shell doesn't like a qr//, only a literal string
         my $match = defined $ver ? "/\\/$basename-$ver\\./"
                                  : "/\\/$basename-\\d+/";

         my $latestver;
         foreach my $dist ( CPAN::Shell->expand( Distribution => $match ) ) {
            $dists{$dist->pretty_id} = $dist;
            my ( undef, $thisver ) = _split_version $dist->base_id;
            if( !defined $latestver or $latestver < $thisver ) {
               $latestver = $thisver;
            }
         }

         if( !defined $ver ) {
            foreach ( keys %dists ) {
               my ( $thisname, $thisver ) = _split_version $dists{$_}->base_id;
               next if $thisname ne $basename;
               next if $thisver == $latestver;
               delete $dists{$_};
            }
         }
      }
   }

   foreach my $id ( sort keys %dists ) {
      my $dist = $dists{$id};

      # Peeking inside
      $dist->get_file_onto_local_disk;

      my $basename = basename $id;
      copy( $dist->{localfile}, $basename ) or die "Cannot copy - $!";

      print "$id => $basename\n";

      next unless $opts->{extract};

      my @unpack_cmd;
      my $dirname;

      if( $id =~ m/\.tar\.(?:gz|bz2)$/ ) {
         my $tarflags = ( $id =~ m/bz2$/ ) ? "xjf" : "xzf";
         @unpack_cmd = ( "tar", $tarflags, $basename );
         ( $dirname = $basename ) =~ s/\.tar.(?:gz|bz2)$//;
      }
      elsif( $id =~ m/\.zip$/ ) {
         @unpack_cmd = ( "unzip", $basename );
         ( $dirname = $basename ) =~ s/\.zip$//;
      }
      else {
         die "Unsure how to unpack $id\n";
      }

      !$opts->{overwrite} and -d $dirname and
         die "Target directory $dirname already exists; rename it out of the way first or pass --overwrite\n";

      IPC::Run::run [ @unpack_cmd ], ">/dev/null" or
         die "Unable to extract - $unpack_cmd[0] failed with exit code $?\n";

      -d $dirname or
         die "Expected to extract a directory called $dirname\n";

      if( $opts->{unversioned} ) {
         ( my $newname = $dirname ) =~ s/-[0-9._]+$// or
            die "Unable to determine the unversioned name for $dirname\n";

         rename $dirname, $newname or
            die "Unable to rename $dirname to $newname - $!";

         $dirname = $newname;
      }

      print "Unpacked $basename to $dirname\n";

      if( my $vc = $opts->{vc_init} ) {
         my $code = __PACKAGE__->can( "vc_init_$vc" ) or
            die "Unsure how to initialise version control system $vc\n";

         $code->( $dirname,
            id => $id
         ) or exit $?;
      }
   }
}

sub vc_init_bzr
{
   my ( $dirname, %opts ) = @_;

   defined( my $kid = fork() ) or die "Cannot fork - $!";
   return waitpid $kid, 0 if $kid;

   # In a subprocess
   chdir $dirname or die "Cannot chdir $dirname - $!";

   system( "bzr", "init" ) == 0
      or die "Unable to 'bzr init' ($?)\n";
   system( "bzr", "add", "." ) == 0
      or die "Unable to 'bzr add ($?)\n";
   system( "bzr", "commit", "-m", "Imported $opts{id}" ) == 0
      or die "Unable to 'bzr commit' ($?)\n";
}

sub vc_init_git
{
   my ( $dirname, %opts ) = @_;

   defined( my $kid = fork() ) or die "Cannot fork - $!";
   return waitpid $kid, 0 if $kid;

   # In a subprocess
   chdir $dirname or die "Cannot chdir $dirname - $!";

   system( "git", "init" ) == 0
      or die "Unable to 'git init' ($?)\n";
   system( "git", "add", "." ) == 0
      or die "Unable to 'git add ($?)\n";
   system( "git", "commit", "-m", "Imported $opts{id}" ) == 0
      or die "Unable to 'git commit' ($?)\n";
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
