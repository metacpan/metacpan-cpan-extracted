#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::runlist                              #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::runlist;
use Chef::REST::Client::recipe;

$Chef::REST::Client::runlist::VERSION = 1.0;

sub new
{
	my $class = shift;
	my ($param) = (@_);
	my $self  = {};
	bless $self, $class;
	
	return [ map { new Chef::REST::Client::recipe($_) } @$param ];
	
}

1;


=pod

=head1 NAME 

Chef::REST::Client::runlist

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef::REST::Client::runlist;

my $obj = new Chef::REST::Client::runlist;
  
=head1 DESCRIPTION

Class that represents chef runlist
returns a map of L<Chef::REST::Client::recipe> class. 

=head1 METHODS

=head2 Constructor

returns map of Chef::REST::Client::recipe 

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <mail4bhavin@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut

