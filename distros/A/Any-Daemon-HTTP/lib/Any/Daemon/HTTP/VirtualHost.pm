# Copyrights 2013-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Any-Daemon-HTTP. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Any::Daemon::HTTP::VirtualHost;
use vars '$VERSION';
$VERSION = '0.29';


use warnings;
use strict;

use Log::Report    'any-daemon-http';

use Any::Daemon::HTTP::Directory;
use Any::Daemon::HTTP::UserDirs;
use Any::Daemon::HTTP::Proxy;

use HTTP::Status qw/:constants/;
use List::Util   qw/first/;
use File::Spec   ();
use POSIX::1003  qw(strftime);
use Scalar::Util qw(blessed);
use Digest::MD5  qw(md5_base64);


sub new(@)
{   my $class = shift;
    my $args  = @_==1 ? shift : {@_};
    (bless {}, $class)->init($args);
}

sub init($)
{   my ($self, $args) = @_;

    my $name = $self->{ADHV_name} = $args->{name};
    defined $name
        or error __x"virtual host {pkg} has no name", pkg => ref $self;

    my $aliases = $args->{aliases} || 'AUTO';
    $self->{ADHV_aliases}
      = ref $aliases eq 'ARRAY' ? $aliases
      : $aliases eq 'AUTO'      ? [ $self->generateAliases($name) ]
      : defined $aliases        ? [ $aliases ]
	  : [];

    $self->addHandler($args->{handlers} || $args->{handler});

    $self->{ADHV_rewrite}  = $self->_rewrite_call($args->{rewrite});
    $self->{ADHV_redirect} = $self->_redirect_call($args->{redirect});
    $self->{ADHV_udirs}    = $self->_user_dirs($args->{user_dirs});

    $self->{ADHV_sources}     = {};
    $self->_auto_docs($args->{documents});
    my $dirs = $args->{directories} || $args->{directory} || [];
    $self->addDirectory($_) for ref $dirs eq 'ARRAY' ? @$dirs : $dirs;

    $self->{ADHV_proxies}  = {};
    my $proxies = $args->{proxies}  || $args->{proxy} || [];
    $self->addProxy($_) for ref $proxies eq 'ARRAY' ? @$proxies : $proxies;

    $self;
}

sub _user_dirs($)
{   my ($self, $dirs) = @_;
    $dirs or return undef;

    return Any::Daemon::HTTP::UserDirs->new($dirs)
        if ref $dirs eq 'HASH';

    return $dirs
        if $dirs->isa('Any::Daemon::HTTP::UserDirs');

    error __x"vhost {name} user_dirs is not an ::UserDirs object"
      , name => $self->name;
}

sub _auto_docs($)
{   my ($self, $docroot) = @_;
    $docroot or return;

    File::Spec->file_name_is_absolute($docroot)
        or error __x"vhost {name} documents directory must be absolute"
             , name => $self->name;

    -d $docroot
        or error __x"vhost {name} documents `{dir}' must point to dir"
             , name => $self->name, dir => $docroot;

    $docroot =~ s/\\$//; # strip trailing / if present
    $self->addDirectory(path => '/', location => $docroot);
}

#---------------------

sub name()    {shift->{ADHV_name}}
sub aliases() {@{shift->{ADHV_aliases}}}


sub generateAliases($)
{   my ($thing, $h) = @_;
    my @a;
    $h    =~ m/^(([^.:]+)(?:[^:]*)?)(?:\:([0-9]+))?$/;
    push @a, $1      if $3;              # name with port
    push @a, $2      if $1 ne $2;        # hostname vs fqdn
    push @a, "$2:$3" if $1 ne $2 && $3;  # hostname with port
    @a;
}

#---------------------

sub addHandler(@)
{   my $self = shift;
	return if @_==1 && !defined $_[0];

    my @pairs
       = @_ > 1              ? @_
       : ref $_[0] eq 'HASH' ? %{$_[0]}
       :                       ( '/' => $_[0]);
    
    my $h = $self->{ADHV_handlers} ||= {};
    while(@pairs)
    {   my $k    = shift @pairs;
        substr($k, 0, 1) eq '/'
            or error __x"handler path must be absolute, for {rel} in {vhost}"
                 , rel => $k, vhost => $self->name;

        my $v    = shift @pairs;
        unless(ref $v)
        {   my $method = $v;
            $self->can($method)
                or error __x"handler method {name} not provided by {vhost}"
                    , name => $method, vhost => ref $self;
            $v = sub { shift->$method(@_) };
        }

        $h->{$k} = $v;
    }
    $h;
}


*addHandlers = \&addHandler;


sub findHandler(@)
{   my $self = shift;
    my @path = @_>1 ? @_ : ref $_[0] ? $_[0]->path_segments : split('/', $_[0]);

    my $h = $self->{ADHV_handlers} ||= {};
    while(@path)
    {   my $handler = $h->{join '/', @path};
        return $handler if $handler;
        pop @path;
    }

    if(my $handler = $h->{'/'})
    {   return $handler;
    }

    sub { HTTP::Response->new(HTTP_NOT_FOUND) };
}


sub handleRequest($$$;$)
{   my ($self, $server, $session, $req, $uri) = @_;
    $uri      ||= $req->uri;
    info __x"{host} request {uri}", host => $self->name, uri => $uri->as_string;

    my $new_uri = $self->rewrite($uri);
    if($new_uri ne $uri)
    {   info __x"{vhost} rewrote {uri} into {new}", vhost => $self->name
          , uri => $uri->as_string, new => $new_uri->as_string;
        $uri = $new_uri;
    }

    if(my $redir = $self->mustRedirect($new_uri))
    {   return $redir;
    }

    my $path   = $uri->path;

    my @path   = $uri->path_segments;
    my $source = $self->sourceFor(@path);

    # static content?
    my $resp   = $source ? $source->collect($self, $session, $req,$uri) : undef;
    return $resp if $resp;

    # dynamic content
    $resp = $self->findHandler(@path)->($self, $session, $req, $uri, $source);
    $resp or return HTTP::Response->new(HTTP_NO_CONTENT);

    blessed $resp && $resp->isa('HTTP::Response')
        or error __x"Handler for {uri} does not return an HTTP::Response",
            uri => $uri->as_string;

    $resp->code eq HTTP_OK
        or return $resp;

    # cache dynamic content based on md5 checksum
    my $etag     = md5_base64 ${$resp->content_ref};
    my $has_etag = $req->headers->header('ETag');
    return HTTP::Response->new(HTTP_NOT_MODIFIED, 'cached dynamic data')
        if $has_etag && $has_etag eq $etag;

    $resp->headers->header(ETag => $etag);
    $resp;
}

#----------------------

sub rewrite($) { $_[0]->{ADHV_rewrite}->(@_) }

sub _rewrite_call($)
{   my ($self, $rew) = @_;
    $rew or return sub { $_[1] };
    return $rew if ref $rew eq 'CODE';

    if(ref $rew eq 'HASH')
    {   my %lookup = %$rew;
        return sub {
            my $uri = $_[1]            or return undef;
            exists $lookup{$uri->path} or return $uri;
            URI->new_abs($lookup{$uri->path}, $uri)
        };
    }

    if(!ref $rew)
    {   return sub {shift->$rew(@_)}
            if $self->can($rew);

        error __x"rewrite rule method {name} in {vhost} does not exist"
          , name => $rew, vhost => $self->name;
    }

    error __x"unknown rewrite rule type {ref} in {vhost}"
      , ref => (ref $rew || $rew), vhost => $self->name;
}


sub redirect($;$)
{   my ($self, $uri, $code) = @_;
    HTTP::Response->new($code//HTTP_TEMPORARY_REDIRECT, undef
      , [ Location => "$uri" ]
    );
}


sub mustRedirect($)
{   my ($self, $uri) = @_;
    my $new_uri = $self->{ADHV_redirect}->($self, $uri);
    $new_uri && $new_uri ne $uri or return;

    info __x"{vhost} redirecting {uri} to {new}"
      , vhost => $self->name, uri => $uri->path, new => "$new_uri";

    $self->redirect($new_uri);
}

sub _redirect_call($)
{   my ($self, $red) = @_;
    $red or return sub { $_[1] };
    return $red if ref $red eq 'CODE';

    if(ref $red eq 'HASH')
    {   my %lookup = %$red;
        return sub {
            my $uri = $_[1]            or return undef;
            exists $lookup{$uri->path} or return undef;
            URI->new_abs($lookup{$uri->path}, $uri);
        };
    }

    if(!ref $red)
    {   return sub {shift->$red(@_)}
            if $self->can($red);

        error __x"redirect rule method {name} in {vhost} does not exist"
          , name => $red, vhost => $self->name;
    }

    error __x"unknown redirect rule type {ref} in {vhost}"
      , ref => (ref $red || $red), vhost => $self->name;
}


sub addSource($)
{   my ($self, $source) = @_;
    $source or return;

    my $sources = $self->{ADHV_sources};
    my $path    = $source->path;

    if(my $old = exists $sources->{$path})
    {   error __x"vhost {name} directory `{path}' defined twice, for `{old}' and `{new}' "
           , name => $self->name, path => $path
           , old => $old->name, new => $source->name;
    }

    info __x"add configuration `{name}' to {vhost} for {path}"
      , name => $source->name, vhost => $self->name, path => $path;

    $sources->{$path} = $source;
}

#------------------

sub filename($)
{   my ($self, $uri) = @_;
    my $dir = $self->sourceFor($uri);
    $dir ? $dir->filename($uri->path) : undef;
}


sub addDirectory(@)
{   my $self = shift;
    my $dir  = @_==1 && blessed $_[0] ? shift
       : Any::Daemon::HTTP::Directory->new(@_);

    $self->addSource($dir);
}


sub sourceFor(@)
{   my $self  = shift;
    my @path  = @_>1 || index($_[0], '/')==-1 ? @_ : split('/', $_[0]);

    return $self->{ADHV_udirs}
        if substr($path[0], 0, 1) eq '~';

    my $sources = $self->{ADHV_sources};
    while(@path)
    {   my $dir = $sources->{join '/', @path};
        return $dir if $dir;
        pop @path;
    }

    # return empty list, not undef, when not found
    $sources->{'/'} ? $sources->{'/'} : ();
}

#-----------------------------

sub addProxy(@)
{   my $self  = shift;
    my $proxy = @_==1 && blessed $_[0] ? shift
       : Any::Daemon::HTTP::Proxy->new(@_);

    error __x"proxy {name} has a map, so cannot be added to a vhost"
      , name => $proxy->name
        if $proxy->forwardMap;

    info __x"add proxy configuration to {vhost} for {path}"
      , vhost => $self->name, path => $proxy->path;

    $self->addSource($proxy);
}

#-----------------------------


1;
