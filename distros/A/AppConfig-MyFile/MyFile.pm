#============================================================================
#
# AppConfig::MyFile.pm
#
# Perl5 module to read configuration files and use the contents therein 
# to update variable values in an AppConfig::State object.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1997,1998 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This module is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
#
# $Id$
#
#============================================================================

package AppConfig::MyFile;

require 5.004;

use AppConfig;
use AppConfig::State;

use strict;
use vars qw( $VERSION );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);



#========================================================================
#                      -----  PUBLIC METHODS -----
#========================================================================

#========================================================================
#
# new($state, $file, [$file, ...])
#
# Module constructor.  The first, mandatory parameter should be a 
# reference to an AppConfig::State object to which all actions should 
# be applied.  The remaining parameters are assumed to be file names or
# file handles for reading and are passed to parse().
#
# Returns a reference to a newly created AppConfig::File object.
#
#========================================================================

sub new {
    my $class = shift;
    my $state = shift;
    

    my $self = {
	STATE    => $state,                # AppConfig::State ref
	DEBUG    => $state->_debug(),      # store local copy of debug 
	PEDANTIC => $state->_pedantic,     # and pedantic flags
    };

    bless $self, $class;

    # call parse(@_) to parse any files specified as further params
    $self->parse(@_)
	if @_;

    return $self;
}



#========================================================================
#
# parse($file, [file, ...])
#
# Reads and parses a config file...
#
# Returns undef on system error, 0 if all files were parsed but generated
# one or more warnings, 1 if all files parsed without warnings.
#
#========================================================================

sub parse {
    my $self = shift;
    my $warnings = 0;
    my $file;


    # take a local copy of the state to avoid much hash dereferencing
    my ($state, $debug, $pedantic) = @$self{ qw( STATE DEBUG PEDANTIC ) };

    # we want to install a custom error handler into the AppConfig::State 
    # which appends filename and line info to error messages and then 
    # calls the previous handler;  we start by taking a copy of the 
    # current handler..
    my $errhandler = $state->_ehandler();

    # ...and if it doesn't exist, we craft a default handler
    $errhandler = sub { warn(sprintf(shift, @_), "\n") }
	unless defined $errhandler;

    # install a closure as a new error handler
    $state->_ehandler(
	sub {
	    # modify the error message 
	    my $format  = shift;
	       $format .= ref $file 
	                  ? " at line $."
	                  : " at $file line $.";

	    # chain call to prevous handler
	    &$errhandler($format, @_);
	}
    );

    # trawl through all files passed as params
    FILE: while ($file = shift) {

	# local/lexical vars ensure opened files get closed
	my $handle;
	local *FH;

	# if the file is a reference, we assume it's a file handle, if
	# not, we assume it's a filename and attempt to open it
	$handle = $file;
	if (ref($file)) {
	    $handle = $file;

	    # DEBUG
	    print STDERR "reading from file handle: $file\n" if $debug;
	}
	else {
	    # open and read config file
	    open(FH, $file) or do {
		# restore original error handler and report error
	    	$state->_ehandler($errhandler);
		$state->_error("$file: $!");

		return undef;
	    };
	    $handle = \*FH;

	    # DEBUG
	    print STDERR "reading file: $file\n" if $debug;
	}

	# your code goes here...
	while (<$handle>) {
	    print;
	};
    }

    # restore original error handler
    $state->_ehandler($errhandler);
    
    # return $warnings => 0, $success => 1
    return $warnings ? 0 : 1;
}



#========================================================================
#                 -----  AppConfig PUBLIC METHOD -----
#========================================================================

package AppConfig;


#========================================================================
#
# myfile(@files)
#
# The myfile() method is called to...
#
# Propagates the return value from AppConfig::MyFile->parse().
# 
#========================================================================

sub myfile {
    my $self  = shift;
    my $state = $self->{ STATE };
    my $myfile;


    # create an AppConfig::MyFile object if one isn't defined 
    $myfile = $self->{ MYFILE } ||= AppConfig::MyFile->new($state);

    # call on the AppConfig::File object to process files.
    $myfile->parse(@_);
}



1;

__END__

=head1 NAME

AppConfig::MyFile - Perl5 module for reading configuration files.

=head1 SYNOPSIS

    use AppConfig;

    my $appconfig = AppConfig->new(\%cfg);
    $appconfig->myfile($file, [$file...])

=head1 OVERVIEW

AppConfig::MyFile is a Perl5 module which...

=head1 DESCRIPTION

=head2 USING THE AppConfig::File MODULE

To import and use the AppConfig::File module the following line should appear
in your Perl script:

    use AppConfig::File;

    my $appconfig = AppConfig->new();
    $appconfig->myfile($file);

=head1 AUTHOR

Andy Wardley, C<E<lt>abw@cre.canon.co.ukE<gt>>

Web Technology Group, Canon Research Centre Europe Ltd.

=head1 REVISION

$Revision$

=head1 COPYRIGHT

Copyright (C) 1998 Canon Research Centre Europe Ltd.  
All Rights Reserved.

This module is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=head1 SEE ALSO

AppConfig, AppConfig::State

=cut
