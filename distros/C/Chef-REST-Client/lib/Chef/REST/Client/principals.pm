#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::principals                           #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::principals;
use parent qw { Chef::REST::Client::EndPoints };

$Chef::REST::Client::principals::VERSION = 1.0;

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

Chef::REST::Client::principals

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef::REST::Client::principals;

$obj->principals( $principal_name )->details;
  
=head1 DESCRIPTION

Class that represents collection of environments 

=head1 METHODS

=head2 list

return list of environments, array of L<Chef::REST::Client::environment> objects.

=head2 details ( $details )

retun detail about a perticular environment.

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <mail4bhavin@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut