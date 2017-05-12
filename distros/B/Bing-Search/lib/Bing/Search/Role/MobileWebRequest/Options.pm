package Bing::Search::Role::MobileWebRequest::Options;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';

has 'MobileWeb_Options' => ( 
   is => 'rw',
   isa => 'ArrayRef',
   lazy_build => 1
);

sub _build_MobileWeb_Options { [] }

sub setMobileWeb_Option { 
   my( $self, $option ) = @_;
   # Since there's only two possible options here..
   unless( $option =~ /DisableHostCollapsing$|DisableQueryAlterations$/ ) {
      carp 'Invalid option: ' . $option . ' -- ignoring.';
      return;
   }
   if( $option =~ /^-/ ) { 
      # Remove an option.
      my @removed = grep { !$option } @{$self->MobileWeb_Options};
      $self->MobileWeb_Options( \@removed );
   } else { 
      # add an option
      my $list = $self->Options;
      unless( grep { $option } @$list ) { 
         push @$list, $option;
         $self->MobileWeb_Options( $list );
      }
   }

}


before 'build_request' => sub { 
   my $self = shift;
   my $hash = $self->params;
   $hash->{'MobileWeb.Options'} = $self->MobileWeb_Options;
   $self->params( $hash );
};

1;
