package AnyEvent::Worker::Pool;

use common::sense 2;m{
use warnings;
use strict;
}x;

#our $VERSION = '0.06';
use AnyEvent::Worker;

=head1 NAME

AnyEvent::Worker::Pool - Easily create a pool of workers and use'em like a single worker

=head1 SYNOPSIS

    use AnyEvent 5;
    use AnyEvent::Worker::Pool;
    
    # Create a pool of 2 workers
    my $workers = AnyEvent::Worker::Pool->new( 2, @common_worker_init_args );

    # Will be run instantly (left 1 idle worker)
    $workers->do( @common_worker_do_args );
    
    # Will be run instantly (left 0 idle workers)
    $workers->do( @common_worker_do_args );
    
    # Will be run after one of busy worker will get free
    $workers->do( @common_worker_do_args );

    $workers->take_worker(sub {
        my $worker = shift;
        $worker->do(@args, sub {
            $workers>ret_worker($worker);
        });
    });
    
=cut

sub new {
	my $pkg = shift;
	my $count = shift;
	my $self = bless {}, $pkg;
	$self->{pool} = [
		map { AnyEvent::Worker->new(@_) } 1..$count
	];
	return $self;
}

sub do {
	my $self = shift;
	my $cb = pop;
	my @args = @_;
	$self->take_worker(sub {
		my $worker = shift;
		$worker->do(@args, sub {
			$self->ret_worker($worker);
			goto &$cb;
		});
	});
	return;
}

sub take_worker {
	my $self = shift;
	my $cb = shift or die "cb required for take_worker at @{[(caller)[1,2]]}\n";
	#warn("take wrk, left ".$#{$self->{pool}}." for @{[(caller)[1,2]]}\n");
	if (@{$self->{pool}}) {
		$cb->(shift @{$self->{pool}});
	} else {
		#warn("no worker for @{[(caller 1)[1,2]]}, maybe increase pool?");
		push @{$self->{waiting_db}},$cb
	}
}

sub ret_worker {
	my $self = shift;
	#warn("ret wrk, got ".@{$self->{pool}}.'+'.@_." for @{[(caller)[1,2]]}\n");
	push @{ $self->{pool} }, @_;
	$self->take_worker(shift @{ $self->{waiting_db} }) if @{ $self->{waiting_db} };
}

=head1 AUTHOR

Mons Anderson, C<< <mons@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::Worker::Pool
