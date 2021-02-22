package Amazon::SNS::V4::Topic;

use strict;
use warnings;

our $VERSION = '2.0';
use base qw(Class::Accessor);

use JSON;

__PACKAGE__->mk_accessors(qw/ sns arn /);

sub Publish
{
	my ($self, $msg, $subj, $attr) = @_;

	# XXX croak on invalid arn

	my $structure = undef;
	my $attributes = undef;

	# support JSON payload
	if (ref($msg) eq 'HASH') {

		$structure = 'json';
		$msg = encode_json($msg);
	}

	if (defined($attr) and ref($attr) eq 'HASH') {

		my $i = 1;

		foreach my $key (keys %$attr) {

			$attributes->{"MessageAttributes.entry.$i.Name"} = $key;
			$attributes->{"MessageAttributes.entry.$i.Value.DataType"} = $attr->{$key}->{'Type'};

			if($attr->{$key}->{'Type'} eq 'Binary') {
				$attributes->{"MessageAttributes.entry.$i.Value.BinaryValue"} = $attr->{$key}->{'Value'};
			} else {
				$attributes->{"MessageAttributes.entry.$i.Value.StringValue"} = $attr->{$key}->{'Value'};
			}

			$i++;
		}
	}

	my $r = $self->sns->dispatch({
		'Action'		=> 'Publish',
		'TopicArn'		=> $self->arn,
		'Message'		=> $msg,
		'MessageStructure'	=> $structure,
		'Subject'		=> $subj,
		'Attributes'		=> $attributes,
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

