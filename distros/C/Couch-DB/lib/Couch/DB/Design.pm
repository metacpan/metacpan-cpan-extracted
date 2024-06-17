# Copyrights 2024 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Design;
use vars '$VERSION';
$VERSION = '0.004';

use parent 'Couch::DB::Document';

use Couch::DB::Util;

use Log::Report 'couch-db';

use URI::Escape  qw/uri_escape/;
use Scalar::Util qw/blessed/;


#-------------

sub _pathToDoc(;$) { $_[0]->db->_pathToDB('_design/' . $_[0]->id) . (defined $_[1] ? '/' . uri_escape $_[1] : '')  }

#-------------

sub create($%)
{	my $self = shift;
	defined $self->id
		or error __x"Design documents do not generate an id by themselves.";
	$self->update(@_);
}


sub update($%)
{	my ($self, $data, $args) = @_;
	$self->couch
		->toJSON($data, bool => qw/autoupdate/)
		->check($data->{lists}, deprecated => '3.0.0', 'DesignDoc create() option list')
		->check($data->{lists}, removed    => '4.0.0', 'DesignDoc create() option list')
		->check($data->{show},  deprecated => '3.0.0', 'DesignDoc create() option show')
		->check($data->{show},  removed    => '4.0.0', 'DesignDoc create() option show')
		->check($data->{rewrites}, deprecated => '3.0.0', 'DesignDoc create() option rewrites');

	#XXX Do we need more parameter conversions in the nested queries?

	$self->SUPER::create($data, $args);
}


sub details(%)
{	my ($self, %args) = @_;

	$self->couch->call(GET => $self->_pathToDoc('_info'),
		$self->couch->_resultsConfig(\%args),
	);
}

#-------------

#-------------

sub createIndex($%)
{	my ($self, $filter, %args) = @_;
	$self->db->createIndex(%args, design => $self);
}


sub deleteIndex($%)
{	my ($self, $ddoc, $index, %args) = @_;
	$self->couch->call(DELETE => $self->db->_pathToDB('_index/' . uri_escape($self->id) . '/json/' . uri_escape($index)),
		$self->couch->_resultsConfig(\%args),
	);
}


sub __indexValues($$%)
{	my ($self, $result, $raw, %args) = @_;
	delete $args{full_docs} or return $raw;

	my $values = +{ %$raw };
	$values->{docs} = delete $values->{rows};
	$self->db->__toDocs($result, $values, db => $self->db);
	$values;
}

sub indexFind($%)
{	my ($self, $index, %args) = @_;
	my $couch = $self->couch;

	my $search  = delete $args{search} || {};
	my $query   = +{ %$search };

	# Everything into the query :-(  Why no POST version?
	$couch
		->toQuery($query, json => qw/counts drilldown group_sort highlight_fields include_fields ranges sort/)
		->toQuery($query, int  => qw/highlight_number highlight_size limit/)
		->toQuery($query, bool => qw/include_docs/);

	$couch->call(GET => $self->_pathToDDoc('_search/' . uri_escape $index),
		introduced => '3.0.0',
		query      => $query,
		$couch->_resultsPaging(\%args,
			on_values  => sub { $self->__indexValues($_[0], $_[1], db => $self->db, full_docs => $search->{include_docs}) },
		),
	);
}


sub indexDetails($%)
{	my ($self, $index, %args) = @_;

	$self->couch->call(GET => $self->_pathToDDoc('_search_info/' . uri_escape($index)),
		introduced => '3.0.0',
		$self->couch->_resultsConfig(\%args),
	);
}

#-------------

sub viewFind($;$%)
{	my ($self, $view, $search, %args) = @_;
	$self->db->listDocuments($search, view => $view, design => $self, %args);
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
