#============================================================= -*-perl-*-
#
# Apache::Template
#
# DESCRIPTION
#   Apache/mod_perl handler for the Template Toolkit.
#
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2004 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-2002 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: Template.pm,v 1.5 2004/04/27 09:11:31 abw Exp $
#
#========================================================================

package Apache::Template;

use strict;
use vars qw( $VERSION $DEBUG $ERROR $SERVICE );

use DynaLoader ();
use Apache::ModuleConfig ();
use Apache::Constants qw( :common );
use Template::Service::Apache;
use Template::Config;

$VERSION = '0.09';
$ERROR   = '';
$DEBUG   = 0 unless defined $DEBUG;
$Template::Config::SERVICE = 'Template::Service::Apache';

if ($ENV{ MOD_PERL }) {
    no strict;
    @ISA = qw( DynaLoader );
    __PACKAGE__->bootstrap($VERSION);
}


#------------------------------------------------------------------------
# handler($request)
#
# Main Apache/mod_perl content handler which delegates to an
# underlying Template::Service::Apache object.  A service is created that
# is unique to the hostname (e.g. to support multiple configurations for 
# virtual hosts).  This is created and stored in the $SERVICE hash and 
# then reused across requests to the same hostname.  This allows compiled 
# templates to be cached and re-used without requiring re-compilation.  
# The service implements 4 methods for different phases of the request:
#
#   template($request)            # fetch a compiled template
#   params($request)              # build parameter set (template vars)
#   process($template, $params)   # process template
#   headers($request, $template, \$content)
#                                 # set and send http headers
#------------------------------------------------------------------------

sub handler {
    my $r = shift;

    # create and cache a service for each hostname
    my $service = $SERVICE->{ $r->hostname() } ||= do {
        my $cfg = Apache::ModuleConfig->get($r) || { };
#        warn "setup service for hostname: ", $r->hostname, "  ($cfg):\n", 
#             dump_hash($cfg), "\n";
        Template::Config->service($cfg) || do {
            $r->log_reason(Template::Config->error(), $r->filename());
            return SERVER_ERROR;
        };
    };

    my $template = $service->template($r);
    return $template unless ref $template;

    my $params = $service->params($r);
    return $params unless ref $params;

    my $content = $service->process($template, $params);
    unless (defined $content) {
        $r->log_reason($service->error(), $r->filename());
        return SERVER_ERROR;
    }

    $service->headers($r, $template, \$content);

    $r->print($content);

    return OK;
}


#========================================================================
# Configuration Handlers
#========================================================================

#------------------------------------------------------------------------
# TT2Tags html          # specify TAG_STYLE
# TT2Tags [* *]         # specify START_TAG and END_TAG
#------------------------------------------------------------------------

sub TT2Tags($$$$) {
    my ($cfg, $parms, $start, $end) = @_;
    if (defined $end and length $end) {
        $cfg->{ START_TAG } = quotemeta($start);
        $cfg->{ END_TAG   } = quotemeta($end);
    }
    else {
        $cfg->{ TAG_STYLE } = $start;
    }
}

#------------------------------------------------------------------------
# TT2PreChomp On        # enable PRE_CHOMP
#------------------------------------------------------------------------

sub TT2PreChomp($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ PRE_CHOMP } = $on;
}

#------------------------------------------------------------------------
# TT2PostChomp On       # enable POST_CHOMP
#------------------------------------------------------------------------

sub TT2PostChomp($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ POST_CHOMP } = $on;
}

#------------------------------------------------------------------------
# TT2Trim On            # enable TRIM
#------------------------------------------------------------------------

sub TT2Trim($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ TRIM } = $on;
}

#------------------------------------------------------------------------
# TT2AnyCase On         # enable ANYCASE
#------------------------------------------------------------------------

sub TT2AnyCase($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ ANYCASE } = $on;
}

#------------------------------------------------------------------------
# TT2Interpolate On     # enable INTERPOLATE
#------------------------------------------------------------------------

sub TT2Interpolate($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ INTERPOLATE } = $on;
}

#------------------------------------------------------------------------
# TT2Tolerant On        # enable TOLERANT
#------------------------------------------------------------------------

sub TT2Tolerant($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ TOLERANT } = $on;
}

#------------------------------------------------------------------------
# TT2IncludePath /here /there   # define INCLUDE_PATH directories
# TT2IncludePath /elsewhere     # additional INCLUDE_PATH directories
#------------------------------------------------------------------------

sub TT2IncludePath($$@) {
    my ($cfg, $parms, $path) = @_;
    my $incpath = $cfg->{ INCLUDE_PATH } ||= [ ];
    push(@$incpath, $path);
}

#------------------------------------------------------------------------
# TT2Absolute On        # enable ABSOLUTE file paths
#------------------------------------------------------------------------

sub TT2Absolute($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ ABSOLUTE } = $on;
}

#------------------------------------------------------------------------
# TT2Relative On        # enable RELATIVE file paths
#------------------------------------------------------------------------

sub TT2Relative($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ RELATIVE } = $on;
}

#------------------------------------------------------------------------
# TT2Delimiter ,        # set alternate directory delimiter
#------------------------------------------------------------------------

sub TT2Delimiter($$$) {
    my ($cfg, $parms, $delim) = @_;
    $cfg->{ DELIMITER } = $delim;
}

#------------------------------------------------------------------------
# TT2PreProcess config header   # define PRE_PROCESS templates
# TT2PreProcess menu            # additional PRE_PROCESS templates
#------------------------------------------------------------------------

sub TT2PreProcess($$@) {
    my ($cfg, $parms, $file) = @_;
    my $preproc = $cfg->{ PRE_PROCESS } ||= [ ];
    push(@$preproc, $file);
}

#------------------------------------------------------------------------
# TT2Process main1 main2    # define PROCESS templates
# TT2Process main3          # additional PROCESS template
#------------------------------------------------------------------------

sub TT2Process($$@) {
    my ($cfg, $parms, $file) = @_;
    my $process = $cfg->{ PROCESS } ||= [ ];
    push(@$process, $file);
}

#------------------------------------------------------------------------
# TT2Wrapper main1 main2    # define WRAPPER templates
# TT2Wrapper main3          # additional WRAPPER template
#------------------------------------------------------------------------

sub TT2Wrapper($$@) {
    my ($cfg, $parms, $file) = @_;
    my $wrapper = $cfg->{ WRAPPER } ||= [ ];
    push(@$wrapper, $file);
}

#------------------------------------------------------------------------
# TT2PostProcess menu copyright # define POST_PROCESS templates
# TT2PostProcess footer         # additional POST_PROCESS templates
#------------------------------------------------------------------------

sub TT2PostProcess($$@) {
    my ($cfg, $parms, $file) = @_;
    my $postproc = $cfg->{ POST_PROCESS } ||= [ ];
    push(@$postproc, $file);
}

#------------------------------------------------------------------------
# TT2Default notfound       # define DEFAULT template
#------------------------------------------------------------------------

sub TT2Default($$$) {
    my ($cfg, $parms, $file) = @_;
    $cfg->{ DEFAULT } = $file;
}

#------------------------------------------------------------------------
# TT2Error error        # define ERROR template
#------------------------------------------------------------------------

sub TT2Error($$$) {
    my ($cfg, $parms, $file) = @_;
    $cfg->{ ERROR } = $file;
}

#------------------------------------------------------------------------
# TT2EvalPerl On        # enable EVAL_PERL
#------------------------------------------------------------------------

sub TT2EvalPerl($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ EVAL_PERL } = $on;
}

#------------------------------------------------------------------------
# TT2LoadPerl On        # enable LOAD_PERL
#------------------------------------------------------------------------

sub TT2LoadPerl($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ LOAD_PERL } = $on;
}

#------------------------------------------------------------------------
# TT2Recursion On       # enable RECURSION
#------------------------------------------------------------------------

sub TT2Recursion($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ RECURSION } = $on;
}

#------------------------------------------------------------------------
# TT2PluginBase My::Plugins     # define PLUGIN_BASE package(s)
# TT2PluginBase Your::Plugin    # additional PLUGIN_BASE package(s)
#------------------------------------------------------------------------

sub TT2PluginBase($$@) {
    my ($cfg, $parms, $base) = @_;
    my $pbases = $cfg->{ PLUGIN_BASE } ||= [ ];
    push(@$pbases, $base);
}

#------------------------------------------------------------------------
# TT2AutoReset Off      # disable AUTO_RESET
#------------------------------------------------------------------------

sub TT2AutoReset($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ AUTO_RESET } = $on;
}

#------------------------------------------------------------------------
# TT2CacheSize 128      # define CACHE_SIZE
#------------------------------------------------------------------------

sub TT2CacheSize($$$) {
    my ($cfg, $parms, $size) = @_;
    $cfg->{ CACHE_SIZE } = $size;
}

#------------------------------------------------------------------------
# TT2CompileExt .tt2        # define COMPILE_EXT
#------------------------------------------------------------------------

sub TT2CompileExt($$$) {
    my ($cfg, $parms, $ext) = @_;
    $cfg->{ COMPILE_EXT } = $ext;
}

#------------------------------------------------------------------------
# TT2CompileDir /var/tt2/cache  # define COMPILE_DIR
#------------------------------------------------------------------------

sub TT2CompileDir($$$) {
    my ($cfg, $parms, $dir) = @_;
    $cfg->{ COMPILE_DIR } = $dir;
}

#------------------------------------------------------------------------
# TT2Debug On           # enable DEBUG
#------------------------------------------------------------------------

sub TT2Debug($$$) {
    my ($cfg, $parms, $on) = @_;
    $cfg->{ DEBUG } = $DEBUG = $on;
}

#------------------------------------------------------------------------
# TT2Headers length etag        # add certain HTTP headers
#------------------------------------------------------------------------

sub TT2Headers($$@) {
    my ($cfg, $parms, $item) = @_;
    my $headers = $cfg->{ SERVICE_HEADERS } ||= [ ];
    push(@$headers, $item);
}

#------------------------------------------------------------------------
# TT2Params uri env pnotes uploads request            # add template vars
#------------------------------------------------------------------------

sub TT2Params($$@) {
    my ($cfg, $parms, $item) = @_;
    my $params = $cfg->{ SERVICE_PARAMS } ||= [ ];
    push(@$params, $item);
}

#------------------------------------------------------------------------
# TT2ContentType   text/xml                         # custom content type
#------------------------------------------------------------------------

sub TT2ContentType($$$) {
    my ($cfg, $parms, $type) = @_;
    $cfg->{ CONTENT_TYPE } = $type;
}

#------------------------------------------------------------------------
# TT2ServiceModule   My::Service::Class     # custom service module
#------------------------------------------------------------------------

sub TT2ServiceModule($$$) {
    my ($cfg, $parms, $module) = @_;
    $Template::Config::SERVICE = $module;
}

#------------------------------------------------------------------------
# TT2Variable name value       # define template variable
#------------------------------------------------------------------------

sub TT2Variable($$$$) {
    my ($cfg, $parms, $name, $value) = @_;
    $cfg->{ VARIABLES }->{ $name } = $value;
}

#------------------------------------------------------------------------
# TT2Constant   foo  bar
#------------------------------------------------------------------------

sub TT2Constant($$@@) {
    my ($cfg, $parms, $name, $value) = @_;
    my $constants = $cfg->{ CONSTANTS } ||= { };
    $constants->{ $name } = $value;
}

#------------------------------------------------------------------------
# TT2ConstantsNamespace const
#------------------------------------------------------------------------

sub TT2ConstantsNamespace($$$) {
    my ($cfg, $parms, $namespace) = @_;
    $cfg->{ CONSTANTS_NAMESPACE } = $namespace;
}



#========================================================================
# Configuration creators/mergers
#========================================================================

my $dir_counter = 1;        # used for debugging/testing of problems
my $srv_counter = 1;        # with SERVER_MERGE and DIR_MERGE

sub SERVER_CREATE {
    my $class  = shift;
    my $config = bless { }, $class;
    warn "SERVER_CREATE($class) => $config\n" if $DEBUG;
    return $config;
}

sub SERVER_MERGE {
    my ($parent, $config) = @_;
    my $merged = _merge($parent, $config);
    
    if ($DEBUG) {
        $merged->{ counter } = $srv_counter;
        warn "\nSERVER_MERGE #" . $srv_counter++ . "\n" 
            . "$parent\n" . dump_hash($parent) . "\n+\n"
            . "$config\n" . dump_hash($config) . "\n=\n"
            . "$merged\n" . dump_hash($merged) . "\n";
    }
    return $merged;
}

sub DIR_CREATE {
    my $class  = shift;
    my $config = bless { }, $class;
    warn "DIR_CREATE($class) => $config\n" if $DEBUG;
    return $config;
}

sub DIR_MERGE {
    my ($parent, $config) = @_;
    my $merged = _merge($parent, $config);
    if ($DEBUG) {
        $merged->{ counter } = $dir_counter;
        warn "\nDIR_MERGE #" . $dir_counter++ . "\n" 
            . "$parent\n" . dump_hash($parent) . "\n+\n"
            . "$config\n" . dump_hash($config) . "\n=\n"
            . "$merged\n" . dump_hash($merged) . "\n";
    }
    return $merged;
}


sub _merge {
    my ($parent, $config) = @_;

    # let's not merge with ourselves.
    # it's not.. umm.. natural.
    return $config if $parent eq $config;
    
    my $merged = bless { }, ref($parent);
  
    foreach my $key (keys %$parent) {
        if(!ref $parent->{$key}) {
            $merged->{$key} = $parent->{$key};
        } 
        elsif (ref $parent->{$key} eq 'ARRAY') {
            $merged->{$key} = [ @{$parent->{$key}} ];
        } 
        elsif (ref $parent->{$key} eq 'HASH') {
            $merged->{$key} = { %{$parent->{$key}} };
        } 
        elsif (ref $parent->{$key} eq 'SCALAR') {
            $merged->{$key} = \${$parent->{$key}};
        }
    }
    
    foreach my $key (keys %$config) {
        if(!ref $config->{$key}) {
            $merged->{$key} = $config->{$key};
        } 
        elsif (ref $config->{$key} eq 'ARRAY') {
            push @{$merged->{$key} ||= []}, @{$config->{$key}};
        } 
        elsif (ref $config->{$key} eq 'HASH') {
            $merged->{$key} = { %{$merged->{$key}}, %{$config->{$key}} };
        } 
        elsif (ref $config->{$key} eq 'SCALAR') {
            $merged->{$key} = \${$config->{$key}};
        }
    }
    return $merged;
}


# debug methods for testing problems with DIR_MERGE, etc.

sub dump_hash {
    my $hash = shift;
    my $out = "  {\n";

    while (my($key, $value) = (each %$hash)) {
        $value = "[ @$value ]" if ref $value eq 'ARRAY';
        $out .= "      $key => $value\n";
    }
    $out .= "  }";
}

sub dump_hash_html {
    my $hash = dump_hash(shift);
    for ($hash) {
        s/>/&gt;/g;
        s/\n/<br>/g;
        s/ /&nbsp;/g;
    }
    return $hash;
}

    
1;

__END__

=head1 NAME

Apache::Template - Apache/mod_perl interface to the Template Toolkit

=head1 SYNOPSIS

    # add the following to your httpd.conf
    PerlModule          Apache::Template

    # set various configuration options, e.g.
    TT2Trim             On
    TT2PostChomp        On
    TT2EvalPerl         On
    TT2IncludePath      /usr/local/tt2/templates
    TT2IncludePath      /home/abw/tt2/lib
    TT2PreProcess       config header
    TT2PostProcess      footer
    TT2Error            error

    # now define Apache::Template as a PerlHandler, e.g.
    <Files *.tt2>
        SetHandler      perl-script
        PerlHandler     Apache::Template
    </Files>

    <Location /tt2>
        SetHandler      perl-script
        PerlHandler     Apache::Template
    </Location>

=head1 DESCRIPTION

The Apache::Template module provides a simple interface to the
Template Toolkit from Apache/mod_perl.  The Template Toolkit is a
fast, powerful and extensible template processing system written in
Perl.  It implements a general purpose template language which allows
you to clearly separate application logic, data and presentation
elements.  It boasts numerous features to facilitate in the generation
of web content both online and offline in "batch mode".

This documentation describes the Apache::Template module, concerning
itself primarily with the Apache/mod_perl configuration options
(e.g. the httpd.conf side of things) and not going into any great
depth about the Template Toolkit itself.  The Template Toolkit
includes copious documentation which already covers these things in
great detail.  See L<Template> and L<Template::Manual> for further
information.

=head1 UPGRADING FROM EARLIER VERSIONS OF Apache::Template

If you are upgrading from an earlier version of Apache::Template
(e.g. 0.08 or earlier) then you should pay particular attention to
the changes in the TT2Headers option in version 0.09.

The Content-Type header can now be controlled by the TT2Headers option
(to enable or disable it) and by the TT2ContentType option (to set
a specific Content-Type).

If you don't specify any TT2Headers option, then it will default to 
sending the Content-Type header only, emulating the existing behaviour
of Apache::Template 0.08 and earlier.  Thus the default is equivalent 
to the following:

    TT2Headers      type              # default 

If you do specify a TT2Headers option, then you must now explicitly
add the 'type' value to have Apache::Template send the Content-Type
header.

    TT2Headers      type length

If you don't specify 'type' in the TT2Headers option then
Apache::Template will not add a Content-Type header.  

The default value for Content-Type is 'text/html' but can now be changed
using the TT2ContentType option.

    TT2ContentType  text/xml

=head1 CONFIGURATION

Most of the Apache::Template configuration directives relate directly
to their Template Toolkit counterparts, differing only in having a
'TT2' prefix, mixed capitalisation and lack of underscores to space
individual words.  This is to keep Apache::Template configuration
directives in keeping with the preferred Apache/mod_perl style.

e.g.

    Apache::Template  =>  Template Toolkit
    --------------------------------------
    TT2Trim               TRIM
    TT2IncludePath        INCLUDE_PATH
    TT2PostProcess        POST_PROCESS
    ...etc...

In some cases, the configuration directives are named or behave
slightly differently to optimise for the Apache/mod_perl environment
or domain specific features.  For example, the TT2Tags configuration
directive can be used to set TAG_STYLE and/or START_TAG and END_TAG
and as such, is more akin to the Template Toolkit TAGS directive.

e.g.

    TT2Tags     html
    TT2Tags     <!--  -->

The configuration directives are listed in full below.  Consult 
L<Template> for further information on their effects within the 
Template Toolkit.

=over 4

=item TT2Tags

Used to set the tags used to indicate Template Toolkit directives
within source templates.  A single value can be specified to 
indicate a TAG_STYLE, e.g.

    TT2Tags     html

A pair of values can be used to indicate a START_TAG and END_TAG.

    TT2Tags     <!--    -->

Note that, unlike the Template Toolkit START_TAG and END_TAG
configuration options, these values are automatically escaped to
remove any special meaning within regular expressions.

    TT2Tags     [*  *]  # no need to escape [ or *

By default, the start and end tags are set to C<[%> and C<%]>
respectively.  Thus, directives are embedded in the form: 
[% INCLUDE my/file %].

=item TT2PreChomp

Equivalent to the PRE_CHOMP configuration item.  This flag can be set
to have removed any whitespace preceeding a directive, up to and
including the preceeding newline.  Default is 'Off'.

    TT2PreChomp     On

=item TT2PostChomp

Equivalent to the POST_CHOMP configuration item.  This flag can be set
to have any whitespace after a directive automatically removed, up to 
and including the following newline.  Default is 'Off'.

    TT2PostChomp    On

=item TT2Trim

Equivalent to the TRIM configuration item, this flag can be set
to have all surrounding whitespace stripped from template output.
Default is 'Off'.

    TT2Trim         On

=item TT2AnyCase

Equivalent to the ANY_CASE configuration item, this flag can be set
to allow directive keywords to be specified in any case.  By default,
this setting is 'Off' and all directive (e.g. 'INCLUDE', 'FOREACH', 
etc.) should be specified in UPPER CASE only.

    TT2AnyCase      On

=item TT2Interpolate

Equivalent to the INTERPOLATE configuration item, this flag can be set
to allow simple variables of the form C<$var> to be embedded within
templates, outside of regular directives.  By default, this setting is
'Off' and variables must appear in the form [% var %], or more explicitly,
[% GET var %].

    TT2Interpolate  On

=item TT2IncludePath

Equivalent to the INCLUDE_PATH configuration item.  This can be used
to specify one or more directories in which templates are located.
Multiple directories may appear on each TT2IncludePath directive line,
and the directive may be repeated.  Directories are searched in the 
order defined.

    TT2IncludePath  /usr/local/tt2/templates
    TT2InludePath   /home/abw/tt2   /tmp/tt2

Note that this only affects templates which are processed via
directive such as INCLUDE, PROCESS, INSERT, WRAPPER, etc.  The full
path of the main template processed by the Apache/mod_perl handler is
generated (by Apache) by appending the request URI to the
DocumentRoot, as per usual.  For example, consider the following
configuration extract:

    DocumentRoot    /usr/local/web/ttdocs
    [...]
    TT2IncludePath  /usr/local/tt2/templates

    <Files *.tt2>
    SetHandler  perl-script
        PerlHandler     Apache::Template
    </Files>

A request with a URI of '/foo/bar.tt2' will cause the handler to
process the file '/usr/local/web/ttdocs/foo/bar.tt2' (i.e.
DocumentRoot + URI).  If that file should include a directive such
as [% INCLUDE foo/bar.tt2 %] then that template should exist as the
file '/usr/local/tt2/templates/foo/bar.tt2' (i.e. TT2IncludePath + 
template name).

=item TT2Absolute

Equivalent to the ABSOLUTE configuration item, this flag can be enabled
to allow templates to be processed (via INCLUDE, PROCESS, etc.) which are
specified with absolute filenames.

    TT2Absolute     On

With the flag enabled a template directive of the form:

    [% INCLUDE /etc/passwd %]

will be honoured.  The default setting is 'Off' and any attempt to
load a template by absolute filename will result in a 'file' exception
being throw with a message indicating that the ABSOLUTE option is not
set.  See L<Template> for further discussion on exception handling.

=item TT2Relative

Equivalent to the RELATIVE configuration item.  This is similar to the 
TT2Absolute option, but relating to files specified with a relative filename,
that is, starting with './' or '../'

    TT2Relative On

Enabling the option permits templates to be specifed as per this example:

    [% INCLUDE ../../../etc/passwd %]

As with TT2Absolute, this option is set 'Off', causing a 'file' exception
to be thrown if used in this way.

=item TT2Delimiter

Equivalent to the DELIMTER configuration item, this can be set to define 
an alternate delimiter for separating multiple TT2IncludePath options.
By default, it is set to ':', and thus multiple directories can be specified
as:

    TT2IncludePath  /here:/there

Note that Apache implicitly supports space-delimited options, so the
following is also valid and defines 3 directories, /here, /there and
/anywhere.

    TT2IncludePath  /here:/there /anywhere

If you're unfortunate enough to be running Apache on a Win32 system and 
you need to specify a ':' in a path name, then set the TT2Delimiter to 
an alternate value to avoid confusing the Template Toolkit into thinking
you're specifying more than one directory:

    TT2Delimiter    ,
    TT2IncludePath  C:/HERE D:/THERE E:/ANYWHERE

=item TT2PreProcess

Equivalent to PRE_PROCESS, this option allows one or more templates to
be named which should be processed before the main template.  This can
be used to process a global configuration file, add canned headers,
etc.  These templates should be located in one of the TT2IncludePath
directories, or specified absolutely if the TT2Absolute option is set.

    TT2PreProcess   config header

=item TT2PostProcess

Equivalent to POST_PROCESS, this option allow one or more templates to
be named which should be processed after the main template, e.g. to
add standard footers.  As per TTPreProcess, these should be located in
one of the TT2IncludePath directories, or specified absolutely if the
TT2Absolute option is set.

    TT2PostProcess  copyright footer

=item TT2Process

This is equivalent to the PROCESS configuration item.  It can be used
to specify one or more templates to be process instead of the main
template.  This can be used to apply a standard "wrapper" around all
template files processed by the handler.

    TT2Process      mainpage

The original template (i.e. whose path is formed from the DocumentRoot
+ URI, as explained in the L<TT2IncludePath|TT2IncludePath> item
above) is preloaded and available as the 'template' variable.  This a 
typical TT2Process template might look like:

    [% PROCESS header %]
    [% PROCESS $template %] 
    [% PROCESS footer %]

Note the use of the leading '$' on template to defeat the auto-quoting
mechanism which is applied to INCLUDE, PROCESS, etc., directives.  The
directive would otherwise by interpreted as:

    [% PROCESS "template" %]

=item TT2Wrapper

This is equivalent to the WRAPPER configuration item.  It can be used
to specify one or more templates to be wrapped around the content 
generated by processing the main page template.

    TT2Wrapper      sitewrap

The original page template is processed first.  The wrapper template
is then processed, with the C<content> variable containing the output
generated by processing the main page template.

Multiple wrapper templates can be specified.  For example, to wrap each
page in the F<layout> template, and then to wrap that in the F<htmlpage> 
template, you would write:

    TT2Wrapper htmlpage layout

Or:

    TT2Wrapper htmlpage
    TT2Wrapper layout

Note that the TT2Wrapper options are specified in "outside-in" order 
(i.e. the outer wrapper, followed by the inner wrapper).  However, 
they are processed in reverse "inside-out" order (i.e. the page content,
followed by the inner wrapper, followed by the outer wrapper).

