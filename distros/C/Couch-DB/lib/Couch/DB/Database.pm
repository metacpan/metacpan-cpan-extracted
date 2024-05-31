# Copyrights 2024 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Database;
use vars '$VERSION';
$VERSION = '0.002';


use Log::Report 'couch-db';

use Couch::DB::Util   qw(flat);

use Scalar::Util      qw(weaken blessed);
use HTTP::Status      qw(HTTP_OK HTTP_NOT_FOUND);


sub new(@) { my ($class, %args) = @_; (bless {}, $class)->init(\%args) }

sub init($)
{	my ($self, $args) = @_;

	my $name = $self->{CDD_name} = delete $args->{name} or panic "Requires name";
	$name =~ m!^[a-z][a-z0-9_$()+/-]*$!
		or error __x"Illegal database name '{name}'.", name => $name;

	$self->{CDD_couch} = delete $args->{couch} or panic "Requires couch";
	weaken $self->{CDD_couch};

	$self->{CDD_batch} = delete $args->{batch};
	$self;
}

#-------------

sub name()  { $_[0]->{CDD_name} }
sub couch() { $_[0]->{CDD_couch} }
sub batch() { $_[0]->{CDD_batch} }

sub _pathToDB(;$) { '/' . $_[0]->name . (defined $_[1] ? '/' . $_[1] : '') }

#-------------

sub ping(%)
{	my ($self, %args) = @_;

	$self->couch->call(HEAD => $self->_pathToDB,
		$self->couch->_resultsConfig(\%args),
	);
}


sub exists()
{	my $self = shift;
	my $result = $self->ping(_delay => 0);
	  $result->code eq HTTP_NOT_FOUND ? 0
    : $result->code eq HTTP_OK        ? 1
	:                                   undef;  # will probably die in the next step
}


sub __detailsValues($$)
{	my ($result, $raw) = @_;
	my $couch = $result->couch;
	my %values = %$raw;   # deep not needed;
	$couch->toPerl(\%values, epoch => qw/instance_start_time/);
	\%values;
}

sub details(%)
{	my ($self, %args) = @_;
	my $part = delete $args{partition};

	#XXX Value instance_start_time is now always zero, useful to convert if not
	#XXX zero in old nodes?

	$self->couch->call(GET => $self->_pathToDB($part ? '_partition/'.uri_escape($part) : undef),
		to_values  => \&__detailsValues,
		$self->couch->_resultsConfig(\%args),
	);
}


sub create(%)
{	my ($self, %args) = @_;
	my $couch = $self->couch;

	my %query;
	exists $args{$_} && ($query{$_} = delete $args{$_})
		for qw/partitioned q n/;
	$couch->toQuery(\%query, bool => qw/partitioned/);
	$couch->toQuery(\%query, int  => qw/q n/);

	$couch->call(PUT => $self->_pathToDB,
		query => \%query,
		send  => { },
		$self->couch->_resultsConfig(\%args),
	);
}


sub remove(%)
{	my ($self, %args) = @_;

	$self->couch->call(DELETE => $self->_pathToDB,
		$self->couch->_resultsConfig(\%args),
	);
}


sub userRoles(%)
{	my ($self, %args) = @_;

	$self->couch->call(GET => $self->_pathToDB('_security'),
		$self->couch->_resultsConfig(\%args),
	);
}


sub userRolesChange(%)
{	my ($self, %args) = @_;
	my %send  = (
		admin   => delete $args{admin}   || [],
		members => delete $args{members} || [],
	);

	$self->couch->call(PUT => $self->_pathToDB('_security'),
		send  => \%send,
		$self->couch->_resultsConfig(\%args),
	);
}


sub changes { ... }


sub compact(%)
{	my ($self, %args) = @_;
	my $path = $self->_pathToDB('_compact');

	if(my $ddoc = delete $args{ddoc})
	{	$path .= '/' . $ddoc->id;
	}

	$self->couch->call(POST => $path,
		send  => { },
		$self->couch->_resultsConfig(\%args),
	);
}


