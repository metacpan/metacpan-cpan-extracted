package CGI::Lazy::ID;

use strict;

use Digest::MD5;
use Time::HiRes qw(gettimeofday);
use CGI::Lazy::Globals;

#---------------------------------------------------------------------------------------
sub generate {
	my $self = shift;
	
	my($s,$us)=gettimeofday();
  	my($v)=sprintf("%09d%06d%10d%06d%255s",rand(999999999),$us,$s,$$,$self->session->config->configfile);
	my $id = Digest::MD5::md5_base64($v);
	$id =~ tr{+/}{_-};
	return $id;
}

#---------------------------------------------------------------------------------------
sub new	{
	my $class = shift;
	my $session = shift;

	srand;

	bless {_session => $session}, $class;
}

#---------------------------------------------------------------------------------------
sub session {
	my $self = shift;
	return $self->{_session};
}

#---------------------------------------------------------------------------------------
sub valid {
	my $self = shift;
	my $sessionID = shift || '';

	return $sessionID =~ m/^[\w\d-]{22}$/;
}

1

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2008 by Nik Ogura. All rights reserved.
Much of this was taken from PlainBlack's WebGUI with many thanks.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy::ID

=head1 SYNOPSIS

	my $id = $session->id->generate();

=head1 DESCRIPTION

Module to generate unique id's.  Inspiration and ideas for this module, and even code itself was taken from PlainBlack's WebGUI with many thanks and much appreciation.  WebGUI was awesome, but far heavier a tool than what was needed.

=head1 METHODS

=head2 generate ( ) 

Generates a unique identifier.

=head2 session ( )

Returns the session object this object was created with.

=head2 new ( session )

Constructor.

=head3 session

CGI::Lazy::Session object

=head2 valid ($sessionID)

Returns true if $sessionID is a valid id string

=cut
