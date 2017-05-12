#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::sandboxes                            #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::sandboxes;
use parent qw { Chef::REST::Client::EndPoints };

$Chef::REST::Client::sandboxes::VERSION = 1.0;

sub list 
{
	my $self = shift;
	my $sandboxes = $self->___data___;
	
	return $sandboxes;
}

sub details
{
  my $self = shift;
  my $data = $self->___data___;

  return $self->raw() unless ref $data eq 'HASH';
    
  return $data;
}  
  
1;


=pod

=head1 NAME 

Chef::REST::Client::sandboxes

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef::REST::Client::sandboxes;

$obj->sandboxes->list;
$obj->sandboxes( 'dev-sandbox' )->details;
  
=head1 DESCRIPTION

Class that represents collection of Chef sanboxes 

=head1 METHODS

=head2 list

return list of sandboxes.

=head2 details

return details about a particular sandbox. or dump raw hash.

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <mail4bhavin@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut
