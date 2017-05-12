package Apache::Action::DesignDB::Feedback;

use strict;
use vars qw(@ISA);
use Apache::Action;
use Apache::Constants qw(:response);

@ISA = qw(Apache::Action);

__PACKAGE__->register('DesignDB', 'Feedback',
				create	=> \&create,
				respond	=> \&respond,
					);

sub create {
	my ($self) = @_;

	my $args = $self->params;

	$args->{user} = $self->session('user_id');
	$args->{category} = $self->session('category_id') || 1;
	$args->{pattern} = $self->session('pattern_id');
	$args->{submitted} = time();
	$args->{answered} = 0;
	$args->{response} = '';

	if ($args->{errorinclude}) {
		$args->{request} = "Automatically included error message:\n" .
				$args->{errormessage} . "\n--\n" .
				$args->{request}
	}

	my $ob = Anarres::DesignDB::Feedback->http_create($args);
	$self->session('feedback_id', $ob->id);
	return OK;
}

sub respond {
	my ($self) = @_;

	unless ($self->state->user) {
		$self->error("Please log in first.");
		return FORBIDDEN;
	}

	unless ($self->state->user->admin) {
		$self->error("Only administrators may respond to feedback.");
		return FORBIDDEN;
	}

	my $ob = retrieve Anarres::DesignDB::Feedback($self->param('feedback'));
	unless ($ob) {
		$self->error("No such feedback item.");
		return NOT_FOUND;
	}

	$ob->response($self->param('response'));
	$ob->answered(time());
	$ob->commit;
	return OK;
}

1;
