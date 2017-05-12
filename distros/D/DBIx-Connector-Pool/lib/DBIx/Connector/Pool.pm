package DBIx::Connector::Pool::Item::_on_destroy;

sub new {
	${$_[1]} //= 0;
	++${$_[1]};
	bless [@_[1 .. $#_]];
}

sub DESTROY {
	$_[0][1](@{$_[0]}[2 .. @{$_[0]} - 1]) if --${$_[0][0]} == 0;
}

package DBIx::Connector::Pool::Item;
use warnings;
use strict;
use DBIx::Connector;

our @ISA              = ('DBIx::Connector');
our $not_in_use_event = sub {
	$_[0]->used_now;
};

sub _rebase {
	my ($base) = @_;
	if ($base) {
		$ISA[0] = $base;
	}
}

sub import {
	my ($class, $base) = @_;
	_rebase $base;
}

sub used_now {
	$_[0]->{_item_last_use} = time;
}

sub txn {
	my $self = $_[0];
	my $use_guard
		= DBIx::Connector::Pool::Item::_on_destroy->new(\$_[0]->{_item_in_use}, $not_in_use_event, $_[0]);
	$_[0]->used_now;
	shift->SUPER::txn(@_);
}

sub run {
	my $use_guard
		= DBIx::Connector::Pool::Item::_on_destroy->new(\$_[0]->{_item_in_use}, $not_in_use_event, $_[0]);
	$_[0]->used_now;
	shift->SUPER::run(@_);
}

sub item_in_use {
	$_[0]->{_item_in_use};
}

sub item_last_use {
	$_[0]->{_item_last_use};
}

package DBIx::Connector::Pool;
use warnings;
use strict;
use Carp;
use Time::HiRes 'time';

our $VERSION = "0.02";

sub new {
	my ($class, %args) = @_;
	$args{initial}   //= 1;
	$args{tid_func}  //= sub {1};
	$args{wait_func} //= sub {croak "real waiting function must be supplied"};
	$args{max_size} ||= -1;
	$args{keep_alive}     //= -1;
	$args{user}           //= ((getpwuid $>)[0]);
	$args{password}       //= '';
	$args{attrs}          //= {};
	$args{dsn}            //= 'dbi:Pg:dbname=' . $args{user};
	$args{connector_mode} //= 'fixup';
	if ($args{max_size} > 0 && $args{initial} != 0 && $args{initial} > $args{max_size}) {
		$args{initial} = $args{max_size};
	}
	$args{pool} = [];
	my $self = bless \%args, $class;
	if ($args{connector_base}) {
		DBIx::Connector::Pool::Item::_rebase($args{connector_base});
	}
	$self->_make_initial;
	$self;
}

sub _make_initial {
	my $self = $_[0];
	for my $i (0 .. $self->{initial} - 1) {
		$self->{pool}[$i] = {
			tid       => undef,
			connector => (
				       DBIx::Connector::Pool::Item->new($self->{dsn}, $self->{user}, $self->{password}, $self->{attrs})
					or croak "Can't create initial connect: " . DBI::errstr
			)
		};
		$self->{pool}[$i]{connector}->mode($self->{connector_mode});
	}
}

sub connected_size {
	my $self           = $_[0];
	my $connected_size = 0;
	for my $i (0 .. @{$self->{pool}} - 1) {
		if (defined($self->{pool}[$i]{tid}) && $self->{pool}[$i]{connector}) {
			++$connected_size;
		}
	}
	$connected_size;
}

sub collect_unused {
	my $self           = $_[0];
	my $connected_size = $self->connected_size;
	return if $connected_size <= $self->{initial};
	my $i;
	my $remove_sub = sub {
		if ($i == @{$self->{pool}} - 1) {
			pop @{$self->{pool}};
		} else {
			$self->{pool}[$i] = {};
		}
		--$connected_size;
	};
	my $now = time;
	for ($i = @{$self->{pool}} - 1; $i >= 0 && $connected_size > $self->{initial}; --$i) {
		if ($self->{pool}[$i]{connector} && !$self->{pool}[$i]{connector}->item_in_use) {
			if ($now - $self->{pool}[$i]{connector}->item_last_use > $self->{keep_alive}) {
				$remove_sub->();
			} else {
				$self->{pool}[$i]{tid} = undef;
			}
		} elsif (!$self->{pool}[$i]{connector}) {
			$remove_sub->();
		}
	}
}

sub get_connector {
	my $self = $_[0];
	my $tid  = $self->{tid_func}();
	for my $i (0 .. @{$self->{pool}} - 1) {
		if (defined($self->{pool}[$i]{tid}) && $self->{pool}[$i]{tid} == $tid && $self->{pool}[$i]{connector}) {
			$self->{pool}[$i]{connector}->used_now;
			return $self->{pool}[$i]{connector};
		}
	}
RESELECT:
	do {
		for my $i (0 .. @{$self->{pool}} - 1) {
			if ($self->{pool}[$i]{connector}
				&& (!defined($self->{pool}[$i]{tid}) || !$self->{pool}[$i]{connector}->item_in_use))
			{
				$self->{pool}[$i]{tid} = $tid;
				$self->{pool}[$i]{connector}->used_now;
				return $self->{pool}[$i]{connector};
			}
		}
		$self->{wait_func}() if $self->{max_size} > 0 && @{$self->{pool}} >= $self->{max_size};
	} while ($self->{max_size} > 0 && @{$self->{pool}} >= $self->{max_size});
	my $connector = eval {DBIx::Connector::Pool::Item->new($self->{dsn}, $self->{user}, $self->{password}, $self->{attrs})};
	if (!$connector) {
		if ($self->{initial} > 0 && $self->{max_size} > $self->{initial}) {
			--$self->{max_size};
			carp "Corrected connector pool size: $self->{max_size}";
			goto RESELECT;
		} elsif ($self->{max_size} < 0) {
			$self->{max_size} = @{$self->{pool}};
		} else {
			croak "Can't create new connector: " . DBI::errstr;
		}
	}
	$connector->mode($self->{connector_mode});
	$connector->used_now;
	push @{$self->{pool}}, {tid => $tid, connector => $connector};
	$connector;
}

1;

__END__
=head1 NAME
 
DBIx::Connector::Pool - A pool of DBIx::Connector or its subclasses for asynchronous environment
 
=head1 SYNOPSIS

  use Coro;
  use AnyEvent;
  use Coro::AnyEvent;
  use DBIx::Connector::Pool;
  
  my $pool = DBIx::Connector::Pool->new(
    initial    => 1,
    keep_alive => 1,
    max_size   => 5,
    tid_func   => sub {"$Coro::current" =~ /(0x[0-9a-f]+)/i; hex $1},
    wait_func => sub        {Coro::AnyEvent::sleep 0.05},
    attrs     => {RootClass => 'DBIx::PgCoroAnyEvent'}
  );
  
  async {
    my $connector = $pool->get_connector;
    $connector->run(
      sub {
        my $sth = $_->prepare(q{select isbn, title, rating from books});
        $sth->execute;
        my ($isbn, $title, $rating) = $sth->fetchrow_array;
        # ... 
      }
    );
  };

=head1 Description
 
L<DBI> is great and L<DBIx::Connector> is a nice interface with good features 
to it. But when it comes to work in some asynchronous environment like
L<AnyEvent> you have to use something another with callbacks if you don't want
to block your event loop completely waiting for data from DB. This module 
(together with L<DBIx::PgCoroAnyEvent> for PostgreSQL or some another alike) 
was developed to overcome this inconvenience. You can write your "normal" DBI
code without blocking your event loop. 

This module requires some threading model and I know about only one really 
working L<Coro>. 

=head1 Methods

=over 

=item B<new>
  
  my $pool = DBIx::Connector::Pool->new(
    initial    => 1,
    keep_alive => 1,
    max_size   => 5,
    tid_func   => sub {"$Coro::current" =~ /(0x[0-9a-f]+)/i; hex $1},
    wait_func => sub        {Coro::AnyEvent::sleep 0.05},
    attrs     => {RootClass => 'DBIx::PgCoroAnyEvent'}
  );

Creates new pool. Possible parameters:

=over

=item B<initial>

Initial number of connected connectors. This means also minimum of of
connected connectors. It throws error if this minimum can not be met.

=item B<keep_alive>

How long connector can live after it becomes unused. Initial connectors will
live forever. C<-1> means no limit. C<0> means collect it immediate. Positive 
number means seconds.

=item B<max_size>

Maximum pool capacity. C<-1> means unlimited.

=item B<user>

=item B<password>

=item B<dsn>

=item B<attrs>

Data for C<< DBIx::Connector->new >> function. This is the same as for 
C<< DBI->connect >>. Usually you want to add some unblocking DBI subclass
as C<RootClass> attribute. Like C<< RootClass => 'DBIx::PgCoroAnyEvent' >>
for PostgreSQL.

=item B<connector_mode>

Sets the default L<DBIx::Connector/"Connection Modes"> attribute, which is 
used by run(), txn(), and svp() if no mode is passed to them. Defaults to 
"fixup".

=item B<tid_func>

Thread identification function. Must return number. Good choice for L<Coro> is

  sub {"$Coro::current" =~ /(0x[0-9a-f]+)/i; hex $1}

=item B<wait_func>

This function put B<get_connector> into sleep to wait for a free connector 
in pool.

=item B<connector_base>

In case you use some subclass of L<DBIx::Connector> you have to point it out.

=back 

=item B<get_connector>

Returns available connector. Returned object is a subclass of 
L<DBIx::Connector> or subclass of B<connector_base>. 

The same thread will get the same already used connector until it's free. 
Function always wait for an available connector, it can't return undef. 

When new connection can not be established an error is thrown 
or if B<max_size> is greater than B<intial> or equal to C<-1> then
B<max_size> will be automatically lowered to actually possible size.

=item B<collect_unused>

Method marks unused and disconnects timed out connectors. It keeps minimum 
B<initial> number of connectors connected. Intended to be used from timers 
events. 

=item B<connected_size>

Returns number of currently connected connectors.

=item B<$DBIx::Connector::Pool::Item::not_in_use_event>

This package variable is a subroutine referenc which is called when connectors
object is not in use anymore. You can use it together with B<wait_func> to 
wake up a waiting for a free connector B<get_connector>. For example:

  my @pool_wait_queue;
  $DBIx::Connector::Pool::Item::not_in_use_event = sub {
     if (my $wc = shift @pool_wait_queue) {
        $wc->ready;
     }
     $_[0]->used_now;
  };
...
  wait_func => sub {push @pool_wait_queue, $Coro::current; Coro::schedule;}   

=back

=head1 SEE ALSO
 
=over
 
=item * L<DBIx::Connector>
 
=item * L<DBI>
 
=item * L<DBIx::PgCoroAnyEvent>

=item * L<DBD::Pg>
 
=item * L<Coro>

=item * L<AnyEvent>

=back

=head1 BUGS

Currently this module tested only for PostgreSQL + Coro + AnyEvent.

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut
