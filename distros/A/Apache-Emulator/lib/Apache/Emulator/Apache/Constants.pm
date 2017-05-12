package Apache::Emulator::Apache::Constants;
package Apache::Constants;
use strict;
use vars qw (%EXPORT_TAGS @EXPORT_OK $EXPORT @ISA);
require Exporter;
@ISA = qw(Exporter);

my @common = qw(OK
		DECLINED
		DONE
		NOT_FOUND
		FORBIDDEN
		AUTH_REQUIRED
		SERVER_ERROR);

sub OK            {   0 }
sub DECLINED      {  -1 }
sub DONE          {  -2 }
sub NOT_FOUND     { 404 }
sub FORBIDDEN     { 403 }
sub AUTH_REQUIRED { 401 }
sub SERVER_ERROR  { 500 }

my(@methods) = qw(M_CONNECT
		  M_DELETE
		  M_GET
		  M_INVALID
		  M_OPTIONS
		  M_POST
		  M_PUT
		  M_TRACE
		  M_PATCH
		  M_PROPFIND
		  M_PROPPATCH
		  M_MKCOL
		  M_COPY
		  M_MOVE
		  M_LOCK
		  M_UNLOCK
		  METHODS);

my(@options)    = qw(OPT_NONE OPT_INDEXES OPT_INCLUDES 
		     OPT_SYM_LINKS OPT_EXECCGI OPT_UNSET OPT_INCNOEXEC
		     OPT_SYM_OWNER OPT_MULTI OPT_ALL);

my(@server)     = qw(MODULE_MAGIC_NUMBER
		     SERVER_VERSION SERVER_BUILT);

my(@response)   = qw(DOCUMENT_FOLLOWS
		     MOVED
		     REDIRECT
		     USE_LOCAL_COPY
		     BAD_REQUEST
		     BAD_GATEWAY 
		     RESPONSE_CODES
		     NOT_IMPLEMENTED
		     NOT_AUTHORITATIVE
		     CONTINUE);

#define DOCUMENT_FOLLOWS    HTTP_OK
#define PARTIAL_CONTENT     HTTP_PARTIAL_CONTENT
#define MULTIPLE_CHOICES    HTTP_MULTIPLE_CHOICES
#define MOVED               HTTP_MOVED_PERMANENTLY
#define REDIRECT            HTTP_MOVED_TEMPORARILY
#define USE_LOCAL_COPY      HTTP_NOT_MODIFIED
#define BAD_REQUEST         HTTP_BAD_REQUEST
#define AUTH_REQUIRED       HTTP_UNAUTHORIZED
#define FORBIDDEN           HTTP_FORBIDDEN
#define NOT_FOUND           HTTP_NOT_FOUND
#define METHOD_NOT_ALLOWED  HTTP_METHOD_NOT_ALLOWED
#define NOT_ACCEPTABLE      HTTP_NOT_ACCEPTABLE
#define LENGTH_REQUIRED     HTTP_LENGTH_REQUIRED
#define PRECONDITION_FAILED HTTP_PRECONDITION_FAILED
#define SERVER_ERROR        HTTP_INTERNAL_SERVER_ERROR
#define NOT_IMPLEMENTED     HTTP_NOT_IMPLEMENTED
#define BAD_GATEWAY         HTTP_BAD_GATEWAY
#define VARIANT_ALSO_VARIES HTTP_VARIANT_ALSO_VARIES

my(@satisfy)    = qw(SATISFY_ALL SATISFY_ANY SATISFY_NOSPEC);

my(@remotehost) = qw(REMOTE_HOST
		     REMOTE_NAME
		     REMOTE_NOLOOKUP
		     REMOTE_DOUBLE_REV);

use constant REMOTE_HOST       => 0;
use constant REMOTE_NAME       => 1;
use constant REMOTE_NOLOOKUP   => 2;
use constant REMOTE_DOUBLE_REV => 3;

my(@http)       = qw(HTTP_OK
		     HTTP_MOVED_TEMPORARILY
		     HTTP_MOVED_PERMANENTLY
		     HTTP_METHOD_NOT_ALLOWED 
		     HTTP_NOT_MODIFIED
		     HTTP_UNAUTHORIZED
		     HTTP_FORBIDDEN
		     HTTP_NOT_FOUND
		     HTTP_BAD_REQUEST
		     HTTP_INTERNAL_SERVER_ERROR
		     HTTP_NOT_ACCEPTABLE 
		     HTTP_NO_CONTENT
		     HTTP_PRECONDITION_FAILED
		     HTTP_SERVICE_UNAVAILABLE
		     HTTP_VARIANT_ALSO_VARIES);

use constant HTTP_OK                    => 200;
use constant HTTP_MOVED_TEMPORARILY     => 302;
use constant HTTP_MOVED_PERMANENTLY     => 301;
use constant HTTP_METHOD_NOT_ALLOWED    => 405;
use constant HTTP_NOT_MODIFIED          => 304;
use constant HTTP_UNAUTHORIZED          => 401;
use constant HTTP_FORBIDDEN             => 403;
use constant HTTP_NOT_FOUND             => 404;
use constant HTTP_BAD_REQUEST           => 400;
use constant HTTP_INTERNAL_SERVER_ERROR => 500;
use constant HTTP_NOT_ACCEPTABLE        => 406;
use constant HTTP_NO_CONTENT            => 204;
use constant HTTP_PRECONDITION_FAILED   => 412;
use constant HTTP_SERVICE_UNAVAILABLE   => 503;
use constant HTTP_VARIANT_ALSO_VARIES   => 506;

my(@config)     = qw(DECLINE_CMD);
my(@types)      = qw(DIR_MAGIC_TYPE);
my(@override)    = qw(
		      OR_NONE
		      OR_LIMIT
		      OR_OPTIONS
		      OR_FILEINFO
		      OR_AUTHCFG
		      OR_INDEXES
		      OR_UNSET
		      OR_ALL
		      ACCESS_CONF
		      RSRC_CONF);
my(@args_how)    = qw(
		      RAW_ARGS
		      TAKE1
		      TAKE2
		      ITERATE
		      ITERATE2
		      FLAG
		      NO_ARGS
		      TAKE12
		      TAKE3
		      TAKE23
		      TAKE123);

my $rc = [@common, @response];

%EXPORT_TAGS = (
		common     => \@common,
		config     => \@config,
		response   => $rc,
		http       => \@http,
		options    => \@options,
		methods    => \@methods,
		remotehost => \@remotehost,
		satisfy    => \@satisfy,
		server     => \@server,				   
		types      => \@types, 
		args_how   => \@args_how,
		override   => \@override,
		#deprecated
		response_codes => $rc,
		);

@EXPORT_OK = (
	      @response,
	      @http,
	      @options,
	      @methods,
	      @remotehost,
	      @satisfy,
	      @server,
	      @config,
	      @types,
	      @args_how,
	      @override,
	      ); 

*EXPORT = \@common;

1;


