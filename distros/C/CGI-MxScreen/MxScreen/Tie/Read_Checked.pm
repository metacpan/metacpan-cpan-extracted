# -*- Mode: perl -*-
#
# $Id: Read_Checked.pm,v 0.1 2001/04/22 17:57:04 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Read_Checked.pm,v $
# Revision 0.1  2001/04/22 17:57:04  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Tie::Read_Checked;

require Tie::Hash;

use vars qw(@ISA);
@ISA = qw(Tie::StdHash);

use Carp::Datum;
use Log::Agent;

#
# (TIEHASH)
#
# Initial tieing.
#
sub TIEHASH {
	DFEATURE my $f_;
	my $self = bless {}, shift;
	return DVAL $self;
}

#
# (FETCH)
#
# Redefined to croak when accessing non-existing key.
#
sub FETCH {
	return $_[0]->{$_[1]} if exists $_[0]->{$_[1]};
	logcroak "access to unknown key '$_[1]'";
}

1;

=head1 NAME

CGI::MxScreen::Tie::Read_Checked - Global hash key access checking

=head1 SYNOPSIS

 # Not meant to be used directly

=head1 DESCRIPTION

This class implements the runtime checks to keys from the global persistent
hash, made available to all screens via C<$self-E<gt>vars>.  This behaviour
is configured by the C<$mx_check_vars> variable: see L<CGI::MxScreen::Config>.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Config(3).

