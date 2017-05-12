package Chef::REST::Client;
$Chef::REST::Client::VERSION = 1.2;

=pod

=head1 NAME

Chef::REST::Client

=head1 VERSION

1.2

=head1 SYNOPSIS

use Chef::REST::Client;

my $obj = new Chef::REST::Client
          ( 'chef_client_name' => $chef_client_name ,
            'chef_client_privaate_key' => $private_key );

   $obj->private_key( $private_key );
   $obj->name( $chef_client_name );
   $obj->roles('vagrant')->details;
   $obj->roles('vagrant','environments')->details
   $obj->roles->list;
   
   $obj->search( 'secrets' , {  q => 'id:centrify', rows => 1 } )->details
   
   $obj->environments(<env_name>,'cookbooks' , <cookbook_name>)->details;

   $obj->environments(<env_name>,'cookbooks_versions'
                                ,{ 'method' => 'post'
                                , 'data' => { 'runlist' => [ 'ms-scribe'] }
                                  }
                     );
   $obj->roles(<role_name>)->details->override_attributes;
                   
=head1 DESCRIPTION

This is the interface to the Chef server api methods listed on opscode documentation 
L<opscode Chef Api|http://docs.opscode.com/api_chef_server.html>
currently it provides implementation for only GET methods

=head1 METHODS

=head2 role( $role )

returns new L<Chef::REST::Client::role> object
used by other classes

=head2 roles ( @roles )

makes a GET request to the chef server for all the @roles and returns and L<Chef::REST::Client::roles> object.
you can directly get details for all the roles as $obj->role( 'role1', 'role2' )->details;

this inturn will return L<Chef::REST::Client::role> 

=over 

=item /roles

$obj->roles->list 

=item /roles/<role_name>

$obj->roles(<role_name>)->details

$obj->roles(<role_name>)->details->run_list;

$obj->roles(<role_name>)->details->override_attributes;

=back

=head2 runlist ( @$recipes )

returns new L<Chef::REST::Client::runlist> object. it takes a list of recipies as parameter.
used by other classes

=head2 sandboxes

returns new L<Chef::REST::Client::sandboxes> object. $obj->sandboxes->list;

=over 

=item /sandboxes

$obj->sandboxes->list 

=item /sandboxes/<id>

$obj->sandboxes(<id>)->details

=back

=head2 search

returns new L<Chef::REST::Client::search> 

=over

=item /search

$obj->search->listen

=item /search/<index>

$obj->search(<index>)->details

=item /search/ query id:centrify and get rows 1

$obj->search( 'secrets' , {  q => 'id:centrify', rows => 1 } )->details

=back  

=head2 recipe

returns new L<Chef::REST::Client::recipe> object. used by other classes

=head2 principals

returns new L<Chef::REST::Client::principals> object. $obj->principals->details;

=over 

=item /principals

$obj->principals->list 

=item /principals/<name>

$obj->principals(<name>)->details

=back

=head2 node

returns new L<Chef::REST::Client::node> object. $obj->node->details;
used by other classes
 
=head2 nodes

returns new L<Chef::REST::Client::nodes> object. $obj->nodes->list;

=over 

=item /nodes

$obj->nodes->listen

=item /nodes/<node_name>

$obj->nodes(<node_name>)->details 

=back

=head2 envrunlist

returns new L<Chef::REST::Client::envrunnlist> object. used by other classes

=head2 environment

returns new L<Chef::REST::Client::environment> object. used by other classes

=head2 environments

returns new L<Chef::REST::Client::environments> object.

=over 

=item  /environment/<env_name>

$obj->environments(<env_name>)->details;

=item /environment/<env_name>/cookbooks/<cookbook_name>

$obj->environments(<env_name>,'cookbooks' , <cookbook_name>)->details;

=item /environment/<env_name>/cookbooks

$obj->environments(<env_name>,'cookbooks')

=item POST /environments/<env_name>/cookbooks_versions

$obj->environments(<env_name>,'cookbooks_versions'
                             ,{ 'method' => 'post'
                              , 'data' => { 'runlist' => [ 'ms-scribe'] }
                              }
                   );

=back

=head2 databag

returns new L<Chef::REST::Client::databag> object.

=head2 data

returns new L<Chef::REST::Client::data> object.

=over 

=item /data

$obj->data->list

=item /data/<var_name>

$obj->data( <var_name> )->details

=back

=head2 cookbook

returns new L<Chef::REST::Client::cookbook> object.

=head2 cookbooks

returns new L<Chef::REST::Client::cookbooks> object.

=over 

=item /cookbooks

$obj->cookbooks->list 

=item /cookbooks/<cookbook_name>

$obj->cookbooks(<cookbook_name>)->details 

