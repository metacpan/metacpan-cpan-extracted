package App::ECR;

use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);

use Role::Tiny::With;
with 'App::AWS';

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(profile region));

use parent qw(App::Command);

########################################################################
sub describe_images {
########################################################################
  my ( $self, $repository_name, $query ) = @_;

  return $self->command(
    'describe-images' => [
      '--repository-name' => $repository_name,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub get_latest_image {
########################################################################
  my ( $self, $repository_name ) = @_;

  if ( $repository_name =~ /\//xsm ) {
    $repository_name = ( split /\//xsm, $repository_name )[-1];
  }

  ($repository_name) = split /:/xsm, $repository_name;

  my $query = 'imageDetails[?imageTags != null && contains(imageTags, `latest`)]';

  my $result = $self->describe_images( $repository_name, $query );

  return @{ $result || [] };
}

########################################################################
sub validate_images {
########################################################################
  my ( $self, @images ) = @_;

  foreach my $image (@images) {
    warn sprintf "WARN: image not found in ECR: [%s]\n", $image
      if !$self->get_latest_image($image);
  }

  return;
}

1;
