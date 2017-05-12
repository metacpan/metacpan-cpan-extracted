#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::search                               #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::search;
use parent qw { Chef::REST::Client::EndPoints };
use Chef::REST::Client::environments;

$Chef::REST::Client::search::VERSION = 1.0;

sub list 
{
	my $self = shift;
	my $search = $self->___data___;
	
	return $search;
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

Chef::REST::Client::search

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef::REST::Client::search;

$obj->search->list;
$obj->search( 'secrets' , {  q => 'id:centrify', rows => 1 } )->details;
  
=head1 DESCRIPTION

Class that represents collection of Chef seach feature. 

=head1 METHODS

=head2 list

return list of searches.

=head2 details

return details about a particular search.

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <mail4bhavin@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut
