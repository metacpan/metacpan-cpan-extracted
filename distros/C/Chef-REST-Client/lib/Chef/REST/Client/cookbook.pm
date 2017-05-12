#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::cookbook                             #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::cookbook;

use Chef::REST::Client::cookbook_versions;
use Chef::REST::Client::attributes;

$Chef::REST::Client::cookbook::VERSION = 1.0;

=pod 

=head1 NAME

Chef::REST::Client::cookbook

=head1 VERSION

1.0

=head1 SYNOPSIS

my $obj = new Chef::REST::Client::cookbook( 'name'       => $cookbook_name
                                          , 'url'        => $cookbook_url
                                          , 'versions'   => $versions
                                          , 'libraries'  => $libraries
                                          , 'providers'  => $providers
                                          , 'resources'  => $resources
                                          , 'root_files' => $root_files
                                          , 'version'    => $cookbook_version
                                          , 'templates'  => $templates
                                          , 'files'      => $files
                                          , 'attributes' => $attributes
                                          , 'recipes'    => $recipes
                                          , 'metadata'   => $metadata );
   
=head1 DESCRIPTION

used internally by other classes like L<Chef::REST::Client::cookbooks>

=head1 METHODS

=head2 Constructor

returns new Chef::REST::Client::cookbook object

=cut

sub new {
   my $class = shift;
   my $param = {@_};
   
   my $self = {};
 	bless $self, $class;   

   $self->name(     $param->{'name'      });
   $self->url(      $param->{'url'       });
   $self->versions( $param->{'versions'  });
   
   $self->libraries(  $param->{'libraries' });
   $self->providers(  $param->{'providers' });
   $self->resources(  $param->{'resources' });
   $self->root_files( $param->{'root_files'});
   $self->version (   $param->{'version'   });
   $self->templates ( $param->{'templates' });
   $self->files (     $param->{'files'     });
   $self->attributes( $param->{'attributes'});
   $self->recipes(    $param->{'recipes'   });
   $self->metadata(   $param->{'metadata'  });

  return $self;
}

=pod

=head2 url( $url )

set 'url' property value if speicfied else return previous value;

=cut

sub url        { $_[0]->{'url'       } = $_[1] if defined $_[1]; return $_[0]->{'url'       };}  

=pod

=head2 name( $name )

set 'name' property value if speicfied else return previous value;

=cut

sub name       { $_[0]->{'name'      } = $_[1] if defined $_[1]; return $_[0]->{'name'      };}

=pod

=head2 version( $version )

set 'version' property value if speicfied else return previous value;

=cut

sub version    { $_[0]->{'version'   } = $_[1] if defined $_[1]; return $_[0]->{'version'   };}

=pod

=head2 libraries( $libraries )

set 'libraries' value if speicfied else return previous value;

=cut

sub libraries
{
	my $self = shift;
	my $libraries = shift;
	$self->{'libraries'} = $libraries;
	return $self->{'libraries'}; 
}

=pod

=head2 providers( $providers )

set 'providers' value if speicfied else return previous value;

=cut

sub providers
{
	my $self = shift;
	my $providers = shift;
	$self->{'providers'} = $providers;
	return $self->{'providers'}; 
}

=pod

=head2 resources( $resources )

set 'resources' value if speicfied else return previous value;

=cut

sub resources
{
	my $self = shift;
	my $resources = shift;
	$self->{'resources'} = $resources;
	return $self->{'resources'};
}

=pod

=head2 root_files( $root_files )

set 'root_files' value if speicfied else return previous value;

=cut

sub root_files
{
	my $self = shift;
	my $root_files = shift;
	$self->{'root_files'} = $root_files;
	return $self->{'root_files'};
}

=pod

=head2 templates( $templates )

set 'templates' value if speicfied else return previous value;

=cut

sub templates
{
	my $self = shift;
	my $templates = shift;
	$self->{'templates'} = $templates;
	return $self->{'templates'};
}

=pod

=head2 files( $files )

set 'filess' value if speicfied else return previous value;

=cut

sub files
{
	my $self = shift;
	my $files = shift;
	$self->{'files'} = $files;
	return $self->{'files'};
}

=pod

=head2 attributes( $attributes )

$attributes is converted to L<Chef::REST::Client::attributes> class and is assigned to 'attributes' property
returns values of 'attributes' property if no argument is given.

=cut

sub attributes
{
	my $self = shift;
	my $attributes = shift;
	$self->{'attributes'} = new Chef::REST::Client::attributes($attributes) if defined $attributes;
	return $self->{'attributes'};
}

=pod

=head2 recipes( $recipes )

set 'recipes' value if speicfied else return previous value;

=cut

sub recipes
{
	my $self = shift;
	my $recipes = shift;
	$self->{'recipes'} = $recipes if defined $recipes;
	return $self->{'recipes'};
}

=pod

=head2 metadata( $metadata )

set 'metadata' value if speicfied else return previous value;

=cut

sub metadata
{
	my $self = shift;
	my $metadata = shift;
	$self->{'metadata'} = $metadata;
	return $self->{'metadata'};
}

=pod

=head2 versions( $versions )

set 'versions' value if speicfied else return previous value;
$versions is converted to L<Chef::REST::Client::coookbook_versions> class

=cut

# move to seperate class if possible
sub versions
{ 
	my $self  = shift;
	my $param = shift;
	   $param = new Chef::REST::Client::cookbook_versions( $param )
				    unless ref $param eq 'ARRAY'
				    &&     ref $param->[0] eq 'Chef::REST::Client::cookbook_version';
				     
	$self->{'versions'} = $param if defined $param;
	return $self->{'version'};
}

1;

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <bpatel10@nyit.edu>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut