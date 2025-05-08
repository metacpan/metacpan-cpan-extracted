# Copyrights 2012-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Apache-Solr.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Apache::Solr::JSON;{
our $VERSION = '1.11';
}

use base 'Apache::Solr';

use warnings;
use strict;

use Log::Report          qw(solr);

use Apache::Solr::Result ();
use HTTP::Request        ();
use JSON                 ();
use Scalar::Util         qw(blessed);


sub init($)
{	my ($self, $args) = @_;
	$args->{format}   ||= 'JSON';
	$self->SUPER::init($args);

	$self->{ASJ_json} = $args->{json} || JSON->new->utf8;
	$self;
}

#---------------

sub json() {shift->{ASJ_json}}

#--------------------------

sub _select($$)
{	my ($self, $args, $params) = @_;

	# select may be called more than once, but do not add wt each time
	# again.
	my $endpoint = $self->endpoint('select', params => $params);
	my $result   = Apache::Solr::Result->new(%$args, params => $params, endpoint => $endpoint, core => $self);
	$self->request($endpoint, $result);

	if(my $dec = $result->decoded)
	{	# JSON uses different names!
		my $r = $dec->{result} = delete $dec->{response};
		$r->{doc} = delete $r->{docs};
	}
	$result;
}

sub _extract($$$)
{	my ($self, $params, $data, $ct) = @_;
	my $endpoint = $self->endpoint('update/extract', params => $params);
	my $result   = Apache::Solr::Result->new(params => $params, endpoint => $endpoint, core => $self);
	$self->request($endpoint, $result, $data, $ct);
	$result;
}

sub _add($$$)
{	my ($self, $docs, $attrs, $params) = @_;
	$attrs   ||= {};
	$params  ||= [];

	my $sv = $self->serverVersion;
	$sv ge '3.1' or error __x"Solr version too old for updates in JSON syntax";

	# We cannot create HASHes with twice the same key in Perl, so cannot
	# produce the syntax for adding multiple documents.  Try to save it.
	delete $attrs->{boost}
		if $attrs->{boost} && $attrs->{boost}==1.0;

	$params = +{ @$params } if ref $params eq 'ARRAY';
	exists $attrs->{$_} && ($params->{$_} = delete $attrs->{$_})
		for qw/commit commitWithin overwrite boost/;

	my $endpoint = $self->endpoint(($sv lt '4.0' ? 'update/json' : 'update'), params => $params);
	my $result   = Apache::Solr::Result->new(params => $params, endpoint => $endpoint, core => $self);

	my $add;
	if(@$docs==1)
	{	$add = +{ add => +{ %$attrs, doc => $self->_doc2json($docs->[0]) } }
	}
	elsif(keys %$attrs)
	{	# in combination with attributes only
		error __x"Unable to add more than one doc with JSON interface";
	}
	else
	{	$add = [ map $self->_doc2json($_), @$docs ];
	}

	$self->request($endpoint, $result, $add);
	$result;
}

sub _doc2json($)
{	my ($self, $this) = @_;
	my %doc;
	foreach my $fieldname ($this->fieldNames)
	{	my @f;
		foreach my $field ($this->fields($fieldname))
		{	my $update = $field->{update} || 'value';
			my $boost  = $field->{boost}  || 1.0;

			undef $boost
				if $boost > 0.9999 && $boost < 1.0001;

			push @f
			  , ! defined $boost && $update eq 'value'
			  ? $field->{content}
			  : defined $boost
			  ? +{ boost => $boost, $update => $field->{content} }
			  : +{ $update => $field->{content} };
		}
		# we have to combine multi-fields into ARRAYS
		$doc{$fieldname} = @f > 1 ? \@f : $f[0];
	}

	\%doc;
}

sub _commit($)   { my ($s, $attr) = @_; $s->simpleUpdate(commit   => $attr) }
sub _optimize($) { my ($s, $attr) = @_; $s->simpleUpdate(optimize => $attr) }
sub _delete($$)  { my $self = shift; $self->simpleUpdate(delete   => @_) }
sub _rollback()  { shift->simpleUpdate('rollback') }

sub _terms($)
{	my ($self, $terms) = @_;
	my $endpoint = $self->endpoint('terms', params => $terms);
	my $result   = Apache::Solr::Result->new(params => $terms, endpoint => $endpoint, core => $self);
	$self->request($endpoint, $result);

	my $table = $result->decoded->{terms} || {};
	$table    = {@$table} if ref $table eq 'ARRAY';  # bug in Solr 1.4

	while(my ($field, $terms) = each %$table)
	{	# repack array-of-pairs into array-of-arrays-of-pair
		my @pairs = @$terms;
		my @terms; 
		push @terms, [shift @pairs, shift @pairs] while @pairs;
		$result->terms($field => \@terms);
	}

	$result;
}

#--------------------------

sub request($$;$$)
{	my ($self, $url, $result, $body, $body_ct) = @_;

	if(ref $body && ref $body ne 'SCALAR')
	{	$body_ct ||= 'application/json; charset=utf-8';
		$body      = \$self->json->encode($body);
	}

	# Solr server 3.6.2 seems not to detect the JSON input from the
	# body content, so requires this work-around
	# https://solr.apache.org/guide/6_6/uploading-data-with-index-handlers.html#UploadingDatawithIndexHandlers-JSONUpdateConveniencePaths
	$url =~ s!/update\?!/update/json?!;

	$self->SUPER::request($url, $result, $body, $body_ct);
}

sub decodeResponse($)
{	my ($self, $resp) = @_;

	# At least until Solr 4.0 response ct=text/plain while producing JSON
	my $ct = $resp->content_type;
	$ct =~ m/json/i
		or error __x"Answer from solr server is not json but {type}", type => $ct;

	$self->json->decode($resp->decoded_content || $resp->content);
}


sub simpleUpdate($$;$)
{	my ($self, $command, $attrs, $content) = @_;
	my $sv       = $self->serverVersion;
	$sv ge '3.1' or error __x"Solr version too old for updates in JSON syntax";

	$attrs     ||= {};
	my $params   = [ commit => delete $attrs->{commit} ];
	my $endpoint = $self->endpoint(($sv lt '4.0' ? 'update/json' : 'update'), params => $params);
	my $result = Apache::Solr::Result->new(params => $params, endpoint => $endpoint, core => $self);
	my %params = (%$attrs, (!$content ? () : ref $content eq 'HASH' ? %$content : @$content));
	my $doc    = $self->simpleDocument($command, \%params);
	$self->request($endpoint, $result, $doc);
	$result;
}


sub simpleDocument($;$$)
{	my ($self, $command, $attrs, $content) = @_;
	$attrs   ||= {};
	$content ||= {};
	+{ $command => { %$attrs, %$content } }
}

sub endpoint($@)
{	my ($self, $action, %args) = @_;
	my $params = $args{params} ||= [];

	if(ref $params eq 'HASH') { $params->{wt} ||= 'json' }
	else { $args{params} = [ wt => 'json', @$params ] }

	$self->SUPER::endpoint($action, %args);
}

1;
