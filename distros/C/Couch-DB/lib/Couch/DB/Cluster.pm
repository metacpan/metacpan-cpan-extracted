# Copyrights 2024 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package Couch::DB::Cluster;
use vars '$VERSION';
$VERSION = '0.001';


use Couch::DB::Util  qw/flat/;;

use Log::Report 'couch-db';

use Scalar::Util  qw(weaken);
use URI::Escape   qw(uri_escape);


sub new(@) { my ($class, %args) = @_; (bless {}, $class)->init(\%args) }

sub init($)
{   my ($self, $args) = @_;

    $self->{CDC_couch} = delete $args->{couch} or panic "Requires couch";
    weaken $self->{CDC_couch};

    $self;
}


#-------------

sub couch() { $_[0]->{CDC_couch} }

#-------------

sub clusterState(%)
{	my ($self, %args) = @_;

	$args{client} || @{$args{client} || []}==1
		or error __x"Explicitly name one client for clusterState().";

	my %query;
	my @need = flat delete $args{ensure_dbs_exists};
	$query{ensure_dbs_exists} = $self->couch->jsonText(\@need, compact => 1)
		if @need;

	$self->couch->call(GET => '/_cluster_setup',
		introduced => '2.0.0',
		query      => \%query,
		$self->couch->_resultsConfig(\%args),
	);
}


sub clusterSetup(%)
{	my ($self, %args) = @_;

	$args{client} || @{$args{client} || []}==1
		or error __x"Explicitly name one client for clusterSetup().";

	$self->couch->call(POST => '/_cluster_setup',
		introduced => '2.0.0',
		send       => \%args,
		$self->couch->_resultsConfig(\%args),
	);
}

#-------------

#XXX The example in CouchDB API doc 3.3.3 says it returns 'reason' with /state,
#XXX but the spec says 'state_reason'.

sub reshardStatus(%)
{	my ($self, %args) = @_;
	my $path = '/_reshard';
	$path   .= '/state' if delete $args{counts};

	$self->couch->call(GET => $path,
		introduced => '2.4.0',
		$self->couch->_resultsConfig(\%args),
	);
}


#XXX The example in CouchDB API doc 3.3.3 says it returns 'reason' with /state,
#XXX but the spec says 'state_reason'.

sub resharding(%)
{	my ($self, %args) = @_;

	my %send   = (
		state  => (delete $args{state} or panic "Requires 'state'"),
		reason => delete $args{reason},
	);

	$self->couch->call(PUT => '/_reshard/state',
		introduced => '2.4.0',
		send       => \%send,
		$self->couch->_resultsConfig(\%args),
	);
}


sub __jobValues($$)
{	my ($couch, $job) = @_;

	$couch->toPerl($job, isotime => qw/start_time update_time/)
	      ->toPerl($job, node => qw/node/);

	$couch->toPerl($_, isotime => qw/timestamp/)
		for @{$job->{history} || []};
}

sub __reshardJobsValues($$)
{	my ($result, $data) = @_;
	my $couch  = $result->couch;

	my $values = dclone $data;
	__jobValues($couch, $_) for @{$values->{jobs} || []};
	$values;
}

sub reshardJobs(%)
{	my ($self, %args) = @_;

	$self->couch->call(GET => '/_reshard/jobs',
		introduced => '2.4.0',
		$self->couch->_resultsConfig(\%args),
		to_values  => \&__reshardJobsValues,
	);
}


sub __reshardCreateValues($$)
{	my ($result, $data) = @_;
	my $values = dclone $data;
	$result->couch->toPerl($_, node => 'node')
		for @$values;

	$values;
}

sub reshardCreate(%)
{	my ($self, %args) = @_;
	my %config = $self->couch->_resultsConfig(\%args);

	#XXX The spec in CouchDB API doc 3.3.3 lists request param 'node' twice.

	$self->couch->call(POST => '/_reshard/jobs',
		introduced => '2.4.0',
		send       => \%args,
		to_values  => \&__reshardCreateValues,
		%config,
	);
}


sub __reshardJobValues($$)
{	my ($result, $data) = @_;
	my $couch  = $result->couch;

	my $values = dclone $data;
	__jobValues($couch, $values);
	$values;
}

sub reshardJob($%)
{	my ($self, $jobid, %args) = @_;

	$self->couch->call(GET => "/_reshard/jobs/$jobid",
		introduced => '2.4.0',
		$self->couch->_resultsConfig(\%args),
		to_values  => \&__reshardJobValues,
	);
}


sub reshardJobRemove($%)
{	my ($self, $jobid, %args) = @_;

	$self->couch->call(DELETE => "/_reshard/jobs/$jobid",
		introduced => '2.4.0',
		$self->couch->_resultsConfig(\%args),
	);
}


sub reshardJobState($%)
{	my ($self, $jobid, %args) = @_;

	#XXX in the 3.3.3 docs, "Request JSON Object" should read "Response ..."
	$self->couch->call(GET => "/_reshard/job/$jobid/state",
		introduced => '2.4.0',
		$self->couch->_resultsConfig(\%args),
	);
}


sub reshardJobChange($%)
{	my ($self, $jobid, %args) = @_;

	my %send = (
		state  => (delete $args{state} or panic "Requires 'state'"),
		reason => delete $args{reason},
	);

	$self->couch->call(PUT => "/_reshard/job/$jobid/state",
		introduced => '2.4.0',
		send       => \%send,
		$self->couch->_resultsConfig(\%args),
	);
}


sub __dbshards($$)
{	my ($result, $data) = @_;
	my $couch  = $result->couch;

	my %values = %$data;
	my $shards = delete $values{shards} || {};

	my %nodes;
	foreach my $shard (sort keys %$shards)
	{	$nodes{$shard} = [ $couch->listToPerl($shard, node => $shards->{$shard}) ];
	}

	$values{shards} = \%nodes;
	\%values;
}

sub shardsForDB($%)
{	my ($self, $db, %args) = @_;

	$self->couch->call(GET => $db->_pathToDB('_shards'),
		introduced => '2.0.0',
		to_values  => \&__dbshards,
		$self->couch->_resultsConfig(\%args),
	);
}


sub __docshards($$)
{	my ($result, $data) = @_;
	my $values = +{ %$data };
	$values->{nodes} = [ $result->couch->listToPerl($values, node => delete $values->{nodes}) ];
	$values;
}

sub shardsForDoc($%)
{	my ($self, $doc, %args) = @_;
	my $db = $doc->db;

	$self->couch->call(GET => $db->_pathToDB('_shards/'.$doc->id),
		introduced => '2.0.0',
		to_values  => \&__docshards,
		$self->couch->_resultsConfig(\%args),
	);
}


sub syncShards($%)
{	my ($self, $db, %args) = @_;

	$self->couch->call(POST => $db->_pathToDB('_sync_shards'),
		introduced => '2.3.1',
		$self->couch->_resultsConfig(\%args),
	);
}

#-------------

1;
