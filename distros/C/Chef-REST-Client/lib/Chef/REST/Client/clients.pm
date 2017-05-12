#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::clients                              #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::clients;
use parent qw { Chef::REST::Client::EndPoints };

$Chef::REST::Client::clients::VERSION = 1.0;

sub list 
  {
    my $self = shift;
    my $list_of_roles = $self->___data___;
    foreach my $c ( keys(%$list_of_clients) ){
      my $client = Chef::REST::Client::client( 'name' => $r,  
                                             'url'  => $list_of_roles->{$r} 
                                           );
      push @{'___clients_list___'} , $client;
    }
    return @{'___clients_list___'};
  }
  
  1;
  
__DATA__
 
=pod
  
=head1 NAME
  
Chef::REST::Client::clients
  
=head1 VERSION
  
1.0
  
=head1 SYNOPSIS

$obj->client->list;
 
=head1 DESCRIPTION

This is an internal module used by L<Chef::REST::Client>

=head1 METHODS

=head2 list

lists all the L<Chef::REST::Client::client> clients

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <bpatel10@nyit.edu>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut