#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::cookbooks                            #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::cookbooks;
use parent qw { Chef::REST::Client::EndPoints };

$Chef::REST::Client::cookbooks::VERSION = 1.0;

use Chef::REST::Client::cookbook;
use Chef::REST::Client::cookbook_versions;

=pod 

=head1 NAME

Chef::REST::Client::cookbooks

=head1 VERSION

1.0

=head1 SYNOPSIS

$obj->cookbooks('yum', '_latest')->details;
$obj->cookbooks('yum', '_latest')->details->attributes;

=head1 DESCRIPTION

This class contains methods to get cookbooks from chef server.

=head1 METHODS

=head2 list 

This method list all the cookbooks available. 
$obj->cookbook()->list;

=cut

# this module will be passed tha json parsed hash 
# under ___data__() or variable.
# process it depending on the content expected.

sub list 
{
    my $self = shift;
    my $list_of_cookbooks = $self->___data___;
	 return undef if $self->___data___->{'chef_type'} eq 'cookbook';
	
    foreach my $c ( keys(%$list_of_cookbooks) ){
      my $cookbook = new Chef::REST::Client::cookbook('name' => $c);
 			$cookbook->url( $list_of_cookbooks->{$c}->{'url'});
 			$cookbook->versions( $list_of_cookbooks->{$c}->{'versions'} );
      push @{'___cookbooks_list___'} , $cookbook;
    }
    return @{'___cookbooks_list___'};
}

=head2 details

This method fetches details about a cookbook

$obj->cookbook('yum')->details;

=cut

sub details
{
  my $self = shift;
  my $data = $self->___data___;

#return $self->raw();

  return $self->raw() unless ref $data eq 'HASH';

	return new Chef::REST::Client::cookbook(
		'name'       => $data->{'cookbook_name'},
		'libraries'  => $data->{'libraries'    },
		'providers'  => $data->{'providers'    },
		'resources'  => $data->{'resources'    },
		'root_files' => $data->{'root_files'   },
		'version'    => $data->{'version'      },
		'templates'  => $data->{'templates'    },
		'files'      => $data->{'files'        },
		'attributes' => $data->{'attributes'   },
		'recipes'    => $data->{'recipes'      },
		'metadata'   => $data->{'metadata'     },
	) if defined $data->{'cookbook_name'};  
  
  my $obj =  new Chef::REST::Client::cookbook (  'name' => keys(%$data));
     $obj->url(      $data->{ $obj->name }->{'url'     } );
     $obj->versions( $data->{ $obj->name }->{'versions'} );


	return $obj;     
}
 
1;

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <bpatel10@nyit.edu>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut