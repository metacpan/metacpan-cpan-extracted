#factory response object
package CGI::Mungo::Response;

=pod

=head1 NAME

CGI::Mungo::Response - Page response class

=head1 SYNOPSIS

=head1 DESCRIPTION

Factory class for creating response objects.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp;
#########################################################

=pod

=head2 new($mungo, $plugin)

Constructor, a factory method that will return an instance of the requested response plugin.

If the response is not modified from the client's provided Etag header an instance of <LCGI::Mungo::Response::NotModified>
will be returned instead.

=cut

#########################################################
sub new{
	my($class, $mungo, $plugin) = @_;
	if($plugin){
		eval "use $plugin;";	#should do this a better way
		if(!$@){	#plugin loaded ok
			my $self = $plugin->new($mungo);
			return $self;			
		}
		else{
			confess("Plugin load problem: $@");
		}
	}
	else{
		confess("No plugin given");
	}
	return undef;
}
#########################################################
=pod

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 Copyright

Copyright (c) 2013 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

##########################################
return 1;
