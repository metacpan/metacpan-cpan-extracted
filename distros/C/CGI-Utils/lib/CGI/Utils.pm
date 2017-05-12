# -*-perl-*-
# Creation date: 2003-08-13 20:23:50
# Authors: Don
# Change log:
# $Id: Utils.pm,v 1.73 2008/11/13 03:56:46 don Exp $

# Copyright (c) 2003-2008 Don Owens

# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

=pod

=head1 NAME

CGI::Utils - Utilities for retrieving information through the
Common Gateway Interface

=head1 SYNOPSIS

 use CGI::Utils;
 my $utils = CGI::Utils->new;

 my $fields = $utils->vars; # or $utils->Vars
 my $field1 = $$fields{field1};

     or

 my $field1 = $utils->param('field1');


 # File uploads
 my $file_handle = $utils->param('file0'); # or $$fields{file0};
 my $file_name = "$file_handle";  

=head1 DESCRIPTION

This module can be used almost as a drop-in replacement for
CGI.pm for those of you who do not use the HTML generating
features of CGI.pm

This module provides an object-oriented interface for retrieving
information provided by the Common Gateway Interface, as well as
url-encoding and decoding values, and parsing CGI
parameters. For example, CGI has a utility for escaping HTML,
but no public interface for url-encoding a value or for taking a
hash of values and returning a url-encoded query string suitable
for passing to a CGI script. This module does that, as well as
provide methods for creating a self-referencing url, converting
relative urls to absolute, adding CGI parameters to the end of a
url, etc.  Please see the METHODS section below for more
detailed descriptions of functionality provided by this module.

File uploads via the multipart/form-data encoding are supported.
The parameter for the field name corresponding to the file is a
file handle that, when evaluated in string context, returns the
name of the file uploaded.  To get the contents of the file,
just read from the file handle.

mod_perl is supported if a value for apache_request is passed to
new(), or if the apache request object is available via
Apache->request, or if running under HTML::Mason.  See the
documentation for the new() method for details.

If not running in a mod_perl or CGI environment, @ARGV will be
searched for key/value pairs in the format

 key1=val1 key2=val2

If all command-line arguments are in this format, the key/value
pairs will be available as if they were passed via a CGI or
mod_perl interface.

=head1 METHODS

=cut

# TODO
# modify CGI::Utils::UploadFile to use hidden attributes instead of making up class names
# cache values like parsed cookies
# NPH stuff for getHeader()

use strict;

{   package CGI::Utils;

    use vars qw($VERSION @ISA @EXPORT_OK @EXPORT %EXPORT_TAGS $AUTOLOAD);

    use CGI::Utils::UploadFile;
    
    BEGIN {
        $VERSION = '0.12'; # update below in POD as well

        local($SIG{__DIE__});
        if (defined($ENV{MOD_PERL}) and $ENV{MOD_PERL} ne '') {
            eval q{
                use mod_perl;
                $CGI::Utils::MP2 = $mod_perl::VERSION >= 1.99;
                if (defined($CGI::Utils::MP2)) {
                    if ($CGI::Utils::MP2) {
                        require Apache2::Const;
                        require Apache2::RequestUtil;
                    }
                    else {
                        require Apache::Constants;
                    }
                    $CGI::Utils::Loaded_Apache_Constants = 1;
                }
            };
        }
    }

    use constant MP2 => $CGI::Utils::MP2;
    
    require Exporter;
    @ISA = 'Exporter';
    @EXPORT = ();
    @EXPORT_OK = qw(urlEncode urlDecode urlEncodeVars urlDecodeVars getSelfRefHostUrl
                    getSelfRefUrl getSelfRefUrlWithQuery getSelfRefUrlDir addParamsToUrl
                    getParsedCookies escapeHtml escapeHtmlFormValue convertRelativeUrlWithParams
                    convertRelativeUrlWithArgs getSelfRefUri);
    $EXPORT_TAGS{all_utils} = [ qw(urlEncode urlDecode urlEncodeVars urlDecodeVars
                                   getSelfRefHostUrl
                                   getSelfRefUrl getSelfRefUrlWithQuery getSelfRefUrlDir
                                   addParamsToUrl getParsedCookies escapeHtml escapeHtmlFormValue
                                   convertRelativeUrlWithParams convertRelativeUrlWithArgs
                                   getSelfRefUri)
                              ];

=pod

=head2 new(\%params)

Returns a new CGI::Utils object.  Parameters are optional.
CGI::Utils supports mod_perl if the Apache request object is
passed as $params{apache_request}, or if it is available via
Apache->request (or Apache2::RequestUtil->request), or if running
under HTML::Mason.

You may also pass max_post_size in %params.

=cut
    sub new {
        my ($proto, $args) = @_;
        $args = {} unless ref($args) eq 'HASH';
        my $self = { _params => {}, _param_order => [], _upload_info => {},
                     _max_post_size => $$args{max_post_size},
                     _apache_request => $$args{apache_request},
                     _mason => $$args{mason},
                   };
        bless $self, ref($proto) || $proto;
        return $self;
    }

    # added for v0.07
    sub _getApacheRequest {
        my ($self) = @_;
        my $r;
        $r = $self->{_apache_request} if ref($self);
        return $r if $r;

        if ($ENV{MOD_PERL}) {
            if ($self->_getMasonObject) {
                # we're running under mason
                return $self->_getApacheRequestFromMason;
            } elsif (defined($mod_perl::VERSION)) {
                if (MP2) {
                    $r = Apache2::RequestUtil->request;
                }
                else {
                    $r = Apache->request;
                }
                return $r if $r;
            }
        }

        return;
    }

    sub _getModPerlVersion {
        if (defined($mod_perl::VERSION)) {
            if ($mod_perl::VERSION >= 1.99) {
                return 2;
            } else {
                return 1;
            }
        } else {
            return undef;
        }
    }

    sub _isModPerl {
        if ($ENV{MOD_PERL} and defined $mod_perl::VERSION) {
            return 1;
        }
        return undef;
    }
    
    # added for v0.07
    sub _getMasonObject {
        my $self = shift;
        if (defined ${'HTML::Mason::Commands::m'}) {
            return $HTML::Mason::Commands::m; #; fix parsing bug in cperl
        }
        return undef;
    }

    # added for v0.07
    sub _getMasonArgs {
        my $self = shift;
        my $m = $self->_getMasonObject;
        if ($m) {
            return $m->request_args;
        }
        return undef;
    }

    # added for v0.07
    sub _getApacheRequestFromMason {
        my ($self) = @_;
        if (defined ${'HTML::Mason::Commands::r'}) {
            return $HTML::Mason::Commands::r; #; fix parsing bug in cperl
        }
        return undef;
    }
    
    # added for v0.07
    sub _isCgi {
        if ($ENV{GATEWAY_INTERFACE}
            # and $ENV{GATEWAY_INTERFACE} !~ /perl/i # don't count cgi env vars under mod_perl
           ) {
            return 1;
        }
        return undef;
    }

    # added for v0.07
    sub _fromCgiOrModPerl {
        my ($self, $apache_request_method, $cgi_env_var) = @_;
        if ($self->_isModPerl) {
            my $r = $self->_getApacheRequest;
            return $r->$apache_request_method() if $r;
        } elsif ($self->_isCgi) {
            return $ENV{$cgi_env_var};
        }
        return undef;
    }

    # added for v0.07
    sub _fromCgiOrModPerlConnection {
        my ($self, $apache_connection_method, $cgi_env_var) = @_;
        if ($self->_isModPerl) {
            my $r = $self->_getApacheRequest;
            if ($r) {
                my $c = $r->connection;
                return $c->$apache_connection_method();
            }
        } elsif ($self->_isCgi) {
            return $ENV{$cgi_env_var};
        }
        return undef;
    }

    # added for v0.07
    sub _getHttpHeader {
        my $self = shift;
        my $header = shift;
        if ($self->_isModPerl) {
            my $r = $self->_getApacheRequest;
            if ($r) {
                return $r->headers_in()->{$header};
            }
        } elsif ($self->_isCgi) {
            $header =~ s/-/_/g;
            return $ENV{'HTTP_' . uc($header)};
        }
        return undef;
    }

=pod

=head2 urlEncode($str)

Returns the fully URL-encoded version of the given string.  It
does not convert space characters to '+' characters.

Aliases: url_encode()

=cut
BEGIN {
    if ($] >= 5.006) {
        eval q{
    sub urlEncode {
        my ($self, $str) = @_;
                
        use bytes;
        $str =~ s{([^A-Za-z0-9_])}{sprintf("%%%02x", ord($1))}eg;
        return $str;
    }
    *url_encode = \&urlEncode;
};
    } else {
        eval q{
    sub urlEncode {
        my ($self, $str) = @_;

        $str =~ s{([^A-Za-z0-9_])}{sprintf("%%%02x", ord($1))}eg;
        return $str;
    }
    *url_encode = \&urlEncode;
};
    }
}

=pod

=head2 urlUnicodeEncode($str)

Returns the fully URL-encoded version of the given string as
unicode characters.  It does not convert space characters to '+'
characters.

Aliases: url_unicode_encode()

=cut
    sub urlUnicodeEncode {
        my ($self, $str) = @_;
        $str =~ s{([^A-Za-z0-9_])}{sprintf("%%u%04x", ord($1))}eg;
        return $str;
    }
    *url_unicode_encode = \&urlUnicodeEncode;

=pod

=head2 urlDecode($url_encoded_str)

Returns the decoded version of the given URL-encoded string.

Aliases: url_decode()

=cut
    sub urlDecode {
        my ($self, $str) = @_;
        $str =~ tr/+/ /;
        $str =~ s|%([A-Fa-f0-9]{2})|chr(hex($1))|eg;
        return $str;
    }
    *url_decode = \&urlDecode;

=pod

=head2 urlUnicodeDecode($url_encoded_str)

Returns the decoded version of the given URL-encoded string,
with unicode support.

Aliases: url_unicode_decode()

=cut
    sub urlUnicodeDecode {
        my ($self, $str) = @_;
        $str =~ tr/+/ /;
        $str =~ s|%([A-Fa-f0-9]{2})|chr(hex($1))|eg;
        $str =~ s|%u([A-Fa-f0-9]{2,4})|chr(hex($1))|eg;
        return $str;
    }
    *url_unicode_decode = \&urlUnicodeDecode;

=pod

=head2 urlEncodeVars($var_hash, $sep)

Takes a hash of name/value pairs and returns a fully URL-encoded
query string suitable for passing in a URL.  By default, uses
the newer separator, a semicolon, as recommended by the W3C.  If
you pass in a second argument, it is used as the separator
between key/value pairs.

Aliases: url_encode_vars()

=cut
    sub urlEncodeVars {
        my ($self, $var_hash, $sep) = @_;
        $sep = ';' unless defined $sep;
        my @pairs;
        foreach my $key (sort keys %$var_hash) {
            my $val = $$var_hash{$key};
            my $ref = ref($val);
            if ($ref eq 'ARRAY' or $ref =~ /=ARRAY/) {
                push @pairs, map { $self->urlEncode($key) . "=" . $self->urlEncode($_) } @$val;
            } else {
                push @pairs, $self->urlEncode($key) . "=" . $self->urlEncode($val);
            }
        }

        return join($sep, @pairs);
    }
    *url_encode_vars = \&urlEncodeVars;

=pod

=head2 urlDecodeVars($query_string)

Takes a URL-encoded query string, decodes it, and returns a
reference to a hash of name/value pairs.  For multivalued
fields, the value is an array of values.  If called in array
context, it returns a reference to a hash of name/value pairs,
and a reference to an array of field names in the order they
appear in the query string.

Aliases: url_decode_vars()

=cut
    sub urlDecodeVars {
        my ($self, $query) = @_;
        my $var_hash = {};
        my @pairs = split /[;&]/, $query;
        my $var_order = [];
        
        foreach my $pair (@pairs) {
            my ($name, $value) = map { $self->urlDecode($_) } split /=/, $pair, 2;
            if (exists($$var_hash{$name})) {
                my $this_val = $$var_hash{$name};
                if (ref($this_val) eq 'ARRAY') {
                    push @$this_val, $value;
                } else {
                    $$var_hash{$name} = [ $this_val, $value ];
                }
            } else {
                $$var_hash{$name} = $value;
                push @$var_order, $name;
            }
        }
        
        return wantarray ? ($var_hash, $var_order) : $var_hash;
    }
    *url_decode_vars = \&urlDecodeVars;

=pod

=head2 escapeHtml($text)

Escapes the given text so that it is not interpreted as HTML.  &,
<, >, and " characters are escaped.

Aliases: escape_html()

=cut
    # added for v0.05
    sub escapeHtml {
        my ($self, $text) = @_;
        return undef unless defined $text;
        
        $text =~ s/\&/\&amp;/g;
        $text =~ s/</\&lt;/g;
        $text =~ s/>/\&gt;/g;
        $text =~ s/\"/\&quot;/g;
        $text =~ s/\'/\&#39;/g;

        return $text;
    }
    *escape_html = \&escapeHtml;

=pod

=head2 escapeHtmlFormValue($text)

Escapes the given text so that it is valid to put in a form
field.

Aliases: escape_html_form_value()

=cut
    # added for v0.05
    sub escapeHtmlFormValue {
        my ($self, $str) = @_;
        $str =~ s/\"/&quot;/g;
        $str =~ s/>/&gt;/g;
        $str =~ s/</&lt;/g;
        
        return $str;
    }
    *escape_html_form_value = \&escapeHtmlFormValue;


=pod

=head2 getSelfRefHostUrl()

Returns a url referencing top level directory in the current
domain, e.g., http://mydomain.com

Aliases: get_self_ref_host_url()

=cut
    sub getSelfRefHostUrl {
        my ($self) = @_;
        my $https = $ENV{HTTPS};
        my $port = $self->_fromCgiOrModPerl('get_server_port', 'SERVER_PORT');
#         my $scheme = (defined($https) and lc($https) eq 'on') ? 'https' : 'http';
#         $scheme = 'https' if defined($port) and $port == 443;
        my $scheme = $self->getProtocol;
        my $host = $self->getHost;
        my $host_url = "$scheme://$host";

        if ($port != 80 and $port != 443) {
            $host_url .= ":$port" unless $host_url =~ /:\d+$/;
        }
        
        return $host_url;
    }
    *get_self_ref_host_url = \&getSelfRefHostUrl;
    *get_self_host_url = \&getSelfRefHostUrl;

=pod

=head2 getSelfRefUrl()

Returns a url referencing the current script (without any query
string).

Aliases: get_self_ref_url

=cut
    sub getSelfRefUrl {
        my ($self) = @_;
        return $self->getSelfRefHostUrl . $self->getSelfRefUri;
    }
    *get_self_ref_url = \&getSelfRefUrl;

=pod

=head2 getSelfRefUri()

Returns the current URI.

Aliases: get_self_ref_uri()

