#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::environment                          #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::environment;
use parent qw { Chef::REST::Client::EndPoints };

$Chef::REST::Client::environment::VERSION = 1.0;

sub new {
   my $class = shift;
   my $param = {@_};
   
   my $self = $class->SUPER::new(@_);
 	bless $self, $class;   

   $self->name(
          $param->{'name'               });
   $self->url(
          $param->{'url'                });
   $self->description(
          $param->{'description'        });
   $self->override_attributes(
          $param->{'override_attributes'});
   $self->default_attributes(
          $param->{'default_attributes' });
   $self->cookbook_versions(
          $param->{'cookbook_versions'  });

  return $self;
}

sub override_attributes { $_[0]->{'override_attributes'} = $_[1] if defined $_[1]; return $_[0]->{'override_attributes'};}
sub default_attributes  { $_[0]->{'default_attributes' } = $_[1] if defined $_[1]; return $_[0]->{'default_attributes' };}

sub url                 { $_[0]->{'url'                } = $_[1] if defined $_[1]; return $_[0]->{'url'                };}  
sub name                { $_[0]->{'name'               } = $_[1] if defined $_[1]; return $_[0]->{'name'               };}
sub description         { $_[0]->{'description'        } = $_[1] if defined $_[1]; return $_[0]->{'descripton'         };}

# move to seperate class if possible
sub cookbook_versions   { $_[0]->{'cookbook_versions'  } = $_[1] if defined $_[1]; return $_[0]->{'cookbook_versions'  };}

1;

=pod

=head1 NAME 

Chef::REST::Client::environment

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef::REST::Client::environment;

  my $obj = new Chef::REST::Client::environment
                ( 'name'                => $name
                , 'url'                 => $url
                , 'description'         => $description
                , 'override_attributes' => $override_attributes
                , 'default_attributes'  => $default_attributes
                , 'cookbook_versions'   => $cookbook_versions
                );
     $obj->key;
     $obj->value;

=head1 DESCRIPTION

Class representation of Chef Environment.

=head1 METHODS

=head2 Constructor

returns new object of class L<Chef::REST::Client::environment> with %params

=head2 name ( $name )

get or set value for 'name'

=head2 url ( $url )

get or set value for 'url'

=head2 description ( $description )

get or set value for 'description'

=head2 override_attributes ( $override_attributes )

get or set value for 'override_attributes'

=head2 default_attributes ( $default_attributes )

get or set value for 'default_attributes'

=head2 cookbook_versions ( $cookbook_versions )

get or set value for 'cookbook_versions'

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <mail4bhavin@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut