package Astroboy::AlbumDir;
use strict;
use vars qw($VERSION);
use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.9 $ =~ /(\d+)/g;
use LEOCHARRE::Dir ':all';
use Cwd;
use Astroboy::Base;
use LEOCHARRE::Class2;
#use Smart::Comments '###';
use Astroboy::AlbumFile;
__PACKAGE__->make_accessor_setget(qw(abs_path errstr));
__PACKAGE__->make_accessor_setget_aref(qw(ls_trash ls_mp3 ls));



sub new {
   my $class = shift;
   my $_abs = shift;
   $_abs or croak('Missing abs path to dir argument');
   
   my $abs_path = Cwd::abs_path($_abs) or carp("Can't abs_path() to $_abs") and return;

   -d $abs_path or carp("Not dir on disk: $abs_path") and return;

   my @ls = lsf($abs_path);

   my @mp3s = grep { /\.mp3$/i } @ls;
   my @trash = grep { !/\.mp3$/i } @ls;
   
   $ENV{HOME} or die("need env home to be set");
   
   my $self = {
      abs_path    => $abs_path,
      ls          => \@ls,
      ls_trash    => \@trash,
      ls_mp3      => \@mp3s,      
   };

   ### $self
   
   
   bless $self, $class;



      
   $self->is_album or carp("Not deemed album: $abs_path") and return;

   return $self;
}


sub ls_mp3_percent {
   my $self = shift;

   my $total_files = $self->ls_count || 0;
   my $total_mp3   = $self->ls_mp3_count || 0;
   $total_mp3 or return 0;
   
   #debug("$total_files $total_mp3");

   int( ($total_mp3 * 100 ) / $total_files );
}


sub is_album { ($_[0]->ls_mp3_percent) > 50  ? 1 : 0 }

sub empty_trash {
   $_[0]->ls_trash_count or warn("Nothing in trash.\n") and return;
   unlink @{$_[0]->ls_trash};
   1;
}


# paths
#
sub rel_path_suggested {
   my $self = shift;
   my $artist = $self->artist or return;
   my $album  = $self->album or return;
   "$artist/$album";
}

sub abs_path_suggested {
   my $self = shift;
   my $rel = $self->rel_path_suggested or return;
   $self->abs_music .'/'.$rel;
}

sub abs_path_suggested_exists {
   my $self = shift;
   my $abs = $self->abs_path_suggested or die;
   -e $abs ? 1 : 0;  
}

sub abs_path_suggested_require {
   my $self= shift;
   $self->abs_path_suggested or return;
   $self->abs_path_suggested_exists and return $self->abs_path_suggested;
   require File::Path;

   File::Path::mkpath($self->abs_path_suggested) or die;
   $self->abs_path_suggested;
}  




sub refile {
   my $self = shift;

   my $abs_loc = $self->abs_path_suggested_require 
      or $self->errstr("Can't refile, cant get abs path suggested require, ".$self->errstr ) 
      and return;

   
   
   for my $filename ( @{$self->ls} ){
      my $from = $self->abs_path ."/$filename";
      my $to   = $abs_loc."/$filename"; 
   

      system('mv',$from, $to) ==0 
         or die(sprintf "Cannot move %s to %s, $?", $from,$to);
   }

   rmdir $self->abs_path;

   $abs_loc;
}



sub artist {
   my($self,$arg)=@_;
   $arg and $self->{artist} = $arg;

   $self->{artist} ||= $self->_ls_mp3s_aggree_on('artist');
}



sub album {
   my($self,$arg)=@_;
   $arg and $self->{album} = $arg;

   $self->{album} ||= $self->_ls_mp3s_aggree_on('album');
}


sub _ls_mp3s_aggree_on {
   my ($self,$param) = @_;
   no strict 'refs';

   my $suggested;
   my $x=0;
   for ( @{$self->ls_mp3} ){
            my $abs = $self->abs_path.'/'.$_;
            debug("consolidating with : $abs");
            my $a = $self->file($abs) 
               or warn("cant instance $abs")
               and next;

            $a->is_mp3 
               or debug("not mp3") and next;
            my $got = $a->$param or next;
            $suggested ||= $got;
            $x++;

            if($suggested){
               $suggested eq $got
                  or $self->errstr("Cant figure out '$param', $suggested not same as $got for $abs") 
                  and return;
            }
   }

   $suggested or $self->errstr("Cant consolidate '$param' in $x files");

   $suggested;
}

sub file { 
   my ($self,$_path) = @_;
   my $abs = Cwd::abs_path($_path) or die;
   -f $abs or die;
   ($self->{file}->{$abs} ||= Astroboy::AlbumFile->new( $abs )) or die;
}




1;

__END__

=pod

=head1 NAME

Astroboy::AlbumDir

=head1 DESCRIPTION

Private.

=head1 METHODS

=head2 new()

Argument is abs path to directory.

If it's not deemed as an is_album(), returns undef.

=head2 abs_path()

Abs path to dir.

=head2 abs_music()

Abs pathto where music should reside. Default is ~/music.

=head2 ls()

Returns array ref of all files, these are filenames only. Not absolute paths.

=head2 ls_count()

Returns count of files.

=head2 ls_mp3()

Like ls(), returns array ref of mp3 files in this dir.

=head2 ls_trash()

Like ls(), returns everything not mp3.

=head2 ls_mp3_percent()

Of the files in this dir, what percentage are mp3s.

=head2 is_album()

If more than 50% of files are mp3, then true, else false.

=head2 empty_trash()

Moves files to a temp directory. Sort of a safe delete.
This is everything that is not an mp3 file.
Call at your own peril.

=head2 album()

If there are mp3 files, and they all have same album id3 tag, returns album.


=head2 artist()

If there are mp3 files, and they all have same artist id3 tag, returns artist.

=head1 SEE ALSO

L<Astroboy>

=head1 CAVEATS

This package is in development.
Do not interface with the api directly. 
Use the command line interface scripts for stability.

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


