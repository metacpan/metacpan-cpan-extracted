package CGI::Lazy::Utility;

use strict;

use CGI::Lazy::Globals;
use CGI::Lazy::Utility::Debug;

#--------------------------------------------------------------
sub debug {
	my $self = shift;

	return CGI::Lazy::Utility::Debug->new($self->q);
}

#--------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->{_q};
}

#--------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;

	return bless {_q => $q}, $class;
}

1

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2008 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy::Utility

=head1 SYNOPSIS

	use CGI::Lazy;

	my $q = CGI::Lazy->new('/path/to/config/file');

	my $t = $q->util->debug;

=head1 DESCRIPTION

Wrapper object for utility functions.  Primarily serves as a means to access more specific utility objects, while not polluting the namespace of the parent.

=head1 METHODS

=head2 debug ()

Debugging object.  See CGI::Lazy::Utility::Debug for details.

=head2 q

Returns CGI::Lazy object

=head2 new (lazy)

Constructor.

=head3 lazy

CGI::Lazy object.

=cut

