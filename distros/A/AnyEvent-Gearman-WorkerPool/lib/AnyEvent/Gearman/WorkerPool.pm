package AnyEvent::Gearman::WorkerPool;
# ABSTRACT: Managing Worker's lifecycle with Slots
our $VERSION = '1.0'; # VERSION
use Log::Log4perl qw(:easy);

use Data::Dumper;
use Moose;
use Storable qw(freeze thaw);

use AnyEvent;
use AnyEvent::Gearman::Worker;
use AnyEvent::Gearman::Worker::RetryConnection;

use AnyEvent::Gearman::WorkerPool::Slot;
has slotmap=>(is=>'rw', isa=>'HashRef', default=>sub{ return {}; });
has config=>(is=>'rw', isa=>'HashRef',required=>1);
has idle_watcher=>(is=>'rw');
has boss_channel=>(is=>'rw', default=>sub{time});
has reporters=>(is=>'rw');
sub BUILD{
    my $self = shift;

    my $conf = $self->config;
    my %global = %{$conf->{'global'}};
    my %baseconf = (
        job_servers=>[''],
        min=>1,
        max=>1,
        workleft=>0,
    );
    %global = (%baseconf,%global);
    
    my @reporters;
    my %confs = %{$conf->{slots}};
    foreach my $worker (keys %confs){
        my %conf = %{$confs{$worker}};

        %conf = (%global,%conf);
        DEBUG Dumper(\%conf);

        my @slots;
        foreach (0 .. $conf{max}-1){
            my $slot = AnyEvent::Gearman::WorkerPool::Slot->new(
                job_servers=>$conf{job_servers},
                libs=>$conf{libs},
                workleft=>$conf{workleft},
                boss_channel=>$self->boss_channel,
                worker_package=>$worker,
                worker_channel=>$worker.'__'.$_,
            );
            push( @slots, $slot);
        }
        $self->slotmap->{$worker} = {conf=>\%conf, slots=>\@slots};

        my $w = AnyEvent::Gearman::Worker->new(
            job_servers => [@{$conf{job_servers}}],
        );
        $w = AnyEvent::Gearman::Worker::RetryConnection::patch_worker($w);
        $w->register_function( "AnyEvent::Gearman::WorkerPool_".$self->boss_channel."::report" => sub{
            my $job = shift;
            my $workload = thaw($job->workload);
            if( $workload ){
                my $status = $workload->{status};
                my ($key,$idx) = split(/__/,$workload->{channel});
                DEBUG "SB $status $key $idx";
                if( $status eq 'busy'){
                    $self->slots($key)->[$idx]->is_busy(1);
                }
                elsif( $status eq 'idle'){
                    $self->slots($key)->[$idx]->is_busy(0);
                }
            }
            $job->complete;
        } );
        push(@reporters, $w);
    }

    $self->reporters(\@reporters);
}

sub slots{
    my $self = shift;
    my $key = shift;
    return $self->slotmap->{$key}->{slots};
}

sub conf{
    my $self = shift;
    my $key = shift;
    return $self->slotmap->{$key}->{conf};
}

sub start{
    DEBUG __PACKAGE__." start";
    my $self = shift;
    foreach my $key (keys %{$self->slotmap}){
        my $slots = $self->slots($key);
        my $conf = $self->conf($key);
        my $min = $conf->{min};
        foreach my $i ( 0 .. $min-1 ){
            $slots->[$i]->start();
        }
    }
    my $iw = AE::timer 0,5, sub{$self->on_idle;};
    $self->idle_watcher($iw);
}

sub on_idle{
    my $self = shift;
    DEBUG "ON_IDLE";
    foreach my $key (keys %{$self->slotmap}){
        my @slots = @{$self->slots($key)};
        my %conf = %{$self->conf($key)};
        my $idle = 0;
        my $running = 0;
        foreach my $s ( @slots ){
            $idle += $s->is_idle;
            $running += $s->is_running;
        }
        DEBUG "[$key] idle: $idle, running: $running";
        if( !$idle ){
            if( $running < $conf{max} ){
                DEBUG "expand $key";
                my @stopped = grep{$_->is_stopped}@slots;
                shift(@stopped)->start;
            }
        }
        else{
            if( $running > $conf{min} ){
                DEBUG "reduce $key";
                my @running = grep{$_->is_running}@slots;
                pop(@running)->stop;
            }
        }
    }

}

sub stop{
    DEBUG __PACKAGE__." stop";
    my $self = shift;
    $self->idle_watcher(undef);
    foreach my $key (keys %{$self->slotmap}){
        my $slots = $self->slots($key);
        foreach my $s ( @{$slots} ){
            $s->stop() unless $s->is_stopped;
        }
    }
}

sub DEMOLISH{
    DEBUG __PACKAGE__.' DEMOLISHED';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Gearman::WorkerPool - Managing Worker's lifecycle with Slots

=head1 VERSION

version 1.0

=head1 SYNOPSIS

worker_pool.pl

	#!/usr/bin/env perl

	use AnyEvent;
	use AnyEvent::Gearman::WorkerPool;
	
	my $cv = AE::cv;

	my $sig = AE::signal 'INT'=> sub{ 
		DEBUG "TERM!!";
		$cv->send;
	};

	my $pool = AnyEvent::Gearman::WorkerPool->new(
		config=>
		{   
			global=>{ # common config
				job_servers=>['localhost'], # gearmand servers
				libs=>['./lib'], # perl5 library paths
				max=>3, # max workers
				},  
			slots=>{
				'TestWorker'=>{ # module package name which extends AnyEvent::Gearman::WorkerPool::Worker.
					min=>20, # min workers, count when started.
					max=>50, # overrides global config's max. Workers will extend when all workers are busy.
					workleft=>10, # workleft is life of worker. A worker will be respawned after used 10 times. 
								# if workleft is set as 0, a worker will be never respawned.
								# this feature is useful if worker code may has some memory leaks.
				},
				# you can place more worker modules here.
			}   
		}   
	);

	$pool->start();

	my $res = $cv->recv;
	undef($tt);
	$pool->stop;
	undef($pool);

lib/TestWorker.pm

	package TestWorker;
	use Log::Log4perl qw(:easy);
	Log::Log4perl->easy_init($DEBUG);

	use Moose;

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
        DEBUG 'reverse';
        my $self = shift;
        my $job = shift;
        my $res = reverse($job->workload);
        DEBUG $res;
        $job->complete( $res );
    }
    sub _private{
        my $self = shift;
        my $job = shift;
        DEBUG "_private:".$job->workload;
        $job->complete();
    }

	1;

client.pl

	#!/usr/bin/env perl
	use AnyEvent;
	use AnyEvent::Gearman;
	my $cv = AE::cv;
	my $c = gearman_client 'localhost';
	$c->add_task(
		'TestWorker::reverse' => 'HELLO WORLD', # 'MODULE_NAME::EXPORTED_METHOD' => PAYLOAD
		on_complete=>sub{
			my $reversed = $_[1];
			$cv->send( $reversed );
		},
	);

	my $reversed = $cv->recv;

	print $reversed."\n"; # 'DLROW OLLEH'

=head1 AUTHOR

HyeonSeung Kim <sng2nara@hanmail.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by HyeonSeung Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
