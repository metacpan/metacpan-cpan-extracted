#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::envrunlist                           #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::envrunlist;

$Chef::REST::Client::envrunlist::VERSION = 1.0;

sub new
{
	my $class = shift;
	my $param = {@_};
	my $self  = {};
	bless $self, $class;
	
	$self->env_name( $param->{'env_name'} );
	$self->run_list( $param->{'run_list'} );
	
	return $self;
}

sub env_name  { $_[0]->{'env_name' } = $_[1] if defined $_[1]; return $_[0]->{'env_name' }; }
sub run_list  { $_[0]->{'run_list' } = $_[1] if defined $_[1]; return $_[0]->{'run_list' }; }


1;

=pod

=head1 NAME 

Chef::REST::Client::attribute

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef::REST::Client::envrunlist;

  my $obj = new Chef::REST::Client::envrunlist
                ( 'env_name' => $environment_name
                , 'run_list' => $run_list
                );
     $obj->env_name;
     $obj->run_list;

=head1 DESCRIPTION

Class that reperesents Chef Environment run list.

=head1 METHODS

=head2 Constructor

returns new object of class L<Chef::REST::Client::envrunlist> with %params

=head2 env_name ( $environment_name )

get or set value for 'env_name'

=head2 run_list ($run_list )

get or set value for 'run_list'

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <mail4bhavin@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut