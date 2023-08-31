package CHI::Driver::SharedMem;

# There is an argument for mapping namespaces into keys and then putting
# different namespaces into different shared memory areas.  I will think about
# that.

use warnings;
use strict;
use CHI::Constants qw(CHI_Meta_Namespace);
use Moose;
use IPC::SysV qw(S_IRUSR S_IWUSR IPC_CREAT);
use IPC::SharedMem;
use JSON::MaybeXS;
use Carp;
use Config;
use Fcntl;

extends 'CHI::Driver';

has 'shm_key' => (is => 'ro', isa => 'Int');
has 'shm' => (is => 'ro', builder => '_build_shm', lazy => 1);
has 'shm_size' => (is => 'rw', isa => 'Int', default => 8 * 1024);
has 'lock_file' => (is => 'rw', isa => 'Str|Undef');
has 'lock_fd' => (
	is => 'ro',
	builder => '_build_lock',
);
has '_data_size' => (
	is => 'rw',
	isa => 'Int',
	reader => '_get_data_size',
	writer => '_set_data_size'
);
has '_data' => (
	is => 'rw',
	# isa => 'ArrayRef[ArrayRef]',	# For Storable, now using JSON
	isa => 'Str',
	reader => '_get_data',
	writer => '_set_data'
);

__PACKAGE__->meta->make_immutable();

=head1 NAME

CHI::Driver::SharedMem - Cache data in shared memory

=head1 VERSION

Version 0.19

=cut

our $VERSION = '0.19';

# FIXME - get the pod documentation right so that the layout of the memory
# area looks correct in the man page

=head1 SYNOPSIS

L<CHI> driver which stores data in shared memory objects for persistence
over processes.
Size is an optional parameter containing the size of the shared memory area,
in bytes.
Shmkey is a mandatory parameter containing the IPC key for the shared memory
area.
See L<IPC::SharedMem> for more information.

    use CHI;
    my $cache = CHI->new(
	driver => 'SharedMem',
	max_size => 2 * 1024,	# Size of the cache
	shm_size => 32 * 1024,	# Size of the shared memory area
	shm_key => 12344321,	# Choose something unique, but the same across
				# all caches so that namespaces will be shared,
				# but we won't step on any other shm areas
    );
    # ...

The shared memory area is stored thus:

	# Number of bytes in the cache [ int ]
	'cache' => {
		'namespace1' => {
			'key1' => 'value1',
			'key2' => 'value2',
			# ...
		},
		'namespace2' => {
			'key1' => 'value3',
			'key3' => 'value2',
			# ...
		}
		# ...
	}

=head1 SUBROUTINES/METHODS

=head2 store

Stores an object in the cache.
The data are serialized into JSON.

=cut

sub store {
	my($self, $key, $value) = @_;

	$self->_lock(type => 'write');
	my $h = $self->_data();
	$h->{$self->namespace()}->{$key} = $value;
	# if($self->{'is_size_aware'}) {
		# $h->{CHI_Meta_Namespace()}->{'last_used_time'}->{$key} = time;
	# }
	$self->_data($h);
	$self->_unlock();
}

=head2 fetch

Retrieves an object from the cache

=cut

sub fetch {
	my($self, $key) = @_;

	if($self->{is_size_aware}) {
		$self->_lock(type => 'write');
	} else {
		$self->_lock(type => 'read');
	}
	# open(my $tulip, '>>', '/tmp/tulip');
	# print $tulip __LINE__, "\n";
	# print $tulip __LINE__, "\n";
	my $rc = $self->_data()->{$self->namespace()}->{$key};
	# print $tulip __LINE__, "\n";
	if($self->{is_size_aware}) {
		my $h = $self->_data();
		$h->{CHI_Meta_Namespace()}->{last_used_time}->{$key} = time;
		$self->_data($h);
	}
	$self->_unlock();
	# print $tulip __LINE__, "\n";
	# close $tulip;
	return $rc;
}

=head2 remove

Remove an object from the cache

=cut

sub remove {
	my($self, $key) = @_;

	$self->_lock(type => 'write');
	if($ENV{'AUTHOR_TESTING'} && $self->{'is_size_aware'} && (my $timeout = $self->discard_timeout())) {
		# Workaround for test_discard_timeout
		# my $sleep_time = $timeout + 1;
		# open(my $tulip, '>>', '/tmp/tulip');
		# print $tulip "sleeping $sleep_time\n";
		# close $tulip;
		# sleep($sleep_time);
		sleep(1);
	}
	my $h = $self->_data();
	delete $h->{$self->namespace()}->{$key};
	delete $h->{CHI_Meta_Namespace()}->{last_used_time}->{$key};
	$self->_data($h);
	$self->_unlock();

	# open(my $tulip, '>>', '/tmp/tulip');
	# print $tulip "remove: $key\n";
}

=head2 clear

Removes all data from the current namespace

=cut

sub clear {
	my $self = shift;

	$self->_lock(type => 'write');
	my $h = $self->_data();
	delete $h->{$self->namespace()};
	$self->_data($h);
	$self->_unlock();

	# open(my $tulip, '>>', '/tmp/tulip');
	# print $tulip "clear ", $self->namespace(), "\n";
}

=head2 get_keys

Gets a list of the keys in the current namespace

=cut

sub get_keys {
	my $self = shift;

	$self->_lock(type => 'read');
	my $h = $self->_data();
	$self->_unlock();
	return(keys(%{$h->{$self->namespace()}}));
}

=head2 get_namespaces

Gets a list of the namespaces in the cache

=cut

sub get_namespaces {
	my $self = shift;

	$self->_lock(type => 'read');
	my $rc = $self->_data();
	$self->_unlock();
	# Needs to be sorted for RT89892
	my @rc = sort keys(%{$rc});
	return @rc;
}

=head2 default_discard_policy

Use an LRU algorithm to discard items when the cache can't add anything

=cut

sub default_discard_policy { 'lru' }

=head2 discard_policy_lru

When the Shared memory area is getting close to full, discard the least recently used objects

=cut

sub discard_policy_lru {
	my $self = shift;

	if($ENV{'AUTHOR_TESTING'} && $self->{'is_size_aware'} && (my $timeout = $self->discard_timeout())) {
		# Workaround for test_discard_timeout
		# my $sleep_time = $timeout + 1;
		# open(my $tulip, '>>', '/tmp/tulip');
		# print $tulip "sleeping $sleep_time\n";
		# close $tulip;
		# sleep($sleep_time);
		sleep(1);
	}
	$self->_lock(type => 'read');
	my $last_used_time = $self->_data()->{CHI_Meta_Namespace()}->{last_used_time};
	$self->_unlock();
	my @keys_in_lru_order =
		sort { $last_used_time->{$a} <=> $last_used_time->{$b} } $self->get_keys();
	return sub {
		shift(@keys_in_lru_order);
	};
}

# Internal routines

# The area must be locked by the caller
sub _build_shm {
	my $self = shift;
	my $shm_size = $self->shm_size();

	if((!defined($shm_size)) || ($shm_size == 0)) {
		# Probably some strange condition in cleanup
		# croak 'Size == 0';
		return;
	}
	my $shm = IPC::SharedMem->new($self->shm_key(), $shm_size, S_IRUSR|S_IWUSR);
	unless($shm) {
		$shm = IPC::SharedMem->new($self->shm_key(), $shm_size, S_IRUSR|S_IWUSR|IPC_CREAT);
		unless($shm) {
			croak "Couldn't create a shared memory area of $shm_size bytes with key ",
				$self->shm_key(), ": $!";
			return;
		}
		$shm->write(pack('I', 0), 0, $Config{intsize});
	}
	$shm->attach();
	return $shm;
}

sub _build_lock {
	my $self = shift;

	# open(my $fd, '<', $0) || croak("$0: $!");
	# FIXME: make it unique for each object, not a singleton
	$self->lock_file('/tmp/' . __PACKAGE__);
	# open(my $tulip, '>>', '/tmp/tulip');
	# print $tulip "build_lock\n", $self->lock_file(), "\n";
	open(my $fd, '>', $self->lock_file()) || croak($self->lock_file(), ": $!");
	# close $tulip;
	return $fd;
}

sub _lock {
	my ($self, %params) = @_;

	# open(my $tulip, '>>', '/tmp/tulip');
	# print $tulip $params{'type'}, ' lock ', $self->lock_file(), "\n";
	# my $i = 0;
	# while((my @call_details = (caller($i++)))) {
		# print $tulip "\t", $call_details[1], ':', $call_details[2], ' in function ', $call_details[3], "\n";
	# }
	return unless $self->lock_file();

	if(my $lock = $self->lock_fd()) {
		# print $tulip "locking\n";
		flock($lock, ($params{type} eq 'read') ? Fcntl::LOCK_SH : Fcntl::LOCK_EX);
	} else {
		# print $tulip 'lost lock ', $self->lock_file(), "\n";
		croak('Lost lock: ', $self->lock_file());
	}
	# print $tulip "locked\n";
	# close $tulip;
}

sub _unlock {
	my $self = shift;

	# open(my $tulip, '>>', '/tmp/tulip');
	# print $tulip 'unlock ', $self->lock_file(), "\n";
	# my $i = 0;
	# while((my @call_details = (caller($i++)))) {
		# print $tulip "\t", $call_details[1], ':', $call_details[2], ' in function ', $call_details[3], "\n";
	# }
	if(my $lock = $self->lock_fd()) {
		flock($lock, Fcntl::LOCK_UN);
	} else {
		# print $tulip 'lost lock for unlock ', $self->lock_file(), "\n";
		croak('Lost lock for unlock: ', $self->lock_file());
	}
	# close $tulip;
}

# The area must be locked by the caller
sub _data_size {
	my($self, $value) = @_;

	if(!$self->shm()) {
		croak __PACKAGE__, ': panic: _data_size has lost the shared memory segment';
		return 0;
	}
	if(defined($value)) {
		$self->shm()->write(pack('I', $value), 0, $Config{intsize});
		return $value;
	}
	my $size = $self->shm()->read(0, $Config{intsize});
	unless(defined($size)) {
		return 0;
	}
	return unpack('I', $size);
}

# The area must be locked by the caller
sub _data {
	my($self, $h) = @_;

	# open(my $tulip, '>>', '/tmp/tulip');
	# print $tulip __LINE__, "\n";
	if(defined($h)) {
		my $f = JSON::MaybeXS->new()->ascii(1)->encode($h);
		my $cur_size = length($f);
		# print $tulip __LINE__, " cmp $cur_size > ", $self->shm_size(), "\n";
		if($cur_size > ($self->shm_size() - $Config{intsize})) {
			$self->_unlock();
			croak("Sharedmem set failed - value too large? ($cur_size bytes) > ", $self->shm_size());
		}
		if($f !~ /\}$/) {
			$self->_unlock();
			croak("Encoding failed. ($cur_size bytes: $f) ");
		}
		$self->shm()->write($f, $Config{intsize}, $cur_size);
		$self->_data_size($cur_size);
		# print $tulip "set: $cur_size bytes\n";
		# close $tulip;
		return $h;
	}
	my $cur_size = $self->_data_size();
	# print $tulip "get: $cur_size bytes\n";
	if($cur_size) {
		my $rc;
		eval {
			$rc = JSON::MaybeXS->new()->ascii(1)->decode($self->shm()->read($Config{intsize}, $cur_size));
		};
		if($@) {
			$self->_lock(type => 'write');
			$self->_data_size(0);
			my $foo = $self->shm()->read($Config{intsize}, $cur_size);
			# print $tulip "\tDecode fail $cur_size bytes $@\n\t$foo\n";
			# my $i = 0;
			# while((my @call_details = (caller($i++)))) {
				# print $tulip "\t", $call_details[1], ':', $call_details[2], ' in function ', $call_details[3], "\n";
			# }
			croak($@);
			$self->_unlock();
		}
		return $rc;
		# return JSON::MaybeXS->new()->ascii(1)->decode($self->shm()->read($Config{intsize}, $cur_size));
	}
	# close $tulip;
	return {};
}

=head2 BUILD

Constructor - validate arguments

=cut

sub BUILD {
	my $self = shift;

	unless($self->shm_key()) {
		croak 'CHI::Driver::SharedMem - no shm_key given';
	}
	$| = 1;
}

=head2 DEMOLISH

If there is no data in the shared memory area, and no-one else is using it,
it's safe to remove it and reclaim the memory.

=cut

sub DEMOLISH {
	# if(defined($^V) && ($^V ge 'v5.14.0')) {
		# return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
	# }
	my $self = shift;

	# open(my $tulip, '>>', '/tmp/tulip');
	# print $tulip "DEMOLISH\n";
	if($self->shm_key() && $self->shm()) {
		$self->_lock(type => 'write');
		my $cur_size = $self->_data_size();
		# print $tulip "DEMOLISH: $cur_size bytes\n";
		my $can_remove = 0;
		my $stat = $self->shm()->stat();
		if($cur_size == 0) {
			if(defined($stat) && ($stat->nattch() == 1)) {
				$self->shm()->detach();
				$self->shm()->remove();
				$can_remove = 1;
			}
		# } elsif(defined($stat) && ($stat->nattch() == 1)) {
			# # Scan the cache and see if all has expired.
			# # If it has, then the cache can be removed if nattch = 1
			# $can_remove = 1;
			# foreach my $namespace($self->get_namespaces()) {
				# print $tulip "DEMOLISH: namespace = $namespace\n";
				# foreach my $key($self->get_keys($namespace)) {
					# # May give substr error in CHI
					# print $tulip "DEMOLISH: key = $key\n";
					# if($self->is_valid($key)) {
					# print $tulip "DEMOLISH: is_valid\n";
						# $can_remove = 0;
						# last;
					# }
				# }
			# }
			# $self->shm()->detach();
			# if($can_remove) {
				# $self->shm()->remove();
			# }
		} else {
			$self->shm()->detach();
		}
		$self->_unlock();
		if($can_remove && (my $lock_file = $self->lock_file())) {
			$self->lock_file(undef);
			close $self->lock_fd();
			unlink $lock_file;
			# print $tulip "unlink $lock_file\n";
			# close $tulip;
		}
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-chi-driver-sharedmem at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CHI-Driver-SharedMem>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Max_size is handled, but if you're not consistent across the calls to each cache,
the results are unpredictable because it's used to create the size of the shared memory
area.

The shm_size argument should be deprecated and only the max_size argument used.

=head1 SEE ALSO

L<CHI>, L<IPC::SharedMem>

=cut

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CHI::Driver::SharedMemory

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/CHI-Driver-SharedMem>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=CHI-Driver-SharedMemory>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=CHI-Driver-SharedMemory>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=CHI::Driver::SharedMemory>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2023 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
