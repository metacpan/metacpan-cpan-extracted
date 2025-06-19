# Copyrights 2024-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Design;{
our $VERSION = '0.200';
}

use parent 'Couch::DB::Document';

use Couch::DB::Util;

use Log::Report 'couch-db';

use URI::Escape  qw/uri_escape/;
use Scalar::Util qw/blessed/;

my $id_generator;


sub init($)
{	my ($self, $args) = @_;
	my $which = $args->{id} || $id_generator->($args->{db} or panic);
	my ($id, $base) = $which =~ m!^_design/(.*)! ? ($which, $1) : ("_design/$which", $which);
	$args->{id} = $id;

	$self->SUPER::init($args);
	$self->{CDD_base} = $base;
	$self;
}

#-------------

$id_generator = sub ($) { $_[0]->couch->freshUUID };
sub setIdGenerator($) { $id_generator = $_[1] }


sub idBase() { $_[0]->{CDD_base} }

#-------------

sub create($%)
{	my $self = shift;
	$self->update(@_);
}


sub update($%)
{	my ($self, $data, %args) = @_;
	$data->{_id} = $self->id;

	$self->couch
		->toJSON($data, bool => qw/autoupdate/)
		->check($data->{lists}, deprecated => '3.0.0', 'DesignDoc create() option list')
		->check($data->{lists}, removed    => '4.0.0', 'DesignDoc create() option list')
		->check($data->{show},  deprecated => '3.0.0', 'DesignDoc create() option show')
		->check($data->{show},  removed    => '4.0.0', 'DesignDoc create() option show')
		->check($data->{rewrites}, deprecated => '3.0.0', 'DesignDoc create() option rewrites');

	#XXX Do we need more parameter conversions in the nested queries?

	$self->SUPER::create($data, %args);
}

# get/delete/etc. are simply produced by extension of the _pathToDoc() which
# adds "_design/" to the front of the path.

sub details(%)
{	my ($self, %args) = @_;

	$self->couch->call(GET => $self->_pathToDoc('_info'),
		$self->couch->_resultsConfig(\%args),
	);
}

#-------------

#-------------

sub createIndex($%)
{	my ($self, $config, %args) = @_;

	my $send  = +{ %$config, ddoc => $self->id };
	my $couch = $self->couch;
	$couch->toJSON($send, bool => qw/partitioned/);

	$couch->call(POST => $self->db->_pathToDB('_index'),
		send => $send,
		$couch->_resultsConfig(\%args),
	);
}


sub deleteIndex($%)
{	my ($self, $ddoc, $index, %args) = @_;
	my $id = $self->idBase;  # id() would also work
	$self->couch->call(DELETE => $self->db->_pathToDB("_index/$id/json/" . uri_escape($index)),
		$self->couch->_resultsConfig(\%args),
	);
}


sub __searchRow($$$%)
{	my ($self, $result, $index, $column, %args) = @_;
	my $answer = $result->answer->{rows}[$index] or return ();
	my $values = $result->values->{rows}[$index];

	  (	answer    => $answer,
		values    => $values,
		docdata   => $args{full_docs} ? $values : undef,
		docparams => { db => $self },
	  );
}

sub search($$%)
{	my ($self, $index, $search, %args) = @_;
	my $query = defined $search ? +{ %$search } : {};

	# Everything into the query :-(  Why no POST version?
	my $couch = $self->couch;
	$couch
		->toQuery($query, json => qw/counts drilldown group_sort highlight_fields include_fields ranges sort/)
		->toQuery($query, int  => qw/highlight_number highlight_size limit/)
		->toQuery($query, bool => qw/include_docs/);

	$couch->call(GET => $self->_pathToDoc('_search/' . uri_escape $index),
		introduced => '3.0.0',
		query      => $query,
		$couch->_resultsPaging(\%args,
			on_row => sub { $self->__searchRow(@_, full_docs => $search->{include_docs}) },
		),
	);
}


sub indexDetails($%)
{	my ($self, $index, %args) = @_;

	$self->couch->call(GET => $self->_pathToDoc('_search_info/' . uri_escape($index)),
		introduced => '3.0.0',
		$self->couch->_resultsConfig(\%args),
	);
}

#-------------

sub viewDocs($;$%)
{	my ($self, $view, $search, %args) = @_;
	$self->db->allDocs($search, view => $view, design => $self, %args);
}

#-------------

sub show($;$%)
{	my ($self, $function, $doc, %args) = @_;
	my $path = $self->_pathToDoc('_show/'.uri_escape($function));
	$path .= '/' . (blessed $doc ? $doc->id : $doc) if defined $doc;

	$self->couch->call(GET => $path,
		deprecated => '3.0.0',
		removed    => '4.0.0',
		$self->couch->_resultsConfig(\%args),
	);
}


sub list($$%)
{	my ($self, $function, $view, %args) = @_;

	my $other = defined $args{view_ddoc} ? '/'.delete $args{view_ddoc} : '';
	my $path = $self->_pathToDoc('_list/' . uri_escape($function) . $other . '/' . uri_escape($view));

	$self->couch->call(GET => $path,
		deprecated => '3.0.0',
		removed    => '4.0.0',
		$self->couch->_resultsConfig(\%args),
	);
}


#XXX The 3.3.3 doc says /{docid} version requires PUT, but shows a POST example.
#XXX The 3.3.3post4 docs make the example patch with PUT.
#XXX The code probably says: anything except GET is okay.

sub applyUpdate($%)
{	my ($self, $function, $doc, %args) = @_;
	my $path = $self->_pathToDoc('_update/'.uri_escape($function));
	$path .= '/' . (blessed $doc ? $doc->id : $doc) if defined $doc;

	$self->couch->call(POST => $path,
		deprecated => '3.0.0',
		removed    => '4.0.0',
		send       => { },
		$self->couch->_resultsConfig(\%args),
	);
}

# [CouchDB API "ANY /{db}/_design/{ddoc}/_rewrite/{path}", deprecated 3.0, removed 4.0, UNSUPPORTED]
# The documentation of this method is really bad, and you probably should do this in your programming
# language anyway.

1;
