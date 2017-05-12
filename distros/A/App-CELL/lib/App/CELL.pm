# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
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

package App::CELL;

use strict;
use warnings;
use 5.012;

use Carp;
use App::CELL::Config qw( $meta $core $site );
use App::CELL::Load;
use App::CELL::Log qw( $log );
use App::CELL::Status;
use App::CELL::Util qw( stringify_args utc_timestamp );
use Params::Validate qw( :all );
use Scalar::Util qw( blessed );


=head1 NAME

App::CELL - Configuration, Error-handling, Localization, and Logging



=head1 VERSION

Version 0.222

=cut

our $VERSION = '0.222';



=head1 SYNOPSIS

    # imagine you have a script/app called 'foo' . . . 

    use Log::Any::Adapter ( 'File', "/var/tmp/foo.log" );
    use App::CELL qw( $CELL $log $meta $site );

    # load config params and messages from sitedir
    my $status = $CELL->load( sitedir => '/etc/foo' );
    return $status unless $status->ok;

    # set appname to FOO_APPNAME (a config param just loaded from sitedir)
    $CELL->appname( $CELL->FOO_APPNAME || "foo" );

    # write to the log
    $log->notice("Configuration loaded from /etc/foo");

    # get value of site configuration parameter FOO_PARAM
    my $val = $site->FOO_PARAM;

    # get a list of all supported languages
    my @supp_lang = $CELL->supported_languages;

    # determine if a language is supported
    print "sk supported" if $CELL->language_supported('sk');

    # get message object and text in default language
    $status = $CELL->msg('FOO_INFO_MSG');
    my $fmsg = $status->payload if $status->ok;
    my $text = $fmsg->text;

    # get message object and text in default language
    # (message that takes arguments)
    $fmsg = $CELL->msg('BAR_ARGS_MSG', "arg1", "arg2");
    print $fmsg->text, "\n";

    # get text of message in a different language
    my $sk_text = $fmsg->lang('sk')->text;




=head1 DESCRIPTION

This is the top-level module of App::CELL, the Configuration,
Error-handling, Localization, and Logging framework for applications (or
scripts) written in Perl.

For details, read the POD in the L<App::CELL> distro. For an introduction,
read L<App::CELL::Guide>.



=head1 EXPORTS

This module provides the following exports:

=over 

=item C<$CELL> - App::CELL singleton object

=item C<$log> - App::CELL::Log singleton object

=item C<$meta> - App::CELL::Config singleton object

=item C<$core> - App::CELL::Config singleton object

=item C<$site> - App::CELL::Config singleton object

=back

=cut 

use Exporter qw( import );
our @EXPORT_OK = qw( $CELL $log $meta $core $site );

our $CELL = bless { 
        appname  => __PACKAGE__,
        enviro   => '',
    }, __PACKAGE__;

# ($log is imported from App::CELL::Log)
# ($meta, $core, and $site are imported from App::CELL::Config)



=head1 METHODS


=head2 appname

If no argument is given, returns the C<appname> -- i.e. the name of the
application or script that is using L<App::CELL> for its configuration,
error handling, etc.

If an argument is given, assumes that it denotes the desired C<appname> and sets
it. Also initializes the logger.

=cut

sub appname { 
    my @ARGS = @_;
    return $CELL->{appname} if not @ARGS; 
    $CELL->{appname} = $ARGS[0];
    $log->ident( $CELL->{'appname'} );
}


=head2 enviro

Get the C<enviro> attribute, i.e. the name of the environment variable
containing the sitedir

=cut

sub enviro { return $CELL->{enviro}; }


=head2 loaded

Get the current load status, which can be any of the following:
    0        nothing loaded yet
    'SHARE'  sharedir loaded
    'BOTH'   sharedir _and_ sitedir loaded

=cut

sub loaded {
    return 'SHARE' if $App::CELL::Load::sharedir_loaded and not
                      @App::CELL::Load::sitedir;
    return 'BOTH'  if $App::CELL::Load::sharedir_loaded and
                      @App::CELL::Load::sitedir;
    return 0;
}


=head2 sharedir

Get the C<sharedir> attribute, i.e. the full path of the site configuration
directory (available only after sharedir has been successfully loaded)

=cut

sub sharedir { 
    return '' if not $App::CELL::Load::sharedir_loaded;
    return $App::CELL::Load::sharedir;
}


=head2 sitedir

Get the C<sitedir> attribute, i.e. the full path of the site configuration
directory (available only after sitedir has been successfully loaded)

=cut

sub sitedir { 
    return '' if not $App::CELL::Load::sitedir_loaded;
    return $App::CELL::Load::sitedir;
}


=head2 supported_languages

