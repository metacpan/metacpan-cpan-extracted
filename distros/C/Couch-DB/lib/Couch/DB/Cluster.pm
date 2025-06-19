# Copyrights 2024-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Cluster;{
our $VERSION = '0.200';
}


use Couch::DB::Util  qw/flat/;;

use Log::Report 'couch-db';

use Scalar::Util  qw(weaken);
use URI::Escape   qw(uri_escape);
use Storable      qw(dclone);


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


sub clusterSetup($%)
{	my ($self, $config, %args) = @_;

	$self->couch->toJSON($config, int => qw/port node_count/);
	
	$self->couch->call(POST => '/_cluster_setup',
		introduced => '2.0.0',
		send       => $config,
		$self->couch->_resultsConfig(\%args),
	);
}

#-------------

sub reshardStatus(%)
{	my ($self, %args) = @_;
	my $path = '/_reshard';
	$path   .= '/state' unless delete $args{counts};

	$self->couch->call(GET => $path,
		introduced => '2.4.0',
		$self->couch->_resultsConfig(\%args),
	);
}


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
{	my ($self, $couch, $job) = @_;

	$couch->toPerl($job, isotime => qw/start_time update_time/)
	      ->toPerl($job, node => qw/node/);

	$couch->toPerl($_, isotime => qw/timestamp/)
		for @{$job->{history} || []};
}

sub __reshardJobsValues($$)
{	my ($self, $result, $data) = @_;
	my $couch  = $result->couch;

	my $values = dclone $data;
	$self->__jobValues($couch, $_) for @{$values->{jobs} || []};
	$values;
}

sub reshardJobs(%)
{	my ($self, %args) = @_;

	$self->couch->call(GET => '/_reshard/jobs',
		introduced => '2.4.0',
		$self->couch->_resultsConfig(\%args,
			on_values => sub { $self->__reshardJobsValues(@_) },
		),
	);
}


sub __reshardStartValues($$)
{	my ($self, $result, $data) = @_;
	my $values = dclone $data;
	$result->couch->toPerl($_, node => 'node')
		for @$values;

	$values;
}

sub reshardStart($%)
{	my ($self, $create, %args) = @_;

	$self->couch->call(POST => '/_reshard/jobs',
		introduced => '2.4.0',
		send       => $create,
		$self->couch->_resultsConfig(\%args,
			on_values => sub { $self->__reshardStartValues(@_) },
		),
	);
}


sub __reshardJobValues($$)
{	my ($self, $result, $data) = @_;
	my $couch  = $result->couch;

	my $values = dclone $data;
	$self->__jobValues($couch, $values);
	$values;
}

sub reshardJob($%)
{	my ($self, $jobid, %args) = @_;

	$self->couch->call(GET => "/_reshard/jobs/$jobid",
		introduced => '2.4.0',
		$self->couch->_resultsConfig(\%args,
			on_values => sub { $self->__reshardJobValues(@_) }),
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
{	my ($self, $result, $data) = @_;
	my $couch  = $result->couch;

	my %values = %$data;
	my $shards = delete $values{shards} || {};
	$values{shards} = [ map +($_ => $couch->listToPerl($_, node => $shards->{$_}) ), keys %$shards ];
	\%values;
}

sub shardsForDB($%)
{	my ($self, $db, %args) = @_;

	$self->couch->call(GET => $db->_pathToDB('_shards'),
		introduced => '2.0.0',
		$self->couch->_resultsConfig(\%args,
			on_values => sub { $self->__dbshards(@_) },
		),
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
		$self->couch->_resultsConfig(\%args,
			on_values => sub { $self->__docshards(@_) },
		),
	);
}


sub syncShards($%)
{	my ($self, $db, %args) = @_;

	$self->couch->call(POST => $db->_pathToDB('_sync_shards'),
		send => {},
		introduced => '2.3.1',
		$self->couch->_resultsConfig(\%args),
	);
}

1;
