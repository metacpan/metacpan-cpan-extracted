# ************************************************************************* 
# Copyright (c) 2014-2020, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

package App::CELL::Log;

use strict;
use warnings;
use 5.012;

# IMPORTANT: this module must not depend on any other CELL modules
#            except possibly App::CELL::Util
use Data::Dumper;
use File::Spec;
use Log::Any;
use Scalar::Util;



=head1 NAME

App::CELL::Log - the Logging part of CELL



=head1 SYNOPSIS

    use App::CELL::Log qw( $log );

    # set up logging for application FooBar -- need only be done once
    $log->init( ident => 'FooBar' );  

    # do not suppess 'trace' and 'debug' messages
    $log->init( debug_mode => 1 );     

    # do not append filename and line number of caller
    $log->init( show_caller => 0 );

    # log messages at different log levels
    my $level = 'warn'  # can be any of the levels provided by Log::Any
    $log->$level ( "Foobar log message" );

    # the following App::CELL-specific levels are supported as well
    $log->ok       ( "Info-level message prefixed with 'OK: '");
    $log->not_ok   ( "Info-level message prefixed with 'NOT_OK: '");

    # by default, the caller's filename and line number are appended
    # to suppress this for an individual log message:
    $log->debug    ( "Debug-level message", suppress_caller => 1 );

    # Log a status object (happens automatically when object is
    # constructed)
    $log->status_obj( $status_obj );

    # Log a message object
    $log->message_obj( $message_obj );



=head1 EXPORTS

This module provides the following exports:

=over 

=item C<$log> - App::CELL::Log singleton

=back

=cut 

use Exporter qw( import );
our @EXPORT_OK = qw( $log );



=head1 PACKAGE VARIABLES

=over

=item C<$ident> - the name of our application

=item C<$show_caller> - boolean value, determines if caller information is
displayed in log messages

=item C<$debug_mode> - boolean value, determines if we display debug
messages

=item C<$log> - App::CELL::Log singleton object

=item C<$log_any_obj> - Log::Any singleton object

=item C<@permitted_levels> - list of permissible log levels

=back 

=cut

our $debug_mode = 0;
our $ident = 'CELLtest';
our $show_caller = 1;
our $log = bless {}, __PACKAGE__;
our $log_any_obj;
our @permitted_levels = qw( OK NOT_OK TRACE DEBUG INFO INFORM NOTICE
        WARN WARNING ERR ERROR CRIT CRITICAL FATAL EMERGENCY );
our $AUTOLOAD;



=head1 DESCRIPTION

App::CELL's logs using L<Log::Any>. This C<App::CELL::Log> module exists
to: (1) provide documentation, (2) store the logging category (C<$ident>),
(3) store the L<Log::Any> log object, (4) provide convenience functions for
logging 'OK' and 'NOT_OK' statuses.



=head1 METHODS


=head2 debug_mode

If argument provided, set the $debug_mode package variable.
If no argument, simply return the current debug-mode setting.
Examples:

    $log->debug_mode(0); # turn debug mode off
    $log->debug_mode(1); # turn debug mode on
    print "Debug mode is on\n" if $log->debug_mode;

=cut

sub debug_mode { 
    my ( $self, @ARGS ) = @_;
    return $debug_mode = $ARGS[0] if @ARGS;
    return $debug_mode;
}


=head2 ident

Set the $ident package variable and the Log::Any category

=cut

sub ident {
    my $self = shift;
    $ident = shift;
    return $log_any_obj = Log::Any->get_logger(category => $ident);
}


=head2 show_caller

Set the $show_caller package variable

=cut

sub show_caller { return $show_caller = $_[1]; }


=head2 permitted_levels

Access the C<@permitted_levels> package variable.

=cut

sub permitted_levels { return @permitted_levels };


=head2 init

Initializes (or reconfigures) the logger. Although in most cases folks will
want to call this in order to set C<ident>, it is not required for logging
to work. See L<App::CELL::Guide> for instructions on how to log with 
L<App::CELL>.

Takes PARAMHASH as argument. Recognized parameters: 

=over

=item C<ident> -- (i.e., category) string, e.g. 'FooBar' for
the FooBar application, or 'CELLtest' if none given

=item C<show_caller> -- sets the C<$show_caller> package variable (see
above)

=item C<debug_mode> -- sets the C<$debug_mode> package variable (see above)

=back

Always returns 1.

=cut

