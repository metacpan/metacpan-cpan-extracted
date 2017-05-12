package MultiModuleTest::OtherModule;
$MultiModuleTest::OtherModule::VERSION = '1.143160';
use strict;use warnings;
use Message::Transform qw(mtransform);
use Data::Dumper;

use parent 'App::MultiModule::Task';


=head2 is_stateful

=cut
sub is_stateful {
    return 'yes!';
}

=head2 message

=cut
sub message {
    my $self = shift;
    my $message = shift;
    my $incr = $self->{config}->{increment_by};
    my $ct = $message->{ct};
    $message->{my_ct} = $ct + $incr;
    $message->{module_pid} = $$;
    $self->debug('OtherModule message: ' . Data::Dumper::Dumper $message) if $self->{debug};
    $self->{state}->{most_recent} = $message->{my_ct};
    if($self->{config}->{transform}) {
        mtransform $message, $self->{config}->{transform};
    }
    $self->emit($message);
}

1;