sub __ensure($$)
{	my ($result, $raw) = @_;
	return $raw unless $raw->{instance_start_time};  # exists && !=0
	my $v = { %$raw };
	$result->couch->toPerl($v, epoch => qw/instance_start_time/);
	$v;
}

sub ensureFullCommit(%)
{	my ($self, %args) = @_;

	$self->couch->call(POST => $self->_pathToDB('_ensure_full_commit'),
		deprecated => '3.0.0',
		send       => { },
		to_values  => \&__ensure,
		$self->couch->_resultsConfig(\%args),
	);
}


sub purgeDocuments($%)
{	my ($self, $plan, %args) = @_;

	#XXX looking for smarter behavior here, to construct a plan.
	my $send = $plan;

	$self->couch->call(POST => $self->_pathToDB('_purge'),
		$self->couch->_resultsConfig(\%args),
	);
}


#XXX seems not really a useful method.

sub purgeRecordsLimit(%)
{	my ($self, %args) = @_;

	$self->couch->call(GET => $self->_pathToDB('_purged_infos_limit'),
		$self->couch->_resultsConfig(\%args),
	);
}


#XXX attribute of database creation

sub purgeRecordsLimitSet($%)
{	my ($self, $value, %args) = @_;

	$self->couch->call(PUT => $self->_pathToDB('_purged_infos_limit'),
		send => int($value),
		$self->couch->_resultsConfig(\%args),
	);
}


sub purgeUnusedViews(%)
{	my ($self, %args) = @_;

	#XXX nothing to send?
	$self->couch->call(POST => $self->_pathToDB('_view_cleanup'),
		$self->couch->_resultsConfig(\%args),
	);
}


sub revisionsMissing($%)
{	my ($self, $plan, %args) = @_;

	#XXX needs extra features
	$self->couch->call(POST => $self->_pathToDB('_missing_revs'),
		send => $plan,
		$self->couch->_resultsConfig(\%args),
	);
}


sub revisionsDiff($%)
{	my ($self, $plan, %args) = @_;

	#XXX needs extra features
	$self->couch->call(POST => $self->_pathToDB('_revs_diff'),
		send => $plan,
		$self->couch->_resultsConfig(\%args),
	);
}


#XXX seems not really a useful method.

sub revisionLimit(%)
{	my ($self, %args) = @_;

	$self->couch->call(GET => $self->_pathToDB('_revs_limit'),
		$self->couch->_resultsConfig(\%args),
	);
}


#XXX attribute of database creation

sub revisionLimitSet($%)
{	my ($self, $value, %args) = @_;

	$self->couch->call(PUT => $self->_pathToDB('_revs_limit'),
		send => int($value),
		$self->couch->_resultsConfig(\%args),
	);
}

#-------------

sub listDesigns(%)
{	my ($self, %args) = @_;
	my $couch   = $self->couch;

	my ($method, $path, $send) = (GET => $self->_pathToDB('_design_docs'), undef);
	if(my @search  = flat delete $args{search})
	{	$method = 'POST';
	 	my @s   = map $self->_designPrepare($method, $_), @search;

		if(@search==1)
		{	$send  = $search[0];
		}
		else
		{	$send  = +{ queries => \@search };
			$path .= '/queries';
		}
	}

	$self->couch->call($method => $path,
		($send ? (send => $send) : ()),
		$couch->_resultsConfig(\%args),
	);
}


sub _designPrepare($$$)
{	my ($self, $method, $data, $where) = @_;
	$method eq 'POST' or panic;
	my $s     = +{ %$data };

	# Very close to a view search, but not equivalent.  At least: according to the
	# API documentation :-(
	$self->couch
		->toJSON($s, bool => qw/conflicts descending include_docs inclusive_end update_seq/)
		->toJSON($s, int  => qw/limit skip/);
	$s;
}


sub createIndex($%)
{	my ($self, $filter, %args) = @_;
	my $couch  = $self->couch;

	my $send   = +{ %$filter };
	if(my $design = delete $args{design})
	{	$send->{ddoc} = blessed $design ? $design->id : $design;
	}

	$couch->toJSON($send, bool => qw/partitioned/);

	$couch->call(POST => $self->_pathToDB('_index'),
		send => $send,
		$couch->_resultsConfig(\%args),
	);
}


sub listIndexes(%)
{	my ($self, %args) = @_;

	$self->couch->call(GET => $self->_pathToDB('_index'),
		$self->couch->_resultsConfig(\%args),
	);
}

#-------------

sub doc($%)
{	my ($self, $id) = @_;
	Couch::DB::Document->new(id => $id, db => $self, @_);
}


sub __updated($$$$)
{	my ($self, $result, $saves, $deletes, $on_error) = @_;
	$result or return;

	my %saves   = map +($_->id => $_), @$saves;
	my %deletes = map +($_->id => $_), @$deletes;

	foreach my $report (@{$result->values})
	{	my $id     = $report->{id};
		my $delete = exists $deletes{$id};
		my $doc    = delete $deletes{$id} || delete $saves{$id}
			or panic "missing report for updated $id";

		if($report->{ok})
		{	$doc->saved($id, $report->{rev});
			$doc->deleted if $delete;
		}
		else
		{	$on_error->($result, $doc, +{ %$report, delete => $delete });
		}
	}

	$on_error->($result, $saves{$_},
		+{ error => 'missing', reason => "The server did not report back on saving $_." }
	) for keys %saves;

	$on_error->($result, $deletes{$_},
		+{ error => 'missing', reason => "The server did not report back on deleting $_.", delete => 1 }
	) for keys %deletes;
}

sub updateDocuments($%)
{	my ($self, $docs, %args) = @_;
	my $couch   = $self->couch;

	my @plan    = map $_->data, @$docs;
	my @deletes = flat delete $args{delete};

	foreach my $del (@deletes)
	{	push @plan, +{ _id => $del->id, _rev => $del->rev, _delete => 1 };
		$couch->toJSON($plan[-1], bool => qw/_delete/);
	}

	@plan or error __x"need at least on document for bulk processing.";
	my $send    = +{ docs => \@plan };

	$send->{new_edits} = delete $args{new_edits} if exists $args{new_edits};
	$couch->toJSON($send, bool => qw/new_edits/);

	$couch->call(POST => $self->_pathToDB('_bulk_docs'),
		send     => $send,
		$couch->_resultsConfig(\%args,
			on_final => sub { $self->_updated($_[0], $docs, \@deletes) },
		),
	);
}


sub inspectDocuments($%)
{	my ($self, $docs, %args) = @_;
	my $couch = $self->couch;

	my $query;
	$query->{revs} = delete $args{revs} if exists $args{revs};
	$couch->toQuery($query, bool => qw/revs/);

	@$docs or error __x"need at least on document for bulk query.";

	#XXX what does "conflicted documents mean?
	#XXX what does "a": 1 mean in its response?

	$self->couch->call(POST =>  $self->_pathToDB('_bulk_get'),
		query => $query,
		send  => { docs => $docs },
		$couch->_resultsConfig(\%args),
	);
}


sub __toDocs($$%)
{	my ($self, $result, $data, %args) = @_;
	my @docs = flat $data->{docs};
	$data->{docs} = [ map Couch::DB::Document->_fromResponse($result, $_, %args), @docs ] if @docs;
	$data;
}

sub __listValues($$%)
{	my ($self, $result, $raw, %args) = @_;
	$args{db}  = $self;
	my $values = +{ %$raw };

	if(my $multi = $values->{results})
	{	# Multiple queries, multiple answers
		$values->{results} = [ map $self->__toDocs($result, +{ %$_ }, %args), flat $multi ];
	}
	else
	{	# Single query
		$self->__toDocs($result, $values, %args);
	}

	$values;
}

