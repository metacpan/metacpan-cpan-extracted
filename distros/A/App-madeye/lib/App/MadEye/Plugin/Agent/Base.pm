package App::MadEye::Plugin::Agent::Base;
use strict;
use warnings;
use base qw/App::MadEye::Plugin::Base/;

sub import {
    my $class = shift;
    my $pkg = caller;

    no strict 'refs';
    push @{"$pkg\::ISA"}, $class;

    *{"$pkg\::run_jobs"} = sub :Hook('run_jobs') {
        my ($self, $context, $args) = @_;

        $context->log( info => "run " . ref $self );

        my $target = $self->config->{config}->{target};
           $target = [$target] unless ref $target eq 'ARRAY';

        for my $t (@$target) {
            $context->log('debug', "register job: $self, $t");
            $context->run_job( +{ target => $t, plugin => $self, } );
        }
    };
}

1;

