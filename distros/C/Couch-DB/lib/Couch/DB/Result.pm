# Copyrights 2024 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Result;
use vars '$VERSION';
$VERSION = '0.004';


use Couch::DB::Util     qw(flat pile);
use Couch::DB::Document ();

use Log::Report   'couch-db';
use HTTP::Status  qw(is_success status_constant_name HTTP_OK HTTP_CONTINUE HTTP_MULTIPLE_CHOICES);
use Scalar::Util  qw(weaken blessed);

my %couch_code_names   = ();   # I think I saw them somewhere.  Maybe none

my %default_code_texts = (  # do not construct them all the time again
	&HTTP_OK				=> 'Data collected successfully.',
	&HTTP_CONTINUE			=> 'The data collection is delayed.',
	&HTTP_MULTIPLE_CHOICES	=> 'The Result object does not know what to do, yet.',
);


use overload
	bool => sub { $_[0]->code < 400 };


sub new(@) { my ($class, %args) = @_; (bless {}, $class)->init(\%args) }

sub init($)
{	my ($self, $args) = @_;

	$self->{CDR_couch}     = delete $args->{couch} or panic;
	weaken $self->{CDR_couch};

	$self->{CDR_on_final}  = pile delete $args->{on_final};
	$self->{CDR_on_error}  = pile delete $args->{on_error};
	$self->{CDR_on_chain}  = pile delete $args->{on_chain};
	$self->{CDR_on_values} = pile delete $args->{on_values};
	$self->{CDR_code}      = HTTP_MULTIPLE_CHOICES;
	$self->{CDR_page}      = delete $args->{paging};

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


sub status($$)
{	my ($self, $code, $msg) = @_;
	$self->{CDR_code} = $code;
	$self->{CDR_msg}  = $msg;
	$self;
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

	$self->{CDR_answer} = $self->couch->_extractAnswer($self->response),
}


sub values(@)
{	my $self = shift;
	return $self->{CDR_values} if exists $self->{CDR_values};

	my $values = $self->answer;
	$values = $_->($self, $values) for reverse @{$self->{CDR_on_values}};
	$self->{CDR_values} = $values;
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

# The next is used r/w when _succeed is a result object, and when results
# have arrived.

sub _thisPage() { $_[0]->{CDR_page} or panic "Call does not support paging." }


sub nextPageSettings()
{	my $self = shift;
	my %next = %{$self->_thisPage};
	delete $next{harvested};
	$next{start} += (delete $next{skip}) + @{$self->page};
#use Data::Dumper;
#warn "NEXT PAGE=", Dumper \%next;
	\%next;
}


sub page() { $_[0]->_thisPage->{harvested} }

sub _pageAdd($@)
{	my $this     = shift->_thisPage;
	my $bookmark = shift;
	my $page     = $this->{harvested};
	if(@_)
	{	push @$page, @_;
		$this->{bookmarks}{$this->{start} + $this->{skip} + @$page} = $bookmark
			if defined $bookmark;
	}
	else
	{	$this->{end_reached} = 1;
	}
	$page;
}


sub pageIsPartial()
{	my $this = shift->_thisPage;
	! $this->{end_reached} && ($this->{all} || @{$this->{harvested}} < $this->{page_size});
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
	$self->status($code, delete $data->{message});

	delete $self->{CDR_answer};  # remove cached while paging
	delete $self->{CDR_values};

	# "on_error" handler
	unless(is_success $code)
	{	$_->($self) for @{$self->{CDR_on_error}};
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
	$self->status(HTTP_CONTINUE);
	$self;
}


sub delayPlan() { $_[0]->{CDR_delayed} }

#-------------

1;
