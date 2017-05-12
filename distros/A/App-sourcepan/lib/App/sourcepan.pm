#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2014 -- leonerd@leonerd.org.uk

package App::sourcepan;

use strict;
use warnings;

our $VERSION = '0.02';

use CPAN;
use File::Basename qw( basename );
use File::Copy qw( copy );

=head1 NAME

C<App::sourcepan> - fetch source tarballs from CPAN

=head1 SYNOPSIS

 $ sourcepan App::sourcepan

 $ sourcepan --module App::sourcepan

 $ sourcepan --dist App-sourcepan

 $ sourcepan --dist App-sourcepan-0.01

=head1 DESCRIPTION

This module provides a command F<sourcepan>, which fetches the source
distribution for the modules or distributions named on the commandline, and
places each in the current working directory.

=cut

# TODO: damnit does CPAN::Shell not have a method for this??
sub _split_version
{
   shift =~ m/^(.*?)(?:-(\d+[[:digit:].]*))?$/;
}

sub run
{
   shift;
   my ( $type, @items ) = @_;

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
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