=cut
    sub getSelfRefUri {
        my ($self) = @_;
        my $uri;
        if ($self->_isModPerl) {
            my $r = $self->_getApacheRequest;
            $uri = $r->uri || $r->path_info;
        } elsif ($self->_isCgi) {
            $uri = $ENV{REQUEST_URI} || $ENV{PATH_INFO};
        }
        
        $uri =~ s/^(.*?)\?.*$/$1/;
        return $uri;
    }
    *get_self_ref_uri = \&getSelfRefUri;

=pod

=head2 getSelfRefUrlWithQuery()

Returns a url referencing the current script along with any
query string parameters passed via a GET method.

Aliases: get_self_ref_url_with_query()

=cut
    sub getSelfRefUrlWithQuery {
        my ($self) = @_;

        my $url = $self->getSelfRefUrl;
        my $query_str;
        if ($self->_isModPerl) {
            my $r = $self->_getApacheRequest;
            $query_str = $r ? $r->args : $ENV{QUERY_STRING};
        }
        else {
            $query_str = $ENV{QUERY_STRING};
        }
        if (defined($query_str) and $query_str ne '') {
            return $url . '?' . $query_str;
        }
        return $url;
    }
    *get_self_ref_url_with_query = \&getSelfRefUrlWithQuery;

=pod

=head2 getSelfRefUrlWithParams($params, $sep)

Returns a url reference the current script along with the given
hash of parameters added onto the end of url as a query string.

If the optional $sep parameter is passed, it is used as the
parameter separator instead of ';', unless the URL already
contains '&' chars, in which case it will use '&' for the
separator.

Aliases: get_self_ref_url_with_params()

=cut
    # added for 0.06
    sub getSelfRefUrlWithParams {
        my ($self, $args, $sep) = @_;

        return $self->addParamsToUrl($self->getSelfRefUrl, $args, $sep);
    }
    *get_self_ref_url_with_params = \&getSelfRefUrlWithParams;

=pod

=head2 getSelfRefUrlDir()

Returns a url referencing the directory part of the current url.

Aliases: get_self_ref_url_dir()

=cut
    sub getSelfRefUrlDir {
        my ($self) = @_;
        my $url = $self->getSelfRefUrl;
        $url =~ s{^(.+?)\?.*$}{$1};
        $url =~ s{/[^/]+$}{};
        return $url;
    }
    *get_self_ref_url_dir = \&getSelfRefUrlDir;

=pod

=head2 convertRelativeUrlWithParams($relative_url, $params, $sep)

Converts a relative URL to an absolute one based on the current
URL, then adds the parameters in the given hash $params as a
query string.

If the optional $sep parameter is passed, it is used as the
parameter separator instead of ';', unless the URL already
contains '&' chars, in which case it will use '&' for the
separator.

Aliases: convertRelativeUrlWithArgs(), convert_relative_url_with_params(),
convert_relative_url_with_args()

=cut
    # Takes $rel_url as a url relative to the current directory,
    # e.g., a script name, and adds the given cgi params to it.
    # added for v0.05
    sub convertRelativeUrlWithParams {
        my ($self, $rel_url, $args, $sep) = @_;
        my $host_url = $self->getSelfRefHostUrl;
        my $uri = $self->getSelfRefUri;
        $uri =~ s{^(.+?)\?.*$}{$1};
        $uri =~ s{/[^/]+$}{};

        if ($rel_url =~ m{^/}) {
            $uri = $rel_url;
        } else {
            while ($rel_url =~ m{^\.\./}) {
                $rel_url =~ s{^\.\./}{}; # pop dir off front
                $uri =~ s{/[^/]+$}{}; # pop dir off end
            }
            $uri .= '/' . $rel_url;
        }

        return $self->addParamsToUrl($host_url . $uri, $args, $sep);
    }
    *convertRelativeUrlWithArgs = \&convertRelativeUrlWithParams;
    *convert_relative_url_with_params = \&convertRelativeUrlWithParams;
    *convert_relative_url_with_args = \&convertRelativeUrlWithParams;

=pod

=head2 addParamsToUrl($url, $param_hash, $sep)

Takes a url and reference to a hash of parameters to be added
onto the url as a query string and returns a url with those
parameters.  It checks whether or not the url already contains a
query string and modifies it accordingly.  If you want to add a
multivalued parameter, pass it as a reference to an array
containing all the values.

If the optional $sep parameter is passed, it is used as the
parameter separator instead of ';', unless the URL already
contains '&' chars, in which case it will use '&' for the
separator.

Aliases: add_params_to_url()

=cut
    sub addParamsToUrl {
        my ($self, $url, $param_hash, $sep) = @_;
        return $url unless ref($param_hash) eq 'HASH' and %$param_hash;
        $sep = ';' unless defined($sep) and $sep ne '';
        if ($url =~ /^([^?]+)\?(.*)$/) {
            my $query = $2;
            # if query uses & for separator, then keep it consistent
            if ($query =~ /\&/) {
                $sep = '&';
            }
            $url .= $sep unless $url =~ /\?$/;
        } else {
            $url .= '?';
        }

        $url .= $self->urlEncodeVars($param_hash, $sep);
        return $url;
    }
    *add_params_to_url = \&addParamsToUrl;

    sub _getRawCookie {
        my $self = shift;

        if ($self->_isModPerl) {
            my $r = $self->_getApacheRequest;
            return $r ? $r->headers_in()->{Cookie} : ($ENV{HTTP_COOKIE} || $ENV{COOKIE} || '');
        }
        else {
            return $ENV{HTTP_COOKIE} || $ENV{COOKIE} || '';
        }
    }

=pod

=head2 getParsedCookies()

Parses the cookies passed to the server.  Returns a hash of
key/value pairs representing the cookie names and values.

Aliases: get_parsed_cookies

=cut
    sub getParsedCookies {
        my ($self) = @_;
        my %cookies = map { (map { $self->urlDecode($_) } split(/=/, $_, 2)) }
            split(/;\s*/, $self->_getRawCookie);
        return \%cookies;
    }
    *get_parsed_cookies = \&getParsedCookies;

    # added for v0.06
    # for compatibility with CGI.pm
    # may want to create an object here
    sub cookie {
        my ($self, @args) = @_;
        my $map_list = [ 'name', [ 'value', 'values' ], 'path', 'expires', 'domain', 'secure' ];
        my $params = $self->_parse_sub_params($map_list, \@args);
        if (exists($$params{value})) {
            return $params;
        } else {
            my $cookies = $self->getParsedCookies;
            if ($cookies and %$cookies) {
                return $$cookies{$$params{name}};
            }
            return '';
        }
        return $params;
    }

# =pod

# =head2 parse({ max_post_size => $max_bytes })

#  Parses the CGI parameters.  GET and POST (both url-encoded and
#  multipart/form-data encodings), including file uploads, are
#  supported.  If the request method is POST, you may pass a
#  maximum number of bytes to accept via POST.  This can be used to
#  limit the size of file uploads, for example.

# =cut
    sub parse {
        my ($self, $args) = @_;

        return 1 if $$self{_already_parsed};
        $$self{_already_parsed} = 1;

        $args = {} unless ref($args) eq 'HASH';

        if ($self->_isModPerl) {
            # If running under mod_perl, grab the GET or POST data
            my $rv = $self->_modPerlParse($args);
            return $rv if $rv;
        } elsif (not $ENV{'GATEWAY_INTERFACE'}) {
            # Not CGI, so must be commandline
            if (scalar(@ARGV)) {
                return $self->_cmdLineParse(\@ARGV);
            }
        }


        # check for mod_perl - GATEWAY_INTERFACE =~ m{^CGI-Perl/}
        # check for PerlEx - GATEWAY_INTERFACE =~ m{^CGI-PerlEx}

        return $self->_cgiParse($args);
    }

    sub _cmdLineParse {
        my $self = shift;
        my $args = shift;

        my %params;
        foreach my $arg (@$args) {
            if ($arg =~ /^([^=]+)=(.*)$/s) {
                my $key = $1;
                my $val = $2;
                $params{$key} = $val;
            }
            else {
                # bad param, drop them all
                return;
            }
        }

        $self->{_params} = \%params;
        
        return 1;
    }
    
    sub _cgiParse {
        my $self = shift;
        my $args = shift;
        
        my $method = lc($ENV{REQUEST_METHOD});
        my $content_length = $ENV{CONTENT_LENGTH} || 0;

        if ($method eq 'post') {
            my $max_size = $$args{max_post_size} || $$self{_max_post_size};
            $max_size = 0 unless defined($max_size);
            if ($max_size > 0 and $content_length > $max_size) {
                return undef;
            }
        }

        if ($method eq 'post' and $ENV{CONTENT_TYPE} =~ m|^multipart/form-data|) {
            if ($ENV{CONTENT_TYPE} =~ /boundary=(\"?)([^\";,]+)\1/) {
                my $boundary = $2;
                $self->_readMultipartData($boundary, $content_length, \*STDIN);
            } else {
                return undef;
            }
        } elsif ($method eq 'get' or $method eq 'head') {
            my $query_string = $ENV{QUERY_STRING};
            $self->_parseParams($query_string);
        } elsif ($method eq 'post') {
            my $query_string;
            $self->_readPostData(\*STDIN, \$query_string, $content_length) if $content_length > 0;
            $self->_parseParams($query_string);
            # FIXME: may want to append anything in query string
            # to POST data, so can do a post with an action that
            # contains a query string.
        }

        return 1;
    }

    sub _modPerlParse {
        my $self = shift;
        my $args = shift;

        my $r;
        if ($self->_getMasonObject) {
            $self->{_params} = $self->_getMasonArgs;
            my $method = $self->getRequestMethod;
            if (lc($method) eq 'post' and $self->getContentType =~ m|^multipart/form-data|) {
                $r = $self->_getApacheRequest;
                my @uploads = $r->upload; # $r is really an Apache::Request obj in this case
                if (@uploads) {
                    # make a copy so we don't mess around with Mason
                    %{$self->{_params}} = %{$self->{_params}};
                    foreach my $upload (@uploads) {
                        my $field_name = $upload->name;
                        my $fh = $upload->fh;
                        # seek($fh, 0, 0);
                        my $filename = $upload->filename;
                        my $cgi_style_fh =
                            CGI::Utils::UploadFile->new_from_handle($filename, $fh);
                        $self->{_params}->{$field_name} = $cgi_style_fh;
                        my $info = { 'Content-Type' => $upload->type };
                        $self->{_upload_info}->{$filename} = $info;
                    }
                }
            }
            return 1;
        } elsif ($r = $self->_getApacheRequest) {
            my $query_string = $r->args;
            $self->_parseParams($query_string);
            my $method = $self->getRequestMethod;
            if (lc($method) eq 'post') {
                unless (defined $CGI::Utils::Has_Apache_Request) {
                    local($SIG{__DIE__});
                    if (MP2) {
                        eval 'require Apache2::Request';
                        # my $apr = Apache2::RequestUtil->request($r)
                    } else {
                        eval 'require Apache::Request';
                    }
                    if ($@) {
                        $CGI::Utils::Has_Apache_Request = 0;
                    } else {
                        $CGI::Utils::Has_Apache_Request = 1;
                    }
                }

                if ($CGI::Utils::Has_Apache_Request) {
                    my $apr = Apache::Request->new($r);
                    my $cur_params = $self->{_params};
                    my @params = $apr->param;
                    foreach my $key (@params) {
                        my @vals = $apr->param($key);
                        if (scalar(@vals) > 1) {
                            $cur_params->{$key} = \@vals;
                        } else {
                            $cur_params->{$key} = $vals[0];
                        }
                    }

                    if ($self->getContentType =~ m|^multipart/form-data|) {
                        my @uploads = $apr->upload;
                        foreach my $upload (@uploads) {
                            my $field_name = $upload->name;
                            my $fh = $upload->fh;
                            my $filename = $upload->filename;
                            my $cgi_style_fh =
                                CGI::Utils::UploadFile->new_from_handle($filename, $fh);
                            $self->{_params}->{$field_name} = $cgi_style_fh;
                            my $info = { 'Content-Type' => $upload->type };
                            $self->{_upload_info}->{$filename} = $info;
                        }
                    }
                } elsif ($self->_isCgi) {
                    # Using the perl-script handler that provides
                    # a CGI environment under mod_perl.  So fall
                    # back to getting everything from the CGI
                    # environment.
                    return $self->_cgiParse($args);
                } else {
                    return undef;
                }
            }

            return 1;
        }

        return undef;
    }

=pod

=head2 param($name)

Returns the CGI parameter with name $name.  If called in array
context, it returns an array.  In scalar context, it returns an
array reference for multivalued fields, and a scalar for
single-valued fields.

=cut
    sub param {
        my ($self, $name) = @_;
        $self->parse;
        
        if (scalar(@_) == 1 and wantarray()) {
            my $params = $$self{_params};
            my $order = $$self{_param_order};
            return grep { exists($$params{$_})  } @$order;
        }
        return undef unless defined($name);
        my $val = $$self{_params}{$name};

        if (wantarray()) {
            return ref($val) eq 'ARRAY' ? @$val : ($val);
        } else {
            return $val;
        }
    }

=pod

=head2 getVars($delimiter)

Also Vars() to be compatible with CGI.pm.  Returns a reference
to a tied hash containing key/value pairs corresponding to each
CGI parameter.  For multivalued fields, the value is an array
ref, with each element being one of the values.  If you pass in
a value for the delimiter, multivalued fields will be returned
as a string of values delimited by the delimiter you passed in.

Aliases: vars(), Vars(), get_args(), args()

=cut
    sub getVars {
        my ($self, $multivalue_delimiter) = @_;
        if (defined($$self{_multivalue_delimiter}) and $$self{_multivalue_delimiter} ne '') {
            $multivalue_delimiter = $$self{_multivalue_delimiter}
                if not defined($multivalue_delimiter) or $multivalue_delimiter eq '';
        } elsif (defined($multivalue_delimiter) and $multivalue_delimiter ne '') {
            $$self{_multivalue_delimiter} = $multivalue_delimiter;
        }

        $self->parse;
        
        if (wantarray()) {
            my $params = $$self{_params};
            my %vars = %$params;
            foreach my $key (keys %vars) {
                if (ref($vars{$key}) eq 'ARRAY') {
                    if ($multivalue_delimiter ne '') {
                        $vars{$key} = join($multivalue_delimiter, @{$vars{$key}});
                    } else {
                        my @copy = @{$vars{$key}};
                        $vars{$key} = \@copy;
                    }
                }
            }
            return %vars;
        }
        
        my $vars = $$self{_vars_hash};
        return $vars if $vars;

        my %vars;
        tie %vars, 'CGI::Utils', $self;

        return \%vars;
    }
    *vars = \&getVars;
    *Vars = \&getVars;
    *get_vars = \&getVars;
    *get_args = \&getVars;
    *args = \&getVars;

=pod

# Other information provided by the CGI environment

=head2 getPathInfo(), path_info(), get_path_info();

Returns additional virtual path information from the URL (if
any) after your script.

=cut
    # added for 0.06
    sub getPathInfo {
        my ($self) = @_;
        return $$self{_path_info} if defined($$self{_path_info});
        
        my $r = $self->_getApacheRequest;

        my $path_info = $r ? $r->path_info : (defined($ENV{PATH_INFO}) ? $ENV{PATH_INFO} : '');
        $$self{_path_info} = $path_info;
        return $path_info;
    }
    *path_info = \&getPathInfo;
    *get_path_info = \&getPathInfo;

=pod

=head2 getRemoteAddr(), remote_addr(), get_remote_addr()

Returns the dotted decimal representation of the remote client's
IP address.

=cut
    # added for v0.07
    sub getRemoteAddr {
        my $self = shift;
        return $self->_fromCgiOrModPerlConnection('remote_ip', 'REMOTE_ADDR');
    }
    *remote_addr = \&getRemoteAddr;
    *get_remote_addr = \&getRemoteAddr;

=pod

=head2 getRemoteHost(), remote_host(), get_remote_host()

Returns the name of the remote host, or its IP address if the
name is unavailable.

=cut
    # added for v0.07
    sub getRemoteHost {
        my $self = shift;

        my $host = $self->_fromCgiOrModPerl('remote_host', 'REMOTE_HOST');
        unless (defined($host) and $host ne '') {
            $host = $self->_fromCgiOrModPerlConnection('remote_ip', 'REMOTE_ADDR');
        }

        return $host;
    }
    *remote_host = \&getRemoteHost;
    *get_remote_host = \&getRemoteHost;

=pod

=head2 getHost(), host(), virtual_host(), get_host()

Returns the name of the host in the URL being accessed.  This is
sent as the Host header by the web browser.

=cut
    # added for v0.07
    sub getHost {
        my $self = shift;
        return $self->_fromCgiOrModPerl('hostname', 'HTTP_HOST');
    }
    *host = \&getHost;
    *virtual_host = \&getHost;
    *get_host = \&getHost;

=pod

=head2 getReferer(), referer(), get_referer(), getReferrer(), referrer(), get_referrer()

Returns the referring URL.

=cut
    # added for v0.07
    sub getReferer {
        my $self = shift;

        return $self->_getHttpHeader('Referer');
    }
    *referer = \&getReferer;
    *get_referer = \&getReferer;
    *getReferrer = \&getReferer;
    *referrer = \&getReferer;
    *get_referrer = \&getReferer;

=pod

=head2 getProtocol(), protocol(), get_protocol()

Returns the protocol, i.e., http or https.

=cut
    # added for v0.07
    sub getProtocol {
        my $self = shift;
        my $https = $ENV{HTTPS};
        my $proto = (defined($https) and lc($https) eq 'on') ? 'https' : 'http';
        my $port = $self->_fromCgiOrModPerl('get_server_port', 'SERVER_PORT');
        $proto = 'https' if defined($port) and $port == 443;
        
        return $proto;
    }
    *protocol = \&getProtocol;
    *get_protocol = \&getProtocol;

=pod

=head2 getRequestMethod(), request_method(), get_request_method()

Returns the request method, i.e., GET, POST, HEAD, or PUT.

=cut
    # added for 0.06
    sub getRequestMethod {
        my $self = shift;
        return $self->_fromCgiOrModPerl('method', 'REQUEST_METHOD');
    }
    *request_method = \&getRequestMethod;
    *get_request_method = \&getRequestMethod;

=pod

=head2 getContentType(), content_type(), get_content_type()

 Returns the content type.

=cut
    # added for 0.06
    sub getContentType {
        my $self = shift;
        if ($self->_isModPerl) {
            return $self->_getHttpHeader('Content-Type');
        } else {
            return $ENV{CONTENT_TYPE};
        }
    }
    *content_type = \&getContentType;
    *get_content_type = \&getContentType;

=pod

=head2 getPathTranslated(), path_translated(), get_path_translated()

Returns the physical path information if provided in the CGI environment.

=cut
    # added for 0.06
    sub getPathTranslated {
        my $self = shift;
        return $self->_fromCgiOrModPerl('filename', 'PATH_TRANSLATED');
    }
    *path_translated = \&getPathTranslated;
    *get_path_translated = \&getPathTranslated;

=pod

=head2 getQueryString(), query_string(), get_query_string()

Returns a query string created from the current parameters.

=cut
    # create a query string from current CGI params
    # added for 0.06
    sub getQueryString {
        my ($self) = @_;
        my $fields = $self->getVars;
        return $self->urlEncodeVars($fields);
    }
    *query_string = \&getQueryString;
    *get_query_string = \&getQueryString;

=pod

=head2 getHeader(@args)

Generates HTTP headers.  Standard arguments are content_type,
cookie, target, expires, and charset.  These should be passed as
name/value pairs.  If only one argument is passed, it is assumed
to be the 'content_type' argument.  If no values are passed, the
content type is assumed to be 'text/html'.  The charset defaults
to ISO-8859-1.  A hash reference can also be passed.  E.g.,

 print $cgi_obj->getHeader({ content_type => 'text/html', expires => '+3d' });

The names 'content-type', and 'type' are aliases for
'content_type'.  The arguments may also be passed CGI.pm style
with a '-' in front, e.g.

 print $cgi_obj->getHeader( -content_type => 'text/html', -expires => '+3d' );

Cookies may be passed with the 'cookies' key either as a string,
a hash ref, or as a CGI::Cookies object, e.g.

 my $cookie = { name => 'my_cookie', value => 'cookie_val' };
 print $cgi_obj->getHeader(cookies => $cookie);

You may also pass an array of cookies, e.g.,

 print $cgi_obj->getHeader(cookies => [ $cookie1, $cookie2 ]);

Aliases: header(), get_header

=cut
    sub getHeader {
        my ($self, @args) = @_;
        my $arg_count = scalar(@args);
        if ($arg_count == 0) {
            return "Content-Type: text/html\r\n\r\n";
        }
        if ($arg_count == 1 and ref($args[0]) ne 'HASH') {
            # content-type provided
            return "Content-Type: $args[0]\r\n\r\n";
        }

        my $map_list = [ [ 'type', 'content-type', 'content_type' ],
                         'status',
                         [ 'cookie', 'cookies' ],
                         'target', 'expires', 'nph', 'charset', 'attachment',
                         'mod_perl',
                       ];
        my ($params, $extras) = $self->_parse_sub_params($map_list, \@args);
        
        my $charset = $$params{charset} || 'ISO-8859-1';
        my $content_type = $$params{type};
        $content_type ||= 'text/html' unless defined($content_type);
        $content_type .= "; charset=$charset"
            if $content_type =~ /^text/ and $content_type !~ /\bcharset\b/;

        # FIXME: handle NPH stuff

        my $headers = [];
        push @$headers, "Status: $$params{status}" if defined($$params{status});
        push @$headers, "Window-Target: $$params{target}" if defined($$params{target});
        
        my $cookies = $$params{cookie};
        if (defined($cookies) and $cookies) {
            my $cookie_array = ref($cookies) eq 'ARRAY' ? $cookies : [ $cookies ];
            foreach my $cookie (@$cookie_array) {
                # handle plain strings as well as CGI::Cookie objects and hashes
                my $str = '';
                if (UNIVERSAL::isa($cookie, 'CGI::Cookie')) {
                    $str = $cookie->as_string;
                } elsif (ref($cookie) eq 'HASH') {
                    $str = $self->_createCookieStrFromHash($cookie);
                } else {
                    $str = $cookie;
                }
                push @$headers, "Set-Cookie: $str" unless $str eq '';
            }
        }

        if (defined($$params{expires})) {
            my $expire = $self->_canonicalizeHttpDate($$params{expires});
            push @$headers, "Expires: $expire";
        }

        if (defined($$params{expires}) or (defined($cookies) and $cookies)) {
            push @$headers, "Date: " . $self->_canonicalizeHttpDate(0);
        }
        
        push @$headers, qq{Content-Disposition: attachment; filename="$$params{attachment}"}
            if defined($$params{attachment});
        push @$headers, "Content-Type: $content_type" if defined($content_type) and $content_type ne '';

        if ($params->{mod_perl}) {
            my $header_list = [];
            
            foreach my $field (sort keys %$extras) {
                my $val = $$extras{$field};
                $field =~ s/\b(.)/\U$1/g;
                $field = ucfirst($field);
                push @$header_list, [ $field, $val ];
            }

            return $header_list;
        }
        
        foreach my $field (sort keys %$extras) {
            my $val = $$extras{$field};
            $field =~ s/\b(.)/\U$1/g;
            $field = ucfirst($field);
            push @$headers, "$field: $val";
        }
        
        # FIXME: make line endings work on windoze
        return join("\r\n", @$headers) . "\r\n\r\n";
    }
    *header = \&getHeader;
    *get_header = \&getHeader;

=pod

=head2 sendHeader(@args)

Like getHeader() above, except sends it.  Under mod_perl, this
sends the header(s) via the Apache request object.  In a CGI
environment, this prints the header(s) to STDOUT.

Aliases: send_header()

=cut
    sub sendHeader {
        my ($self, @args) = @_;
        my $mod_perl = 0;
        my $r;
        if ($self->_isModPerl and $r = $self->_getApacheRequest) {
            $mod_perl = 1;
        }
        
        my $arg_count = scalar(@args);
        if ($arg_count == 0) {
            if ($mod_perl) {
                $r->err_header_out('Content-Type' => 'text/html');
            } else {
                print STDOUT "Content-Type: text/html\r\n\r\n";
            }
            return 1;
        }
        
        if ($arg_count == 1 and ref($args[0]) ne 'HASH') {
            # content-type provided
            if ($mod_perl) {
                $r->err_header_out('Content-Type' => $args[0]);
            } else {
                print STDOUT "Content-Type: $args[0]\r\n\r\n";
            }
            
            return 1;
        }

        unless ($mod_perl) {
            my $str = $self->getHeader(@args);
            print STDOUT $str;
            return 1;
        }

        return undef unless $r;

        my $headers = [];
        if (ref($args[0]) eq 'HASH') {
            my %args = %{$args[0]};
            $args{mod_perl} = 1;
            $headers = $self->getHeader(\%args);
        } else {
            push @args, 'mod_perl', 1;
            $headers = $self->getHeader(@args);
        }

        my $rv = $self->apache_ok;
        foreach my $header (@$headers) {
            if (lc($header->[0]) eq 'set-cookie') {
                $r->err_headers_out()->add(@$header);
            }
            else {
                if (lc($header->[0]) eq 'location') {
                    $rv = $self->apache_redirect;
                }
                $r->err_header_out(@$header);
            }
        }

        return $rv;
    }
    *send_header = \&sendHeader;

    sub load_apache_constants {
        unless (defined $CGI::Utils::Loaded_Apache_Constants) {
            local($SIG{__DIE__});
            eval q{
                use mod_perl;
                use constant MP2 => $mod_perl::VERSION >= 1.99;
                if (defined(MP2)) {
                    if (MP2) {
                        require Apache2;
                        require Apache::Const;
                    }
                    else {
                        require Apache::Constants;
                    }
                    $CGI::Utils::Loaded_Apache_Constants = 1;
                }
                };
        }
    }
    

=pod

=head2 getRedirect($url)

Returns the header required to do a redirect.  This method also
accepts named arguments, e.g.,

 print $cgi_obj->getRedirect(url => $url, status => 302,
                             cookie => \%cookie_params);

You may also pass a cookies argument as in getHeader().

Aliases: redirect()

=cut
    sub getRedirect {
        my ($self, @args) = @_;
        my $map_list = [ [ 'location', 'uri', 'url' ],
                         'status',
                         [ 'cookie', 'cookies' ],
                         'target',
                       ];
        my ($params, $extras) = $self->_parse_sub_params($map_list, \@args);
        $params->{status} = 302 unless $params->{status};
        return $self->header({ type => '', %$params, %$extras });
    }
    *redirect = \&getRedirect;

=pod

=head2 sendRedirect($url)

Like getRedirect(), but in a CGI environment the output is sent
to STDOUT, and in a mod_perl environment, the appropriate
headers are set.  The return value is 1 for a CGI environment
when successful, and Apache::Constants::REDIRECT in a mod_perl
environment, so you can do something like

 return $utils->sendRedirect($url)

n a mod_perl handler.

Aliases: send_redirect()

=cut
    sub send_redirect {
        my ($self, @args) = @_;
        my $map_list = [ [ 'location', 'uri', 'url' ],
                         'status',
                         [ 'cookie', 'cookies' ],
                         'target',
                       ];
        my ($params, $extras) = $self->_parse_sub_params($map_list, \@args);
        $params->{status} = 302 unless $params->{status};
        return $self->send_header({ type => '', %$params, %$extras });        
    }
    *sendRedirect = \&send_redirect;

=pod

=head2 getLocalRedirect(), local_redirect(), get_local_redirect()

Like getRedirect(), except that the redirect URL is converted
from relative to absolute, including the host.

=cut
    # Added for v0.07
    sub getLocalRedirect {
        my ($self, @args) = @_;
        my $map_list = [ [ 'location', 'uri', 'url' ],
                         'status',
                         [ 'cookie', 'cookies' ],
                         'target',
                       ];
        my ($params, $extras) = $self->_parse_sub_params($map_list, \@args);
        unless ($params->{location} =~ m{^https?://}) {
            $params->{location} = $self->convertRelativeUrlWithParams($params->{location}, {});
        }
        return $self->getRedirect(%$params);
    }
    *local_redirect = \&getLocalRedirect;
    *get_local_redirect = \&getLocalRedirect;

=pod

=head2 getCookieString(\%hash), get_cookie_string(\%hash);

Returns a string to pass as the value of a 'Set-Cookie' header.

=cut
    sub getCookieString {
        my ($self, $hash) = @_;
        return $self->_createCookieStrFromHash($hash);
    }
    *get_cookie_string = \&getCookieString;

=pod

=head2 getSetCookieString(\%params), getSetCookieString([ \%params1, \%params2 ])

Returns a string to pass as the 'Set-Cookie' header(s), including
the line ending(s).  Also accepts a simple hash with key/value pairs.

=cut
    sub getSetCookieString {
        my ($self, $cookies) = @_;
        if (ref($cookies) eq 'HASH') {
            my $array = [ map { { name => $_, value => $cookies->{$_} } } keys %$cookies ];
            $cookies = $array;
        }
        my $cookie_array = ref($cookies) eq 'ARRAY' ? $cookies : [ $cookies ];

        my $headers = [];
        foreach my $cookie (@$cookie_array) {
            # handle plain strings as well as CGI::Cookie objects and hashes
            my $str = '';
            if (UNIVERSAL::isa($cookie, 'CGI::Cookie')) {
                $str = $cookie->as_string;
            } elsif (ref($cookie) eq 'HASH') {
                $str = $self->_createCookieStrFromHash($cookie);    
            } else {
                $str = $cookie;
            }
            push @$headers, "Set-Cookie: $str" unless $str eq '';
        }

        # FIXME: make line endings work on windoze
        return join("\r\n", @$headers) . "\r\n";
    }
    *get_set_cookie_string = \&getSetCookieString;

=pod

=head2 setCookie(\%params), set_cookie(\%params);

Sets the cookie generated by getCookieString.  That is, in a
mod_perl environment, it adds an outgoing header to set the
cookie.  In a CGI environment, it prints the value of
getSetCookieString to STDOUT (including the end-of-line
sequence).

=cut
    sub setCookie {
        my $self = shift;
        my $params = shift;

        my $str = $self->_createCookieStrFromHash($params);
        my $r = $self->_getApacheRequest;

        if ($r) {
            $r->err_headers_out()->add('Set-Cookie' => $str);
        }
        else {
            print STDOUT "Set-Cookie: $str\r\n";
        }
    }
    *set_cookie = \&setCookie;
    
    sub _createCookieStrFromHash {
        my ($self, $hash) = @_;
        my $pairs = [];

        my $map_list = [ 'name', [ 'value', 'values', 'val' ],
                         'path', 'expires', 'domain', 'secure',
                       ];
        my $params = $self->_parse_sub_params($map_list, [ $hash ]);

        my $value = $$params{value};
        if (my $ref = ref($value)) {
            if ($ref eq 'ARRAY') {
                $value = join('&', map { $self->urlEncode($_) } @$value);
            } elsif ($ref eq 'HASH') {
                $value = join('&', map { $self->urlEncode($_) } %$value);
            }
        } else {
            $value = $self->urlEncode($value);
        }
        push @$pairs, qq{$$params{name}=$value};

        my $path = $$params{path} || '/';
        push @$pairs, qq{path=$path};
        
        push @$pairs, qq{domain=$$params{domain}} if $$params{domain};

        if ($$params{expires}) {
            my $expire = $self->_canonicalizeCookieDate($$params{expires});
            push @$pairs, qq{expires=$expire};
        }

        push @$pairs, qq{secure} if $$params{secure};

        return join('; ', @$pairs);
    }
    
    sub _canonicalizeCookieDate {
        my ($self, $expire) = @_;
        return $self->_canonicalizeDate('-', $expire);
    }
    
    sub _canonicalizeHttpDate {
        my ($self, $expire) = @_;
        return $self->_canonicalizeDate(' ', $expire);
        
        my $time = $self->_get_expire_time_from_offset($expire);
        return $time unless $time =~ /^\d+$/;

        my $wdays = [ qw(Sun Mon Tue Wed Thu Fri Sat) ];
        my $months = [ qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec) ];
        
        my $sep = ' ';

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);
        $year += 1900 unless $year > 1000;
        return sprintf "%s, %02d$sep%s$sep%04d %02d:%02d:%02d GMT",
            $$wdays[$wday], $mday, $$months[$mon], $year, $hour, $min, $sec;
    }

    sub _canonicalizeDate {
        my ($self, $sep, $expire) = @_;
        my $time = $self->_get_expire_time_from_offset($expire);
        return $time unless $time =~ /^\d+$/;

        my $wdays = [ qw(Sun Mon Tue Wed Thu Fri Sat) ];
        my $months = [ qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec) ];

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);
        $year += 1900 unless $year > 1000;
        return sprintf "%s, %02d$sep%s$sep%04d %02d:%02d:%02d GMT",
            $$wdays[$wday], $mday, $$months[$mon], $year, $hour, $min, $sec;

    }

    sub _get_expire_time_from_offset {
        my ($self, $offset) = @_;
        my $ret_offset = 0;
        if (not $offset or lc($offset) eq 'now') {
            $ret_offset = 0;
        } elsif ($offset =~ /^\d+$/) {
            return $offset;
        } elsif ($offset =~ /^([-+]?(?:\d+|\d*\.\d*))([mhdMy]?)/) {
            my $map = { 's' => 1,
                        'm' => 60,
                        'h' => 60 * 60,
                        'd' => 60 * 60 * 24,
                        'M' => 60 * 60 * 24 * 30,
                        'y' => 60 * 60 * 24 * 365,
                      };
            $ret_offset = ($$map{$2} || 1) * $1;
        } else {
            $ret_offset = $offset;
        }

        return time() + $ret_offset;
    }
    
    # canonicalize parameters so we can be compatible with CGI.pm
    sub _parse_sub_params {
        my ($self, $map_list, $args) = @_;

        my $arg_count = scalar(@$args);
        return {} if $arg_count == 0;

        my $hash;
        if ($arg_count == 1) {
            if (ref($$args[0]) eq 'HASH') {
                $hash = $$args[0];
            } else {
                my $rv;
                if (ref($$map_list[0]) eq 'ARRAY') {
                    $rv = { $$map_list[0][0] => $$args[0] };
                } else {
                    $rv = { $$map_list[0] => $$args[0] };
                }
                return wantarray ? ($rv, {}) : $rv;
            }
        } else {
            $hash = { @$args };
        }

        my $return_hash = {};
        my $found = {};
        foreach my $key (keys %$hash) {
            my $orig_key = $key;
            $key =~ s/^-{1,2}//;
            $key = lc($key);
            foreach my $e (@$map_list) {
                if (ref($e) eq 'ARRAY') {
                    my $canon_key = $$e[0];
                    foreach my $e2 (@$e) {
                        if ($e2 eq $key) {
                            $$return_hash{$canon_key} = $$hash{$orig_key};
                            $$found{$orig_key} = 1;
                        }
                    }
                } else {
                    if ($e eq $key) {
                        $$return_hash{$e} = $$hash{$orig_key};
                        $$found{$orig_key} = 1;
                    }
                }
            }
        }

        my $left_overs = {};
        while (my ($key, $value) = each %$hash) {
            $$left_overs{$key} = $value unless exists($$found{$key});
        }

        return wantarray ? ($return_hash, $left_overs) : $return_hash;
    }
    
    sub TIEHASH {
        my ($proto, $obj) = @_;
        return $obj;
    }

    sub STORE {
        my ($self, $key, $val) = @_;
        my $params = $$self{_params};
        # FIXME: memory leak here - need to compress the array if has empty slots
        # push(@{$$self{_param_order}}, $key) unless exists($$params{$key});
        $$params{$key} = $val;
    }

    sub FETCH {
        my ($self, $key) = @_;
        my $params = $$self{_params};
        my $val = $$params{$key};
        if (ref($val) eq 'ARRAY') {
            my $delimiter = $$self{_multivalue_delimiter};
            $val = join($delimiter, @$val) unless $delimiter eq '';
        }
        return $val;
    }

    sub FIRSTKEY {
        my ($self) = @_;
        my @keys = keys %{$$self{_params}};
        $$self{_keys} = \@keys;
        return shift @keys;
    }

    sub NEXTKEY {
        my ($self) = @_;
        return shift(@{$$self{_keys}});
    }

    sub EXISTS {
        my ($self, $key) = @_;
        my $params = $$self{_params};
        return exists($$params{$key});
    }

    sub DELETE {
        my ($self, $key) = @_;
        my $params = $$self{_params};
        delete $$params{$key};
    }

    sub CLEAR {
        my ($self) = @_;
        %{$$self{_params}} = ();
    }

    sub _parseParams {
        my ($self, $query_string) = @_;
        ($$self{_params}, $$self{_param_order}) = $self->urlDecodeVars($query_string);
    }

    sub _readPostData {
        my ($self, $fh, $buf, $len) = @_;
        return CORE::read($fh, $$buf, $len);
    }

    sub _readMultipartData {
        my ($self, $boundary, $content_length, $fh) = @_;
        my $line;
        my $eol = $self->_getEndOfLineSeq;
        my $end_char = substr($eol, -1, 1);
        my $buf;
        my $len = 1024;
        my $amt_read = 0;
        my $sep = "--$boundary$eol";

        my $params = {};
        my $param_order = [];

        while (my $size = $self->_read($fh, $buf, $len, 0, $end_char)) {
            $amt_read += $size;
            if ($buf eq $sep) {
                last;
            }
            last unless $amt_read < $content_length;
        }

        while ($amt_read < $content_length) {
            my ($headers, $amt) = $self->_readMultipartHeader($fh);
            $amt_read += $amt;
            my $disp = $$headers{'content-disposition'};
            my ($type, @fields) = split /;\s*/, $disp;
            my %disp_fields = map { s/^(\")(.+)\1$/$2/; $_ } map { split(/=/, $_, 2) } @fields;
            my $name = $disp_fields{name};
            my ($body, $body_size) = $self->_readMultipartBody($boundary, $fh, $headers, \%disp_fields);
            $amt_read += $body_size;

            next if $name eq '';

            if (exists($$params{$name})) {
                my $val = $$params{$name};
                if (ref($val) eq 'ARRAY') {
                    push @$val, $body;
                } else {
                    my $array = [ $val, $body ];
                    $$params{$name} = $array;
                }
            } else {
                $$params{$name} = $body;
                push @$param_order, $name;
            }

        }

        $$self{_params} = $params;
        $$self{_param_order} = $param_order;

        return 1;
    }

    sub _readMultipartBody {
        my ($self, $boundary, $fh, $headers, $disposition_fields) = @_;

        local($^W) = 0; # turn off lame warnings
        
        if ($$disposition_fields{filename} ne '') {
            return $self->_readMultipartBodyToFile($boundary, $fh, $headers, $disposition_fields);
        }
        
        my $amt_read = 0;
        my $eol = $self->_getEndOfLineSeq;
        my $end_char = substr($eol, -1, 1);
        my $buf;
        my $body;

        while (my $size = $self->_read($fh, $buf, 4096, 0, $end_char)) {
            $amt_read += $size;
            if (substr($buf, -1, 1) eq $end_char and $buf =~ /^--$boundary(?:--)?$eol$/
                and $body =~ /$eol$/
               ) {
                $body =~ s/$eol$//;
                last;
            }
            $body .= $buf;
        }

        return wantarray ? ($body, $amt_read) : $body;
    }

    sub _readMultipartBodyToFile {
        my ($self, $boundary, $fh, $headers, $disposition_fields) = @_;

        my $amt_read = 0;
        my $body;
        my $eol = $self->_getEndOfLineSeq;
        my $end_char = substr($eol, -1, 1);
        my $buf = '';
        my $buf2 = '';

        my $file_name = $$disposition_fields{filename};
        my $info = { 'Content-Type' => $$headers{'content-type'} };
        $$self{_upload_info}{$file_name} = $info;

        my $out_fh = CGI::Utils::UploadFile->new_tmpfile($file_name);
        
        while (my $size = $self->_read($fh, $buf, 4096, 0, $end_char)) {
            $amt_read += $size;
            if (substr($buf, -1, 1) eq $end_char and $buf =~ /^--$boundary(?:--)?$eol$/
                and $buf2 =~ /$eol$/
               ) {
                $buf2 =~ s/$eol$//;
                $buf = '';
                print $out_fh $buf2;
                last;
            }
            print $out_fh $buf2;
            $buf2 = $buf;
            $buf = '';
        }
        if ($buf ne '') {
            print $out_fh $buf;
        }
        select((select($out_fh), $| = 1)[0]);
        seek($out_fh, 0, 0); # seek back to beginning of file
        
        return wantarray ? ($out_fh, $amt_read) : $out_fh;
    }

=pod

=head2 uploadInfo($file_name)

Returns a reference to a hash containing the header information
sent along with a file upload.

=cut
    # provided for compatibility with CGI.pm
    sub uploadInfo {
        my ($self, $file_name) = @_;
        $self->parse;
        return $$self{_upload_info}{$file_name};
    }

    sub _readMultipartHeader {
        my ($self, $fh) = @_;
        my $amt_read = 0;
        my $eol = $self->_getEndOfLineSeq;
        my $end_char = substr($eol, -1, 1);
        my $buf;
        my $header_str;
        while (my $size = $self->_read($fh, $buf, 4096, 0, $end_char)) {
            $amt_read += $size;
            last if $buf eq $eol;
            $header_str .= $buf;
        }

        my $headers = {};
        my $last_header;
        foreach my $line (split($eol, $header_str)) {
            if ($line =~ /^(\S+):\s*(.+)$/) {
                $last_header = lc($1);
                $$headers{$last_header} = $2;
            } elsif ($line =~ /^\s+/) {
                $$headers{$last_header} .= $eol . $line;
            }
        }

        return wantarray ? ($headers, $amt_read) : $headers;
    }

    sub _getEndOfLineSeq {
        return "\x0d\x0a"; # "\015\012" in octal
    }

    sub _read {
        my ($self, $fh, $buf, $len, $offset, $end_char) = @_;
        return '' if $len == 0;
        my $cur_len = 0;
        my $buffer;
        my $buf_ref = \$buffer;
        my $char;
        while (defined($char = CORE::getc($fh))) {
            $$buf_ref .= $char;
            $cur_len++;
            if ($char eq $end_char or $cur_len == $len) {
                if ($offset > 0) {
                    substr($_[2], $offset, $cur_len) = $$buf_ref;
                } else {
                    $_[2] = $$buf_ref;
                }
                return $cur_len;
            }
        }
        return 0;
    }

=pod

=head1 Apache constants under mod_perl

Shortcut methods are provided for returning Apache constants
under mod_perl.  The methods figure out if they are running under
mod_perl 1 or 2 and make the appropriate call to get the right
constant back, e.g., Apache::Constants::OK() versus Apache::OK().
The methods are created on the fly using AUTOLOAD.  The method
names are in the format apache_$name where $name is the
lowercased constant name, e.g., $utils->apache_ok,
$utils->apache_forbidden.  See
L<http://perl.apache.org/docs/1.0/api/Apache/Constants.html> for
a list of constants available.

=cut
    
    sub AUTOLOAD {
        my $self = shift;
        (my $method = $AUTOLOAD) =~ s{\A.*\:\:([^:]+)\Z}{$1};

        if ($method eq 'DESTROY') {
            return;
        }

        if ($method =~ /\Aapache_(.+)/) {
            my $const = uc($1);
            eval "sub $method "
                . "{ return MP2 ? Apache\:\:$const() : Apache\:\:Constants\:\:$const(); }";
            unless ($@) {
                return $self->$method;
            }

            return;
        }

        die "no such method $method in package " . __PACKAGE__;
    }
}

1;

=pod

=head1 EXPORTS

You can export methods into your namespace in the usual way.
All of the util methods are available for export, e.g.,
getSelfRefUrl(), addParamsToUrl(), etc.  Beware, however, that
these methods expect to be called as methods.  You can also use
the tag :all_utils to import all of the util methods into your
namespace.  This allows for incorporating these methods into
your class without having to inherit from CGI::Utils.

=head1 ACKNOWLEDGEMENTS

Other people who have contributed ideas and/or code for this module:

    Kevin Wilson

=head1 AUTHOR

Don Owens <don@regexguy.com>

=head1 COPYRIGHT

Copyright (c) 2003-2008 Don Owens

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl
itself.

=head1 VERSION

0.12

=cut
