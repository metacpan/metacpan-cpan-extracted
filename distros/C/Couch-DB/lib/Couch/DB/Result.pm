# Copyrights 2024 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Result;
use vars '$VERSION';
$VERSION = '0.002';


use Couch::DB::Util     qw(flat);
use Couch::DB::Document ();

use Log::Report   'couch-db';
use HTTP::Status  qw(is_success status_constant_name HTTP_OK HTTP_CONTINUE HTTP_MULTIPLE_CHOICES);
use Scalar::Util  qw(weaken);

my %couch_code_names   = ();   # I think I saw them somewhere.  Maybe none

my %default_code_texts = (  # do not construct them all the time again
	HTTP_OK					=> 'Data collected successfully.',
	HTTP_CONTINUE			=> 'The data collection is delayed.',
	HTTP_MULTIPLE_CHOICES	=> 'The Result object does not know what to do, yet.',
);


use overload
	bool => sub { $_[0]->code < 400 };


sub new(@) { my ($class, %args) = @_; (bless {}, $class)->init(\%args) }

sub init($)
{	my ($self, $args) = @_;

	$self->{CDR_couch}     = delete $args->{couch} or panic;
	weaken $self->{CDR_couch};

	$self->{CDR_on_final}  = [ flat delete $args->{on_final} ];
	$self->{CDR_on_error}  = [ flat delete $args->{on_error} ];
	$self->{CDR_code}      = HTTP_MULTIPLE_CHOICES;
	$self->{CDR_to_values} = delete $args->{to_values} || sub { $_[1] };
	$self->{CDR_next}      = delete $args->{next};
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


sub next()      { $_[0]->{CDR_next} }


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
	$self->{CDR_values} ||= $self->{CDR_to_values}->($self, $self->answer);
}


sub nextPage(%)
{	my ($self, %options) = @_;

	$self->isReady
		or panic "The results are not available yet, not ready.";

	my $next     = $self->next
		or panic "This call does not support pagination.";

	$self
		or error __x"The previous page had an error";

	$self->couch->call($next);
}

#-------------

sub setFinalResult($%)
{	my ($self, $data, %args) = @_;
	my $code = delete $data->{code} || HTTP_OK;

	$self->{CDR_client}   = my $client = delete $data->{client} or panic "No client";
	weaken $self->{CDR_client};

	$self->{CDR_request}  = delete $data->{request};
	$self->{CDR_response} = delete $data->{response};
	$self->status($code, delete $data->{message});
	$self->{CDR_ready}    = 1;

	$_->($self) for @{$self->{CDR_on_final}};

	if(is_success $code)
	{	if(my $next = $self->next)
		{	$next->{client}   = $client->name;   # no objects!
			$next->{bookmark} = $self->answer->{bookmark};
		}
	}
	else
	{	$_->($self) for @{$self->{CDR_on_error}};
		#XXX what to do with pagination here?
	}

	$self;
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