$obj->cookbooks(<cookbook_name> , '_latest' )->details->recipes;

$obj->cookbooks(<cookbook_name> , '_latest' )->details->attributes;

=back

=head2 cookbook_version

returns new L<Chef::REST::Client::cookbook_version> object.
used by other classes

=head2 cookbook_versions

returns new L<Chef::REST::Client::cookbook_versions> object.
collection of L<Chef::REST::Client::cookbook_version>

=head2 clients

returns new L<Chef::REST::Client::clients> object.

=over 

=item /clients

$obj->clients->list 

=item /clients/<client_name>/

$obj->clients(<client_name>)->details


=back

=head2 attribute

returns new L<Chef::REST::Client::attribute> object.
used by other classes to structure data

=head2 attributes

returns new L<Chef::REST::Client::attributes> object.
collection of L<Chef::REST::Client::attribute>

=cut

my @base;
BEGIN {
use File::Basename qw { dirname };
use File::Spec::Functions qw { splitdir rel2abs };
 @base = ( splitdir ( rel2abs ( dirname(__FILE__) ) ) );
 pop @base; #REST
 pop @base; #Chef
 push @INC, '/', @base;
};

use parent qw { Chef::REST };
use Mojo::JSON;
use Module::Load;
use vars qw { $AUTOLOAD };

sub new {
  my $class = shift;
  my $param = {@_};
  my $self  = $class->SUPER::new(@_);
     $self->name($param->{'chef_client_name'}) if defined $param->{'chef_client_name'};
     $self->private_key($param->{'chef_client_private_key'}) if defined $param->{'chef_client_private_key'};     
  bless $self, $class;
  return $self;
}

sub name {
  my ($self,$client_name) = (@_);
         $self->{ 'CHEF_CLIENT' } = $client_name if defined $client_name;
  return $self->{ 'CHEF_CLIENT' };
}

#----------------------------------#
# Class : Chef::REST::Client::Role #
#----------------------------------#
sub role_ 
{
  my $self = shift;
  my $param = {@_};


}

#-----------------------------------#
# Class : Chef::REST::Client::Roles #
#-----------------------------------#
sub roles_ 
{
  my $self = shift;
  
  package Chef::REST::Client::roles;

  use parent qw { Chef::REST::Client };

  bless $self, 'Chef::REST::Client::roles';
        $self->api_end_point('roles');
  return $self;
  
  sub api_end_point 
  {
    my ($self,$api_end_point) = (@_);
           $self->{ 'API_END_POINT' } = $api_end_point if defined $api_end_point;
    return $self->{ 'API_END_POINT' };
  }
    
  sub list 
  {
    my $self = shift;
    my $end_point = $self->api_end_point;
    my $mojo_json = new Mojo::JSON();
    my $list_of_roles = 
       $mojo_json->decode(
             $self->ua(  'client_name'   => $self->name )
                  ->get( 'api_end_point' => $end_point  )
                  ->decoded_content
          );
    my @_roles;      
    foreach my $r ( keys(%$list_of_roles) ){
      my $role = Chef::REST::Client::role( 'name' => $r,  
                                           'url'  => $list_of_roles->{$r} 
                                         );
       push @_roles , $role;
    }
    return \@_roles;
  }

}

sub AUTOLOAD {
   my $self = shift;
   my $hash_param = pop @_;
   my ($method, $data) = ( 'GET');
   my $request_url = undef;
   
   if( ref $hash_param ne 'HASH')
   {
      push @_ , $hash_param if defined $hash_param;
      undef $hash_param;
   }
   else {
   	$method = 'POST' if $hash_param->{'method'} =~ m/post/i;
   	$data   = $hash_param->{'data'};
   }  

   my @param = @_;

	my $module =  (split ('::', $AUTOLOAD))[-1];
	load $AUTOLOAD;	
	my $obj = $AUTOLOAD->new();

	my (@api_end_point, @q );
	   @api_end_point = ( $module , @param );
	   
	foreach my $k ( keys(%$hash_param))
	{		
		push @q , join '=' , ($k , $hash_param->{$k});
	}
	
	$request_url = join '/', @api_end_point;
	$request_url = join '?' , $request_url , (join '&', @q ) if defined $q[0];
   
	my $result;
	
	 if ($method eq 'GET' )
	 { 
	   $result = $self->get( 'api_end_point' =>  $request_url )->decoded_content;
	 }
	 elsif( $method eq 'POST')
	 {
	   $result = $self->post( 
	                    'api_end_point' =>  $request_url ,
	                    'data'          => $data
	                 );
	 }         
   $obj->populate( $result ); 
	return $obj;
}

1;

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <bpatel10@nyit.edu>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut
