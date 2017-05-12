package Business::MollieAPI::TestLog;
use Moo::Role;

has log_response_called => (is => 'rw', default => 0);

has log_response_message => (is => 'rw');

after log_response => sub {
    my ($self, $log) = @_;
    $self->log_response_called($self->log_response_called+1);
    $self->log_response_message($log);
    return;
};


1;
