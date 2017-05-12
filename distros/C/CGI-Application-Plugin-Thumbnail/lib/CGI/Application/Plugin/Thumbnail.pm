package CGI::Application::Plugin::Thumbnail;
use strict;
use Carp;
use LEOCHARRE::DEBUG;
use warnings;
use Cwd;
use Exporter;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
our $VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /(\d+)/g;
@ISA = qw/ Exporter /;

@EXPORT_OK = (qw(
__thumbnail_style
_abs_thumbnail
_img
abs_image
abs_thumbnail
get_abs_image
set_abs_image
thumbnail_header_add
thumbnail_restriction
_thumbnail_rel_dir
__assure_thumb_dir
));

%EXPORT_TAGS = (
   'all' => \@EXPORT_OK,
);

sub set_abs_image {
   my($self,$arg) = @_; 
   defined $arg or confess('missing arg');
   $self->{_data_}->{_img} = undef;

   require File::PathInfo;
   my $f = new File::PathInfo;
   $f->set($arg) or return;
   $self->{_data_}->{_img} = $f;
   return 1;  
}

sub get_abs_image {
   my($self, $name) = @_;
   $name ||= 'rel_path';
   $self->{_data_}->{_img} = undef;
   
   $self->query->param($name) or return;
   my $abs = $ENV{DOCUMENT_ROOT}.'/'.$self->query->param($name);
   
   require File::PathInfo;   
   my $f = new File::PathInfo;
   $f->set($abs) or return;
   $self->{_data_}->{_img} = $f;
   return 1;
}

sub abs_image {
   my $self = shift;
   $self->_img or return;
   return $self->_img->abs_path;   
}


sub abs_thumbnail {
   my $self = shift;   
   $self->{_abs_thumbnail} ||= $self->_abs_thumbnail or return;
   return $self->{_abs_thumbnail};
}

# --------------

sub _img {
   my $self = shift;
   $self->{_data_}->{_img} or $self->get_abs_image or return;   
   return $self->{_data_}->{_img};
}

sub _thumbnail_rel_dir {
   my $self= shift;
   $self->{_thumbnail_rel_dir} ||= ( $self->param('thumbnail_rel_dir') || '.thumbnails' );
   
}

sub _abs_thumbnail {
   my $self = shift;
   
   $self->_img or return;

   my $tmbd =  $self->_thumbnail_rel_dir;
   
   my $abs_td = $ENV{DOCUMENT_ROOT} .'/'.$tmbd;
   my $abs_thumb = $abs_td . '/'. $self->thumbnail_restriction .'/'.$self->_img->rel_path;
   debug("$abs_thumb\n");

   # does it exist
   if (-f $abs_thumb){
      return $abs_thumb;
   }

   # THEN WE ARE CREATING ONE...

   $self->__assure_thumb_dir($abs_thumb);      
   my $abs_input =    $self->_img->abs_path;
   my $size = $self->thumbnail_restriction;
   $size or die('no size');
   $abs_input or die('no abs input');

   require Image::Thumbnail;

   my $thumb = Image::Thumbnail->new(
      size        => $size,
      input       => $abs_input,
      outputpath  => $abs_thumb,
   );
   #my $thumb = $self->__create_a_thumbnail_object();   
   
   $self->__thumbnail_style($thumb); # optional user hook        
   $thumb->create;
   return $abs_thumb;
}


sub __assure_thumb_dir {
   my ($self, $abs_thumb) = @_;
   # ok. lets make up the path
   require File::Path;
   my $abs_loc = $abs_thumb;
   $abs_loc=~s/\/[^\/]+$// or die;
   unless( -d $abs_loc ){
      File::Path::mkpath($abs_loc) or die;
   }   
   return $abs_loc;
}


sub __thumbnail_style {
   my($self,$thumbnail_object) = @_;
   return 1;
}












# THE REST HERE DOWN IS NOT AFFECTED BY PATHS OF THUMB AND IMAGE

sub thumbnail_restriction {
   my $self = shift;
   $self->{_data_} ||={};
   unless( defined $self->{_data_}->{thumbnail_restriction}){

      my $tnr;

      # first via query string
      if ( defined $self->query->param('thumbnail_restriction') and $self->query->param('thumbnail_restriction')){
         my $_tnr = $self->query->param('thumbnail_restriction');
         unless( $_tnr=~/^\d+x\d+$/ ){
            warn("thumbnail restriction received via query string [$_tnr] is invalid");
            $_tnr = undef;
         }
         $tnr = $_tnr;         
      }

      # via constructor?
      elsif ( defined $self->param('thumbnail_restriction') and $self->param('thumbnail_restriction')){
         my $_tnr = $self->param('thumbnail_restriction');
         unless( $_tnr=~/^\d+x\d+$/ ){
            warn("thumbnail restriction received via param to constructor [$_tnr] is invalid");
            $_tnr = undef;
         }
         $tnr = $_tnr; 
      }   

      $tnr ||= '100x100';
      $self->{_data_}->{thumbnail_restriction} = $tnr;
   }   

   return  $self->{_data_}->{thumbnail_restriction};
}

sub thumbnail_header_add {
   my $self = shift;
   
   $self->_img or debug('no _img') and return;
   my $ext = $self->_img->ext or debug('no _img ext') and return;

   debug($ext);
   my $mime =
   $ext=~/jpe?g$/i ? 'image/jpeg' :
      $ext=~/gif$/i ? 'image/gifg' :
         $ext=~/png$/i ? 'image/png' : undef;
   
   $mime or debug('no mime') and return;

   $self->header_add(
      -type => $mime,
      -attachment => $self->_img->filename,
   );
   return 1;      
}


1;

