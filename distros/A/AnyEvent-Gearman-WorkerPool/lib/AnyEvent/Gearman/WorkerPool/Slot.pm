package AnyEvent::Gearman::WorkerPool::Slot;


# ABSTRACT: Slot class
our $VERSION = '1.0'; # VERSION
use Log::Log4perl qw(:easy);

use Moose;
use AnyEvent;
use AnyEvent::Gearman::WorkerPool::Worker;
use Data::Dumper;

has libs=>(is=>'rw',isa=>'ArrayRef',default=>sub{[]});
has job_servers=>(is=>'rw',isa=>'ArrayRef',required=>1);
has workleft=>(is=>'rw');
has worker_package=>(is=>'rw');
has worker_channel=>(is=>'rw');

has is_busy=>(is=>'rw',default=>0);
has is_stopped=>(is=>'rw',default=>1);
has boss_channel=>(is=>'rw',default=>'');

has worker_watcher=>(is=>'rw');
has worker_pid=>(is=>'rw');


sub BUILD{
    my $self = shift;
}

sub is_idle{
    my $self = shift;
    return ($self->is_running)&&(!$self->is_busy);
}
sub is_running{
    my $self = shift;
    return (!$self->is_stopped);
}

sub stop{
    DEBUG 'stop called';
    my $self = shift;
    $self->is_stopped(1);
    if( $self->worker_pid ){
        kill INT => $self->worker_pid;
    }
}

sub start{
    my $self = shift;
    
    my $cpid = fork();
    if( $cpid ){
        $self->worker_pid($cpid);
        $self->worker_watcher( AE::child $cpid, sub{
            my ($pid,$status) = @_;
            if( $self->is_stopped != 1){
                DEBUG '------------------ child restart ------------------------';
                $self->start();
            }
            else{
                DEBUG 'kill child OK';
                $self->worker_pid(undef);
                $self->worker_watcher(undef);
            }
        });
        $self->is_stopped(0);
    }
    else{
        my $class = $self->worker_package;
        my $boss_channel = $self->boss_channel;
        my $worker_channel = $self->worker_channel;
        my $libs = join(' ',map{"-I$_"}@{$self->libs});;
        my $workleft = $self->workleft;

        my $job_servers = '['.join(',',map{"\"$_\""}@{$self->job_servers}).']';

        my $cmd = qq!$^X $libs -M$class -e '$class->Loop(job_servers=>$job_servers,boss_channel=>"$boss_channel",channel=>"$worker_channel",workleft=>"$workleft");' !;
        
        DEBUG 'start '.$cmd;
        my $res = 0;
        $res = exec($cmd);
        die "unexpected error $res";
    }
}

sub DEMOLISH{

    DEBUG __PACKAGE__.' DEMOLISHED';
    my $self = shift;
    if( $self->worker_pid ){
        DEBUG 'killed child forcely';
        kill INT => $self->worker_pid;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Gearman::WorkerPool::Slot - Slot class

=head1 VERSION

version 1.0

=head1 AUTHOR

HyeonSeung Kim <sng2nara@hanmail.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by HyeonSeung Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
