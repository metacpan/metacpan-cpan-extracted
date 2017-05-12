package MultiModuleTest::Example1;
$MultiModuleTest::Example1::VERSION = '1.143160';
use strict;use warnings;

use parent 'App::MultiModule::Task';

sub message {
    my $self = shift; my $message = shift;
    if($message->{new_ct}) {
        $self->{state}->{ct} = $message->{new_ct};
        print STDERR "Example1: set ct to $message->{new_ct}\n";
    }
}

sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config; #not necessary in this example
    $self->{state} = { ct => 0 } unless $self->{state};
    $self->named_recur(
        recur_name => 'Example1',
        repeat_interval => 1,
        work => sub {
            my $message = {
                ct => $self->{state}->{ct}++,
                outstr => $config->{outstr},
                static_forwards => [
                    [   {   transform => {
                                some => 'transform',
                            },
                            forward => {
                                qname => 'Example2',
                            }
                        }
                    ]
                ],
            };
            $self->emit($message);
        },
    );
}

sub is_stateful {
    return 'yes!';
}

=head1 some pod
=cut

1;
