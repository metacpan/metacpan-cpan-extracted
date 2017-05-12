#============================================================= -*-Perl-*-
#
# Template::Service::Apache
#
# DESCRIPTION
#   Module subclassed from Template::Service which implements a service 
#   specific to the Apache/mod_perl environment.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2004 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
# 
#----------------------------------------------------------------------------
#
# $Id: Apache.pm,v 1.4 2004/04/27 09:11:31 abw Exp $
#
#============================================================================

package Template::Service::Apache;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $ERROR $CONTENT_TYPE );
use base qw( Template::Service );
use Digest::MD5 qw( md5_hex );
use Template::Config;
use Template::Constants;
use Template::Exception;
use Template::Service;

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$CONTENT_TYPE = 'text/html';

use Apache::Util qw( escape_uri ht_time );
use Apache::Constants qw( :common );
use Apache::Request;

#========================================================================
#                     -----  PUBLIC METHODS -----
#========================================================================

#------------------------------------------------------------------------
# template($request)
#
# Fetch root template document from the ROOT_PROVIDER using the 
# request filename.  Returns a reference to a Template::Document
# object on success or a DECLINED status code if not found.  On error,
# the relevant error message is logged and SERVER_ERROR is returned.
#------------------------------------------------------------------------

sub template {
    my ($self, $r) = @_;
    my $filename = $r->filename();
    
    return DECLINED unless -f $filename;
    $self->{ TEMPLATE_ERROR } = undef;

    my ($template, $error) = $self->{ ROOT_PROVIDER }->fetch($filename);
    if ($error && $error == &Template::Constants::STATUS_DECLINED) {
        return DECLINED;
    }
    elsif ($error) {
        # save error as exception for params() to add to template vars
        $self->{ TEMPLATE_ERROR } = Template::Exception->new(
            Template::Constants::ERROR_FILE, $template
        );
        
        # if there is an ERROR template defined then we attempt to 
        # fetch it as a substitute for the original template.  Note 
        # that we must fetch it from the regular template providers
        # in the Template::Context because they honour the INCLUDE_PATH 
        # parameters whereas the ROOT_PROVIDER expects an absolute file
        
        if ($template = $self->{ ERROR }) {
            eval { $template = $self->{ CONTEXT }->template($template) };
            if ($@) {
                $r->log_reason($self->{ TEMPLATE_ERROR } . " / $@", $filename);
                return SERVER_ERROR;
            }
        }
        else {
            $r->log_reason($template, $filename);
            return SERVER_ERROR;
        }
    }
    
    return $template;
}


#------------------------------------------------------------------------
# params($request, $params)
#
# Create a set of processing parameters (i.e. template variables) for
# the request.
#------------------------------------------------------------------------

sub params {
    my ($self, $request, $params) = @_;
    $params ||= { };

    my $plist = $self->{ SERVICE_PARAMS };
    my $all = $plist->{ all };

    return $params unless keys %$plist;
    $request = Apache::Request->new($request);

    $params->{ env } = { %{ $request->subprocess_env() } }
        if $all or $plist->{ env };

    $params->{ uri } = $request->subprocess_env('REDIRECT_URL') || $request->uri()
        if $all or $plist->{ uri };

    $params->{ pnotes } = $request->pnotes()
        if $all or $plist->{ pnotes };

    $params->{ params } = { %{ $request->parms() } }
        if $all or $plist->{ params };

    $params->{ request } = $request
        if $all or $plist->{ request };

    if ($all or $plist->{ uploads }) {
        my @uploads = $request->upload;
        $params->{ uploads } = \@uploads;
    }

    $params->{ cookies } = { 
        map { $1 => escape_uri($2) if (/([^=]+)=(.*)/) }
        grep(!/^$/, split(/;\s*/, $request->header_in('cookie'))),
    } if $all or $plist->{ cookies };
    
    # add any error raised by main template failure
    $params->{ error } = $self->{ TEMPLATE_ERROR };

    return $params;
}


#------------------------------------------------------------------------
# headers($request, $template, $content_ref)
#
# Set and then send the required http headers.
#------------------------------------------------------------------------

sub headers {
    my ($self, $r, $template, $content) = @_;
    my $headers = $self->{ SERVICE_HEADERS };
    my $all = $headers->{ all };

    $r->content_type($self->{ CONTENT_TYPE })
        if $all or $headers->{ type };
    $r->headers_out->add('Content-Length' => length $$content)
        if $all or $headers->{ length };
    $r->headers_out->add('Last-Modified'  => ht_time($template->modtime()))
        if $all or $headers->{ modified } and $template;
    $r->headers_out->add('E-tag' => sprintf q{"%s"}, md5_hex($$content))
        if $all or $headers->{ etag };
    $r->send_http_header;
}


#------------------------------------------------------------------------
# _init()
#
# In additional to the regular template providers (Template::Provider
# objects) created as part of the context initialisation and used to
# deliver templates loaded via INCLUDE, PROCESS, etc., we also create
# a single additional provider responsible for loading the main
# template.  We do this so that we can enable its ABSOLUTE flag,
# allowing us to specify a requested template by absolute filename (as
# Apache provides for us in $r->filename()) but without forcing all
# other providers to honour the ABSOLUTE flag.  We pre-create a PARSER
# object (Template::Parser) which can be shared across all providers.
#------------------------------------------------------------------------

sub _init {
    my ($self, $config) = @_;

    # create a parser to be shared by all providers
    $config->{ PARSER } ||= Template::Config->parser($config) 
        || return $self->error(Template::Config->error());

    # create a provider for the root document
    my $rootcfg = {
        ABSOLUTE => 1,
        map { exists $config->{ $_ } ? ($_, $config->{ $_ }) : () }
        qw( COMPILE_DIR COMPILE_EXT CACHE_SIZE PARSER ),
    };

    my $rootprov = Template::Config->provider($rootcfg)
        || return $self->error(Template::Config->error());

    # now let the Template::Service superclass initialiser continue
    $self->SUPER::_init($config)
        || return undef;

    # save reference to root document provider
    $self->{ ROOT_PROVIDER } = $rootprov;

    # determine content type or use default
    $self->{ CONTENT_TYPE } = $config->{ CONTENT_TYPE } || $CONTENT_TYPE;


    # if TT2Headers not explicitly defined then we default it to 
    # just send the Content-Type, for the simple cases and backwards
    # compatibility with earlier versions (0.08 and earlier) where
    # the Content-Type was always sent regardless

    $config->{ SERVICE_HEADERS } = ['type']
        unless $config->{ SERVICE_HEADERS };

    # extract other relevant SERVICE_* config items
    foreach (qw( SERVICE_HEADERS SERVICE_PARAMS )) {
        my $item = $config->{ $_ } || [ ];
        $self->{ $_ } = { map { $_ => 1 } @$item };
    }
    
    
    return $self;
}
    
1;
