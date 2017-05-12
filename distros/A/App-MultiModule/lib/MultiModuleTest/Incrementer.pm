package MultiModuleTest::Incrementer;
$MultiModuleTest::Incrementer::VERSION = '1.143160';
use strict;use warnings;
use Data::Dumper;

use parent 'App::MultiModule::Task';


=head2 message

=cut
sub message {
    my $self = shift;
    my $message = shift;
    $self->debug('Incrementer message: ' . Data::Dumper::Dumper $message) if $self->{debug};
    $message->{i} = $message->{i} + 1;
    $self->emit($message);
}

1;
