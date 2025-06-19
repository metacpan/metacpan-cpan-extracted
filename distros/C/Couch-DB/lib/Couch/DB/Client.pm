# Copyrights 2024-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Client;{
our $VERSION = '0.200';
}


use Couch::DB::Util   qw(flat);
use Couch::DB::Result ();

use Log::Report 'couch-db';

use Scalar::Util    qw(weaken blessed);
use List::Util      qw(first);
use MIME::Base64    qw(encode_base64);
use Storable        qw(dclone);
use URI::Escape     qw(uri_escape);

my $seqnr = 0;


sub new(@) { (bless {}, shift)->init( {@_} ) }

sub init($)
{	my ($self, $args) = @_;
	$self->{CDC_server} = my $server = delete $args->{server} or panic "Requires 'server'";
	$self->{CDC_name}   = delete $args->{name} || "$server";
	$self->{CDC_ua}     = delete $args->{user_agent} or panic "Requires 'user_agent'";
	$self->{CDC_uuids}  = [];
	$self->{CDC_seqnr}  = ++$seqnr;

	$self->{CDC_couch}  = delete $args->{couch} or panic "Requires 'couch'";
	weaken $self->{CDC_couch};

	$self->{CDC_hdrs}   = my $headers = delete $args->{headers} || {};

	my $username        = delete $args->{username} // '';
	$self->login(
		auth     => delete $args->{auth} || 'BASIC',
		username => $username,
		password => delete $args->{password},
	) if length $username;

	$self;
}

#-------------

sub name() { $_[0]->{CDC_name} }


sub couch() { $_[0]->{CDC_couch} }


sub server() { $_[0]->{CDC_server} }


sub userAgent() { $_[0]->{CDC_ua} }


sub headers($) { $_[0]->{CDC_hdrs} }


sub seqnr() { $_[0]->{CDC_seqnr} }

#-------------

sub _clientIsMe($)   # check no client parameter is used
{	my ($self, $args) = @_;
	defined $args->{client} and panic "No parameter 'client' allowed.";
	$args->{clients} && @{delete $args->{clients}} and panic "No parameter 'clients' allowed.";
	$args->{client} = $self;
}

sub login(%)
{	my ($self, %args) = @_;
	$self->_clientIsMe(\%args);

	my $auth     = delete $args{auth} || 'BASIC';
	my $username = delete $args{username} or panic "Requires username";
	my $password = delete $args{password} or panic "Requires password";

	if($auth eq 'BASIC')
	{	$self->headers->{Authorization} = 'Basic ' . encode_base64("$username:$password", '');
		return $self;  #XXX must return Result object
	}

	$auth eq 'COOKIE'
		or error __x"Unsupport authorization '{how}'", how => $auth;

	my $send = $self->{CDC_login} =     # keep for cookie refresh (uninplemented)
	 	+{ name => $username, password => $password };

	$self->couch->call(POST => '/_session',
		send      => $send,
		query     => { next => delete $args{next} },
		$self->couch->_resultsConfig(\%args, on_final  => sub {
			$self->{CDC_roles} = $_[0]->isReady ? $_[0]->values->{roles} : undef;
		}),
	);
}


sub session(%)
{	my ($self, %args) = @_;
	$self->_clientIsMe(\%args);
	my $couch = $self->couch;

	my %query;
	$query{basic} = delete $args{basic} if exists $args{basic};
	$couch->toQuery(\%query, bool => qw/basic/);

	$couch->call(GET => '/_session',
		query     => \%query,
		$couch->_resultsConfig(\%args, on_final => sub {
			$self->{CDC_roles} = $_[0]->isReady ? $_[0]->values->{userCtx}{roles} : undef; $_[0];
		}),
	);
}


sub logout(%)
{	my ($self, %args) = @_;
	$self->_clientIsMe(\%args);

	$self->couch->call(DELETE => '/_session',
		$self->couch->_resultsConfig(\%args),
	);
}


sub roles()
{	my $self = shift;
	$self->{CDC_roles} or $self->session(basic => 1);  # produced as side-effect
	@{$self->{CDC_roles} || []};
}


sub hasRole($) { first { $_[1] eq $_ } $_[0]->roles }

#-------------

sub __serverInfoValues($$)
{	my ($self, $result, $data) = @_;
	my $values = { %$data };

	# 3.3.3 does not contain the vendor/version, as the example in the spec says
	# Probably a mistake.
	$result->couch->toPerl($values, version => qw/version/);
	$values;
}

