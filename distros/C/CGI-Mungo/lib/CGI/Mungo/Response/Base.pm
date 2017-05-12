#response base object for plugins
package CGI::Mungo::Response::Base;

=pod

=head1 NAME

Response Base - Base object for view plugins

=head1 SYNOPSIS

	use myResponse;
	my $response = myResponse->new($mungo);
	
	package myResponse;
	use base ("CGI::Mungo::Response::Base");

=head1 DESCRIPTION

This object should not be used directly, a new class should be created which inherits this one instead.

All response plugins should override at least the display() method and they all a sub class of L<HTTP::Response>.

The module L<CGI::Mungo::Response> will load the specified response plugin on script startup.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp;
use base qw(HTTP::Response CGI::Mungo::Base CGI::Mungo::Log);
#########################################################
sub new{
	my($class, $mungo) = @_;
	if(!defined($mungo)){
		confess("No mungo object given");
	}
	my $self = $class->SUPER::new(200, "OK");	#we dont care about the code or msg as they get removed later
	$self->{'_mungo'} = $mungo;	#so we can access the mungo object FIXME
	$self->{'_displayedHeader'} = 0;	#flag set on first output
	bless $self, $class;
	return $self;
}
#########################################################

=pod

=head2 setCacheable($seconds)

	$response->setCacheable($seconds)

Sets the page to be cached for the specified amount of seconds.

=cut

#########################################################
sub setCacheable{
	my($self, $seconds) = @_;
	$self->header("Cache-Control" => "max-age=$seconds, public");
	return 1;
}
#########################################################
sub getMungo{
	my $self = shift;
	return $self->{'_mungo'};
}
#########################################################
sub display{
	confess("display() not overridden");
}
#########################################################
# private methods
#########################################################
sub _setDisplayedHeader{
	my $self = shift;
	$self->{'_displayedHeader'} = 1;
	return 1;
}
#########################################################
sub _getDisplayedHeader{
	my $self = shift;
	return $self->{'_displayedHeader'};
}
###########################################################

=pod

=head1 Provided classes

In this package there are some responses already available for use:

=over 4

=item Raw

See L<CGI::Mungo::Response::Raw> for details.

=item SimpleTemplate

See L<CGI::Mungo::Response::SimpleTemplate> for details.

=back

=cut

#########################################################
return 1;