
package DebugObject;

sub new {
	my $class = shift;
	return bless {messages => []}, $class;
}

sub print{
	my ($self, @messages) = @_;
	push @{$self->{messages}}, @messages;
}

sub clear{
	$_[0]->{messages} = [];
}

sub grep_messages{
	my ($self, $grep) = @_;
	return grep { $_ =~ qr/$grep/ } @{$self->{messages}};
}

sub get_messages{
	$_[0]->{messages};
}


sub count_messages{
	my ($self, $grep) = @_;
	return scalar( defined $grep ? $self->grep_messages($grep) : @{$self->get_messages});
}

1;
