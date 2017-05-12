#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::databag                              #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::databag;
use vars qw { $AUTOLOAD };

$Chef::REST::Client::databag::VERSION = 1.0;

sub new {
   my $class = shift;
   my $param = {@_};
   
   my $self = {};
 	bless $self, $class;   

   $self->name( $param->{'name' });
   $self->url(  $param->{'url'  });
   
  return $self;
}

sub AUTOLOAD 
{
	my $self  = shift;
	my $param = shift;
	my $module =  (split ('::', $AUTOLOAD))[-1];
	$self->{ $module } = $param if defined $param;
	return $self->{ $module };
}

1;


=pod

=head1 NAME 

Chef::REST::Client::databag

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef::REST::Client::databag;

my $obj = new Chef::REST::Client::databag( 'name' => $name , 'url' => $databag_link );

=head1 DESCRIPTION

Class representation of Chef DataBag;
 
=head1 METHODS

=head2 name

sets or gets 'name' property value 

$obj->name;

=head2 url

sets or gets 'url' property value 

$obj->url;

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <mail4bhavin@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut