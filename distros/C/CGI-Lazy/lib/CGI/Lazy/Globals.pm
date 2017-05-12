package CGI::Lazy::Globals;

use strict;

use Exporter;
use base qw(Exporter);

##CONFIGROOT value
#if your config root is the server's document root, your apps will be more portable, however you will need to take steps to secure teh configs (with the db password et al.) from the outside world

#our $CONFIGROOT = $ENV{DOCUMENT_ROOT};

#Safer, but perhaps still not ideal

#our $CONFIGROOT = $ENV{SERVER_ROOT};

#if you set $CONFIGROOT to the empty string, your confs are safer, but you lose portability unless each server running the script has the same filesystem location for configs. This was chosen as the default as it offers the most flexibility for end users

our $CONFIGROOT = '';

use constant {
	TRUE 	=> 1,
	FALSE	=> !1,
	};

our @EXPORT = qw(TRUE FALSE $CONFIGROOT);

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

CGI::Lazy::Globals

=head1 DESCRIPTION

Class to hold and export global non-configuration variables

=head1 SYNOPSIS

	use CGI::Lazy::Globals

=cut