sub serverInfo(%)
{	my ($self, %args) = @_;
	$self->_clientIsMe(\%args);

	my $cached = delete $args{cached} || 'YES';
	$cached =~ m!^(?:YES|NEVER|RETRY|PING)$!
		or panic "Unsupported cached parameter '$cached'.";

	if(my $result = $self->{CDC_info})
	{	return $self->{CDC_info}
			if $cached eq 'YES' || ($cached eq 'RETRY' && $result->isReady);
	}

	my $result = $self->couch->call(GET => '/',
		$self->couch->_resultsConfig(\%args,
			on_values => sub { $self->__serverInfoValues(@_) }
		),
	);

	if($cached ne 'PING')
	{	$self->{CDC_info} = $result;
		delete $self->{CDC_version};
	}

	$result;
}


sub version()
{	my $self   = shift;
	return $self->{CDC_version} if exists $self->{CDC_version};

	my $result = $self->serverInfo(cached => 'YES');
	$result->isReady or return undef;

	my $version = $result->values->{version}
		or error __x"Server info field does not contain the server version.";

	$self->{CDC_version} = $version;
}


sub __simpleArrayRow($$%)
{   my ($self, $result, $index, %args) = @_;
	my $answer = $result->answer->[$index] or return ();

	  (	answer => $answer,
		values => $result->values->[$index],
	  );
}

sub __activeTasksValues($$)
{	my ($self, $result, $tasks) = @_;
	my $couch = $result->couch;

	my @tasks;
	foreach my $task (@$tasks)
	{	my %task = %$task;
		$couch->toPerl(\%task, epoch => qw/started_on updated_on/);
		push @tasks, \%task;
	}

	\@tasks;
}

sub activeTasks(%)
{	my ($self, %args) = @_;
	$self->_clientIsMe(\%args);

	$self->couch->call(GET => '/_active_tasks',
		$self->couch->_resultsConfig(\%args,
			on_values => sub { $self->__activeTasksValues(@_) },
			on_row    => sub { $self->__simpleArrayRow(@_) },
		),
	);
}


sub __dbNamesFilter($)
{	my ($self, $search) = @_;

	my $query = defined $search ? +{ %$search } : return {};
	$self->couch
		->toQuery($query, bool => qw/descending/)
		->toQuery($query, json => qw/endkey end_key startkey start_key/);
	$query;
}

sub databaseNames(;$%)
{	my ($self, $search, %args) = @_;
	$self->_clientIsMe(\%args);

	$self->couch->call(GET => '/_all_dbs',
		query => $self->__dbNamesFilter($search),
		$self->couch->_resultsConfig(\%args,
			on_row => sub { $self->__simpleArrayRow(@_) },
		),
	);
}


sub databaseInfo(;$%)
{	my ($self, $search, %args) = @_;
	$self->_clientIsMe(\%args);
	my $names  = delete $args{names};

	my ($method, $query, $send, $intro) = $names
	  ?	(POST => undef,  +{ keys => $names }, '2.2.0')
	  :	(GET  => $self->_dbNamesFilter($search), undef, '3.2.0');

	$self->couch->call($method => '/_dbs_info',
		introduced => $intro,
		query      => $query,
		send       => $send,
		$self->couch->_resultsConfig(\%args,
			on_row => sub { $self->__simpleArrayRow(@_) },
		),
	);
}


sub __dbUpRow($$%)
{	my ($self, $result, $index, %args) = @_;
	my $answer = $result->answer->{results}[$index] or return ();
	  (	answer => $answer,
		values => $result->values->{results}[$index],
	  );
}

sub dbUpdates($%)
{	my ($self, $feed, %args) = @_;
	$self->_clientIsMe(\%args);

	my $query  = +{ %$feed };

	$self->couch->call(GET => '/_db_updates',
		introduced => '1.4.0',
		query      => $query,
		$self->couch->_resultsConfig(\%args,
			on_row => sub { $self->__dbUpRow(@_) },
		),
	);
}


sub __clusterNodeValues($$)
{	my ($self, $result, $data) = @_;
	my $couch   = $result->couch;

	my %values  = %$data;
	foreach my $set (qw/all_nodes cluster_nodes/)
	{	my $v = $values{$set} or next;
		$values{$set} = [ $couch->listToPerl($set, node => $v) ];
	}

	\%values;
}

sub clusterNodes(%)
{	my ($self, %args) = @_;
	$self->_clientIsMe(\%args);

	$self->couch->call(GET => '/_membership',
		introduced => '2.0.0',
		$self->couch->_resultsConfig(\%args,
			on_values => sub { $self->__clusterNodeValues(@_) }
		),
	);
}


sub __replicateValues($$)
{	my ($self, $result, $raw) = @_;
	my $couch   = $result->couch;

	my $history = delete $raw->{history} or return $raw;
	my %values  = %$raw;
	my @history;

	foreach my $event (@$history)
	{	my %event = %$event;
		$couch->toPerl(\%event, mailtime => qw/start_time end_time/);
		push @history, \%event;
	}
	$values{history} = \@history;

	\%values;
}

sub replicate($%)
{	my ($self, $rules, %args) = @_;
	$self->_clientIsMe(\%args);

	my $couch  = $self->couch;
	$couch->toJSON($rules, bool => qw/cancel continuous create_target winning_revs_only/);

    #TODO: warn for upcoming changes in source and target: absolute URLs required

	$couch->call(POST => '/_replicate',
		send   => $rules,
		$couch->_resultsConfig(\%args,
			on_values => sub { $self->__replicateValues(@_) }
		),
	);
}


sub __replJobsRow($$%)
{	my ($self, $result, $index, %args) = @_;
	my $answer = $result->answer->{jobs}[$index] or return ();

	  (	answer => $answer,
		values => $result->values->{jobs}[$index],
	  );
}

sub __replJobsValues($$)
{	my ($self, $result, $raw) = @_;
	my $couch   = $result->couch;
	my $values  = dclone $raw;

	foreach my $job (@{$values->{jobs} || []})
	{
		$couch->toPerl($_, isotime => qw/timestamp/)
			foreach @{$job->{history} || []};

		$couch->toPerl($job, isotime => qw/start_time/)
		      ->toPerl($job, abs_url => qw/target source/)
		      ->toPerl($job, node    => qw/node/);
	}

	$values;
}

sub replicationJobs(%)
{	my ($self, %args) = @_;
	$self->_clientIsMe(\%args);

	$self->couch->call(GET => '/_scheduler/jobs',
		$self->couch->_resultsPaging(\%args,
			on_values => sub { $self->__replJobsValues(@_) },
			on_row    => sub { $self->__replJobsRow(@_) },
		),
	);
}


sub __replDocRow($$%)
{	my ($self, $result, $index, %args) = @_;
	my $answer = $result->answer->{jobs}[$index] or return ();

	  (	answer => $answer,
		values => $result->values->{jobs}[$index],
	  );
}

sub __replDocValues($$)
{	my ($self, $result, $raw) = @_;
	my $v = +{ %$raw }; # $raw->{info} needs no conversions

	$result->couch
		->toPerl($v, isotime => qw/start_time last_updated/)
		->toPerl($v, abs_url => qw/target source/)
		->toPerl($v, node    => qw/node/);
	$v;
}

sub __replDocsValues($$)
{	my ($self, $result, $raw) = @_;
	my $couch   = $result->couch;
	my $values  = dclone $raw;
	$values->{docs} = [ map $self->__replDocValues($result, $_), @{$values->{docs} || []} ];
	$values;
}

sub replicationDocs(%)
{	my ($self, %args) = @_;
	$self->_clientIsMe(\%args);
	my $dbname = delete $args{dbname} || '_replicator';

	my $path = '/_scheduler/docs';
	if($dbname ne '_replicator')
	{	$path .= '/' . uri_escape($dbname);
	}

	$self->couch->call(GET => $path,
		$self->couch->_resultsPaging(\%args,
			on_values => sub { $self->__replDocsValues(@_) },
			on_row    => sub { $self->__replDocRow(@_) },
		),
	);
}


#XXX the output differs from replicationDoc, so different method

sub __replOneDocValues($$)
{	my ($self, $result, $raw) = @_;
	$self->__replDocValues($result, $raw);
}

sub replicationDoc($%)
{	my ($self, $doc, %args) = @_;
	$self->_clientIsMe(\%args);

	my $dbname = delete $args{dbname} || '_replicator';
	my $docid  = blessed $doc ? $doc->id : $doc;

	my $path = '/_scheduler/docs/' . uri_escape($dbname) . '/' . $docid;

	$self->couch->call(GET => $path,
		$self->couch->_resultsConfig(\%args,
			on_values => sub { $self->__replOneDocValues(@_) },
		),
	);
}


sub __nodeNameValues($)
{	my ($self, $result, $raw) = @_;
	my $values = dclone $raw;
	$result->couch->toPerl($values, node => qw/name/);
	$values;
}

sub nodeName($%)
{	my ($self, $name, %args) = @_;
	$self->_clientIsMe(\%args);

	$self->couch->call(GET => "/_node/$name",
		$self->couch->_resultsConfig(\%args,
			on_values => sub { $self->__nodeNameValues(@_) }
		),
	);
}


sub node()
{	my $self = shift;
	return $self->{CDC_node} if defined $self->{CDC_node};

 	my $result = $self->nodeName('_local', client => $self);
	$result->isReady or return undef;   # (temporary?) failure

	my $name   = $result->value('name')
		or error __x"Did not get a node name for _local";

	$self->{CDC_node} = $self->couch->node($name);
}


sub serverStatus(%)
{	my ($self, %args) = @_;
	$self->_clientIsMe(\%args);

	$self->couch->call(GET => '/_up',
		introduced => '2.0.0',
		$self->couch->_resultsConfig(\%args),
	);
}


sub serverIsUp()
{	my $self = shift;
	my $result = $self->serverStatus;
	$result && $result->answer->{status} eq 'ok';
}

1;