sub init {
    my ( $self, %ARGS ) = @_;

    # process 'ident'
    if ( defined( $ARGS{ident} ) ) {
        if ( $ARGS{ident} eq $ident and $ident ne 'CELLtest' ) {
            $log->info( "Logging already configured", cell => 1 );
        } else {
            $ident = $ARGS{ident};
            $log_any_obj = Log::Any->get_logger(category => $ident);
        }
    } else {
        $ident = 'CELLtest';
        $log_any_obj = Log::Any->get_logger(category => $ident);
    }    

    # process 'debug_mode' argument
    if ( exists( $ARGS{debug_mode} ) ) {
        $debug_mode = 1 if $ARGS{debug_mode};
        $debug_mode = 0 if not $ARGS{debug_mode};
    }
    #$log->info( "debug_mode is $debug_mode", cell => 1 );
    
    # process 'show_caller'
    if ( exists( $ARGS{show_caller} ) ) {
        $show_caller = 1 if $ARGS{show_caller};
        $show_caller = 0 if not $ARGS{show_caller};
    }

    return 1;
}


=head2 DESTROY

For some reason, Perl 5.012 seems to want a DESTROY method

=cut 

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}


=head2 AUTOLOAD

Call Log::Any methods after some pre-processing

=cut

sub AUTOLOAD {
    
    my ( $class, $msg_text, @ARGS ) = @_;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    # if method is not in permitted_levels, pass through to Log::Any
    # directly
    if ( not grep { $_ =~ m/$method/i } @permitted_levels ) {
        return $log_any_obj->$method( $msg_text, @ARGS );
    }

    # we are logging a message
    my %ARGS;
    %ARGS = @ARGS if @ARGS % 2 == 0;
    my ( $file, $line );
    my ( $level, $text );
    my $method_uc = uc $method;
    if ( $method_uc eq 'OK' or $method_uc eq 'NOT_OK' ) {
        $level = $method_uc;
        $method_uc = 'INFO';
        $method = 'info';
    } else {
        $level = $method_uc;
    }
    my $method_lc = lc $method;

    # determine what caller info will be displayed, if any
    if ( %ARGS ) {
        if ( $ARGS{caller} ) {
            ( undef, $file, $line ) = @{ $ARGS{caller} };
        } elsif ( $ARGS{suppress_caller} ) {
            ( $file, $line ) = ( '', '' );
        } else {
            ( undef, $file, $line ) = caller;
        }
    } else {
        ( undef, $file, $line ) = caller;
    }

    # if this is a CELL internal debug message, continue only if
    # the CELL_DEBUG_MODE environment variable exists and is true
    if ( $ARGS{'cell'} and ( $method_lc eq 'debug' or $method_lc eq 'trace') ) {
        return unless $ENV{'CELL_DEBUG_MODE'};
    }

    $log->init( ident => $ident ) if not $log_any_obj;
    die "No Log::Any object!" if not $log_any_obj;
    return if not $debug_mode and ( $method_lc eq 'debug' or $method_lc eq 'trace' );
    if ( not $msg_text ) {
        $msg_text = "<NO_TEXT>"
    }
    $log_any_obj->$method_lc( _assemble_log_message( "$level: $msg_text", $file, $line ) );
    return;
}


=head2 status_obj

Take a status object and log it.

=cut

sub status_obj {
    my ( $self, $status_obj, $cell ) = @_;
    my ( $level, $code, $text, $caller, %ARGS );
    $level  = $status_obj->level;
    $code   = $status_obj->code;
    $text   = $status_obj->text;
    $caller = $status_obj->caller;
    $ARGS{caller} = $caller if $caller;
    $ARGS{cell} = $cell if $cell;
    if ( $code ne $text ) {
        $text = "($code) $text"
    }
    $text = "<STATUS OBJECT WITHOUT TEXT OR CODE>" if not $text;
    #( $level, $text ) = _sanitize_level( $level, $text );

    $log->init( ident => $ident ) if not $log_any_obj;
    return $log->$level( $text, %ARGS );
}


#=head2 msg
#
#Take a message object and log it.
#
#=cut
#
#sub msg {
#    my ( $self, $msgobj, @ARGS ) = @_;
#    return if not blessed( $msgobj );
#    $log->init( ident => $ident ) if not $log_any_obj;
#    my $level = $msgobj->level;
#    my $text = $msgobj->text;
#}


sub _sanitize_level {
    my ( $level, $msg_text ) = @_;
    if ( $level eq 'OK' ) {
        $level = 'INFO';
        $msg_text = "OK: " . $msg_text;
    } elsif ( $level eq 'NOT_OK' ) {
        $level = 'INFO';
        $msg_text = "NOT_OK: " . $msg_text;
    }
    return ( lc $level, $msg_text );
}

sub _assemble_log_message {
    my ( $message, $file, $line ) = @_;

    if ( $file and File::Spec->file_name_is_absolute( $file ) ) {
       ( undef, undef, $file ) = File::Spec->splitpath( $file );
    }

    return "$message at $file line $line" if $show_caller and $file;

    return $message;
}

1;
