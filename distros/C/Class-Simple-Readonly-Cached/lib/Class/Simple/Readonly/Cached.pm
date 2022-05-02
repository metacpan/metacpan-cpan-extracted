package Class::Simple::Readonly::Cached;

use strict;
use warnings;
use Carp;
use Class::Simple;

my @ISA = ('Class::Simple');

=head1 NAME

Class::Simple::Readonly::Cached - cache messages to an object

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

A sub-class of L<Class::Simple> which caches calls to read
the status of an object that are otherwise expensive.

It is up to the caller to maintain the cache if the object comes out of sync with the cache,
for example by changing its state.

You can use this class to create a caching layer to an object of any class
that works on objects which doesn't change its state based on input:

    $val = $obj->val();
    $val = $obj->val(a => 'b');

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Class::Simple::Readonly::Cached object.

It takes one mandatory parameter: cache,
which is either an object which understands clear(), get() and set() calls,
such as an L<CHI> object;
or is a reference to a hash where the return values are to be stored.

It takes one optional argument: object,
which is an object which is taken to be the object to be cached.
If not given, an object of the class L<Class::Simple> is instantiated
and that is used.

    use Gedcom;

    my %hash;
    my $person = Gedcom::Person->new();
    ... # Set up some data
    my $object = Class::Simple::Readonly::Cached(object => $person, cache => \%hash);
    my $father1 = $object->father();	# Will call gedcom->father() to get the person's father
    my $father2 = $object->father();	# Will retrieve the father from the cache without calling person->father()

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# Use Class::Simple::Readonly::Cached->new(), not Class::Simple::Readonly::Cached::new()
	if(!defined($class)) {
		Carp::carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
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

	if(!$args{'cache'}) {
		Carp::carp('Usage: ', __PACKAGE__, '->new(cache => $cache [, object => $object ], %args)');
		return;
	}

	if(defined($args{'object'})) {
		if(ref($args{'object'})) {
			if(ref($args{'object'}) eq __PACKAGE__) {
				Carp::carp(__PACKAGE__, ' warning: $object is already cached');
				# Note that this isn't a technique for clearing the cache
				return $args{'object'};
			}
		} else {
			Carp::carp(__PACKAGE__, ' $object is a scalar');
			return;
		}
	} else {
		$args{'object'} = Class::Simple->new(%args);
	}

	return bless \%args, $class;
}

=head2 object

Return the encapsulated object

=cut

sub object
{
	my $self = shift;

	return $self->{'object'};
}

sub _caller_class
{
	my $self = shift;

	if(ref($self->{'object'}) eq 'Class::Simple') {
		# return $self->SUPER::_caller_class(@_);
		return $self->Class::Simple::_caller_class(@_);
	}
}

=head2 state

Returns the state of the object

    print Data::Dumper->new([$obj->state()]->Dump();

=cut

sub state {
	my $self = shift;

	return { hits => $self->{_hits}, misses => $self->{_misses} };
}

# Returns a cached object, if you want it to be uncached, you'll need to clone it
sub AUTOLOAD {
	our $AUTOLOAD;
	my $param = $AUTOLOAD;
	$param =~ s/.*:://;

	my $self = shift;
	my $cache = $self->{'cache'};

	if($param eq 'DESTROY') {
		if($cache) {
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
		}
		return;
	}

	# my $func = $self->{'object'} . "::$param";
	my $func = $param;

	# if($param =~ /^[gs]et_/) {
		# # $param = "SUPER::$param";
		# return $object->$func(\@_);
	# }

	my $key = $param . '::' . join('::', grep defined, @_);

	my $rc;
	if(ref($cache) eq 'HASH') {
		$rc = $cache->{$key};
	} else {
		$rc = $cache->get($key);
	}
	if(defined($rc)) {
		# Retrieving a value
		die $key if($rc eq 'never');
		if(ref($rc) eq 'ARRAY') {
			$self->{_hits}{$key}++;
			my @foo = @{$rc};
			if(wantarray) {
				if(defined($foo[0])) {
					die $key if($foo[0] eq __PACKAGE__ . '>UNDEF<');
					die $key if($foo[0] eq 'never');
				}
				return @{$rc};
			}
			return pop @foo;
		}
		if($rc eq __PACKAGE__ . '>UNDEF<') {
			$self->{_hits}{$key}++;
			return;
		}
		if(!wantarray) {
			$self->{_hits}{$key}++;
			return $rc;
		}
		# Want array from cached array after previously requesting it as a scalar
	}
	$self->{_misses}{$key}++;
	my $object = $self->{'object'};
	if(wantarray) {
		my @rc = $object->$func(@_);
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
	$rc = $object->$func(@_);
	if(!defined($rc)) {
		if(ref($cache) eq 'HASH') {
			$cache->{$key} = __PACKAGE__ . '>UNDEF<';
		} else {
			$cache->set($key, __PACKAGE__ . '>UNDEF<', 'never');
		}
		return;
	}
	# This would be nice, but it does break gedcom.  TODO: find out why
	# if(ref($rc) && (ref($rc) =~ /::/) && (ref($rc) ne __PACKAGE__)) {
		# $rc = Class::Simple::Readonly::Cached->new(object => $rc, cache => {});
	# }
	if(ref($cache) eq 'HASH') {
		return $cache->{$key} = $rc;
	}
	return $cache->set($key, $rc, 'never');
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Doesn't work with L<Memoize>.

Please report any bugs or feature requests to L<https://github.com/nigelhorne/Class-Simple-Readonly-Cached/issues>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Class::Simple>, L<CHI>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Simple::Readonly::Cached

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Class-Simple-Readonly-Cached>

=item * Source Repository

L<https://github.com/nigelhorne/Class-Simple-Readonly-Cached>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/Class-Simple-Readonly-Cached>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Class-Simple-Readonly-Cached>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-Simple-Readonly-Cached>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Class::Simple::Readonly::Cached>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-Simple-Readonly-Cached/>

=back

=head1 LICENSE AND COPYRIGHT

Author Nigel Horne: C<njh@bandsman.co.uk>
Copyright (C) 2019-2022 Nigel Horne

Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.
=cut

1;
