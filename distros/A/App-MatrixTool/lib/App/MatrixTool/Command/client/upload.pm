#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package App::MatrixTool::Command::client::upload;

use strict;
use warnings;
use base qw( App::MatrixTool::Command::client );

our $VERSION = '0.08';

use File::Slurper qw( read_binary );

use constant DESCRIPTION => "Upload a file to the media repository";
use constant ARGUMENTS => ( "file", "type?" );
use constant OPTIONS => ();

=head1 NAME

matrixtool client upload - Upload a file to the media repository

=head1 SYNOPSIS

   $ matrixtool client -u @me:example.com upload avatar.png

=head1 DESCRIPTION

This command uploads a file to the media repository of a Matrix homeserver,
printing the returned F<mxc://> URL.

Normally the MIME type must be supplied as a second argument, but in the
common case of files whose names end in certain recognised file extensions,
the MIME type can be automatically inferred for convenience.

The recognised extensions are

   .jpg, .jpeg     image/jpeg
   .png            image/png

=cut

sub run
{
   my $self = shift;
   my ( $opts, $file, $type ) = @_;

   my $content = read_binary( $file );

   unless( defined $type ) {
      $type = "image/jpeg" if $file =~ m/\.jp[e]?g$/;
      $type = "image/png"  if $file =~ m/\.png$/;

      defined $type or
         die "Type not specified and could not guess it from the filename\n";
   }

   $self->do_json( POST => "/_matrix/media/r0/upload",
      content => $content,
      content_type => $type,
   )->then( sub {
      my ( $result ) = @_;

      $self->output_ok( "Uploaded content" );

      print $result->{content_uri} . "\n";

      Future->done();
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
