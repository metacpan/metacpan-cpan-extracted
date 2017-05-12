#--------------------------------------------------------------------#
# Class : Chef                                                       #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef;
$Chef::VERSION = 1.0;

sub new {
  my $class = shift;
  my $param  = {@_};
  my $self   = {};

  bless $self, $class;
  $self->server( $param->{'chef_server'} ) if defined $param->{'chef_server'};
  $self->chef_version( $param->{'chef_version'} ) if defined $param->{'chef_version'};  
  return $self;

  sub server {
    my ($self,$server) = (@_);
       $self->{ 'CHEF_SERVER' } = $server if defined $server;
    return $self->{ 'CHEF_SERVER' };
  }
  sub chef_version {
    my ($self,$chef_version) = (@_);
       $self->{ 'CHEF_VERSION' } = $chef_version if defined $chef_version;
    return $self->{ 'CHEF_VERSION' };
  }
  sub host_port {
    my $self = shift;
    my $server = $self->server;
       $server =~ m/^(http|https):\/\/(.*)(:(\d))?/;
    return "$2";
  }
  sub organization_name {
    my ($self,$organization_name) = (@_);
       $self->{ 'ORGANIZATION_NAME' } = $organization_name if defined $organization_name;
    return $self->{ 'ORGANIZATION_NAME' };
  }
  sub hosted_chef {
    my ($self,$hosted_chef) = (@_);
       $self->{ 'HOSTED_CHEF_' } = $hosted_chef if defined $server;;
    return $self->{ 'HOSTED_CHEF' };
  }
  
  sub private_key {
    my ($self,$private_key) = (@_);
           $self->{ 'CHEF_CLIENT_PRIVATE_KEY' } = $private_key if defined $private_key;
    return $self->{ 'CHEF_CLIENT_PRIVATE_KEY' };
  }
}#nwe

__DATA__

=pod

=head1 NAME 

Chef - Super Class for L<Chef::REST::Client>

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef;

  my $obj = new Chef( 'chef_server'   => 'https://api.opscode.com/organizations/zyx'
                     , 'chef_version' => '11.0.4' );

=head1 DESCRIPTION

This is the Super Class module, Methods listed under this class shouldn't be access directly. 
Inturn these are used internally by other modules eg: L<Chef::REST::Client> 

=head1 METHODS

=head2 Constructor

=head3 Chef( chef_server , chef_version );

returns new Chef object and loads Chef module;

=head3 sever ( [<chef server>] )

sets CHEF_SERVER if the values is passed or returns the initialized value

=head3 chef_version ( [<chef version>] )

sets CHEF_VERSION if passed or returns initialized value

=head3 organization_name( [name] )

set ORGANIZATION_NAME if passed or returns initialized value

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <bpatel10@nyit.edu>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut

1;