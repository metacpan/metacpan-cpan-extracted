package Bing::Search::Role::SearchRequest::Options;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';

has 'Options' => ( 
   is => 'rw',
   isa => 'ArrayRef',
   lazy_build => 1
);

sub _build_Options { [] }

sub setOption { 
   my( $self, $option ) = @_;
   # Since there's only two possible options here..
   unless( $option =~ /DisableLocationDetection$|EnableHighlighting$/ ) {
      carp 'Invalid option: ' . $option . ' -- ignoring.';
      return;
   }
   if( $option =~ /^-/ ) { 
      # Remove an option.
      my @removed = grep { !$option } @{$self->Options};
      $self->Options( \@removed );
   } else { 
      # add an option
      $option =~ s/^\+//;
      my $list = $self->Options;
      unless( grep { $option } @$list ) { 
         push @$list, $option;
         $self->Options( $list );
      }
   }

}


before 'build_request' => sub { 
   my $self = shift;
   my $hash = $self->params;
   $hash->{Options} = $self->Options;
   $self->params( $hash );
};

1;
