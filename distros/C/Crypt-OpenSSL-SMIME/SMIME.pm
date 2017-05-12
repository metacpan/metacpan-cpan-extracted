# U N I V E R M A G  2 
# Web Application Engine
# Property representation for Univermag 2
# Copyright 1999-2001 by YASP Software Ltd.
# $Id: SMIME.pm,v 1.1.1.1 2002/12/02 15:21:43 max Exp $
# 
# [% TAGS #% %# %]


package Crypt::OpenSSL::SMIME;

=head1 NAME

Crypt::OpenSSL::SMIME

=head1 SYNOPSIS

use Crypt::OpenSSL::SMIME

=head1 DESCRIPTION

Crypt::OpenSSL::SMIME

=over

=cut

use strict;

use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);

$VERSION = '0.05'; 

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Crypt::OpenSSL::SMIME macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap Crypt::OpenSSL::SMIME $VERSION;

sub init {
    my $self = shift;
    #print "$self " , $self->{prop_altid}, "\n";
}

1;

=back

=head1 AUTHOR

I<max@yasp.com>

=cut

__END__
