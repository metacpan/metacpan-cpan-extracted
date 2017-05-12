#response object
package CGI::Mungo::Response::NotModified;

=pod

=head1 NAME

Response NotModified - View plugin to return a 304 Response

=head1 SYNOPSIS

	my $response = $mungo->getResponse();

=head1 DESCRIPTION

This view plugin is automatically used by L<CGI::Mungo::Response> when the request Etag matches the current request, eg, the client
has a copy of the page already.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp;
use base qw(CGI::Mungo::Response::Base);
#########################################################

=head2 new($mungo)

Constructor, sets the HTTP response code to 304

=cut

#########################################################
sub new{
	my($class, $mungo) = @_;
	my $self = $class->SUPER::new($mungo);
	bless $self, $class;
	$self->code(304);
	$self->message('Not Modified');
	return $self;
}
#########################################################

=pod

=head2 display()

	$response->display();

This method is called automatically at the end of an action.

Just displays the HTTP headers as no body is needed for a 304 response.

=cut

#########################################################
sub display{	#this sub will display the page headers if needed
	my $self = shift;
	print "Status: " . $self->as_string();
	return 1;
}
#########################################################
#FIXME not required
#########################################################
sub setTemplate{
    return 1;   
}
#########################################################
#FIXME not required
#########################################################
sub setError{
    return 1;
}
#########################################################
#FIXME not required
#########################################################
sub setTemplateVar{
	return 1;
}
##############################################################

=pod

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 Copyright

Copyright (c) 2013 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

#########################################################
return 1;