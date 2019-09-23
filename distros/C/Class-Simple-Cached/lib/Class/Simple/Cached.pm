package Class::Simple::Cached;

use strict;
use warnings;
use Carp;
use Class::Simple;

my @ISA = ('Class::Simple');

=head1 NAME

Class::Simple::Cached - cache messages to an object

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

A sub-class of L<Class::Simple> which caches calls to read
the status of an object that are otherwise expensive.

It is up to the caller to maintain the cache if the object comes out of sync with the cache,
for example by changing its state.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Class::Simple::Cached object.

It takes one mandatory parameter: cache,
which is an object which understands get() and set() calls,
such as an L<CHI> object.

It takes one optional argument: object,
which is an object which is taken to be the object to be cached.
If not given, an object of the class L<Class::Simple> is instantiated
and that is used.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

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

	if($args{'cache'}) {
		return bless \%args, $class;
	}
	Carp::carp('Usage: ', __PACKAGE__, '->new(cache => $cache [, object => $object ], %args)');
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
		if(my $rc = $cache->get($param)) {
			if(ref($rc) eq 'ARRAY') {
				return @{$rc};
			}
			if($rc eq __PACKAGE__ . ">UNDEF<") {
				return;
			}
			return $rc;
		}
		if(wantarray) {
			my @rc = $object->$func();
			if(scalar(@rc) == 0) {
				return;
			}
			$cache->set($param, \@rc, 'never');
			return @rc;
		}
		my $rc = $object->$func();
		if(!defined($rc)) {
			$cache->set($param, __PACKAGE__ . ">UNDEF<", 'never');
			return;
		}
		return $cache->set($param, $rc, 'never');
	}

	# $param = "SUPER::$param";
	# return $cache->set($param, $self->$param(@_), 'never');
	if($_[1]) {
		# Storing an array
		# We store a ref to the array, and dereference on retrieval
		my $val = $object->$func(\@_);
		$cache->set($param, $val, 'never');
		return @{$val};
	}
	# Storing a scalar
	return $cache->set($param, $object->$func($_[0]), 'never');
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Doesn't work with L<Memoize>.

Please report any bugs or feature requests to C<bug-class-simple-cached at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Simple-Cached>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

params() returns a ref which means that calling routines can change the hash
for other routines.
Take a local copy before making amendments to the table if you don't want unexpected
things to happen.

=head1 SEE ALSO

L<Class::Simple>, L<CHI>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Simple::Cached

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Simple-Cached>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-Simple-Cached>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-Simple-Cached/>

=back

=head1 LICENSE AND COPYRIGHT

Author Nigel Horne: C<njh@bandsman.co.uk>
Copyright (C) 2019, Nigel Horne

Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.
=cut

1;
