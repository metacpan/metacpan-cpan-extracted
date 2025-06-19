# Copyrights 2024-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Result;{
our $VERSION = '0.200';
}


use Couch::DB::Util     qw(flat pile);
use Couch::DB::Document ();
use Couch::DB::Row      ();

use Log::Report   'couch-db';
use HTTP::Status  qw(is_success status_constant_name HTTP_OK HTTP_CONTINUE HTTP_MULTIPLE_CHOICES);
use Scalar::Util  qw(weaken blessed);

my %couch_code_names   = ();   # I think I saw them somewhere.  Maybe none

my %default_code_texts = (  # do not construct them all the time again
	&HTTP_OK				=> 'Data collected successfully.',
	&HTTP_CONTINUE			=> 'The data collection is delayed.',
	&HTTP_MULTIPLE_CHOICES	=> 'The Result object does not know what to do, yet.',
);

my $seqnr = 0;


use overload
	bool     => sub { $_[0]->code < 400 },
	'""'     => 'short',
	fallback => 1;


sub new(@) { my ($class, %args) = @_; (bless {}, $class)->init(\%args) }

sub init($)
{	my ($self, $args) = @_;

	$self->{CDR_couch}     = delete $args->{couch} or panic;
	$self->{CDR_on_final}  = pile delete $args->{on_final};
	$self->{CDR_on_error}  = pile delete $args->{on_error};
	$self->{CDR_on_chain}  = pile delete $args->{on_chain};
	$self->{CDR_on_values} = pile delete $args->{on_values};
	$self->{CDR_on_row}    = pile delete $args->{on_row};
	$self->{CDR_code}      = HTTP_MULTIPLE_CHOICES;
	$self->{CDR_page}      = delete $args->{paging};
	$self->{CDR_seqnr}     = ++$seqnr;

	$self;
}

#-------------

sub couch()     { $_[0]->{CDR_couch}  }
sub isDelayed() { $_[0]->code == HTTP_CONTINUE }
sub isReady()   { $_[0]->{CDR_ready} }


sub code()      { $_[0]->{CDR_code} }


sub codeName(;$)
{	my ($self, $code) = @_;
	$code ||= $self->code;
	status_constant_name($code) || couch_code_names{$code} || $code;
}


sub message()
{	my $self = shift;
	$self->{CDR_msg} || $default_code_texts{$self->code} || $self->codeName;
}


sub setStatus($$)
{	my ($self, $code, $msg) = @_;
	$self->{CDR_code} = $code;
	$self->{CDR_msg}  = $msg;
	$self;
}


sub seqnr() { $_[0]->{CDR_seqnr} }


sub short()
{	my $self = shift;
	my $client = $self->client;
	my $req    = $self->request;

	$client && $req
	  ? (sprintf "RESULT %07d.%08d %-6s %s\n", $client->seqnr, $self->seqnr, $req->method, $req->url =~ s/\?.*/?.../r)
	  : (sprintf "RESULT prepare.%08d\n", $self->seqnr);
}

#-------------

sub client()    { $_[0]->{CDR_client} }
sub request()   { $_[0]->{CDR_request} }
sub response()  { $_[0]->{CDR_response} }


sub answer(%)
{	my ($self, %args) = @_;

	return $self->{CDR_answer}
		if defined $self->{CDR_answer};

 	$self->isReady
		or error __x"Document not ready: {err}", err => $self->message;

	$self->{CDR_answer} = $self->couch->_extractAnswer($self->response);
}


sub values(@)
{	my $self = shift;
	return $self->{CDR_values} if exists $self->{CDR_values};

	my $values = $self->answer;
	$values = $_->($self, $values) for reverse @{$self->{CDR_on_values}};
	$self->{CDR_values} = $values;
}

#-------------

sub rows(;$) { @{$_[0]->rowsRef($_[1])} }


sub rowsRef(;$)
{	my ($self, $qnr) = @_;

	! $self->inPagingMode
		or panic "Call used in paging mode, so use the page* methods.";

	$self->_rowsRef($qnr // 0);
}

sub _rowsRef($)
{	my ($self, $qnr) = @_;
	my $rows = $self->{CDR_rows}[$qnr] ||= [];
	return $rows if $self->{CDR_rows_complete}[$qnr];

	for(my $rownr = 1; $self->row($rownr, $qnr); $rownr++) { }
	$self->{CDR_rows_complete}[$qnr] = 1;
	$rows;
}


sub row($;$)
{	my ($self, $rownr, $qnr) = @_;
	my $rows  = $self->{CDR_rows}[$qnr //= 0] ||= [];
	my $index = $rownr -1;
	return $rows->[$index] if exists $rows->[$index];

	my %data = map $_->($self, $rownr-1, column => $qnr), reverse @{$self->{CDR_on_row}};
	keys %data or return ();

	my $doc;
	my $dp = delete $data{docparams} || {};
	if(my $dd = delete $data{docdata})
	{	$doc  = Couch::DB::Document->fromResult($self, $dd, %$dp);
	}
	elsif($dd = delete $data{ddocdata})
	{	$doc  = Couch::DB::Design->fromResult($self, $dd, %$dp);
	}

	my $row = Couch::DB::Row->new(%data, result => $self, rownr => $rownr, doc => $doc);
	$doc->row($row) if $doc;

	$rows->[$index] = $row;    # Remember partial result for rows()
}


sub numberOfRows(;$) { scalar @{$_[0]->rowsRef($_[1])} }


sub docs(;$) { map $_->doc, $_[0]->rows($_[1]) }


sub docsRef(;$) { [ map $_->doc, $_[0]->rows($_[1]) ] }


sub doc($;$)
{	my ($self, $rownr, $qnr) = @_;
	my $r = $self->row($rownr, $qnr);
	defined $r ? $r->doc : undef;
}

#-------------

sub pagingState(%)
{	my ($self, %args) = @_;
	my $next = $self->nextPageSettings;
	$next->{harvester} = defined $next->{harvester} ? 'CODE' : 'DEFAULT';
	$next->{map}       = defined $next->{map} ? 'CODE' : 'NONE';
	$next->{client}    = $self->client->name;

	if(my $maxbook = delete $args{max_bookmarks} // 10)
	{	my $bookmarks = $next->{bookmarks};
		$next->{bookmarks} = +{ (%$bookmarks)[0..(2*$maxbook-1)] } if keys %$bookmarks > $maxbook;
	}

	$next;
}


sub supportsPaging() { defined $_[0]->{CDR_page} }


sub inPagingMode() { my $r = $_[0]->{CDR_page}; $r && $r->{page_mode} }

# The next is used r/w when succeed is a result object, and when results
# have arrived.

sub _thisPage() { $_[0]->{CDR_page} or panic "Call does not support paging." }


sub nextPageSettings()
{	my $self = shift;
	my %next = %{$self->_thisPage};
	delete $next{harvested};
	$next{start} += (delete $next{skip}) + @{$self->_rowsRef(0)};
	$next{pagenr}++;
	\%next;
}


sub page()
{	my $self = shift;

	$self->inPagingMode
		or panic "Call not in paging mode, use the row* and doc* alternative methods.";

	$self->_thisPage->{harvested};
}

sub _pageAdd($$)
{	my ($self, $bookmark, $found) = @_;
	my $this = $self->_thisPage;
	my $page = $this->{harvested};
	push @$page, @$found;

	if(defined $bookmark)
	{	my $recv = $this->{start} + $this->{skip} + @$page;
		$this->{bookmarks}{$recv} = $bookmark;
	}

	$this->{end_reached} = ! @$found || $this->{stop}->($self);
	$page;
}


sub pageRows() { @{$_[0]->page} }


sub pageNumber() { $_[0]->_thisPage->{pagenr} }


sub pageDocs() { map $_->doc, @{$_[0]->page} }


sub pageDoc($) { my $r = $_[0]->page->[$_[1]-1]; defined $r ? $r->doc : undef }


sub pageIsPartial()
{	my $this = shift->_thisPage;
	     $this->{page_mode}
	  && ! $this->{end_reached}
	  && ($this->{all} || @{$this->{harvested}} < $this->{page_size});
}


sub isLastPage() { $_[0]->_thisPage->{end_reached} }

#-------------

sub setFinalResult($%)
{	my ($self, $data, %args) = @_;
	my $code = delete $data->{code} || HTTP_OK;

	$self->{CDR_client}   = my $client = delete $data->{client} or panic "No client";
	weaken $self->{CDR_client};

	$self->{CDR_ready}    = 1;
	$self->{CDR_request}  = delete $data->{request};
	$self->{CDR_response} = delete $data->{response};
	$self->setStatus($code, delete $data->{message});

	delete $self->{CDR_answer};  # remove cached while paging
	delete $self->{CDR_values};
	delete $self->{CDR_rows};

#warn "CODE=$code, $self";
	# "on_error" handler
	unless(is_success $code)
	{	$_->($self) for @{$self->{CDR_on_error}};
		return undef;
	}

	# "on_final" handler
	$_->($self) for @{$self->{CDR_on_final}};

	# "on_change" handler
	# First run inner chains, working towards outer
	my @chains = @{$self->{CDR_on_chain} || []};
	my $tail   = $self;

	while(@chains && $tail)
 	{	$tail = (pop @chains)->($tail);
		blessed $tail && $tail->isa('Couch::DB::Result')
			or panic "Chain must return a Result object";
	}

	$tail;
}


sub setResultDelayed($%)
{	my ($self, $plan, %args) = @_;

	$self->{CDR_delayed}  = $plan;
	$self->setStatus(HTTP_CONTINUE);
	$self;
}


sub delayPlan() { $_[0]->{CDR_delayed} }

#-------------

1;