Get list of supported languages. Equivalent to:

    $site->CELL_SUPP_LANG || [ 'en ]

=cut

sub supported_languages {
    return App::CELL::Message::supported_languages();
}


=head2 language_supported

Determine if a given language is supported.

=cut

sub language_supported {
    return App::CELL::Message::language_supported( $_[1] );
}


=head2 C<load>

Attempt to load messages and configuration parameters from the sharedir
and, possibly, the sitedir as well.

Takes: a PARAMHASH that should include at least one of C<enviro> or
C<sitedir> (if both are given, C<enviro> takes precedence with C<sitedir>
as a fallback). The PARAMHASH can also include a C<verbose> parameter
which, when set to a true value, causes the load routine to log more
verbosely.

Returns: an C<App::CELL::Status> object, which could be any of the
following: 
    OK    success
    WARN  previous call already succeeded, nothing to do 
    ERR   failure

On success, it also sets the C<CELL_META_START_DATETIME> meta parameter.

=cut

sub load {
    my $class = shift;
    my ( %ARGS ) = validate( @_, {
        enviro => { type => SCALAR, optional => 1 },
        sitedir => { type => SCALAR, optional => 1 },
        verbose => { type => SCALAR, default => 0 },
    } );
    my $status; 

    $log->info( "CELL version $VERSION called from " . (caller)[0] . 
                " with arguments " . stringify_args( \%ARGS ),
                cell => 1, suppress_caller => 1 );

    # we only get past this next call if at least the sharedir loads
    # successfully (sitedir is optional)
    $status = App::CELL::Load::init( %ARGS );
    return $status unless $status->ok;
    $log->info( "App::CELL has finished loading messages and site conf params", 
        cell => 1 ) if $meta->CELL_META_LOAD_VERBOSE;

    $log->show_caller( $site->CELL_LOG_SHOW_CALLER );
    $log->debug_mode ( $site->CELL_DEBUG_MODE );

    $App::CELL::Message::supp_lang = $site->CELL_SUPP_LANG || [ 'en' ];
    $App::CELL::Message::def_lang = $site->CELL_DEF_LANG || 'en';

    $meta->set( 'CELL_META_START_DATETIME', utc_timestamp() );
    $log->info( "**************** App::CELL $VERSION loaded and ready ****************", 
                cell => 1, suppress_caller => 1 );

    return App::CELL::Status->ok;
}



=head2 Status constructors

The following "factory" makes a bunch of status constructor methods
(wrappers for App::CELL::Status->new )

=cut

BEGIN {
    foreach (@App::CELL::Log::permitted_levels) {
        no strict 'refs';
        my $level_uc = $_;
        my $level_lc = lc $_;
        *{"status_$level_lc"} = sub { 
            my ( $self, $code, @ARGS ) = @_;
            if ( @ARGS % 2 ) { # odd number of arguments
                $log->warn( "status_$level_lc called with odd number (" . 
                            scalar @ARGS . 
                            ") of arguments; discarding the arguments!" );
                @ARGS = ();
            }
            my %ARGS = @ARGS;
            return App::CELL::Status->new(
                level => $level_uc,
                code => $code,
                caller => [ caller ],
                %ARGS,
            );
        }
    }
}

=head3 status_crit

Constructor for 'CRIT' status objects

=head3 status_critical

Constructor for 'CRIT' status objects

=head3 status_debug

Constructor for 'DEBUG' status objects

=head3 status_emergency

Constructor for 'DEBUG' status objects

=head3 status_err

Constructor for 'ERR' status objects

=head3 status_error

Constructor for 'ERR' status objects

=head3 status_fatal

Constructor for 'FATAL' status objects

=head3 status_info

Constructor for 'INFO' status objects

=head3 status_inform

Constructor for 'INFORM' status objects

=head3 status_not_ok

Constructor for 'NOT_OK' status objects

=head3 status_notice

Constructor for 'NOTICE' status objects

=head3 status_ok

Constructor for 'OK' status objects

=head3 status_trace

Constructor for 'TRACE' status objects

=head3 status_warn

Constructor for 'WARN' status objects

=head3 status_warning

Constructor for 'WARNING' status objects


=head2 msg 

Construct a message object (wrapper for App::CELL::Message::new)

=cut

sub msg { 
    my ( $self, $code, @ARGS ) = @_;
    my $status = App::CELL::Message->new( code => $code, args => [ @ARGS ] );
    return if $status->not_ok; # will return undef in scalar mode
    return $status->payload if blessed $status->payload;
    return;
}




=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014-2015, SUSE LLC

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

3. Neither the name of SUSE LLC nor the names of its contributors may be
used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

=cut

# END OF CELL MODULE
1;
