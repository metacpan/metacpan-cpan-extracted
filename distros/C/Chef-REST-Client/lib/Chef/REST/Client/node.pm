#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::node                                 #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::node;

use vars qw { $AUTOLOAD };

use Chef::REST::Client::environment;
use Chef::REST::Client::attributes;

$Chef::REST::Client::node::VERSION = 1.0;

sub new {
   my $class = shift;
   my $param = {@_};
   
   my $self = {};
 	bless $self, $class;   

   $self->name( $param->{'name' });
   $self->url(  $param->{'url'  });
   $self->normal ( $param->{'normal'});
   $self->environment( $param->{'environment'} );
   $self->automatic( $param->{'automatic'});
   $self->override ($param->{'override'});
   $self->default ( $param->{'default'} );
   
  return $self;
}

sub environment
{
	my $self = shift;
	my $param = shift;
	$self->{'environment'} = 
		new Chef::REST::Client::environment ( 'name' => $param ) if defined $param;
 	return $self->{'environment'};		
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

Chef::REST::Client::node

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef::REST::Client::node;

  my $obj = new Chef::REST::Client::node
                ( 'name'        => $node_name
                , 'url'         => $node_url
                , 'normal'      => $normal
                , 'environment' => $node_environment
                , 'automatic'   => $automatic
                , 'override'    => $override
                , 'default'     => $default
                );

=head1 DESCRIPTION

Class representation of Chef node.

=head1 METHODS

=head2 Constructor

returns new object of class L<Chef::REST::Client::node> with %params

=head2 name ( $name )

get or set value for 'name'

=head2 url ( $url )

get or set value for 'url'

=head2 normal ( $normal )

get or set value for 'normal'

=head2 environment ( $environment )

get or set value for 'environment'

=head2 automatic ( $automatic )

get or set value for 'automatic'

=head2 override ( $override )

get or set value for 'override'

=head2 default ( $default )

get or set value for 'default'

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <mail4bhavin@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut