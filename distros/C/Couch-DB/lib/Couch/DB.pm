# Copyrights 2024-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB;{
our $VERSION = '0.200';
}

use version;

use Log::Report 'couch-db';

use Couch::DB::Client   ();
use Couch::DB::Cluster  ();
use Couch::DB::Database ();
use Couch::DB::Node     ();
use Couch::DB::Util     qw(flat);

use DateTime          ();
use DateTime::Format::ISO8601 ();
use DateTime::Format::Mail    ();
use JSON              qw/encode_json/;
use List::Util        qw(first min);
use Scalar::Util      qw(blessed);
use Storable          qw/dclone/;
use URI               ();
use URI::Escape       qw/uri_escape uri_unescape/;

use constant
{	DEFAULT_SERVER => 'http://127.0.0.1:5984',
};


sub new(%)
{	my ($class, %args) = @_;
	$class ne __PACKAGE__
		or panic "You have to instantiate extensions of this class";

	(bless {}, $class)->init(\%args);
}

sub init($)
{	my ($self, $args) = @_;

	my $v = delete $args->{api} or panic "Parameter 'api' is required";
	$self->{CD_api}     = blessed $v && $v->isa('version') ? $v : version->parse($v);
	$self->{CD_clients} = [];

	# explicit undef for server means: do not create
	my $create_client   = ! exists $args->{server} || defined $args->{server};
	my $server          = delete $args->{server};
	my $external        = $ENV{PERL_COUCH_DB_SERVER};
	my %auth            = ( auth => delete $args->{auth} || 'BASIC' );

	if($server || ! $external)
	{	$auth{username} = delete $args->{username};
		$auth{password} = delete $args->{password};
	}
	elsif($external)
	{	my $ext = URI->new($external);
		if(my $userinfo = $ext->userinfo)
		{	my ($username, $password) = split /:/, $userinfo;
			$auth{username} = uri_unescape $username;
			$auth{password} = uri_unescape $password;
			$ext->userinfo(undef);
		}
		$server = "$ext";
	}
	$self->{CD_auth}    = \%auth;

	$self->createClient(server => $server || DEFAULT_SERVER, name => '_local')
		if $create_client;

	$self->{CD_toperl}  = delete $args->{to_perl}  || {};
	$self->{CD_tojson}  = delete $args->{to_json}  || {};
	$self->{CD_toquery} = delete $args->{to_query} || {};
	$self;
}

#-------------

sub api() { $_[0]->{CD_api} }

#-------------

sub createClient(%)
{	my ($self, %args) = @_;
	my $client = Couch::DB::Client->new(couch => $self, %{$self->{CD_auth}}, %args);
	$client ? $self->addClient($client) : undef;
}


sub db($%)
{	my ($self, $name, %args) = @_;
	Couch::DB::Database->new(name => $name, couch => $self, %args);
}


sub node($)
{	my ($self, $name) = @_;
	$self->{CD_nodes}{$name} ||= Couch::DB::Node->new(name => $name, couch => $self);
}


sub cluster() { $_[0]->{CD_cluster} ||= Couch::DB::Cluster->new(couch => $_[0]) }

#-------------

#XXX the API-doc might be mistaken, calling the "analyzer" parameter "field".

sub searchAnalyze(%)
{	my ($self, %args) = @_;

	my %send = (
		analyzer => delete $args{analyzer} // panic "No analyzer specified.",
		text     => delete $args{text}     // panic "No text to inspect specified.",
	);

	$self->call(POST => '/_search_analyze',
		introduced => '3.0',
		send       => \%send,
		$self->_resultsConfig(\%args),
	);
}


sub requestUUIDs($%)
{	my ($self, $count, %args) = @_;

	$self->call(GET => '/_uuids',
		introduced => '2.0.0',
		query      => { count => $count },
		$self->_resultsConfig(\%args),
	);
}


sub freshUUIDs($%)
{	my ($self, $count, %args) = @_;
	my $stock = $self->{CDC_uuids} || [];
	my $bulk  = delete $args{bulk} || 50;

	while($count > @$stock)
	{	my $result = $self->requestUUIDs($bulk, delay => 0) or last;
		push @$stock, @{$result->values->{uuids} || []};
	}

	splice @$stock, 0, $count;
}


sub freshUUID(%) { my $s = shift; ($s->freshUUIDs(1, @_))[0] }

#-------------

sub addClient($)
{	my ($self, $client) = @_;
	$client or return $self;

	$client->isa('Couch::DB::Client') or panic;
	push @{$self->{CD_clients}}, $client;
	$self;
}


sub clients(%)
{	my ($self, %args) = @_;
	my $clients = $self->{CD_clients};

	my $role = delete $args{role};
	$role ? grep $_->canRole($role), @$clients : @$clients;
}


sub client($)
{	my ($self, $name) = @_;
	$name = "$name" if blessed $name;
	first { $_->name eq $name } $self->clients;   # never many: no HASH needed
}


sub call($$%)
{	my ($self, $method, $path, %args) = @_;
	$args{method}   = $method;
	$args{path}     = $path;
	$args{query}  ||= my $query = {};

	my $headers     = $args{headers} ||= {};
	$headers->{Accept} ||= 'application/json';
	$headers->{'Content-Type'} ||= 'application/json';

#use Data::Dumper;
#warn "CALL ", Dumper \%args;

    my $send = $args{send};
	defined $send || ($method ne 'POST' && $method ne 'PUT')
		or panic "No send in $method $path";

	my $introduced = $args{introduced};
	$self->check(exists $args{$_}, $_ => delete $args{$_}, "Endpoint '$method $path'")
		for qw/removed introduced deprecated/;

	### On this level, we pick a client.  Extensions implement the transport.

	my $paging = $args{paging};
	if($paging && (my $client = $paging->{client}))
	{	# No free choices for clients once we are on page 2
		$args{client} = $client;
		delete $args{clients};
	}

	my @clients;
	if(my $client = delete $args{client})
	{	@clients = blessed $client ? $client : $self->client($client);
	}
	elsif(my $c = delete $args{clients})
	{	@clients = ref $c eq 'ARRAY' ? @$c : $self->clients(role => $c);
	}
	else
	{	@clients = $self->clients;
	}
	@clients or error __x"No clients can run {method} {path}.", method => $method, path => $path;

	my $result  = Couch::DB::Result->new(
		couch     => $self,
		on_values => $args{on_values},
		on_error  => $args{on_error},
		on_final  => $args{on_final},
		on_chain  => $args{on_chain},
		on_row    => $args{on_row},
		paging    => $paging,
	);

  CLIENT:
	foreach my $client (@clients)
	{
		! $introduced || $client->version >= $introduced
			or next CLIENT;  # server release too old

		if($paging)
		{	do
			{	# Merge paging setting into the request
	    		$self->_pageRequest($paging, $method, $query, $send);

				$self->_callClient($result, $client, %args);
				$result
					or next CLIENT;  # fail

			} while $result->pageIsPartial;

			last CLIENT;
		}
		else
		{	# Non-paging commands are simple
			$self->_callClient($result, $client, %args)
				and last CLIENT;
		}
	}

	# The error from the last try will remain.
	$result;
}

sub _callClient { panic "must be extended" }

# Described in the DETAILS below, non-paging commands
sub _resultsConfig($%)
{	my ($self, $args, @more) = @_;
	my %config;

	unshift @more, %$args;
	while(@more)
	{	my ($key, $value) = (shift @more, shift @more);
		if($key eq 'headers')
		{	# Headers are added, as default only
			my $headers = $config{headers} ||= {};
			exists $headers->{$_} or ($headers->{$_} = $value->{$_}) for keys %$value;
		}
		elsif($key =~ /^on_/)
		{	# User specified additional events
			push @{$config{$key}}, $value if defined $value;
		}
		else
		{	# Other parameters used as default
			exists $config{$key} or $config{$key} = $value;
		}
	}

	$config{paging} && !$config{on_row} and panic "paging without on_row";

	delete @{$args}{qw/delay client clients/};
	delete @{$args}{grep /^on_/, keys %$args};
	keys %$args and warn "Unused call parameters: ", join ', ', sort keys %$args;

	%config;
}

# Described in the DETAILS below, paging commands
sub _resultsPaging($%)
{	my ($self, $args, @more) = @_;

	my %state = (harvested => []);
	my $succ;  # successor
	if(my $succeeds = delete $args->{succeed})
	{	delete $args->{clients}; # no client switching within paging

		if(blessed $succeeds && $succeeds->isa('Couch::DB::Result'))
		{	# continue from living previous result
			$succ = $succeeds->nextPageSettings;
			$args->{client} = $succeeds->client;
		}
		else
		{	# continue from resurrected from Result->pagingState()
			my $h = $succeeds->{harvester}
				or panic "_succeed does not contain data from pagingState() nor is a Result object.";

			$h eq 'DEFAULT' || $args->{harvester}
				or panic "Harvester does not survive pagingState(), resupply.";

			$succeeds->{map} eq 'NONE' || $args->{map}
				or panic "Map does not survive pagingState(), resupply.";

			$succ  = $succeeds;
			$args->{client} = $succeeds->{client};
		}
	}

	$state{start}     = $succ->{start} || 0;
	$state{skip}      = delete $args->{skip} || 0;
	$state{all}       = delete $args->{all}  || 0;
	$state{map}       = my $map = delete $args->{map} || $succ->{map};
	$state{harvester} = my $harvester = delete $args->{harvester} || $succ->{harvester};
	$state{page_size} = my $size = delete $args->{page_size} || $succ->{page_size};
	$state{req_rows}  = delete $args->{limit} || $succ->{req_rows} || 100;
	$state{page_mode} = !! ($state{all} || $size);
	$state{stop}      = my $stop = delete $args->{stop} || $succ->{stop} || 'EMPTY';

	my $page;
	if($page = delete $args->{page})
	{	defined $size or panic "page parameter only usefull with page_size.";
		$state{start} = ($page - 1) * $size;
	}
	$state{pagenr}    = delete $args->{pagenr} // $succ->{pagenr} // $page // 1;

	$state{bookmarks} = $succ->{bookmarks} ||= { };
	if(my $bm = delete $args->{bookmark})
	{	$state{bookmarks}{$state{start}} = $bm;
	}

	$harvester ||= sub { $_[0]->_rowsRef(0) };
	my $harvest = sub {
		my $result = shift or return;
		my @found  = flat $harvester->($result);
		@found     = map $map->($result, $_), @found if $map;

		# The answer does not tell me that we are on the last page.
		$result->_pageAdd($result->answer->{bookmark}, \@found);  # also call with 0
	};

	if(ref $stop ne 'CODE')
	{	if($stop eq 'EMPTY')
		{	# we always stop when there were no rows returned
			$state{stop} = sub { 0 };
		}
		elsif($stop eq 'SMALLER')
		{	my $first;
			$state{stop} = sub {
				return $_[0]->numberOfRows < $first if defined $first;
				$first = $_[0]->numberOfRows;
				0;
			};
		}
		elsif($stop =~ m/^UPTO\((\d+)\)$/)
		{	my $upto = $1;
			$state{stop} = sub { $_[0]->numberOfRows <= $upto };
		}
		else
		{	panic "Unknown stop value `$stop`";
		}
	}

	$self->_resultsConfig($args, @more, on_final => $harvest, paging => \%state),
}

sub _pageRequest($$$$)
{	my ($self, $paging, $method, $query, $send) = @_;
	my $params   = $method eq 'GET' ? $query : $send;
	my $progress = @{$paging->{harvested}};      # within the page
	my $start    = $paging->{start};

	$params->{limit}
	  = $paging->{page_size}
	  ? (min $paging->{page_size} - $progress, $paging->{req_rows})
	  : $paging->{req_rows};

	if(my $bookmark = $paging->{bookmarks}{$start + $progress})
	{	$params->{bookmark} = $bookmark;
		$params->{skip}     = $paging->{skip};
	}
	else
	{	delete $params->{bookmark};
		$params->{skip}     = $start + $paging->{skip} + $progress;
	}
}


my %default_toperl = (  # sub ($couch, $name, $datum) returns value/object
	abs_uri   => sub { URI->new($_[2]) },
	epoch     => sub { DateTime->from_epoch(epoch => $_[2]) },
	isotime   => sub { DateTime::Format::ISO8601->parse_datetime($_[2]) },
	mailtime  => sub { DateTime::Format::Mail->parse_datetime($_[2]) },   # smart choice by CouchDB?
 	version   => sub { version->parse($_[2]) },
	node      => sub { $_[0]->node($_[2]) },
);

sub _toPerlHandler($)
{	my ($self, $type) = @_;
	$self->{CD_toperl}{$type} || $default_toperl{$type};
}

sub toPerl($$@)
{	my ($self, $data, $type) = (shift, shift, shift);
	my $conv  = $self->_toPerlHandler($type) or return $self;

	exists $data->{$_} && ($data->{$_} = $conv->($self, $_, $data->{$_}))
		for @_;

	$self;
}


sub listToPerl
{	my ($self, $name, $type) = (shift, shift, shift);
	my $conv  = $self->_toPerlHandler($type) or return flat @_;
	grep defined, map $conv->($self, $name, $_), flat @_;
}


my %default_tojson = (  # sub ($couch, $name, $datum) returns JSON
	# All known backends support these booleans
	bool => sub { $_[2] ? $JSON::true : $JSON::false },

	# All known URL implementations correctly overload stringify
	uri  => sub { "$_[2]" },

	node => sub { my $n = $_[2]; blessed $n ? $n->name : $n },

	# In Perl, the int might come from text (for instance a configuration
	# file.  In that case, the JSON::XS will write "6".  But the server-side
	# JSON is type sensitive and may crash.
	int  => sub { defined $_[2] ? int($_[2]) : undef },
);

sub _toJsonHandler($)
{	my ($self, $type) = @_;
	$self->{CD_tojson}{$type} || $default_tojson{$type};
}

sub toJSON($@)
{	my ($self, $data, $type) = (shift, shift, shift);
	my $conv = $self->_toJsonHandler($type) or return $self;

	exists $data->{$_} && ($data->{$_} = $conv->($self, $_, $data->{$_}))
		for @_;

	$self;
}


# Extend/override the list of toJSON converters
my %default_toquery = (
	bool => sub { $_[2] ? 'true' : 'false' },
	json => sub { encode_json $_[2] },
);

sub _toQueryHandler($)
{	my ($self, $type) = @_;
	   $self->{CD_toquery}{$type} || $default_toquery{$type}
	|| $self->{CD_tojson}{$type}  || $default_tojson{$type};
}

sub toQuery($@)
{	my ($self, $data, $type) = (shift, shift, shift);
	my $conv = $self->_toQueryHandler($type) or return $self;

	exists $data->{$_} && ($data->{$_} = $conv->($self, $_, $data->{$_}))
		for @_;

	$self;
}


sub jsonText($%)
{	my ($self, $json, %args) = @_;
	JSON->new->pretty(not $args{compact})->encode($json);
}


my (%surpress_depr, %surpress_intro);

sub check($$$$)
{	$_[1] or return $_[0];
	my ($self, $condition, $change, $version, $what) = @_;

	# API-doc versions are sometimes without 3rd part.
	my $cv = version->parse($version);

	if($change eq 'removed')
	{	$self->api < $cv
			or error __x"{what} got removed in {release}, but you specified api {api}.",
				what => $what, release => $version, api => $self->api;
	}
	elsif($change eq 'introduced')
	{	$self->api >= $cv || $surpress_intro{$what}++
			or warning __x"{what} was introduced in {release}, but you specified api {api}.",
				what => $what, release => $version, api => $self->api;
	}
	elsif($change eq 'deprecated')
	{	$self->api >= $cv || $surpress_depr{$what}++
			or warning __x"{what} got deprecated in api {release}.",
					what => $what, release => $version;
	}
	else { panic "$change $cv $what" }

	$self;
}

#-------------

#### Extension which perform some tasks which are framework object specific.

# Returns the JSON structure which is part of the response by the CouchDB
# server.  Usually, this is the body of the response.  In multipart
# responses, it is the first part.
sub _extractAnswer($)  { panic "must be extended" }

# The the decoded named extension from the multipart message
sub _attachment($$)    { panic "must be extended" }

# Extract the decoded body of the message
sub _messageContent($) { panic "must be extended" }

1;

#-------------
