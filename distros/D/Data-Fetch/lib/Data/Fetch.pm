package Data::Fetch;

# Author Nigel Horne: njh@bandsman.co.uk
# Copyright (C) 2016, Nigel Horne

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

=head1 NAME

Data::Fetch - give advance warning that you'll be needing a value

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

Sometimes we know in advance that we'll be needing a value which is going to take a long time to compute or determine.
This module fetches the value in the background so that you don't need to wait so long when you need the value.

    use CalculatePi;
    use Data::Fetch;
    my $fetcher = Data::Fetch->new();
    my $pi = CalculatePi->new(places => 1000000);
    $fetcher->prime(object => $pi, message => 'as_string');	# Warn we'll run $pi->as_string() in the future
    # Do other things
    print $fetcher->get(object => $pi, message => 'as_string'), "\n";	# Runs $pi->as_string()

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Data::Fetch object.  Takes no argument.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	return bless({ lock => 0}, $class);
}

=head2 prime

Say what is is you'll be needing later.
Takes two mandatory parameters:

    object - the object you'll be sending the message to
    message - the message you'll be sending

Takes one optional parameter:

    arg - passes this argument to the message

=cut

sub prime {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	return unless($args{'object'} && $args{'message'});

	my $object = $args{'object'} . '->' . $args{'message'};
	if(my $a = $args{arg}) {
		$object .= "($a)"
	}

	if($self->{values} && $self->{values}->{$object} && $self->{values}->{$object}->{status}) {
		my @call_details = caller(0);
		die 'Attempt to prime twice at ', $call_details[2], ' of ', $call_details[1];
	}

	$self->{values}->{$object}->{status} = 'running';

	$self->{values}->{$object}->{thread} = threads->create(sub {
		my ($o, $m, $a) = @_;
		if($a) {
			return eval '$o->$m($a)';
		}
		return eval '$o->$m()';
	}, $args{object}, $args{message}, $args{arg});

	# $self->{values}->{$object}->{thread} = async {
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

Retrieve get a value you've primed.  Takes two mandatory parameters:

    object - the object you'll be sending the message to
    message - the message you'll be sending

Takes one optional parameter:

    arg - passes this argument to the message

If you don't prime it will still work and store the value for subsequent calls,
but in this scenerio you gain nothing over using CHI to cache your values.

=cut

sub get {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	return unless($args{'object'} && $args{'message'});

	my $object = $args{'object'} . '->' . $args{'message'};
	if(my $a = $args{arg}) {
		$object .= "($a)"
	}

	if(!defined($self->{values}->{$object}->{status})) {
		# my @call_details = caller(0);
		# die 'Need to prime before getting at line ', $call_details[2], ' of ', $call_details[1];
		my ($o, $m, $a) = ($args{object}, $args{message}, $args{arg});
		my $rc;
		if($a) {
			$rc = eval '$o->$m($a)';
		} else {
			$rc = eval '$o->$m()';
		}
		$self->{values}->{$object}->{status} = 'complete';
		return $self->{values}->{$object}->{value} = $rc;
	}
	if($self->{values}->{$object}->{status} eq 'complete') {
		return $self->{values}->{$object}->{value};
	}
	if($self->{values}->{$object}->{status} eq 'running') {
		my $rc = $self->{values}->{$object}->{thread}->join();
		$self->{values}->{$object}->{status} = 'complete';
		delete $self->{values}->{$object}->{thread};
		# $self->{values}->{$object}->{thread} = undef;	# ????
		return $self->{values}->{$object}->{value} = $rc;
	}
	die 'Unknown status: ', $self->{values}->{$object}->{status};
}

sub DESTROY {
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
	}
	my $self = shift;

	return unless($self->{values});

	foreach my $o(values %{$self->{values}}) {
		if($o->{thread}) {
			if($o->{thread}->is_running()) {
				$o->{thread}->detach();
			}
			delete $o->{thread};
			delete $o->{value};
		}
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

ARRAY contexts not supported.

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

=head1 SEE ALSO

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Fetch

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Fetch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Fetch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Fetch>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Fetch/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nigel Horne.

This program is released under the following licence: GPL

=cut

1; # End of Data::Fetch
