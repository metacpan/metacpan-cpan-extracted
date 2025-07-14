package Data::Fetch;

# Usage is subject to licence terms.
# The licence terms of this software are as follows:
# Personal single user, single computer use: GPL2
# All other users (including Commercial, Charity, Educational, Government)
#	must apply in writing for a licence for use from Nigel Horne at the
#	above e-mail.

use 5.12.0;	# Threads before that are apparently not good
use strict;
use warnings;
use threads;

use Scalar::Util qw(refaddr);

=head1 NAME

Data::Fetch - Prime method calls for background execution using threads

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

This module allows you to prepare time-consuming method calls in advance.
It runs those methods in background threads so that when you later need the result,
you don't need to wait for it to compute.

    use CalculatePi;
    use Data::Fetch;

    my $fetcher = Data::Fetch->new();
    my $pi = CalculatePi->new(places => 1_000_000);

    # Prime the method call in the background
    $fetcher->prime(
        object  => $pi,
        message => 'as_string',
        arg     => undef  # Optional
    );

    # Do other work here...

    # Retrieve the result later (waits only if it hasn't completed yet)
    my $value = $fetcher->get(
        object  => $pi,
        message => 'as_string',
        arg     => undef
    );

    print $value, "\n";

=head1 DESCRIPTION

Some method calls are expensive, such as generating a large dataset or performing
heavy computations.
If you know in advance that you'll need the result later,
C<Data::Fetch> lets you prime that method call so it begins running in a background thread.

When you later call C<get>,
the value is returned immediately if ready - or you'll wait for it to finish.

=head1 SUBROUTINES/METHODS

=head2 new

    my $fetcher = Data::Fetch->new();

Constructs and returns a new C<Data::Fetch> object.


=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	return bless({ lock => 0 }, $class);
}

=head2 prime

    $fetcher->prime(
        object  => $obj,
        message => 'method_name',
        arg     => $args_ref    # Optional
    );

Starts a background thread that will call the given method on the object.

Takes the following parameters:

=over 4

=item * object

The object on which the method will be invoked.

=item * message

The name of the method to call.

=item * arg

(Optional) The arguments to pass to the method. This must be:

- A scalar
- An arrayref of positional arguments
- A hashref of named arguments

The arguments are passed to the method using Perl's standard C<@_> behavior:

    $obj->$method(@$args)      # if arg is an arrayref
    $obj->$method(%$args)      # if arg is a hashref
    $obj->$method($arg)        # otherwise

=back

If called in list context, the method result will be stored and returned in list context when retrieved via C<get()>.

=cut

sub prime {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	return unless($args{'object'} && $args{'message'});

	# FIXME: Assumes arg is simple and stringable,
	#	should use Storable::freeze

	my $key = join ':',
		refaddr($args{object}), $args{message}, defined($args{arg}) ? $args{arg} : '';

	if($self->{values} && $self->{values}->{$key} && $self->{values}->{$key}->{status}) {
		my @call_details = caller(0);
		die 'Attempt to prime twice at ', $call_details[2], ' of ', $call_details[1];
	}

	$self->{values}->{$key}->{status} = 'running';

	$self->{values}->{$key}->{thread} = threads->create(sub {
		my ($o, $m, $a, $wantarray) = @_;
		if((ref($a) eq 'ARRAY') || (ref($a) eq 'HASH')) {
			if($wantarray) {
				my @rc = eval '$o->$m(@{$a})';
				return \@rc;
			}
			return eval '$o->$m(@{$a})';
		}
		if($wantarray) {
			my @rc;
			if($a) {
				@rc = eval '$o->$m($a)';
			} else {
				@rc = eval '$o->$m()';
			}
			return \@rc;
		}
		if($a) {
			return eval '$o->$m($a)';
		}
		return eval '$o->$m()';
	}, $args{object}, $args{message}, $args{arg}, wantarray);

	# $self->{values}->{$key}->{thread} = async {
		# my $o = $args{object};
		# my $m = $args{message};
		# if(my $a = $args{arg}) {
			# return eval '$o->$m($a)';
		# }
		# return eval '$o->$m()';
	# };

	return $self;	# Easily prime lots of values in one call
}

=head2 get

    my $value = $fetcher->get(
        object  => $obj,
        message => 'method_name',
        arg     => $arg         # Optional
    );

Retrieves the result of a previously primed method.
If the background thread is still running, it will wait for it to finish.
If the method wasn't primed, it
will call the method directly and cache the result.

C<get> can be called in list or scalar context, depending on what the method returns.
If the method returns a list, use:

    my @list = $fetcher->get(...);

=cut

sub get {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	# I'm not sure that silently ignoring that the two arguments are
	#	mandatory is a good idea

	return unless($args{'object'} && $args{'message'});

	my $key = join ':',
		refaddr($args{object}), $args{message}, defined($args{arg}) ? $args{arg} : '';

	my $status = $self->{values}->{$key}->{status};

	if(!defined($status)) {
		# my @call_details = caller(0);
		# die 'Need to prime before getting at line ', $call_details[2], ' of ', $call_details[1];

		$self->{values}->{$key}->{status} = 'complete';
		my ($o, $m, $a) = ($args{object}, $args{message}, $args{arg});
		if(wantarray) {
			my @rc;
			if($a) {
				@rc = eval '$o->$m($a)';
			} else {
				@rc = eval '$o->$m()';
			}
			push @{$self->{values}->{$key}->{value}}, @rc;
			return @rc;
		} else {
			my $rc;
			if($a) {
				$rc = eval '$o->$m($a)';
			} else {
				$rc = eval '$o->$m()';
			}
			return $self->{values}->{$key}->{value} = $rc;
		}
	}

	if($status eq 'complete') {
		my $value = $self->{values}->{$key}->{value};
		if(wantarray && (ref($value) eq 'ARRAY')) {
			my @rc = @{$value};
			return @rc;
		}
		return $value;
	}
	if($status eq 'running') {
		$self->{values}->{$key}->{status} = 'complete';
		$self->{values}->{$key}->{joined} = 1;	# Mark as joined
		if(wantarray) {
			my @rc = @{$self->{values}->{$key}->{thread}->join()};
			delete $self->{values}->{$key}->{thread};
			push @{$self->{values}->{$key}->{value}}, @rc;
			return @rc;
		}
		my $rc = $self->{values}->{$key}->{thread}->join();
		delete $self->{values}->{$key}->{thread};
		return $self->{values}->{$key}->{value} = $rc;
	}
	die "Unknown status: $status";
}

sub DESTROY
{
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';  # >= 5.14.0 only
	}

	my $self = shift;
	return unless($self->{values});

	foreach my $v (values %{$self->{values}}) {
		next unless $v->{thread};

		my $thread = $v->{thread};

		if($v->{joined}) {
			# Thread already joined, just clean up
			delete $v->{thread};
			delete $v->{value};
			next;
		}

		if ($thread->is_running) {
			warn 'Thread ', $thread->tid(), ' primed but not used; detaching';
			$thread->detach;
		} else {
		# } elsif ($thread->is_joinable && ($v->{'status'} ne 'complete')) {
			# FIXME: join the thread.
			# However, that's not a good idea in a DESTROY
			#       routine
			# The thread is done, so join it and store result (if not already done)
			# my $result = $thread->join();
			# $v->{value} = $result unless exists $v->{value};
			# $v->{status} = 'complete';
			warn 'Thread ', $thread->tid(), ' primed but not used';
		}

		delete $v->{thread};  # Always clean up
		delete $v->{value};
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Can't pass more than one argument to the message.

I would not advise using this to call messages that change values in the object.

Changing a value between prime and get will not necessarily get you the data you want. That's the way it works
and isn't going to change.

If you change a value between two calls of get(), the earlier value is always used.  This is definitely a feature
not a bug.

Please report any bugs or feature requests to C<bug-data-fetch at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Fetch>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

See L<http://www.cpantesters.org/cpan/report/116390147>.
This code could produce the "attempt to prime twice" if you're unlucky and Perl assigns the
same address to the new object as the old object.

    my $fetch = Data::Fetch->new();
    my $data = Class::Simple->new();
    $fetch->prime(object => $data, message => 'get');
    $fetch->get(object => $data, message => 'get');
    $data = Class::Simple->new();	# Possibly the address of $data isn't changed
    $fetch->prime(object => $data, message => 'get');	# <<<< This could produce the error

=head1 SEE ALSO

=head1 SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc Data::Fetch

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Data-Fetch>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Fetch>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/Data-Fetch>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Data-Fetch>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Data::Fetch>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
