package Amazon::SNS::V4::Topic;

use strict;
use warnings;

our $VERSION = '1.7';
use base qw(Class::Accessor);

use JSON;

__PACKAGE__->mk_accessors(qw/ sns arn /);

sub Publish
{
	my ($self, $msg, $subj) = @_;

	# XXX croak on invalid arn

	my $structure = undef;

	# support JSON payload
	if (ref($msg) eq 'HASH') {

		$structure = 'json';
		$msg = encode_json($msg);
	}


	my $r = $self->sns->dispatch({
		'Action'		=> 'Publish',
		'TopicArn'		=> $self->arn,
		'Message'		=> $msg,
		'MessageStructure'	=> $structure,
		'Subject'		=> $subj,
	});

	# return message id on success, undef on error
	return $r ? $r->{'PublishResult'}{'MessageId'} : undef;
}

sub DeleteTopic
{
	my ($self) = @_;

	return $self->sns->DeleteTopic($self->arn);
}

1;

