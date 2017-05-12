package Cache::Memcached::Semaphore;
use strict;
require 5.007003;

use base qw(Exporter);
#---------------------------------------------------------------------
our %EXPORT_TAGS = (
						all	=> [ qw(
									&acquire
									&wait_acquire
								) ],
					);
#---------------------------------------------------------------------

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
#---------------------------------------------------------------------

our $VERSION = '0.3';

use Time::HiRes qw( usleep gettimeofday );
use Digest::MD5 qw(md5_hex);

#---------------------------------------------------------------------
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my %args = (
					name	=> undef,
					memd	=> undef,
					force	=> 0,	# force lock is experimental
					timeout	=> undef,
					@_,
				);
	
	if ( $args{name} && $args{memd}) {
		my $memd = $args{memd};
		
		if ( $memd ) {
			my $key = "__lock__" . $args{name};
			my $val = md5_hex( gettimeofday() . $$ );
			my $res = $memd->add( $key, $val );
			if ( $res || $args{force}) {
				unless ( $res ) {
					$memd->set( $key, $val );
					return undef unless $memd->get( $key ) eq $val;
				}
				my $self = {
								key		=> $key,
								val		=> $val,
								memd	=> $memd,
								timeout	=> $args{timeout},
							};
				
				bless $self, $class;
				
				return $self;
			}
		}
	}
	
	return undef;
}
#---------------------------------------------------------------------

sub DESTROY {
	my $self = shift;
	my $memd = $self->{memd};
	
	if ( $memd ) {
		my $val = $memd->get( $self->{key} );
		$val = "" unless $val;
		if ( $val eq $self->{val} ) {
			my $res = $memd->delete( $self->{key}, $self->{timeout} );
		} else {
			warn "Wrong value at $self->{key} while unlocking.\nExpected $self->{val}\nGot $val" ;
		}
	} else {
		warn "No memd $self->{memd_id}. Cannot unlock $self->{key}";
	}
}
#---------------------------------------------------------------------

sub acquire {
	my %args = (
					name	=> undef,
					memd	=> undef,
					timeout	=> undef,
					@_,
				);
	
	return Cache::Memcached::Semaphore->new( %args );
}
#---------------------------------------------------------------------

sub wait_acquire {
	my %args = (
					name		=> undef,
					memd		=> undef,
					timeout		=> undef,
					max_wait	=> undef,
					poll_time	=> 0.1,
					force_after_timeout	=> 0,
					@_,
				);
	
	my $wait_indef = 0;
	$wait_indef = 1 unless $args{max_wait};
	my $wait_left = $args{max_wait};
	my $wait_time = $args{poll_time};
	
	my $lock = Cache::Memcached::Semaphore->new( 
									name	=> $args{name}, 
									memd	=> $args{memd},
									timeout	=> $args{timeout},
								);
	
	while ( !$lock  ) {
		usleep( $wait_time );
		
		$lock = Cache::Memcached::Semaphore->new( 
									name	=> $args{name}, 
									memd	=> $args{memd},
									timeout	=> $args{timeout},
								);

		unless( $wait_indef ) {
			$wait_left -= $wait_time;
			last if ( $wait_left <= 0 );
		}
	}
	
	if ( !$lock && $args{force_after_timeout} ) {
		$lock = Cache::Memcached::Semaphore->new( 
									name	=> $args{name}, 
									memd	=> $args{memd},
									timeout	=> $args{timeout},
									force	=> 1,
								);
	}
	
	return $lock;
}
#---------------------------------------------------------------------

1;
__END__

=head1 NAME

Cache::Memcached::Semaphore - a simple pure-perl library for cross-machine semaphores using memcached.

=head1 SYNOPSIS

	use Cache::Memcached;
	use Cache::Memcached::Semaphore;
	
	my $memd = new Cache::Memcached {
		'servers' => [ "10.0.0.15:11211", "10.0.0.15:11212",
						"10.0.0.17:11211", [ "10.0.0.17:11211", 3 ] ],
	};
	
	# OO interface
	# acquire semaphore
	my $lock = Cache::Memcached::Semaphore(
		memd => $memd, 
		name => "semaphore1",
	);
	# release semaphore
	$lock = undef;

	# acquire semaphore which will stay 10 secs after deleting object
	my $lock2 = Cache::Memcached::Semaphore(
		memd => $memd, 
		name => "semaphore2",
		timeout => 10,
	);
	
	# Functional interface
	# acquire semaphore which will stay 10 secs after deleting object
	my $lock3 = acquire(
		memd => $memd, 
		name => "semaphore3",
		timeout => 10,
	);
	
	# try to acquire semaphore during 10 seconds
	my $lock4 = wait_acquire(
		memd => $memd, 
		name => "semaphore4",
		max_wait	=> 10,
		poll_time	=> 0.1,
	);
	
	
=head1 DESCRIPTION

This module uses Cache::Memcached perl API to maintain semaphores across a number
of servers. It relies upon return value of memcached API add function (true in case
of previously non-existent value, false in case value already exists).

Tested with memcached v 1.1.12, C<Cache::Memcached> 1.15+ on 
FreeBSD 6.0-RELEASE, 6.1-STABLE, 6.1-RELEASE, 6.2-PRERELEASE.

=head1 CONSTRUCTOR

=over 4

=item C<new>

Takes a hash of named options. The main keys are C<memd> which is a reference
to a memcached API object (actually, it can be any blessed reference with
the same interface as C<Cache::Memcached>) and C<name> - the name for the 
semaphore.

Use C<timeout> to set the time in seconds, for which acquiring the semaphore
will be impossible after releasing it.

The constructor return a blessed reference to C<Cache::Memcached::Semaphore>
object in case of success, otherwise C<undef>.

The semaphore is released automatically when the variable holding the 
reference to the object leaves the scope or is explicitly set to any
other value (in the object's destructor).

=back

=head1 FUNCTIONAL INTERFACE

=over 4

=item C<acquire>

Takes the same parameters as the constructor and returns blessed object
reference in case of success, otherwise C<undef>.

=item C<wait_acquire>

Takes the same options as above plus extra two: C<max_wait> and C<poll_time>.
The function tries to acquire the semaphore, in case of failure it waits
C<poll_time> seconds (may be fractions of seconds) and tries again. If 
the function succeeds to acquire the semafore within C<max_wait> seconds,
it returns a blessed object reference. Otherwise it returns C<undef>.

=back

=head1 BUGS

None known yet

=head1 TODO

=over 4

=item Forced lock acquiring

=item Semaphore time-to-live

=item Deadlock resolving

=back

=head1 AUTHOR

Sergei A. Fedorov <zmij@cpan.org>

I will be happy to have your feedback about the module.

=head1 COPYRIGHT

This module is Copyright (c) 2006 Sergei A. Fedorov.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.