sub listDocuments(%)
{	my ($self, %args) = @_;
	my $couch  = $self->couch;

	my @search = flat delete $args{search};
	my $part   = delete $args{partition};
	my $local  = delete $args{local};
	my $view   = delete $args{view};
	my $ddoc   = delete $args{ddoc};
	my $ddocid = blessed $ddoc ? $ddoc->id : $ddoc;

	!$view  || $ddoc  or panic "listDocuments(view) requires design document.";
	!$local || !$part or panic "listDocuments(local) cannot be combined with partition.";
	!$local || !$view or panic "listDocuments(local) cannot be combined with a view.";
	!$part  || @search < 2 or panic "listDocuments(partition) cannot work with multiple searches.";

	my $set
	  = $local ? '_local_docs'
	  :   ($part ? '_partition/'. uri_escape($part) . '/' : '')
        . ($view ? "_design/$ddocid/_view/". uri_escape($view) : '_all_docs');

	my $method = !@search || $part ? 'GET' : 'POST';
	my $path   = $self->_pathToDB($set);

	# According to the spec, _all_docs is just a special view.
	my @send   = map $self->_viewPrepare($method, $_, "listDocuments search"), @search;
		
	my @params;
	if($method eq 'GET')
	{	@send < 2 or panic "Only one search with listDocuments(GET)";
		@params = (query => $send[0]);
	}
	elsif(@send==1)
	{	@params = (send  => $send[0]);
	}
	else
	{	$couch->check(1, introduced => '2.2.0', 'Bulk queries');
		@params = (send => +{ queries => \@send });
		$path .= '/queries';
	}

	$couch->call($method => $path,
		@params,
		to_values => sub { $self->__listValues($_[0], $_[1], local => $local) },
		$couch->_resultsConfig(\%args),
	);
}

my @search_bools = qw/
	conflicts descending group include_docs attachments att_encoding_info
	inclusive_end reducs sorted stable update_seq
	/;

# Handles standard view/_all_docs/_local_docs queries.
sub _viewPrepare($$$)
{	my ($self, $method, $data, $where) = @_;
	my $s     = +{ %$data };
	my $couch = $self->couch;

	# Main doc in 1.5.4.  /{db}/_design/{ddoc}/_view/{view}
	if($method eq 'GET')
	{	$couch
			->toQuery($s, bool => \@search_bools)
			->toQuery($s, json => qw/endkey end_key key keys start_key startkey/);
	}
	else
	{	$couch
			->toJSON($s, bool => \@search_bools)
			->toJSON($s, int  => qw/group_level limit skip/);
	}

	$couch
		->check($s->{attachments}, introduced => '1.6.0', 'Search attribute "attachments"')
		->check($s->{att_encoding_info}, introduced => '1.6.0', 'Search attribute "att_encoding_info"')
		->check($s->{sorted}, introduced => '2.0.0', 'Search attribute "sorted"')
		->check($s->{stable}, introduced => '2.1.0', 'Search attribute "stable"')
		->check($s->{update}, introduced => '2.1.0', 'Search attribute "update"');

	$s;
}


sub __findValues($$)
{	my ($self, $result, $raw) = @_;
	$self->__toDocs($result, +{ %$raw }, db => $self);
}

sub find($%)
{	my ($self, $search, %args) = @_;
	my $part   = delete $args{partition};
	$search->{selector} ||= {};

	my $path   = $self->_pathToDB;
	$path     .= '/_partition/'. uri_espace($part) if $part;

	$self->couch->call(POST => "$path/_find",
		send      => $self->_findPrepare(POST => $search),
		paginate  => 1,
		to_values => sub { $self->__findValues(@_) },
		$self->couch->_resultsConfig(\%args),
	);
}

sub _findPrepare($$)
{	my ($self, $method, $data, $where) = @_;
	my $s = +{ %$data };  # no nesting

	$method eq 'POST' or panic;

	$self->couch
		->toJSON($s, bool => qw/conflicts update stable execution_stats/)
		->toJSON($s, int  => qw/limit sip r/)
		#XXX Undocumented when this got deprecated
		->check(exists $s->{stale}, deprecated => '3.0.0', 'Database find(stale)');

	$s;
}


sub findExplain(%)
{	my ($self, $search, %args) = @_;
	my $part = delete $args{partition};
	$search->{selector} ||= {};

	my $path  = $self->_pathToDB;
	$path    .= '/_partition/' . uri_escape($part) if $part;

	$self->couch->call(POST => "$path/_explain",
		send => $self->_findPrepare(POST => $search),
		$self->couch->_resultsConfig(\%args),
	);
}

1;
