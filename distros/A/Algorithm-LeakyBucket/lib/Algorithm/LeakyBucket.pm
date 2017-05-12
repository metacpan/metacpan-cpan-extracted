package Algorithm::LeakyBucket;

=head1 NAME

Algorithm::LeakyBucket - Perl implementation of leaky bucket rate limiting

=head1 SYNOPSIS

 use Algorithm::LeakyBucket;
 my $bucket = Algorithm::LeakyBucket->new( ticks => 1, seconds => 1 ); # one per second

 while($something_happening)
 {
     if ($bucket->tick)
     {
         # allowed
         do_something();
	 # maybe decide to change limits?
	 $bucket->ticks(2);
	 $bucket->seconds(5);
     }
 }


=head1 CONSTRUCTOR

There are two required options to get the module to do anything useful.  C<ticks> and C<seconds> set the number of 
ticks allowed per that time period.  If C<ticks> is 3 and C<seconds> is 14, you will be able to run 3 ticks every 14 
seconds.  Optionally you can pass C<memcached_servers> and C<memcached_key> to distribute the limiting across multiple
processes.


 my $bucket = Algorithm::LeakyBucket->new( ticks => $ticks, seconds => $every_x_seconds,
                                  memcached_key => 'some_key',
                                  memcached_servers => [ { address => 'localhost:11211' } ] );

=DESCRIPTION

Implements leaky bucket as a rate limiter.  While the code will do rate limiting for a single process, it was intended
as a limiter for multiple processes. (But see the BUGS section)

The syntax of the C<memcached_servers> argument should be the syntax expected by the local memcache module.  If
Cache::Memcached::Fast is installed, use its syntax, otherwise you can use the syntax for Cache::Memcached.  If 
neither module is found it will use a locally defined set of vars internally to track rate limiting.  Obviously
this keeps the code from being used across processes. 

This is an alpha version of the code.  Some early bugs have been ironed out and its in produciton in places, so we would
probably transition it to beta once we have seen it work for a bit. 

=cut

use 5.008008;
use strict;
use warnings;
use Carp qw(cluck);
our $VERSION = '0.08';

sub new
{
	my ($class, %args) = @_;
	my $self = {};
	bless ($self, $class);

	eval {
		require Cache::Memcached::Fast;
		$self->{__mc_module_fast} = 1;
	};

	eval {
		require Cache::Memcached;
		$self->{__mc_module} = 1;
	};

	while (my($k,$v) = each (%args))
	{
		if ($self->can($k))	
		{	
			$self->$k($v);
		}
	}
	$self->init(%args);


	return $self;
}

sub ticks
{
	my ($self, $value) = @_;
	if (defined($value))
	{
		$self->{__ticks} = $value;
	}
	return $self->{__ticks};
}

sub seconds
{
        my ($self, $value) = @_;
        if (defined($value))
        {
                $self->{__seconds} = $value;
        }
        return $self->{__seconds};
}

sub current_allowed
{
        my ($self, $value) = @_;
        if (defined($value))
        {
                $self->{__current_allowed} = $value;
        }
        return $self->{__current_allowed};
}

sub last_tick
{
        my ($self, $value) = @_;
        if (defined($value))
        {
                $self->{__last_tick} = $value;
        }
        return $self->{__last_tick};
}

sub memcached_key
{
        my ($self, $value) = @_;
        if (defined($value))
        {
                $self->{__mc_key} = $value;
        }
        return $self->{__mc_key};
}

sub memcached
{
        my ($self, $value) = @_;
        if (defined($value))
        {
                $self->{__mc} = $value;
        }
        return $self->{__mc};
}

sub memcached_servers
{
        my ($self, $value) = @_;

        if (defined($value))
        {
        	if ((!$self->{__mc_module}) && (!$self->{__mc_module__fast}))
        	{
        	        croak("No memcached support installed, try installing Cache::Memcached or Cache::Memcached::Fast");
        	}
                $self->{__mc_servers} = $value;
        }
        return $self->{__mc_servers};
}

sub tick
{
	my ($self, %args ) = @_;

	if ($self->memcached)
	{
		# init form mc 
		$self->mc_sync;
	}
	
	# seconds since last tick
	my $now = time();
	my $seconds_passed = $now - $self->last_tick;
	$self->last_tick( time() );

	# add tokens to bucket
	my $current_ticks_allowed = $self->current_allowed + ( $seconds_passed * ( $self->ticks / $self->seconds ));
	$self->current_allowed( $current_ticks_allowed );

	if ($current_ticks_allowed > $self->ticks)
	{
		$self->current_allowed($self->ticks);
		if ($self->memcached)
		{
			$self->mc_write;
		}
		return 1;
	}
	elsif ($current_ticks_allowed < 1)
	{
		return 0;
	}
	else
	{
		$self->current_allowed( $current_ticks_allowed - 1);
                if ($self->memcached)
                {
                        $self->mc_write;
                }
		return 1;
	}
	
	return;
}

sub init
{
	my ($self, %args) = @_;
	$self->current_allowed( $self->ticks );
	$self->last_tick( time() );
	if ($self->memcached_servers)
	{
		if ($self->{__mc_module_fast})
		{
			eval {
				my $mc = Cache::Memcached::Fast->new({ servers => $self->memcached_servers,
								       namespace => 'leaky_bucket:', });
				$self->memcached($mc);
				$self->mc_sync;
			};
			if ($@)
			{
				cluck($@);
			}
		}
		elsif ($self->{__mc_module})
		{
                        eval {
                                my $mc = Cache::Memcached->new({ servers => $self->memcached_servers,
                                                                 namespace => 'leaky_bucket:', });
                                $self->memcached($mc);
                                $self->mc_sync;
                        };
			if ($@)
			{
				cluck($@);
			}
		}
	}
	return;
}

sub mc_sync
{
	my ($self, %args) = @_;

	my $packed = $self->memcached->get( $self->memcached_key );
	if ($packed)
	{
		# current allowed | last tick
		my @vals = split(/\|/,$packed);
		$self->current_allowed($vals[0]);
		$self->last_tick($vals[1]);
	}
	return;
}

sub mc_write
{
	my ($self, %args) = @_;
	$self->memcached->set($self->memcached_key, $self->current_allowed . '|' . $self->last_tick);
	return;
}

=head1 BUGS

Probably some.  There is a known bug where if you are in an infinite loop you could move faster than
memcached could be updated remotely, so you'll likely at that point only bbe limted by the local 
counters.  I'm not sure how im going to fix this yet as this is in early development.

=head1 TODO

Will need to look at including some actual tests im thinking.  Maybe once we get more real usage out
of this in our produciton environment some test cases will make themselves obvious.
 
=head1 SEE ALSO

http://en.wikipedia.org/wiki/Leaky_bucket

=head1 AUTHOR

Marcus Slagle, E<lt>marc.slagle@online-rewards.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Marcus Slagle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;


