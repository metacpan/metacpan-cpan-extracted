#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::EndPoints                            #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::EndPoints;
$Chef::REST::Client::EndPoints::VERSION = 1.0;

=pod 

=head1 NAME

Chef::REST::Client::EndPoints

=head1 VERSION

1.0

=head1 SYNOPSIS

my $obj = new Chef::REST::Client::EndPoints( 'api_end_point' => $end_point );
   $obj->populate($result);
   $obj->raw;
   
=head1 DESCRIPTION

used internally by other classes

=head1 METHODS

=head2 Constructor

initialized api_end_point

=head2 api_end_point( $end_point )

set api_end_point if passed otherwise returns current value 

=head2 populate($result)

internal method  generates data structure based on the result of the http request

=head2 raw

returns the raw data structure.

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

use Mojo::JSON;

sub new {
  my $class  = shift;
  my $param  = {@_};
  my $self   = {};
  bless $self, $class;
  $self->api_end_point($param->{'api_end_point'});
  return $self;
}

 sub api_end_point 
  {
    my ($self,$api_end_point) = (@_);
           $self->{ 'API_END_POINT' } = $api_end_point if defined $api_end_point;
    return $self->{ 'API_END_POINT' };
  }

sub populate
{
  my $self = shift;
  my $result = shift;
     $self->___data___($result);
}

sub ___data___
{
	my $self = shift;
	my $result = shift;
	my $mojo_json = new Mojo::JSON();
	   $self->{'___data___'} = 
	   		$mojo_json->decode( $result )  
     						if defined $result;
     						
	return $self->{'___data___'};
}

sub raw { return  $_[0]->___data___; }
	
1;

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <bpatel10@nyit.edu>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut
