#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::recipe                               #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::recipe;

$Chef::REST::Client::recipe::VERSION = 1.0;

sub new
{
	my $class = shift;
	my $recipe = shift;
	my $self = {};
	bless $self, $class;
	$self->parse( $recipe );
	return $self;
}

sub parse
{
	my $self = shift;
	my $recipe = shift;
	$recipe =~ s/^recipe\[(.*)\]/$1/;

	$recipe =~ /((?<cookbook>[\w-_]+)::)?(?<recipe>[\w-_]+)(@(?<version>.*))?/;
		
	$self->cookbook( $+{cookbook });
	$self->recipe(   $+{recipe   });
	$self->version(  $+{version  });
	
}

sub cookbook { $_[0]->{'cookbook'} = $_[1] if defined $_[1]; return $_[0]->{'cookbook'}; }
sub recipe   { $_[0]->{'recipe'  } = $_[1] if defined $_[1]; return $_[0]->{'recipe'  }; }
sub version  { $_[0]->{'version' } = $_[1] if defined $_[1]; return $_[0]->{'version' }; }

1;

=pod

=head1 NAME 

Chef::REST::Client::recipe

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef::REST::Client::recipe;

my $obj = new Chef::REST::Client::recipe( $recipe);
   $obj->cookbook;
   $obj->recipe;
   $obj->version;
  
=head1 DESCRIPTION

Class that represents chef recipe 

=head1 METHODS

=head2 Constructor

return new L<Chef::REST::Client::recipe> object.

=head2 cookbook ( $cookbook )

set or get cookbook property

=head2 recipe ( $recipe )

set or get recipe property

=head2 version ( $version )

set or get version property

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <mail4bhavin@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut
