package MultiModuleTest::StatelessProducer;
$MultiModuleTest::StatelessProducer::VERSION = '1.143160';
use strict;use warnings;
use Data::Dumper;
use Message::Transform qw(mtransform);

use parent 'App::MultiModule::Task';


=head2 message

=cut
sub message {
    my $self = shift;
    my $message = shift;
    $self->debug('StatelessProducer message: ' . Data::Dumper::Dumper $message) if $self->{debug};
#    $self->emit($message);
}

=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
    $self->debug('OtherModule: set_config') if $self->{debug};

    my $emit_rate = $config->{emit_rate} || 1;
    my $emit_ct = 0;
    $self->named_recur(
            recur_name => 'StatelessProducer',
            repeat_interval => 1,
            work => sub {
        for (1..$emit_rate) {
            $emit_ct++;
            my $message = {
                sending_pid => $$,
                emit_ct => $emit_ct,
                emit_rate => $emit_rate,
                from => 'StatelessProducer',
                i => $emit_ct,
            };
            if($config->{other_stuff}) {
                mtransform($message, $config->{other_stuff});
            }
#            print STDERR Data::Dumper::Dumper $message;
            $self->emit($message);
        }
    });
}
1;
