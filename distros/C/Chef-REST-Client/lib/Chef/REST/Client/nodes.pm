#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::nodes                                #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::nodes;
use parent qw { Chef::REST::Client::EndPoints };

use Chef::REST::Client::node;

$Chef::REST::Client::nodes::VERSION = 1.0;

sub list 
  {
    my $self = shift;
    my $list_of_nodes = $self->___data___;

    foreach my $n ( keys(%$list_of_nodes) ){
      my $node = new Chef::REST::Client::node( 
      						'name' => $n,  
                        'url'  => $list_of_nodes->{$n} 
                 );
      push @{'___nodes_list___'} , $node;
    }
    return @{'___nodes_list___'};
  }
  
sub details
{
  my $self = shift;
  my $data = $self->___data___;

  return $self->raw() unless ref $data eq 'HASH';

#  return $data;
  
  return new Chef::REST::Client::node(
  		'name' => $data->{'name'},
  		'environment' => $data->{'chef_environment'},
  		'automatic'   => $data->{'automatic'},
  		'override'    => $data->{'override' },
  		'default'     => $data->{'default'  },
  		'run_list'    => $data->{'run_list' }
  );
	
    
}  
  
1;

=pod

=head1 NAME 

Chef::REST::Client::nodes

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef::REST::Client::nodes;

$obj->nodes->list;
$obj->nodes('server1')->details;
  
=head1 DESCRIPTION

Class that represents collection of nodes 

=head1 METHODS

=head2 list

return list of nodess, array of L<Chef::REST::Client::node> objects.

=head2 details ( $details )

retun detail about a perticular node.

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <mail4bhavin@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut
