package CGI::Lazy::CookieMonster;

use strict;

use CGI::Lazy::Globals;

#-----------------------------------------------------------------------------------------------------------
sub getCookie {
	my $self = shift;
	my $cookie = shift;

	return $self->q->cookie($cookie);
}

#-----------------------------------------------------------------------------------------------------------
sub goodEnoughForMe {
	my $self = shift;
	my $cookie = shift;

	return $cookie ? TRUE : FALSE;
}

#-----------------------------------------------------------------------------------------------------------
sub q {
	my $self = shift;
	
	return $self->{_q};
}

#-----------------------------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;

	my $self = {_q => $q};

	bless $self, $class;
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

CGI::Lazy::CookieMonster

=head1 SYNOPSIS

	use CGI::Lazy::CookieMonster;

	my $cm = CGI::Lazy::CookieMonster->new;

	$cm->getCookie($cookieName);

=head1 DESCRIPTION

Module for handling http cookies.  

Come on, when was I gonna find another opportunity for a module called 'CookieMonster'?

=head1 METHODS

=head2 getCookie ( cookie )

Retrieves cookie.

=head3 cookie

name of cookie.

=head2 goodEnoughForMe( cookie )

Dev's have to have fun too.  Returns true if $cookie.  Will probably mod it so it serves some better function.

=head3 cookie

some value


=head2 q ()

Returns Lazy object


=head2 new ( q  )

Constructor.  Returns CookieMonster object.

=head3 q

CGI::Lazy object.

=cut

