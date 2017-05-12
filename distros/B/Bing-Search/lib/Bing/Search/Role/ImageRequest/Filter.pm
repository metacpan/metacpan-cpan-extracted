package Bing::Search::Role::ImageRequest::Filter;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'Image_Filter' => (
   is => 'rw',
   isa => 'ArrayRef',
   lazy_build => 1

);

sub _build_Image_Filter { [] }

has '_Image_Filter_list' => ( 
   is => 'ro',
   isa => 'ArrayRef',
   default => sub { 
      [ qw(
         Size:Small
         Size:Medium
         Size:Large
         Size:Height:
         Size:Width:
         Aspect:Square
         Aspect:Wide
         Aspect:Tall
         Color:Color
         Color:Monochrome
         Style:Photo
         Style:Graphics
         Face:Face
         Face:Portrait
         Face:Other
      ) ]

   }
);

sub _image_handle_hw { 
   my( $self, $dim, $value );
   # write this, refactor this, etc. 
   
}

sub setImage_Filter { 
   my( $self, $option, $value ) = @_;
   return unless $option;
   my %opts = map { $_ => 1 } @{$self->_Image_Filter_list}; 
   if( $option =~ /Size:Height|Size:Width/ ) { 
      carp "Filter $option not implemented.  Ignoring you.";
      return;
   }
   if( $option =~ /^-/ ) { 
      # Remove an option
      $option =~ s/^-//;
      return unless exists $opts{$option};
      my @removed = grep { !$option } @{$self->Image_Filter}
   } else { 
      # Add an option
      $option =~ s/^\+//;
      return unless exists $opts{$option};
      my $list = $self->Image_Filter;
      unless( grep { $option } @$list ) { 
         push @$list, $option;
         $self->Image_Filter( $list );
      }
   }
}

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Image_Filter ) { 
      my $hash = $self->params;
      $hash->{'Image.Filter'} = $self->Image_Filter;
      $self->params( $hash );
   }
};

1;