=item TT2Default

This is equivalent to the DEFAULT configuration item.  This can be
used to name a template to be used in place of a missing template
specified in a directive such as INCLUDE, PROCESS, INSERT, etc.  Note
that if the main template is not found (i.e. that which is mapped from
the URI) then the handler will decline the request, resulting in a 404
- Not Found.  The template specified should exist in one of the 
directories named by TT2IncludePath.

    TT2Default      nonsuch

=item TT2Error

This is equivalent to the ERROR configuration item.  It can be
used to name a template to be used to report errors that are otherwise
uncaught.  The template specified should exist in one of the 
directories named by TT2IncludePath.  When the error template is 
processed, the 'error' variable will be set to contain the relevant
error details.

    TT2Error        error

=item TT2Variable

This option allows you to define values for simple template variables.
If you have lots of variables to define then you'll probably want to 
put them in a config template and pre-process it with TT2PreProcess.

    TT2Variable     version  3.14

=item TT2Constant

This option allows you to define values for constants.  These are
similar to regular TT variables, but are resolved once when the
template is compiled.

    TT2Constant     pi  3.14

=item TT2ConstantsNamespace

Constants are accessible via the 'constants' namespace by default (e.g.
[% constants.pi %].  This option can be used to provide an alternate
namespace for constants.

    TT2ConstantNamespace  my

=item TT2EvalPerl

This is equivalent to the EVAL_PERL configuration item.  It can be
enabled to allow embedded [% PERL %] ... [% END %] sections
within templates.  It is disabled by default and any PERL sections
encountered will raise 'perl' exceptions with the message 'EVAL_PERL
not set'.

    TT2EvalPerl     On

=item TT2LoadPerl

This is equivalent to the LOAD_PERL configuration item which allows
regular Perl modules to be loaded as Template Toolkit plugins via the 
USE directive.  It is set 'Off' by default.

    TT2LoadPerl     On

=item TT2Recursion

This is equivalent to the RECURSION option which allows templates to
recurse into themselves either directly or indirectly.  It is set
'Off' by default.

    TT2Recursion    On

=item TT2PluginBase

This is equivalent to the PLUGIN_BASE option.  It allows multiple 
Perl packages to be specified which effectively form a search path
for loading Template Toolkit plugins.  The default value is 
'Template::Plugin'.

    TT2PluginBase   My::Plugins  Your::Plugins

=item TT2AutoReset

This is equivalent to the AUTO_RESET option and is enabled by default.
It causes any template BLOCK definitions to be cleared before each
main template is processed.

    TT2AutoReset    Off

=item TT2CacheSize

This is equivalent to the CACHE_SIZE option.  It can be used to limit 
the number of compiled templates that are cached in memory.  The default
value is undefined and all compiled templates will be cached in memory.
It can be set to a specified numerical value to define the maximum
number of templates, or to 0 to disable caching altogether.

    TT2CacheSize    64

=item TT2CompileExt

This is equivalent to the COMPILE_EXT option.  It can be used to
specify a filename extension which the Template Toolkit will use for
writing compiled templates back to disk, thus providing cache
persistance.

    TT2CompileExt   .ttc

=item TT2CompileDir

This is equivalent to the COMPILE_DIR option.  It can be used to
specify a root directory under which compiled templates should be 
written back to disk for cache persistance.  Any TT2IncludePath 
directories will be replicated in full under this root directory.

    TT2CompileDir   /var/tt2/cache

=item TT2Debug

This is equivalent to the DEBUG option which enables Template Toolkit
debugging.  The main effect is to raise additional warnings when
undefined variables are used but is likely to be expanded in a future
release to provide more extensive debugging capabilities.

    TT2Debug        On

=item TT2Tolerant

This is equivalent to the TOLERANT option which makes the Template
Toolkit providers tolerant to errors.

    TT2Tolerant     On

=item TT2Headers

Allows you to specify which HTTP headers you want added to the
response.  Current permitted values are: 'type' (Content-Type),
'length' (Content-Length), 'modified' (Last-Modified) and 'etag'
(E-Tag).

    TT2Headers      type length

It can also be set to 'all' to enable all headers.

    TT2Headers      all

If the TT2Headers option is not specified, then it default to 'type',
sending the Content-Type header set to the value of TT2ContentType
or 'text/html' if undefined. 

    TT2Headers      type    # default - same as no TT2Headers option

The option can be set to 'none' to disable all headers, including the
Content-Type.

    TT2Headers      none

=item TT2ContentType

This option can be used to set a Content-Type other than the default
value of 'text/html'.

    TT2ContentType   text/xml

=item TT2Params

Allows you to specify which parameters you want defined as template
variables.  Current permitted values are 'uri', 'env' (hash of
environment variables), 'params' (hash of CGI parameters), 'pnotes'
(the request pnotes hash), 'cookies' (hash of cookies), 'uploads' (a
list of Apache::Upload instances), 'request' (the Apache::Request
object) or 'all' (all of the above).

    TT2Params       uri env params uploads request

When set, these values can then be accessed from within any 
template processed:

    The URI is [% uri %]

    Server name is [% env.SERVER_NAME %]

    CGI params are:
    <table>
    [% FOREACH key = params.keys %]
       <tr>
     <td>[% key %]</td>  <td>[% params.$key %]</td>
       </tr>
    [% END %]
    </table>


=item TT2ServiceModule

The modules have been designed in such a way as to make it easy to
subclass the Template::Service::Apache module to create your own
custom services.  

For example, the regular service module does a simple 1:1 mapping of
URI to template using the request filename provided by Apache, but
you might want to implement an alternative scheme.  You might prefer,
for example, to map multiple URIs to the same template file, but to
set some different template variables along the way.  

To do this, you can subclass Template::Service::Apache and redefine
the appropriate methods.  The template() method performs the task of
mapping URIs to templates and the params() method sets up the template
variable parameters.  Or if you need to modify the HTTP headers, then
headers() is the one for you.

The TT2ServiceModule option can be set to indicate the name of your
custom service module.  The following trivial example shows how you
might subclass Template::Service::Apache to add an additional parameter,
in this case as the template variable 'message'.

    <perl>
    package My::Service::Module;
    use base qw( Template::Service::Apache );

    sub params {
    my $self = shift;
        my $params = $self->SUPER::params(@_);
        $params->{ message } = 'Hello World';
        return $params;
    }
    </perl>

    PerlModule          Apache::Template
    TT2ServiceModule    My::Service::Module

=back

=head1 CONFIGURATION MERGING

The Apache::Template module creates a separate service for each
virtual server.  Each virtual server can have its own configuration.
Any globally defined options will be merged with any server-specific 
ones.  

The following examples illustrates two separate virtual servers being
configured in one Apache configuration file.

    PerlModule	    Apache::Template
    TT2IncludePath	/usr/local/tt2/templates
    TT2Params       request params
    TT2Wrapper      html/page

    NameVirtualHost 127.0.0.1

    <VirtualHost 127.0.0.1>
        ServerName     shoveit
        SetHandler     perl-script
        PerlHandler    Apache::Template
        TT2Wrapper     layout_a
    </VirtualHost>

    <VirtualHost 127.0.0.1>
       ServerName     kickflip
       SetHandler     perl-script
       PerlHandler    Apache::Template
       TT2Wrapper     layout_b
    </VirtualHost>

In this example, the C<shoveit> virtual host will be configured as if written:

    PerlModule	    Apache::Template
    TT2IncludePath	/usr/local/tt2/templates
    TT2Params       request params
    TT2Wrapper      html/page
    TT2Wrapper      layout_a

The second C<TTWrapper> option (C<layout_a>) is added to the shared
configuration block.

The C<kickflip> virtual host will be configured as if written:

    PerlModule	    Apache::Template
    TT2IncludePath	/usr/local/tt2/templates
    TT2Params       request params
    TT2Wrapper      html/page
    TT2Wrapper      layout_b

Here, the C<layout_b> wrapper template is used instead of C<layout_a>.

Apache::Template does not correctly handle different configurations for
separate directories, location or files within the same virtual server.

=head1 AUTHOR

Andy Wardley E<lt>abw@wardley.orgE<gt>, with contributions from Darren
Chamberlain (who wrote the 'Grover' module which was integrated into
Apache::Template), Mark Fowler, Randal Schwartz, Tony Payne and Rick
Myers.

=head1 VERSION

This is version 0.09 of the Apache::Template module.

=head1 COPYRIGHT

    Copyright (C) 1996-2004 Andy Wardley.  All Rights Reserved.
    Copyright (C) 1998-2002 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

For further information about the Template Toolkit, see L<Template>
or http://www.template-toolkit.org/

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
