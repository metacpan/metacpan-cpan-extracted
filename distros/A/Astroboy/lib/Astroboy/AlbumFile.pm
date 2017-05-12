package Astroboy::AlbumFile;
use strict;
use vars qw($VERSION);
use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)/g;
use Carp;
use LEOCHARRE::Class2;
use Cwd;
use File::PathInfo;
use MP3::Tag;
use Astroboy::Base;
__PACKAGE__->make_accessor_setget(qw(t is_mp3 f abs_path filename_clean refile_overrite
title track artist album comment year genre filename));

sub new {
   my $class = shift;
   my $_abs = shift;
   $_abs or croak("missing pathto file arg");

   my $abs_path = Cwd::abs_path($_abs) or carp("cant abs_path to $_abs") and return;
   -f $abs_path or carp("Not file: $abs_path");
   
   my $_f = File::PathInfo->new($abs_path) or die;
   
   $ENV{HOME} or die('need env home set');
   
   
   my $self = {
      abs_path => $abs_path,      
      _f => $_f,
      is_mp3 => (lc( $_f->ext ) eq 'mp3' ? 1 : 0),
      filename => $_f->filename,
      filename_clean => 0,
      refile_overrite => 0,
   };

   if ($self->{is_mp3}){
      $self->{t} = MP3::Tag->new($abs_path) or die;
      debug("is mp3, got tag object");

      my $info = $self->{t}->autoinfo;
      
      for my $k (qw(title track artist album comment year genre)){
         my $v = $info->{$k};
         
         # clean up artist name
         if ($k eq 'artist'){
            $v = lc($v);
            $v=~s/^the\s*//;
         }
         elsif ($k eq 'album'){
            $v= lc($v);
         }
         elsif ( $k eq 'track' and ( length($v) < 2 )){
            $v = sprintf '%02d',$v;
         }

         $self->{$k} = $v;
         debug("got '$k': '$v'");
      }
      
   }
   
      

   bless $self, $class;

   return $self;
}



sub filename_suggested {
   my $self = shift;
   $self->filename_clean or debug("filename clean is off") and return $self->filename;

   $self->is_mp3 or debug("Not mp3") and return;
  
   my @fields;  
   for my $k (qw(artist album track title)){
      $self->$k or carp("Can't suggest filename, missing '$k'") and return;
      push @fields, $self->$k;
   }
   
   join(' - ',@fields) . '.mp3';

}

sub abs_loc_suggested_exists { 
   my $dir = $_[0]->abs_loc_suggested;
   -d $dir ? 1 : 0 
}

sub abs_loc_suggested_require {
   my $self= shift;
   $self->abs_loc_suggested_exists and return $self->abs_loc_suggested;
   require File::Path;

   File::Path::mkpath($self->abs_loc_suggested) or die;
   $self->abs_loc_suggested;
}  

sub abs_loc_suggested {
   my $self = shift;
   $self->rel_loc_suggested or warn("cannot suggest.") and return;
   
   $self->abs_music .'/'.$self->rel_loc_suggested;
}

sub rel_loc_suggested {
   my $self = shift;
   my $set = shift;

   if($set){
      $self->{rel_loc} = $set;
      return $set;
   }
   
   unless( $self->{rel_loc} ){

      $self->is_mp3 or carp("Not mp3") and return;
    
      my @fields;     
      for my $k (qw(artist album)){
         $self->$k or warn("Can't suggest filename, missing '$k'") and return;
         push @fields, $self->$k;
      }
   
      $self->{rel_loc} = join('/',@fields);
   }

   $self->{rel_loc};
}

sub rel_path_suggested {
   my $self = shift;

   my $filename = $self->filename_suggested;
   $filename ||= $self->filename;

   
   my $rel_loc = $self->rel_loc_suggested or carp("set rel_loc_suggested first") and return;

   "$rel_loc/$filename";
}

sub abs_path_suggested {
   my $self = shift;
   my $abs = $self->abs_loc_suggested .'/'.$self->filename_suggested;
   $abs=~/\.\w{1,5}$/i or die;
   $abs;
}

sub abs_path_suggested_exists {
   my $self = shift;
   my $abs = $self->abs_path_suggested or die;
   -e $abs ? 1 : 0;  
}

sub refile {
   my $self = shift;

   my $suggested = $self->abs_path_suggested;
   warn("refile: $suggested");
   $suggested or warn("no suggestion") and return;
   
   if( $self->abs_path_suggested_exists ){
   
      warn("EXISTS : '$suggested' suggested already exists..");
      if( $self->refile_overrite ){
         debug("overrite on");
      }
      else {
         warn("refile_overrite is off");
         return;
      }
   }
   
   $self->abs_loc_suggested_require;

   system('mv',$self->abs_path, $self->abs_path_suggested)==0
      or die( sprintf "Cannot move %s to %s, $?", $self->abs_path, $self->abs_path_suggested);


   $self->abs_path_suggested;
}



1;

__END__

=pod

=head1 NAME

Astroboy::AlbumFile

=head1 SYNOPSIS

   use Astroboy::AlbumFile;

   my $m =  Astroboy::AlbumFile->new('~/music/file.mp3');
   
   my $organized_path = $m->refile 
      or die($m->errstr);

   print "moved to $organized_path\n";

=head1 DESCRIPTION

Private.

=head1 METHODS

=head2 new()

Argument is path to file.
Returns undef if not file.

=head2 is_mp3()

Boolean.

=head2 title() track() artist() album() comment() year() genre()

If this is an mp3, attempts to seek these id3tags.

=head2 rel_loc_suggested()

Setget. Returns path like artist/album.

=head2 filename()

=head2 filename_suggested()

Tries to determine what the filename should be.

=head2 rel_path_suggested()

=head2 abs_path_suggested()

=head2 abs_path_suggested_exists()

=head2 abs_music()

Abs path to music archive. Defaults to $ENV{HOME}/music.
Please note this is a package variable, so it affects all Astroboy objects.

=head1 METHODS PRIVATE

=head2 f()

Returns File::PathInfo object.

=head2 t()

Returns MP3::Tag object.

=head1 CAVEATS

This package is in development.
Do not use the api, use the cli.
Use the command line interface scripts for stability.

=head1 SEE ALSO

L<Astroboy>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2008 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut


