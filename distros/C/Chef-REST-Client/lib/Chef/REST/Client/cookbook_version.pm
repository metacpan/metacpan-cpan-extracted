#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::cookbook_version                     #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::cookbook_version;

$Chef::REST::Client::cookbook_version::VERSION = 1.0;

=pod 

=head1 NAME

Chef::REST::Client::cookbook_version

=head1 VERSION

1.0

=head1 SYNOPSIS

my $obj = new Chef::REST::Client::cookbook_version
              ( 'url '    => $url
              , 'version' => $version );
   
=head1 DESCRIPTION

used internally by other classes like L<Chef::REST::Client::cookbooks>

=head1 METHODS

=head2 Constructor

returns new Chef::REST::Client::cookbook_version object

=cut

sub new 
{
	my $class = shift;
	my $param = {@_};
	my $self = {};
	
	bless $self, $class;
	
	$self->url    ( $param->{'url'    } );
	$self->version( $param->{'version'} );	
	
	return $self;
}

=pod

=head2 url( $url )

set 'url' property value if speicfied else return previous value;

=cut

sub url     { $_[0]->{'url'    } = $_[1] if defined $_[1]; return $_[0]->{'url'    }; }

=pod

=head2 versions( $versions )

set 'versions' value if speicfied else return previous value;

=cut

sub version { $_[0]->{'version'} = $_[1] if defined $_[1]; return $_[0]->{'version'}; }

1;

=pod 

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <bpatel10@nyit.edu>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut