package AnyEvent::Gearman::WorkerPool::Worker;

# ABSTRACT: A worker launched by Slot
our $VERSION = '1.0'; # VERSION

use Log::Log4perl qw(:easy);


use AnyEvent::Gearman::Client;
use AnyEvent::Gearman::Worker;
use AnyEvent::Gearman::Worker::RetryConnection;
use Storable qw(freeze thaw);

use Moose;

# options
has job_servers=>(is=>'rw', required=>1);
has boss_channel => (is=>'rw',required=>1, default=>'');
has channel=>(is=>'rw',required=>1);
has workleft=>(is=>'rw',isa=>'Int', default=>-1);

# internal
has exported=>(is=>'ro',default=>sub{[]});
has worker=>(is=>'rw');

has is_stopped=>(is=>'rw');
has is_busy=>(is=>'rw');
has reporter=>(is=>'rw');

has cv=>(is=>'rw');

sub BUILD{
    my $self = shift;

    $self->cv->begin;

    my $js = $self->job_servers;

    if( $self->boss_channel ){
        my $client = AnyEvent::Gearman::Client->new(
            job_servers => [@$js]
        );
        $self->reporter($client);
    }

    # register
    my $meta = $self->meta;
    my $package = $meta->{package};
    my $exported = $self->exported;

    if( $self->workleft == 0 ){
        $self->workleft(-1);
    }

    for my $method ( $meta->get_all_methods ) 
    {
        my $packname = $method->package_name;
        next if( $packname eq __PACKAGE__ ); # skip base class

        my $methname = $method->name;
        if( $packname eq $package )
        {
            if( $methname !~ /^_/ && $methname ne uc($methname) && $methname ne 'meta' )
            {
                if( !$meta->has_attribute($methname) ){
                    #DEBUG 'filtered: '.$method->fully_qualified_name;
                    push(@{$exported},$method);
                }
            }
        }
    }
    
    $self->register($js);

    

}

sub report{
    my $self = shift;
    my $msg = lc(shift);

    DEBUG "report $msg boss_channel". $self->boss_channel;
    return unless $self->reporter;

    
    $self->reporter->add_task_bg(
        'AnyEvent::Gearman::WorkerPool_'.$self->boss_channel.'::report'=> freeze({status=>$msg, channel=>$self->channel})
    );
}

sub unregister{
    my $self = shift;
    foreach my $m (@{$self->exported}){
        my $fname = $m->fully_qualified_name;
        $self->worker->unregister_function($fname) if $self->worker;
    }
}

sub register{
    my $self = shift;
    my $js = shift;
    my $w = AnyEvent::Gearman::Worker->new(
        job_servers => [@$js],
    );
    $w = AnyEvent::Gearman::Worker::RetryConnection::patch_worker($w);

    foreach my $m (@{$self->exported}){
        DEBUG "register ".$m->fully_qualified_name;
        my $fname = $m->fully_qualified_name;
        my $fcode = $m->body;

        $w->register_function($fname =>
            sub{
                my $job = shift;
                my $workload = $job->workload;

                DEBUG "[$fname] '$workload' workleft:".$self->workleft;
                $self->report('BUSY');
                $self->is_busy(1);

                my $res;
                eval{
                    $res = $fcode->($self,$job);
                };
                if ($@){
                    ERROR $@;
                    $w->fail;
                    return;
                }

                $self->report('IDLE');
                $self->is_busy(0);

                if( $self->workleft > 0 ){
                    $self->workleft($self->workleft-1);
                }

                if( $self->is_stopped ){
                    $self->stop_safe('stopped');
                }

                if( $self->workleft == 0 ){
                    $self->stop_safe('overworked');
                }
            }
        );
    }

    $self->worker($w);
    
}

sub stop_safe{
    my $self = shift;
    my $msg = shift;
    $self->is_stopped(1);
    $self->unregister;
    $self->worker(undef);
    DEBUG "stop_safe $msg";

    $self->cv->end;
}

sub DEMOLISH{
    my $self = shift;
    $self->unregister() if $self->worker;
    DEBUG __PACKAGE__." DEMOLISHED";
}

# class member
sub Loop{

    my $class = shift;
    die 'Use like PACKAGE->Loop(%opts).' unless $class;
    die 'You need to use your own class extending '. __PACKAGE__ .'!' if $class eq __PACKAGE__;
    my %opt = @_;

    my $cv = AE::cv;

    
    my $worker;
    my $sig = AE::signal INT=>sub{
        $worker->stop_safe('SIGINT');
        $cv->send;
    };

    $cv->begin(sub{ $cv->send; });
    eval{
        $worker = $class->new(%opt,cv=>$cv);
    };
    $cv->end;

    $cv->recv;
    DEBUG "stop completely";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Gearman::WorkerPool::Worker - A worker launched by Slot

=head1 VERSION

version 1.0

=head1 SYNOPSIS

make TestWorker.pm

    package TestWorker;
    use Any::Moose;
    extends 'AnyEvent::Gearman::WorkerPool::Worker';

    sub slowreverse{
        DEBUG 'slowreverse';
        my $self = shift;
        my $job = shift;
        my t = AE::timer 1,0, sub{
            my $res = reverse($job->workload);
            $job->complete( $res );
        };
    }
    sub reverse{
        my $self = shift;
        my $job = shift;
        my $res = reverse($job->workload);
        $job->complete( $res );
    }
    sub _private{
        my $self = shift;
        my $job = shift;
        $job->complete();
    }

You can see only 'reverse'

=head1 AUTHOR

HyeonSeung Kim <sng2nara@hanmail.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by HyeonSeung Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
