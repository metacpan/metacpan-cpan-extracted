#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::role                                 #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::role;

use parent qw { Chef::REST::Client::EndPoints };

$Chef::REST::Client::role::VERSION = 1.0;

sub new {
   my $class = shift;
   my $param = {@_};
   
   my $self = $class->SUPER::new(@_);
 	bless $self, $class;   

   $self->name(
          $param->{'name'               });
   $self->url(
          $param->{'url'                });
   $self->run_list(
          $param->{'run_list'           });
   $self->description(
          $param->{'description'        });
   $self->override_attributes(
          $param->{'override_attributes'});
   $self->default_attributes(
          $param->{'default_attributes' });
   $self->env_run_lists(
          $param->{'env_run_lists'      });

  return $self;
}

sub override_attributes { $_[0]->{'override_attributes'} = $_[1] if defined $_[1]; return $_[0]->{'override_attributes'};}
sub default_attributes  { $_[0]->{'default_attributes' } = $_[1] if defined $_[1]; return $_[0]->{'default_attributes' };}
sub env_run_lists       { $_[0]->{'env_run_lists'      } = $_[1] if defined $_[1]; return $_[0]->{'env_run_lists'      };}
sub run_list            { $_[0]->{'run_list'           } = $_[1] if defined $_[1]; return $_[0]->{'run_list'           };}
sub url                 { $_[0]->{'url'                } = $_[1] if defined $_[1]; return $_[0]->{'url'                };}  
sub name                { $_[0]->{'name'               } = $_[1] if defined $_[1]; return $_[0]->{'name'               };}
sub description         { $_[0]->{'description'        } = $_[1] if defined $_[1]; return $_[0]->{'descripton'         };}

1;


=pod

=head1 NAME 

Chef::REST::Client::role

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef::REST::Client::role;

my $obj = new Chef::REST::Client::role( %params );
   $obj->name
   $obj->url
   $obj->run_list
   $obj->description
   $obj->override_attributes
   $obj->default_attributes
   $obj->env_run_lists
  
=head1 DESCRIPTION

Class that represents chef role

=head1 METHODS

=head2 Constructor

return new L<Chef::REST::Client::role> object.

=head2 name ( $name )

set or get name property

=head2 url ( $url )

set or get url property

=head2 run_list ( $run_list )

set or get run_list property

=head2 description ( $description )

set or get description property

=head2 override_attributes ( $override_attributes )

set or get override_attributes property

=head2 default ( $default_attributes )

set or get default_attributes property

=head2 env_run_lists ( $env_run_lists )

set or get env_run_lists property

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <mail4bhavin@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut
