package Coro::DataPipe;

our $VERSION='0.02';
use 5.006; # Perl::MinimumVersion says that

use strict;
use warnings;
use List::Util qw(first);
use Coro; #qw(schedule async);

# run is single parallel pipe which is trivial case of pipeline
sub run {
    pipeline(@_);
}

sub pipeline {
    my $class=shift;
    if (ref($class) eq 'HASH') {
        unshift @_, $class;
        $class = __PACKAGE__;
    }
    my @pipes;
    # init pipes
    my $default_input;
    for my $param (@_) {
        unless (exists $param->{input}) {
            $param->{input} = $default_input or die "You have to specify input for the first pipe";            
        }
        my $pipe = $class->new($param);
        if (ref($pipe->{output}) eq 'ARRAY') {
            $default_input = $pipe->{output};
        }
        push @pipes, $pipe;
    }
    run_pipes(0,@pipes);
    my $result = $pipes[$#pipes]->{output};
    # @pipes=() kills parent
    # as well as its implicit destroying
    # destroy pipes one by one if you want to survive!!! 
    undef $_ for @pipes;
    return unless defined(wantarray);
    return unless $result;
    return wantarray?@$result:$result;
}

sub run_pipes {
    my ($prev_busy,$me,@next) = @_;
    while (1) {
        my $data_loaded = $me->load_data;        
        my $me_busy = $data_loaded || $me->busy_processors;
        # get processed data 
        schedule if $me_busy;
        # push it to next pipe
        $me_busy = $data_loaded || $me->busy_processors;
        my $next_busy = @next && run_pipes($prev_busy || $me_busy, @next);
        # I am busy either when I am already busy or my child are busy
        $me_busy ||= $next_busy;
        # pipeline is free if every pipe is free and no more data to process
        return 0 unless $me_busy || $data_loaded;
        # get data from pipe if we have free_processors
        return $me_busy if $prev_busy && $me->free_processors;
    }
    return 0;
}

sub set_input_iterator {
    my ($self,$param) = @_;
    my ($input_iterator) = extract_param($param, qw(input));
    if (ref($input_iterator) ne 'CODE') {
        die "array or code reference expected for input_iterator" unless ref($input_iterator) eq 'ARRAY';
        my $queue = $input_iterator;
        $input_iterator = sub {$queue?shift(@$queue):undef};
    }
    $self->{input_iterator} = $input_iterator;
}

sub set_output_iterator {
    my ($self,$param) = @_;
    my ($output_iterator) = extract_param($param, qw(output));
    if (ref($output_iterator) ne 'CODE') {
        my $queue = $output_iterator || [];
        $self->{output} = $queue;
        $output_iterator = sub {push @$queue,$_};
    }
    $self->{output_iterator} = $output_iterator;    
}

sub set_process_iterator {
    my ($self,$param) = @_;
    my $process_data_callback = extract_param($param,qw(process));
    my $main =  $Coro::current;
    $self->{process_iterator} = sub {
        my $data = shift;
        my $item_number = $self->{item_number}++;
        $self->{busy}++;
        my $coro = async {
            local $_ = $data;
            $_ = $process_data_callback->($data);
            $self->{output_iterator}->($_,$item_number);
            $self->{busy}--;
            $main->ready;
        };
    };
}

# loads all free processor with data from input
# return the number of loaded processors
sub load_data {
    my $self = shift;
    my $result = 0;
    while ($self->free_processors) {
        my $data = $self->{input_iterator}->();
        return $result unless defined($data);
        $self->{process_iterator}->($data);
        $result++;
    }
    return $result;
}

sub extract_param {
    my ($param, @alias) = @_;
    return first {defined($_)} map delete($param->{$_}), @alias;
}

sub busy_processors {
    my $self = shift;
    return $self->{busy};
}

sub free_processors {
    my $self = shift;
    return $self->{busy} < $self->{number_of_data_processors};    
}

sub new {
    my ($class, $param) = @_;	
	my $self = {};
    bless $self,$class;
    # this is cooperative, so it's better to set explicit number of processor - your better know when it wins
    my $number_of_data_processors = extract_param($param,'number_of_data_processors');
    unless ($number_of_data_processors) {
        $number_of_data_processors = 2;
        warn "number_of_data_processors set to $number_of_data_processors";
    }
    $self->{number_of_data_processors} = $number_of_data_processors;
    # item_number & busy
    $self->{$_} = 0 for qw(item_number busy);
    $self->set_input_iterator($param);
    $self->set_output_iterator($param);
    $self->set_process_iterator($param);
    my $not_supported = join ", ", keys %$param;
    die "Parameters are redundant or not supported:". $not_supported if $not_supported;	
	return $self;
}

1;

=head1 NAME

C<Coro::DataPipe> - parallel data processing conveyor 

=encoding utf-8

=head1 SYNOPSIS

 use Coro::AnyEvent;
 use Coro::DataPipe;
 Coro::DataPipe::run {
    input => [1..100],
    process => sub { Coro::AnyEvent::sleep(1);$_*2 },
    number_of_data_processors => 100,
    output => sub { print "$_\n" },
 };

 time perl test.t >/dev/null
 # 1 second, not 100!

=head1 DESCRIPTION

This is implementation of L<Parallel::DataPipe> algorithm using cooperative threads (Coro).
See description of alorithm and subroutines there.

This module uses cooperative threads, so all threads share the same memory and no forks are used.
Good use case is when you make some long lasting queries to database/www and then process data
and want to do it asynchronosuly.
In that case even if you have one processor you will win because processor will be always busy thanks to Coro.

=head1 SEE ALSO

L<Coro>

=head1 DEPENDENCIES

It requires Coro 6.31. Alhough may be it will work with more old version - it is just one I use for myself.

=head1 BUGS 

For all bugs please send an email to okharch@gmail.com.

=head1 SOURCE REPOSITORY

See the git source on github
 L<https://github.com/okharch/Coro-DataPipe>

=head1 COPYRIGHT

Copyright (c) 2013 Oleksandr Kharchenko <okharch@gmail.com>

All right reserved. This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

  Oleksandr Kharchenko <okharch@gmail.com>

=cut
