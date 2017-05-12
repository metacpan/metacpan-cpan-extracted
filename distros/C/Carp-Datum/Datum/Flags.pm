# -*- Mode: perl -*-
#
# $Id: Flags.pm,v 0.1 2001/03/31 10:04:36 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Flags.pm,v $
# Revision 0.1  2001/03/31 10:04:36  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

package Carp::Datum::Flags;

BEGIN {
    sub DBG_ON ()           {1};
    sub DBG_OFF ()          {0};

    sub DTM_SET ()          {0};
    sub DTM_CLEAR ()        {1};

    sub DBG_ALL ()          {0xffffffff};
    sub DBG_FLOW ()         {0x00000001}; # Control flow (entry/exit)
    sub DBG_RETURN ()       {0x00000002}; # Trace return value
    sub DBG_REQUIRE ()      {0x00000004}; # Check preconditions
    sub DBG_ASSERT ()       {0x00000008}; # Check plain assertions
    sub DBG_ENSURE ()       {0x00000010}; # Check postconditions
    sub DBG_TRACE ()        {0x00000020}; # Emit trace messages
    sub DBG_PANIC ()        {0x00000040}; # Panic on assertion failure
    sub DBG_STACK ()        {0x00000080}; # Dump stack trace on assert failure
}

BEGIN {    
    sub TRC_ALL ()          {0xffffffff};
    sub TRC_EMERGENCY ()    {0x00000001};
    sub TRC_ALERT ()        {0x00000002};
    sub TRC_CRITICAL ()     {0x00000004};
    sub TRC_ERROR ()        {0x00000008};
    sub TRC_WARNING ()      {0x00000010};
    sub TRC_NOTICE ()       {0x00000020};
    sub TRC_INFO ()         {0x00000040};
    sub TRC_DEBUG ()        {0x00000080};
}

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(
	DBG_ON
	DBG_OFF

	DTM_SET
	DTM_CLEAR

	DBG_ALL
	DBG_FLOW
	DBG_RETURN
	DBG_REQUIRE
	DBG_ASSERT
	DBG_ENSURE
	DBG_TRACE
	DBG_PANIC
	DBG_STACK

	TRC_ALL
	TRC_EMERGENCY
	TRC_ALERT
	TRC_CRITICAL
	TRC_ERROR
	TRC_WARNING
	TRC_NOTICE
	TRC_INFO
	TRC_DEBUG
);

1;

=head1 NAME

Carp::Datum::Flags - Flag Constants

=head1 SYNOPSIS

 # Used internally to define debugging and tracing flag constants

=head1 DESCRIPTION

This module is used internally by C<Carp::Datum>.  It defines the
constants that are exported and made available automatically to all
users of C<Carp::Datum>.

=head1 AUTHORS

Christophe Dehaudt and Raphael Manfredi are the original authors.

Send bug reports, hints, tips, suggestions to Dave Hoover at <squirrel@cpan.org>.

=head1 SEE ALSO

Carp::Datum(3).

=cut

