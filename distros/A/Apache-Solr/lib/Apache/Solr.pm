# Copyrights 2012-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Apache-Solr.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Apache::Solr;{
our $VERSION = '1.11';
}


use warnings;
use strict;

use Apache::Solr::Tables;
use Log::Report    qw(solr);

use Scalar::Util   qw/blessed/;
use Encode         qw/encode/;
use Scalar::Util   qw/weaken/;

use URI            ();
use LWP::UserAgent ();
use MIME::Types    ();

use constant {
	LATEST_SOLR_VERSION => '9.8',  # newest support by this module
	ENETDOWN    => 100,   # error codes may not be available on all platforms
	ENETUNREACH => 101,   #    so cannot use Errno.
};

# overrule this when your host has a different unique field
our $uniqueKey  = 'id';
my  $mimetypes  = MIME::Types->new;
my  $http_agent;

sub _to_bool($)
{	my $b = shift;
	   !defined $b ? undef
	 : ($b && $b ne 'false' && $b ne 'off') ? 'true' 
	 : 'false';
}


sub new(@)
{	my ($class, %args) = @_;
	if($class eq __PACKAGE__)
	{	my $format = delete $args{format} || 'XML';
		$format eq 'XML' || $format eq 'JSON'
			or panic "unknown communication format '$format' for solr";
		$class .= '::' . $format;
		eval "require $class"; panic $@ if $@;
	}
	(bless {}, $class)->init(\%args)
}

sub init($)
{	my ($self, $args) = @_;
	$self->server($args->{server});
	$self->{AS_core}     = $args->{core};
	$self->{AS_commit}   = exists $args->{autocommit} ? $args->{autocommit} : 1;
	$self->{AS_sversion} = $args->{server_version} || LATEST_SOLR_VERSION;
	$self->{AS_retry_wait} = $args->{retry_wait} // 5;  # seconds
	$self->{AS_retry_max}  = $args->{retry_max}  // 60;

	$http_agent = $self->{AS_agent} =
		$args->{agent} || $http_agent || LWP::UserAgent->new(keep_alive=>1);

	weaken $http_agent;
	$self;
}

#---------------

sub core(;$) { my $s = shift; @_ ? $s->{AS_core}   = shift : $s->{AS_core} }
sub autocommit(;$) { my $s = shift; @_ ? $s->{AS_commit} = shift : $s->{AS_commit} }
sub agent() {shift->{AS_agent}}
sub serverVersion() {shift->{AS_sversion}}


sub server(;$)
{	my ($self, $uri) = @_;
	$uri or return $self->{AS_server};
	$uri = URI->new($uri)
		unless blessed $uri && $uri->isa('URI');
	$self->{AS_server} = $uri;
}


#--------------------------

sub select(@)
{	my $self = shift;
	my $args = @_ && ref $_[0] eq 'HASH' ? shift : {};
	$self->_select($args, scalar $self->expandSelect(@_));
}
sub _select($$) {panic "not extended"}


sub queryTerms(@)
{	my $self  = shift;
	$self->_terms(scalar $self->expandTerms(@_));
}
sub _terms(@) {panic "not implemented"}

#-------------------------------------

sub addDocument($%)
{	my ($self, $docs, %args) = @_;
	$docs  = [ $docs ] if ref $docs ne 'ARRAY';

	my $sv = $self->serverVersion;

	my (%attrs, %params);
	$params{commit} = _to_bool(exists $args{commit} ? $args{commit} : $self->autocommit);

	if(my $cw = $args{commitWithin})
	{	if($sv lt '3.4') { $attrs{commit} = 'true' }
		else { $attrs{commitWithin} = int($cw * 1000) }
	}

	$attrs{overwrite} = _to_bool delete $args{overwrite}
		if exists $args{overwrite};

	foreach my $depr (qw/allowDups overwritePending overwriteCommitted/)
	{	if(exists $args{$depr})
		{	  if($sv ge '4.0') { $self->removed("add($depr)"); delete $args{$depr} }
			elsif($sv ge '1.0') { $self->deprecated("add($depr)") }
			else { $attrs{$depr} = _to_bool delete $args{$depr} }
		}
	}

	$self->_add($docs, \%attrs, \%params);
}


sub commit(%)
{	my ($self, %args) = @_;
	my $sv = $self->serverVersion;

	my %attrs;
	if(exists $args{waitFlush})
	{	  if($sv ge '4.0')
			 { $self->removed("commit(waitFlush)"); delete $args{waitFlush} }
		elsif($sv ge '1.4') { $self->deprecated("commit(waitFlush)") }
		else { $attrs{waitFlush} = _to_bool delete $args{waitFlush} }
	}

	$attrs{waitSearcher} = _to_bool delete $args{waitSearcher}
		if exists $args{waitSearcher};

	if(exists $args{softCommit})
	{	if($sv lt '4.0') { $self->ignored("commit(softCommit)") }
		else { $attrs{softCommit} = _to_bool delete $args{softCommit} }
	}

	if(exists $args{expungeDeletes})
	{	if($sv lt '1.4') { $self->ignored("commit(expungeDeletes)") }
		else { $attrs{expungeDeletes} = _to_bool delete $args{expungeDeletes} }
	}

	$self->_commit(\%attrs);
}
sub _commit($) {panic "not implemented"}


sub optimize(%)
{	my ($self, %args) = @_;
	my $sv = $self->serverVersion;

	my %attrs;
	if(exists $args{waitFlush})
	{	if($sv ge '4.0') { $self->removed("commit(waitFlush)"); delete $args{waitFlush} }
		elsif($sv ge '1.4') { $self->deprecated("optimize(waitFlush)") }
		else { $attrs{waitFlush} = _to_bool delete $args{waitFlush} }
	}

	$attrs{waitSearcher} = _to_bool delete $args{waitSearcher}
		if exists $args{waitSearcher};

	if(exists $args{softCommit})
	{	if($sv lt '4.0') { $self->ignored("optimize(softCommit)") }
		else { $attrs{softCommit} = _to_bool delete $args{softCommit} }
	}

	if(exists $args{maxSegments})
	{	if($sv lt '1.3') { $self->ignored("optimize(maxSegments)") }
		else { $attrs{maxSegments} = delete $args{maxSegments} }
	}

	$self->_optimize(\%attrs);
}
sub _optimize($) {panic "not implemented"}


sub delete(%)
{	my ($self, %args) = @_;

	my %attrs;
	$attrs{commit} = _to_bool(exists $args{commit} ? $args{commit} : $self->autocommit);

	if(exists $args{fromPending})
	{	$self->deprecated("delete(fromPending)");
		$attrs{fromPending}   = _to_bool delete $args{fromPending};
	}
	if(exists $args{fromCommitted})
	{	$self->deprecated("delete(fromCommitted)");
		$attrs{fromCommitted} = _to_bool delete $args{fromCommitted};
	}

	my @which;
	if(my $id = $args{id})
	{	push @which, map +(id => $_), ref $id eq 'ARRAY' ? @$id : $id;
	}
	if(my $q  = $args{query})
	{	push @which, map +(query => $_), ref $q  eq 'ARRAY' ? @$q  : $q;
	}
	@which or return;

	# JSON calls do not accept multiple ids at once (it seems in 4.0)
	my $result;
	if($self->serverVersion ge '1.4' && !$self->isa('Apache::Solr::JSON'))
	{	$result = $self->_delete(\%attrs, \@which);
	}
	else
	{	# old servers accept only one id or query per delete
		$result = $self->_delete(\%attrs, [splice @which, 0, 2]) while @which;
	}
	$result;
}
sub _delete(@) {panic "not implemented"}


sub rollback()
{	my $self = shift;
	$self->serverVersion ge '1.4'
		or error __x"Rollback not supported by solr server";

	$self->_rollback;
}


sub extractDocument(@)
{	my $self  = shift;

	$self->serverVersion ge '1.4'
		or error __x"extractDocument() requires Solr v1.4 or higher";
		
	my %p   = $self->expandExtract(@_);
	my $data;

	# expand* changes '_' into '.'
	my $ct  = delete $p{'content.type'};
	my $fn  = delete $p{file};
	$p{'resource.name'} ||= $fn if $fn && !ref $fn;

	$p{commit} = _to_bool $self->autocommit
		unless exists $p{commit};

	if(defined $p{string})
	{	# try to avoid copying the data, which can be huge
		$data = $ct =~ m!^text/!i
		  ? \encode(utf8 => (ref $p{string} eq 'SCALAR' ? ${$p{string}} : $p{string}))
		  : (ref $p{string} eq 'SCALAR' ? $p{string} : \$p{string} );

		delete $p{string};
	}
	elsif($fn)
	{	local $/;
		if(ref $fn eq 'GLOB') { $data = \<$fn> }
		else
		{	local *IN;
			open IN, '<:raw', $fn or fault __x"Cannot read document from {fn}", fn => $fn;
			$data = \<IN>;
			close IN or fault __x"Read error for document {fn}", fn => $fn;
			$ct ||= $mimetypes->mimeTypeOf($fn);
		}
	}
	else
	{	error __x"Extract requires document as file or string";
	}

	$self->_extract([%p], $data, $ct);
}

sub _extract($) { panic "not implemented" }

#-------------------------

sub _core_admin($@)
{	my ($self, $action, $params) = @_;
	$params->{core} ||= $self->core;
	
	my $endpoint = $self->endpoint('cores', core => 'admin', params => $params);
	my @params   = %$params;
	my $result   = Apache::Solr::Result->new(params => [ %$params ], endpoint => $endpoint, core => $self);

	$self->request($endpoint, $result);
	$result;
}


sub coreStatus(%)
{	my ($self, %args) = @_;
	$self->_core_admin('STATUS', \%args);
}


sub coreReload(%)
{	my ($self, %args) = @_;
	$self->_core_admin('RELOAD', \%args);
}


sub coreUnload($%)
{	my ($self, %args) = @_;
	$self->_core_admin('UNLOAD', \%args);
}

#--------------------------

sub _calling_sub()
{	for(my $i=0;$i <10; $i++)
	{	my $sub = (caller $i)[3];
		return $sub if !$sub || index($sub, 'Apache::Solr::') < 0;
	}
}

sub _simpleExpand($$$)
{	my ($self, $p, $prefix) = @_;
	my @p  = ref $p eq 'HASH' ? %$p : @$p;
	my $sv = $self->serverVersion;

	my @t;
	while(@p)
	{	my ($k, $v) = (shift @p, shift @p);
		$k =~ s/_/./g;
		$k = $prefix.$k if defined $prefix && index($k, $prefix)!=0;
		my $param   = $k =~ m/^f\.[^\.]+\.(.*)/ ? $1 : $k;

		my ($dv, $iv);
		if(($dv = $deprecated{$param}) && $sv ge $dv)
		{	my $command = _calling_sub;
			$self->deprecated("$command($param) since $dv");
		}
		elsif(($iv = $introduced{$param}) && $iv gt $sv)
		{	my $command = _calling_sub;
			$self->ignored("$command($param) introduced in $iv");
			next;
		}

		push @t, $k => $boolparams{$param} ? _to_bool($_) : $_
			for ref $v eq 'ARRAY' ? @$v : $v;
	}
	@t;
}


sub expandTerms(@)
{	my $self = shift;
	my $p = @_==1 ? shift : [@_];
	my @t = $self->_simpleExpand($p, 'terms.');
	wantarray ? @t : \@t;
}


sub _expand_flatten($$)
{	my ($self, $v, $prefix) = @_;
	my @l = ref $v eq 'HASH' ? %$v : @$v;
	my @s;
	push @s, $prefix.(shift @l) => (shift @l) while @l;
	@s;
}

sub expandExtract(@)
{	my $self = shift;
	my @p = @_==1 ? @{(shift)} : @_;
	my @s;
	while(@p)
	{	my ($k, $v) = (shift @p, shift @p);
		if(!ref $v || ref $v eq 'SCALAR')
			 { push @s, $k => $v }
		elsif($k eq 'literal' || $k eq 'literals')
			 { push @s, $self->_expand_flatten($v, 'literal.') }
		elsif($k eq 'fmap' || $k eq 'boost' || $k eq 'resource')
			 { push @s, $self->_expand_flatten($v, "$k.") }
		else { panic "unknown set '$k'" }
	}

	my @t = @s ? $self->_simpleExpand(\@s) : ();
	wantarray ? @t : \@t;
}


# probably more config later, currently only one column
# "also-per-field" means, not only $set.$more, but also f.$field.$set.$more
my %sets =   #also-per-field?
  ( expand  => [0]
  , facet   => [1]
  , hl      => [1]
  , mlt     => [0]
  , stats   => [0]
  , suggest => [0]
  , group   => [0]
  );
 
sub expandSelect(@)
{	my $self = shift;
	my @s;
	my (@flat, %seen_set);
	while(@_)
	{	my ($k, $v) = (shift, shift);
		$k =~ s/_/./g;
		my @p = split /\./, $k;

		# fields are $set.$more or f.$field.$set.$more
		my $per_field    = $p[0] eq 'f' && @p > 2;
		my ($set, $more) = $per_field ? @p[2,3] : @p[0,1];

		if(my $def = $sets{$set})
		{	$seen_set{$set} = 1;
			!$per_field || $def->[0]
			   or error __x"Set {set} cannot be used per field, in {field}", set => $set, field => $k;

			if(ref $v eq 'HASH')
			{	!$more or error __x"Field {field} is not simple for a set", field => $k;
				push @s, $self->_simpleExpand($v, "$k.");
			}
			elsif($more)    # skip $set=true for now
			{	push @flat, $k => $v;
			}
		}
		elsif(ref $v eq 'HASH')
		{	error __x"Unknown set {set}", set => $set;
		}
		else
		{	push @flat, $k => $v;
		}
	}
	push @flat, %seen_set;
	unshift @s, $self->_simpleExpand(\@flat);
	wantarray ? @s : \@s;
}


sub deprecated($)
{	my ($self, $msg) = @_;
	return if $self->{AS_depr_msg}{$msg}++;  # report only once
	warning __x"Deprecated solr {message}", message => $msg;
}


sub ignored($)
{	my ($self, $msg) = @_;
	return if $self->{AS_ign_msg}{$msg}++;  # report only once
	warning __x"Ignored solr {message}", message => $msg;
}


sub removed($)
{	my ($self, $msg) = @_;
	return if $self->{AS_rem_msg}{$msg}++;  # report only once
	warning __x"Removed solr {message}", message => $msg;
}


#------------------------

sub endpoint($@)
{	my ($self, $action, %args) = @_;
	my $core = $args{core} || $self->core;
	my $take = $self->server->clone;    # URI
	$take->path($take->path . (defined $core ? "/$core" : '') . "/$action");

	# make parameters ordered
	my $params = $args{params} || [];
	$params	= [ %$params ] if ref $params eq 'HASH';
	@$params or return $take;

	# remove paramers with undefined value
	my @p = @$params;
	my @params;
	while(@p)
	{	push @params, $p[0] => $p[1] if defined $p[1];
		shift @p, shift @p;
	}

	$take->query_form(@params) if @params;
	$take;
}


sub request($$;$$)
{	my ($self, $url, $result, $body, $body_ct) = @_;

	my $req;
	if($body)
	{	# request with 'form' payload
		$req       = HTTP::Request->new
		  ( POST => $url
		  , [ Content_Type        => $body_ct
			, Content_Disposition => 'form-data; name="content"'
			]
		  , (ref $body eq 'SCALAR' ? $$body : $body)
		  );
	}
	else
	{	# request without payload
		$req = HTTP::Request->new(GET => $url);
	}

	$result->request($req);

	my $resp;
	my $retries = $self->{AS_retry_max};
	my $wait    = $self->{AS_retry_wait};
	my $start   = time;

	while($retries--)
	{	$resp = $self->agent->request($req);
		$result->response($resp);
		my $dec = $result->decoded($self->decodeResponse($resp));

		last if $resp->is_success;

		if($resp->code==500)
		{	$! = ENETDOWN;  # HTTP(500) -> unix error
			alert __x"Solr request failed with {code}, {retries} retries left",
			code => $resp->code, retries => $retries, result => $result;
			sleep $wait if $wait && $retries;    # let remote settle a bit
			next;
		}

		error __x"Solr request failed with: {err}",
			err => ($result->solrError || $result->httpError), result => $result;
	}

	unless($resp->is_success)
	{	$! = $resp->code==500 ? ENETDOWN : ENETUNREACH;
		fault __x"Solr request failed after {elapse} seconds after {retries} retries",
			elapse => time - $start, retries => $self->{AS_retry_max} - $retries -1, result => $result;
	}

	$resp;
}

sub decodeResponse($) { undef }

#----------------------------------

1;
