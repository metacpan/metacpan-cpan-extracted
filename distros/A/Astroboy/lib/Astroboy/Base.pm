package Astroboy::Base;
use strict;
use vars qw(@ISA $VERSION @EXPORT);
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw(debug abs_music artists artists_count artist_guess);
use LEOCHARRE::Dir;
use LEOCHARRE::Class2;
use Carp;
no strict 'refs';

__PACKAGE__->make_count_for('artists');
$Astroboy::ABS_MUSIC ||=  $ENV{HOME}.'/music';

$VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /(\d+)/g;

sub debug { $Astroboy::DEBUG and print STDERR "@_"; 1 }

sub abs_music { 
   
   if( $_[1] ){ 
      -d $_[1] 
         or warn("Not dir on disk: $_[1]");
      $Astroboy::ABS_MUSIC = $_[1];
   }
   $Astroboy::ABS_MUSIC ||=  $ENV{HOME}.'/music';
}

 
sub artists {
   my $self = shift;

   unless( $self->{artists} ){
      
      my @a = sort (  LEOCHARRE::Dir::lsd( abs_music() ) );
      $self->{artists} = [@a];
   }
   $self->{artists};
}




sub artist_guess {
   my ($self,$path) = ($_[0],lc($_[1]));

   #TODO consider using String::Similarity::Group

   unless($self->{artists_match}){
      my $artists = $self->artists;
      for (@$artists){
         my $a = lc ($_);
         $a=~s/_+/ /g;
         $a=~s/^\s+|\s+$//g;
         $self->{artists_match}->{$a}++;
      }      
   }


   # just return first match
   for my $artist ( keys %{$self->{artists_match}}  ){
      
      $path=~/\b$artist\b/ or next;
      return $artist;
   }
   
   return;
}


1;

__END__

see Astroboy::API
