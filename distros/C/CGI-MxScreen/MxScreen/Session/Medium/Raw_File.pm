# -*- Mode: perl -*-
#
# $Id: Raw_File.pm,v 0.1 2001/04/22 17:57:04 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Raw_File.pm,v $
# Revision 0.1  2001/04/22 17:57:04  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Session::Medium::Raw_File;

#
# Session storage is a file, via raw Storable access.
#

require CGI::MxScreen::Session::Medium::File;
use vars qw(@ISA);
@ISA = qw(CGI::MxScreen::Session::Medium::File);

use Carp::Datum;
use Getargs::Long;
use Log::Agent;
use Fcntl;

#
# ->_retrieve_locked		-- redefined
#
# retrieve context from (locked) file.
#
sub _retrieve_locked {
	DFEATURE my $f_;
	my $self = shift;
	my ($path) = @_;

	require Storable;

	my $ref = Storable::retrieve($path);
	logerr "unable to retrieve from session file $path" unless defined $ref;

	return DVAL $ref;
}

#
# ->_store_locked			-- redefined
#
# Store context into (locked) file.
#
sub _store_locked {
	DFEATURE my $f_;
	my $self = shift;
	my ($path, $context) = @_;

	require Storable;

	my $ok = $self->shared ?
		Storable::nstore($context, $path) :
		Storable::store($context, $path);

	logerr "unable to save into session file $path" unless defined $ok;

	return DVOID;
}

1;

=head1 NAME

CGI::MxScreen::Session::Medium::Raw_File - Fast file session medium

=head1 SYNOPSIS

 # Not meant to be used directly

=head1 DESCRIPTION

This class behaves exactly as C<CGI::MxScreen::Session::Medium::File>
excepted that it ignores the serializer configuration and hardwires
C<Storable>, which allows for efficient storage and retrieval
since the C<Storable> routines C<store()> and C<retrieve()>
are used directly on files.

This means that there's no compression of the serialized context,
but the aim here is performance.

Please refer to L<CGI::MxScreen::Session::Medium::File> for the creation
routine interface.

You can configure this session medium in the configuration file as
explained in L<CGI::MxScreen::Config> by saying:

    $mx_medium = ["+Raw_File", -directory => "/var/tmp/www-sessions"];

This is the settings I use on my own web server.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Session::Medium::Browser(3),
CGI::MxScreen::Session::Medium::File(3).

=cut

