package Bing::Search::Role::WebRequest::Options;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';

has 'Web_Options' => ( 
   is => 'rw',
   isa => 'ArrayRef',
   lazy_build => 1
);

sub _build_Web_Options { [] }

sub setWeb_Option { 
   my( $self, $option ) = @_;
   # Since there's only two possible options here..
   unless( $option =~ /DisableHostCollapsing$|DisableQueryAlterations$/ ) {
      carp 'Invalid option: ' . $option . ' -- ignoring.';
      return;
   }
   if( $option =~ /^-/ ) { 
      # Remove an option.
      my @removed = grep { !$option } @{$self->Web_Options};
      $self->Web_Options( \@removed );
   } else { 
      # add an option
      my $list = $self->Options;
      unless( grep { $option } @$list ) { 
         push @$list, $option;
         $self->Web_Options( $list );
      }
   }

}


before 'build_request' => sub { 
   my $self = shift;
   my $hash = $self->params;
   $hash->{'Web.Options'} = $self->Web_Options;
   $self->params( $hash );
};

1;
