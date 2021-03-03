package Class::Simple::Cached;

use strict;
use warnings;
use Carp;
use Class::Simple;

my @ISA = ('Class::Simple');

=head1 NAME

Class::Simple::Cached - cache messages to an object

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

A sub-class of L<Class::Simple> which caches calls to read
the status of an object that are otherwise expensive.

It is up to the caller to maintain the cache if the object comes out of sync with the cache,
for example by changing its state.

You can use this class to create a caching layer to an object of any class
that works on objects with a get/set model such as:

    use Class::Simple;
    my $obj = Class::Simple->new();
    $obj->val($newval);
    $oldval = $obj->val();

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Class::Simple::Cached object.

It takes one mandatory parameter: cache,
which is either an object which understands clear(), get() and set() calls,
such as an L<CHI> object;
or is a reference to a hash where the return values are to be stored.

It takes one optional argument: object,
which is an object which is taken to be the object to be cached.
If not given, an object of the class L<Class::Simple> is instantiated
and that is used.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# Use Class::Simple::Cached->new(), not Class::Simple::Cached::new()
	if(!defined($class)) {
		carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		return;
	}

	my %args;
	if(ref($_[0]) eq 'HASH') {
		%args = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::carp('Usage: ', __PACKAGE__, '->new(cache => $cache [, object => $object ], %args)');
		return;
	} elsif(@_ % 2 == 0) {
		%args = @_;
	}

	if(!defined($args{'object'})) {
		$args{'object'} = Class::Simple->new(%args);
	}

	if($args{'cache'} && ref($args{'cache'})) {
		return bless \%args, $class;
	}
	Carp::carp('Usage: ', __PACKAGE__, '->new(cache => $cache [, object => $object ], %args)');
	return;	# undef
}

sub _caller_class
{
	my $self = shift;

	if(ref($self->{'object'}) eq 'Class::Simple') {
		# return $self->SUPER::_caller_class(@_);
		return $self->Class::Simple::_caller_class(@_);
	}
}

sub AUTOLOAD {
	our $AUTOLOAD;
	my $param = $AUTOLOAD;
	$param =~ s/.*:://;

	my $self = shift;
	my $cache = $self->{'cache'};

	if($param eq 'DESTROY') {
		if(ref($cache) eq 'HASH') {
			while(my($key, $value) = each %{$cache}) {
				delete $cache->{$key};
			}
			return;
		}
		if(defined($^V) && ($^V ge 'v5.14.0')) {
			return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
		}
		$cache->clear();
		return;
	}

	# my $func = $self->{'object'} . "::$param";
	my $func = $param;
	my $object = $self->{'object'};

	# if($param =~ /^[gs]et_/) {
		# # $param = "SUPER::$param";
		# return $object->$func(\@_);
	# }

	if(scalar(@_) == 0) {
		# Retrieving a value
		my $rc;
		if(ref($cache) eq 'HASH') {
			$rc = $cache->{$param};
		} else {
			$rc = $cache->get($param);
		}
		if($rc) {
			die $param if($rc eq 'never');
			if(ref($rc) eq 'ARRAY') {
				my @foo = @{$rc};
				die $param if($foo[0] eq __PACKAGE__ . '>UNDEF<');
				die $param if($foo[0] eq 'never');
				return @{$rc};
			}
			if($rc eq __PACKAGE__ . '>UNDEF<') {
				return;
			}
			return $rc;
		}
		if(wantarray) {
			my @rc = $object->$func();
			if(scalar(@rc) == 0) {
				return;
			}
			if(ref($cache) eq 'HASH') {
				$cache->{$param} = \@rc;
			} else {
				$cache->set($param, \@rc, 'never');
			}
			return @rc;
		}
		if(defined(my $rc = $object->$func())) {
			if(ref($cache) eq 'HASH') {
				return $cache->{$param} = $rc;
			}
			return $cache->set($param, $rc, 'never');
		}
		if(ref($cache) eq 'HASH') {
			return $cache->{$param} = __PACKAGE__ . '>UNDEF<';
		}
		$cache->set($param, __PACKAGE__ . '>UNDEF<', 'never');
		return;
	}

	# $param = "SUPER::$param";
	# return $cache->set($param, $self->$param(@_), 'never');
	if($_[1]) {
		# Storing an array
		# We store a ref to the array, and dereference on retrieval
		if(defined(my $val = $object->$func(\@_))) {
			if(ref($cache) eq 'HASH') {
				$cache->{$param} = $val;
			} else {
				$cache->set($param, $val, 'never');
			}
			return @{$val};
		}
		if(ref($cache) eq 'HASH') {
			return $cache->{$param} = __PACKAGE__ . '>UNDEF<';
		}
		$cache->set($param, __PACKAGE__ . '>UNDEF<', 'never');
		return;
	}
	# Storing a scalar
	if(ref($cache) eq 'HASH') {
		return $cache->{$param} = $object->$func($_[0]);
	}
	return $cache->set($param, $object->$func($_[0]), 'never');
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Doesn't work with L<Memoize>.

Only works on messages that take no arguments.

Please report any bugs or feature requests to L<https://github.com/nigelhorne/Class-Simple-Readonly/issues>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Class::Simple>, L<CHI>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Simple::Cached

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Class-Simple-Cached>

=item * Source Repository

L<https://github.com/nigelhorne/Class-Simple-Readonly-Cached>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/Class-Simple-Cached>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Class-Simple-Cached>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-Simple-Cached>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Class::Simple::Cached>

=back

=head1 LICENCE AND COPYRIGHT

Author Nigel Horne: C<njh@bandsman.co.uk>
Copyright (C) 2019-2021, Nigel Horne

Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.
=cut

1;
