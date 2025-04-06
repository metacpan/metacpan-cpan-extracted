package Class::Simple::Cached;

use strict;
use warnings;
use Carp;
use Class::Simple;
use Params::Get;
use Scalar::Util;

my @ISA = ('Class::Simple');

=head1 NAME

Class::Simple::Cached - cache messages to an object

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

A subclass of L<Class::Simple> which caches calls to read the status of an object that are otherwise expensive.

It is up to the caller to maintain the cache if the object comes out of sync with the cache,
for example,
by changing its state.

You can use this class to create a caching layer for any object of any class
that works on objects with a get/set model,
such as:

    use Class::Simple;
    my $obj = Class::Simple->new();
    $obj->val('foo');
    my $oldval = $obj->val();

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Class::Simple::Cached object.

It takes one mandatory parameter: cache,
which is either an object which understands purge(), get() and set() calls,
such as an L<CHI> object;
or is a reference to a hash where the return values are to be stored.

It takes one optional argument: object,
which is an object that is taken to be the object to be cached.
If not given, an object of the class L<Class::Simple> is instantiated
and that is used.

=cut

sub new
{
	my $class = shift;

	# Use Class::Simple::Cached->new(), not Class::Simple::Cached::new()
	if(!defined($class)) {
		carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		return;
	}
	if(Scalar::Util::blessed($class)) {
		my $params = Params::Get::get_params(undef, @_) || {};
		# clone the given object
		return bless { %{$class}, %{$params} }, ref($class);
	}

	my $params = Params::Get::get_params('cache', @_) || {};

	# Later Perls can use //=
	$params->{object} ||= Class::Simple->new(%{$params});	# Default to Class::Simple object

	# FIXME: If there are arguments, put the values in the cache

	# Ensure cache implements required methods
	if(Scalar::Util::blessed($params->{cache})) {
		unless($params->{cache}->can('get') && $params->{cache}->can('set') && $params->{cache}->can('purge')) {
			Carp::croak("Cache object must implement 'get', 'set', and 'purge' methods");
		}
		return bless $params, $class;
	}
	if(ref($params->{'cache'}) eq 'HASH') {
		return bless $params, $class;
	}

	Carp::croak("$class: Cache must be ref to HASH or object");
}

=head2 can

Returns if the embedded object can handle a message

=cut

sub can
{
	my ($self, $method) = @_;

	return ($method eq 'new') || $self->{'object'}->can($method) || $self->SUPER::can($method);
}

=head2 isa

Returns if the embedded object is the given type of object

=cut

sub isa
{
	my ($self, $class) = @_;

	if($class eq ref($self) || ($class eq __PACKAGE__) || $self->SUPER::isa($class)) {
		return 1;
	}
	return $self->{'object'}->isa($class);
}

# sub _caller_class
# {
	# my $self = shift;
#
	# if(ref($self->{'object'}) eq 'Class::Simple') {
		# # return $self->SUPER::_caller_class(@_);
		# return $self->Class::Simple::_caller_class(@_);
	# }
# }

# For older Perls - define a DESTROY method
# See https://github.com/Perl/perl5/issues/14673
sub DESTROY
{
	my $self = shift;
	if(my $cache = $self->{'cache'}) {
		if(ref($cache) eq 'HASH') {
			my $class = ref($self);
			# while(my($key, $value) = each %{$cache}) {
				# if($key =~ /^$class/) {
					# delete $cache->{$key};
				# }
			# }
			delete $cache->{$_} for grep { /^$class/ } keys %{$cache};
		} else {
			$cache->purge();
		}
	}
}

sub AUTOLOAD
{
	our $AUTOLOAD;
	my ($param) = $AUTOLOAD =~ /::(\w+)$/;

	my $self = shift;
	my $cache = $self->{'cache'};

	if($param eq 'DESTROY') {
		if(ref($cache) eq 'HASH') {
			my $class = ref($self);
			# while(my($key, $value) = each %{$cache}) {
				# if($key =~ /^$class/) {
					# delete $cache->{$key};
				# }
			# }
			delete $cache->{$_} for grep { /^$class/ } keys %{$cache};
			return;
		}
		if(defined($^V) && ($^V ge 'v5.14.0')) {
			return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
		}
		$cache->purge();
		return;
	}

	# my $method = $self->{'object'} . "::$param";
	my $object = $self->{'object'};

	# if($param =~ /^[gs]et_/) {
		# # $param = "SUPER::$param";
		# return $object->$method(\@_);
	# }

	# TODO: To add argument support, make the code more than simply "param",
	#	e.g. my $cache_key = join('|', $param, @_);

	my $key = ref($self) . ":$param";

	if(scalar(@_) == 0) {	# Getter
		# Retrieving a value
		my $rc;
		if(ref($cache) eq 'HASH') {
			$rc = $cache->{$key};
		} else {
			$rc = $cache->get($key);
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
			my @rc = $object->$param();
			if(scalar(@rc) == 0) {
				return;
			}
			if(ref($cache) eq 'HASH') {
				$cache->{$key} = \@rc;
			} else {
				$cache->set($key, \@rc, 'never');
			}
			return @rc;
		}
		if(defined(my $rc = $object->$param())) {
			if(ref($cache) eq 'HASH') {
				return $cache->{$key} = $rc;
			}
			return $cache->set($key, $rc, 'never');
		}
		if(ref($cache) eq 'HASH') {
			return $cache->{$key} = __PACKAGE__ . '>UNDEF<';
		}
		$cache->set($key, __PACKAGE__ . '>UNDEF<', 'never');
		return;
	}

	# Setter

	# $param = "SUPER::$param";
	# return $cache->set($key, $self->$param(@_), 'never');
	if($_[1]) {
		# Storing an array
		# We store a ref to the array, and dereference on retrieval
		if(defined(my $val = $object->$param(\@_))) {
			if(ref($cache) eq 'HASH') {
				$cache->{$key} = $val;
			} else {
				$cache->set($key, $val, 'never');
			}
			return @{$val};
		}
		if(ref($cache) eq 'HASH') {
			return $cache->{$param} = __PACKAGE__ . '>UNDEF<';
		}
		$cache->set($key, __PACKAGE__ . '>UNDEF<', 'never');
		return;
	}
	# Storing a scalar
	if(ref($cache) eq 'HASH') {
		return $cache->{$key} = $object->$param($_[0]);
	}
	return $cache->set($key, $object->$param($_[0]), 'never');
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Doesn't work with L<Memoize>.

Only works on messages that take no arguments.
For that, use L<Class::Simple::Readonly::Cached>.

Please report any bugs or feature requests to L<https://github.com/nigelhorne/Class-Simple-Readonly/issues>.
I will be notified,
and then you'll automatically be notified of the progress on your bug as I make changes.

=head1 SEE ALSO

L<Class::Simple>, L<CHI>

=head1 SUPPORT

This module is provided as-is without any warranty.

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

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Class::Simple::Cached>

=back

=head1 LICENCE AND COPYRIGHT

Author Nigel Horne: C<njh@bandsman.co.uk>
Copyright (C) 2019-2025, Nigel Horne

Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.
=cut

1;
