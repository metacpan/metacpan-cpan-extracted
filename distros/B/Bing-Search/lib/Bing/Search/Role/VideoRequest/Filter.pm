package Bing::Search::Role::VideoRequest::Filter;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'Video_Filter' => (
   is => 'rw',
   isa => 'ArrayRef',
   lazy_build => 1

);

sub _build_Video_Filter { [] }

has '_Video_Filter_list' => ( 
   is => 'ro',
   isa => 'ArrayRef',
   default => sub { 
     [ qw(
         Duration:Short
         Duration:Medium
         Duration:Long
         Aspect:Standard
         Aspect:Widescreen
         Resolution:Low
         Resolution:Medium
         Resolution:High
      ) ]
   }
);


sub setVideo_Filter { 
   my( $self, $option ) = @_;
   return unless $option;
   my %opts = map { $_ => 1 } @{$self->_Video_Filter_list}; 
   if( $option =~ /^-/ ) { 
      # Remove an option
      $option =~ s/^-//;
      return unless exists $opts{$option};
      my @removed = grep { !$option } @{$self->Video_Filter}
   } else { 
      # Add an option
      $option =~ s/^\+//;
      return unless exists $opts{$option};
      my $list = $self->Video_Filter;
      unless( grep { $option } @$list ) { 
         push @$list, $option;
         $self->Video_Filter( $list );
      }
   }
}

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Video_Filter ) { 
      my $hash = $self->params;
      $hash->{'Video.Filter'} = $self->Video_Filter;
      $self->params( $hash );
   }
};

1;
