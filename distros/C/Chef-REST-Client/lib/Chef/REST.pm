package Chef::REST;
$Chef::REST::VERSION = 1.0;

my @base;
BEGIN {
use File::Basename qw { dirname };
use File::Spec::Functions qw { splitdir rel2abs };
 @base = ( splitdir ( rel2abs ( dirname(__FILE__) ) ) );
 pop @base; #Chef
 push @INC, '/', @base;
};

use parent qw { Chef Chef::Header };
use LWP::UserAgent;
use Mojo::JSON;

sub new {
   my $class = shift;
   my $self  = $class->SUPER::new(@_);
   bless $self, $class;

		 	
	$self->_UA_( new LWP::UserAgent( ) );
	$self->_UA_->ssl_opts( 'verify_hostname' => 0 );   
   
   return $self;

}

sub _UA_ 
{
	my ($self,$new_ua) = (@_);
  	    $self->{'_UA_'} = $new_ua if defined $new_ua;
  	return $self->{'_UA_'};
}

sub add_headers 
{
  		  my $self = shift;
  		  my $param = shift;
  		  foreach my $header_field( keys( %$param) ){
  		     $self->_UA_->default_header( $header_field, $param->{ $header_field }); 
  		  }
  		  return $self;
}  

sub get {
	my $self  = shift;
	my $param = {@_};
	         
	my $response = 
	   $self->add_headers( 
	       $self->header(
		           'Method'  => 'GET',
		           'Path'    => $param->{'api_end_point'},
		           'Content' => ''
		    )->hash
	   )
		->_UA_
		->get( 
		     $self->get_uri( $param->{'api_end_point'} )
	   );
  			  
	return $response;
}

sub post 
{
	my $self  = shift;
	my $param = {@_};
	my $mojo_json = new Mojo::JSON();
	my $response  = $self->add_headers( 
	                    $self->header(
		                             'Method'  => 'POST',
		                             'Path'    => $param->{'api_end_point'},
		                             'Content' => $mojo_json->encode($param->{'data'})
		                        )->hash
		                      )
		                      ->_UA_
		                      ->post( 
		                         $self->get_uri( $param->{'api_end_point'} ),
		                         'Content' => $mojo_json->encode($param->{'data'})	                     
	                          );
                      
	return $response;

}

sub get_uri 
{
	my ($self,$api_end_point) = (@_);
	return join '/', ( $self->server, 
	                   $api_end_point )
	        if defined $api_end_point ;
}

sub name 
{
	my ($self,$client_name) = (@_);
       $self->{ 'CHEF_CLIENT' } = $client_name if defined $client_name;
   return $self->{ 'CHEF_CLIENT' };
}


1;

__DATA__

=pod

=head1 NAME 

Chef::REST

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef;

  my $obj = new Chef::REST( );

=head1 DESCRIPTION

This clas inherites methods from Chef and Chef::Header. Please do not use these methods directly. 
Inturn these are used internally by L<Chef::REST::Client> to make REST HTTP Requests 

=head1 METHODS

=head2 Constructor

=head3 REST;

returns new Chef::REST object and initialized UserAgent;

=head3 _UA_ 

sets UserAgent object

=head3 add_headers

uses to add headers for UserAgent. It takes hash as key value  

=head3 get

generates GET HTTP request

=head3 post

generates POST HTTP request

=head3 get_uri

generates end point URI for chef request.

=head3 name

sets or gets chef client name
 
=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <bpatel10@nyit.edu>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut

