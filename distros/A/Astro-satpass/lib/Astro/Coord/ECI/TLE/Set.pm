=head1 NAME

Astro::Coord::ECI::TLE::Set - Represent a set of data for the same ID.

=head1 SYNOPSIS

 use Astro::SpaceTrack;
 use Astro::Coord::ECI::TLE;
 use Astro::Coord::ECI::TLE::Set;
 use Astro::Coord::ECI::Utils qw{rad2deg};

 # Get orbital data on the International Space Station and
 # related NASA stuff. 
 my $st = Astro::SpaceTrack->new();
 my $rslt = $st->spaceflight('-all');
 $rslt->is_success
     or die "Unable to get data: ", $rslt->status_line;
 
 # We aggregate the data because NASA provides multiple sets
 # of orbital elements for each body. The Set object will
 # select the correct one for the given time.
 my @sats = Astro::Coord::ECI::TLE::Set->aggregate (
     Astro::Coord::ECI::TLE->parse ($rslt->content));
 my $now = time ();
 
 # Display current International Space Station (etc)
 # position in terms of latitude, longitude, and altitude.
 # Like all position methods, geodetic() returns angles in
 # radians and distances in kilometers.
 print join ("\t", qw{OID Latitude Longitude Altitude}
    ), "\n";
 foreach my $tle (@sats) {
    my ($lat, $long, $alt) = $tle->universal($now)
       ->geodetic();
    print join ("\t", $tle->get ('id'),
       rad2deg($lat), rad2deg($long), $alt),
       "\n";
 }

=head1 DESCRIPTION

This module is intended to represent a set of orbital elements,
representing the same NORAD ID at different points in time. It
can contain any number of objects of class Astro::Coord::ECI::TLE
(or any subclass thereof) provided all contents are of the same
class and represent the same NORAD ID.

In addition to the methods documented here, an
Astro::Coord::ECI::TLE::Set supports all methods provided by the
currently-selected member object, through Perl's AUTOLOAD mechanism.
In this way, the object is almost a plug-compatible replacement for
an Astro::Coord::ECI::TLE object, but it uses the orbital elements
appropriate to the time given. The weasel word 'almost' is expanded
on in the L</Incompatibilities with Astro::Coord::ECI::TLE> section,
below.

When the first member object is added via the add() method, it becomes
the currently-selected object. The select() method can be used to
select the member that best represents the time passed to the select
method. In addition, certain method calls that are delegated to the
currently-selected member object can cause a new member to be selected
before the delegation is done. These include 'universal', 'dynamical',
and any Astro::Coord::ECI::TLE orbital propagation model.

There may be cases where the member class does not want to use the
normal delegation mechanism. In this case, it needs to define a
_nodelegate_xxxx method, where xxxx is the name of the method that
is not to be delegated to. The _nodelegate method is called with the
same calling sequence as the original method, but the first argument
is a reference to the Astro::Coord::ECI::TLE::Set object, not the
member object. Use of this mechanism constitutes a pledge that the
_nodelegate method does not make use of any private interfaces to the
member objects.

=head2 Incompatibilities with Astro::Coord::ECI::TLE

=head3 Inheritance

Astro::Coord::ECI::TLE::Set is not a member of the Astro::Coord::ECI
inheritance hierarchy, so $set->isa ('Astro::Coord::ECI') is false.

=head3 Calling semantics for delegated behaviors

In general, when Astro::Coord::ECI::TLE::Set delegates functionality
to a member object, that object's method receives a reference to the
member object as its first argument. That is, if $set is the
Astro::Coord::ECI::TLE::Set object and $tle is the relevant member
object, $set->method (...) becomes $tle->method (...) from the point
of view of the called method.

If the member class wishes to see the Astro::Coord::ECI::TLE::Set
object as the first argument of method xxxx, it defines method
_nodelegate_xxxx, which is called as though by $set->_nodelegate_xxx
(...). The _nodelegate_xxx method must use only the public interface
to the $tle object (whatever its class). A cheap way to get this
method is

 *_nodelegate_xxxx = \&xxxx;

but nothing says the _nodelegate_xxxx method B<must> be defined this
way.

The C<universal> and C<dynamical> methods are special-cased in the
AUTOLOAD code so that a select() is done before they are called.

=head3 Calling semantics for static behaviors

Some Astro::Coord::ECI methods (e.g. universal()) will instantiate an
object for you if you call them statically. This will not work with
Astro::Coord:ECI::TLE::Set; that is,
Astro::Coord::ECI::TLE::Set->universal () is an error.

=head3 Return semantics for delegated behaviors

In general, when behavior is delegated to a member object, the return
is whatever the delegated method returns. This means that, for methods
that return the object they are called on (e.g. universal()) you get
back a reference to the member object, not a reference to the
containing Astro::Coord::ECI::TLE::Set object.

=head2 Methods

The following methods should be considered public:

=over

=cut

package Astro::Coord::ECI::TLE::Set;

use strict;
use warnings;

use Astro::Coord::ECI::Utils qw{ :params :ref max @CARP_NOT };
use Carp;

our @CARP_NOT = qw{
    Astro::Coord::ECI::TLE::Iridium
    Astro::Coord::ECI::TLE
    Astro::Coord::ECI
};

our $VERSION = '0.117';

use constant ERR_NOCURRENT => <<eod;
Error - Can not call %s because there is no current member. Be
        sure you called add() after instantiating or calling clear().
eod


=item $set = Astro::Coord::ECI::TLE::Set->new ()

This method instantiates a new set. Any arguments are passed to the
add() method.

=cut

sub new {
    my ($class, @args) = @_;
    $class = ref $class if ref $class;
    my $self = {
	current => undef,	# Current member
	members => [],		# [effective, TLE].
    };
    bless $self, $class;
    $self->add (@args) if @args;
    return $self;
}


=item $set->add ($member ...);

This method adds members to the set. The initial member may be any
initialized member of the Astro::Coord::ECI::TLE class, or any subclass
thereof. Subsequent members must be the same class as the initial
member, and represent the same NORAD ID. If not, an exception is thrown.
If a prospective member has the same effective date as a current member,
the prospective member is silently ignored. If a member does not have an
effective date, the epoch is used as a proxy for the effective date.

The first member added becomes the current member for the purpose
of delegating method calls. Adding subsequent members does not
change the current member, though it may be appropriate to call
select() after adding.

=cut

sub add {
    my ($self, @args) = @_;
    my ($id, %ep, $class);
    foreach (@{$self->{members}}) {
	my ($effective, $tle) = @$_;
	$id ||= $tle->get ('id');
	$class ||= ref $tle;
	$effective = $tle->get('effective');
	defined $effective or $effective = $tle->get('epoch');
	$ep{$effective} = $tle;
    }
    foreach my $tle (map {__instance( $_, __PACKAGE__ ) ?
	    $_->members : $_} @args) {
	my $aid = $tle->get ('id');
	if (defined $id) {
	    __instance( $tle, $class ) or croak <<eod;
Error - Additional member of @{[__PACKAGE__]} must be a
        subclass of $class
eod
	    $aid == $id or croak <<eod;
Error - NORAD ID mismatch. Trying to add ID $aid to set defined
        as ID $id.
eod
	} else {
	    __instance( $tle, 'Astro::Coord::ECI::TLE' ) or croak <<eod;
Error - First member of @{[__PACKAGE__]} must be a subclass
        of Astro::Coord::ECI::TLE.
eod
	    $class = ref $tle;
	    $id = $aid;
	    $self->{current} = $tle;
	}
	my $aep = $tle->get ('effective');
	defined $aep or $aep = $tle->get('epoch');
	next if $ep{$aep};
	$ep{$aep} = $tle;
    }
    @{$self->{members}} = sort {$a->[0] <=> $b->[0]}
	map {[$_, $ep{$_}]} keys %ep;
    return $self;
}


=item @sets = Astro::Coord::ECI::TLE::Set->aggregate ($tle ...);

This method aggregates the given Astro::Coord::ECI::TLE objects into
sets by NORAD ID. If there is only one object with a given NORAD ID, it
is simply returned intact, B<not> made into a set with one member.

If you should for some reason want sets with one member, do

 $Astro::Coord::ECI::TLE::Set::Singleton = 1;

before you call aggregate(). Actually, any value that Perl will
interpret as true will work. You might want a 'local' in front of all
this.

Optionally, the first argument may be a hash reference. The hash
contains options that modify the function of this method. The only
option at the moment is

 select => $time

which causes the object best representing the given time to be selected
in any Astro::Coord::ECI::TLE::Set objects.

=cut

our $Singleton = 0;

sub aggregate {
    my ($class, @args) = @_;
    $class = ref $class if ref $class;
    my $opt = HASH_REF eq ref $args[0] ? shift @args : {};
    my %data;
    my @rslt;
    foreach my $tle ( @args ) {
	my $model = $tle->get( 'model' );
	my $id = $tle->get ('id');
	if ( '' eq $id && 'null' eq $model ) {
	    push @rslt, $tle;
	} else {
	    $data{$id} ||= [];
	    push @{$data{$id}}, $tle;
	}
    }
    my $limit = $Singleton ? 0 : 1;
    foreach my $id (sort keys %data) {
	my $items = @{$data{$id}};
	if ($items > $limit) {
	    my $set = $class->new(@{$data{$id}});
	    exists $opt->{select}
		and $set->select($opt->{select});
	    push @rslt, $set;
	} else {
	    push @rslt, @{$data{$id}};
	}
    }
    return @rslt;
}


=item $set->can ($method);

This method checks to see if the object can execute the given method.
If so, it returns a code reference to the subroutine; otherwise it
returns undef.

This override to UNIVERSAL::can is necessary because we want to return
true for member class methods, but we execute them by autoloading, so
they are not in our namespace.

=cut

sub can {
    my ($self, $method) = @_;
    my $rslt = eval {$self->SUPER::can($method)};
    $@ and return;
    $rslt and return $rslt;

    return eval {	## no critic (RequireCheckingReturnValueOfEval)
	$self->{current}->can($method)
    };
}


=item $set->clear ();

This method removes all members from the set, allowing it to be
reloaded with a different NORAD ID.

=cut

sub clear {
    my $self = shift;
    $self->{current} = undef;
    @{$self->{members}} = ();
    return $self;
}

=item $value = $set->get( $name );

This method returns the value of the named attribute.

If the attribute name is C<'tle'>, it returns the concatenated TLE data
of all TLEs in the set. Otherwise it simply returns the named attribute
of the selected C<Astro::Coord::ECI::TLE> object.

=cut

{
    my %override = (
	tle	=> sub {
##	    my ( $self, $name ) = @_;
	    my ( $self ) = @_;	# Name unused
	    my $output;
	    foreach my $body ( $self->members() ) {
		$output .= $body->get( 'tle' );
	    }
	    return $output;
	},
    );

    sub get {
	my ( $self, $name ) = @_;
	$override{$name}
	    and return $override{$name}->( $self, $name );
	return $self->select()->get( $name );
    }
}

=item $time = $set->max_effective_date(...);

This method extends the L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE>
C<max_effective_date()> method appropriately for sets of elements.

If there are arguments, their maximum is taken, the appropriate member
element is set, and C<max_effective_date()> is called on that element,
passing the date used to select the element. If there are no arguments,
C<max_effective_date()> is called on the current element, with no
arguments. If the set has no members, the maximum of the arguments is
returned (or C<undef> if there are no arguments).

=cut

sub max_effective_date {
    my ($self, @args) = @_;
    @{ $self->{members} } or return max(@args);
    if (@args) {
	my $effective = max @args;
	my $tle = $self->select($effective);
	return $tle->max_effective_date($effective);
    } else {
	return $self->{current}->max_effective_date();
    }
}

=item @tles = $set->members ();

This method returns all members of the set, in ascending order by
effective date.

=cut

sub members {
    my $self = shift;
    return ( map { $_->[1] } @{ $self->{members} } );
}

=item $set->represents($class)

If the set has a current member, this method returns true if the current
member represents the given class, or the class name of the current
member if no argument is given.

If the set has no current member, an exception is thrown.

See the Astro::Coord::ECI represents() method for the details of the
behavior if the set has a current member.

Normally we would just let AUTOLOAD take care of this, but it turned out
to be handy to be able to call UNIVERSAL::can on this method.

=cut

sub represents {
    my ($self, $class) = @_;
    $self->{current} or croak sprintf ERR_NOCURRENT, 'represents';
    return $self->{current}->represents($class);
}


=item $set->select ($time);

This method selects the member object that best represents the given
time, and returns that member. If called without an argument or with an
undefined argument, it simply returns the currently-selected member.

The 'best representative' member for a given time is chosen by
considering all members in the set, ordered by ascending effective date.
If all epochs are after the given time, the earliest effective date is
chosen. If some epochs are on or before the given time, the latest
effective date that is not after the given time is chosen.

The 'best representative' algorithm tries to select the element set that
would actually be current at the given time. If no element set is
current (i.e. all are in the future at the given time) we take the
earliest, to minimize peeking into the future. This is done even if that
member's 'backdate' attribute is false.

=cut

sub select : method {	## no critic (ProhibitBuiltInHomonyms)
    my ($self, $time) = @_;
    if (defined $time) {
	croak <<eod unless @{$self->{members}};
Error - Can not select a member object until you have added members.
eod
	my ($effective, $current);
	foreach (@{$self->{members}}) {
	    ($effective, $current) = @$_
		unless defined $effective && $_->[0] > $time;
	}
	$self->{current} = $current;
    }
    return $self->{current};
}


=item $set->set ($name => $value ...);

This method iterates over the individual name-value pairs. If the name
is an attribute of the object's model (that is, if is_model_attribute ()
returns true), it calls set_selected($name, $value). Otherwise, it calls
set_all($name, $value). If the set has no members, this method simply
returns.

=cut

sub set {
    my ($self, @args) = @_;
    return $self unless $self->{current};
    while (@args) {
	my $name = shift @args;
	if ($self->{current}->is_model_attribute ($name)) {
	    $self->set_selected ($name, shift @args);
	} else {
	    $self->set_all ($name, shift @args);
	}
    }
    return $self;
}


=item $set->set_all ($name => $value ...);

This method sets the given attribute values on all members of the set.
It is not an error to call this on an object with no members, but
neither does it accomplish anything useful.

=cut

sub set_all {
    my ($self, @args) = @_;
    foreach my $member (@{$self->{members}}) {
	$member->[1]->set (@args);
    }
    return $self;
}

=item $set->set_selected ($name => $value ...);

This method sets the given attribute values on the currently-selected
member of the set. It is an error to call this on an object with no
members.

=cut

sub set_selected {
    my ($self, @args) = @_;
    my $delegate = $self->{current} or
	croak sprintf ERR_NOCURRENT, 'set_selected';
    return $delegate->set (@args);
}

=item $valid = $set->validate($options, $time ...);

This method calls C<validate()> on each of the members of the set,
removing from the set any members that fail to validate. The number of
members remaining in the set is returned.

The $options argument is itself optional. If passed, it is a reference
to a hash of option names and values. See the
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> C<validate()> method for
the details.

Each member of the set will be validated at the time it would first be
used for computations (if that is defined) and at the time its successor
in the set (if any) would first be used for computation. In addition,
each member will be validated at any of the C<$time> arguments that
happens to fall between these two times.

If a member is removed, validate() will call itself recursively to
ensure that the new set is still valid.

=cut

sub validate {
    my ( $self, @args ) = @_;
    my $opt = HASH_REF eq ref $args[0] ? shift @args : {};

    my @members = map { [ @{ $_ } ] } @{ $self->{members} };
    $members[0][1]->get('backdate') and $members[0][0] = undef;
    foreach my $inx (0 .. $#members - 1) {
	$members[$inx][2] = $members[$inx + 1][0];
    }

    my @valid;
    foreach ( @members ) {
	my ($start, $tle, $end) = @{ $_ };
	my @check = grep { defined $_ } $start, $end;
	foreach my $time ( @args ) {
	    defined $end and $time > $end and next;
	    defined $start and $time < $start and next;
	    push @check, $time;
	}
	$tle->validate($opt, @check) and push @valid, [$start, $tle];
    }

    @valid == @members and return @members;

    @valid or do {
	$self->clear();
	return 0;
    };

    defined $valid[0][0]
	or $valid[0][0] = $valid[0][1]->get('effective');
    defined $valid[0][0]
	or $valid[0][0] = $valid[0][1]->get('epoch');

    my $time;
    $self->{current} and $time = $self->{current}->get('epoch');

    $self->{members} = \@valid;

    defined $time and $self->select($time);

    return $self->validate($opt, @args);
}


#	The AUTOLOAD routine does not define methods, it simply
#	simulates them. This is because there is no good way to
#	get rid of the routines if we end up representing a
#	different class.

my %selector = map {$_ => 1} qw{dynamical universal};

sub AUTOLOAD {
    my @args = @_;
    my $self = $args[0];
    our $AUTOLOAD;
    (my $routine = $AUTOLOAD) =~ s/.*:://;
    my $delegate = $self->{current} or
	croak sprintf ERR_NOCURRENT, $routine;
    if (@args > 1 && ($selector{$routine} ||
	    $delegate->is_valid_model ($routine))) {
	$self->select ($args[1]);
	$delegate = $self->{current};
    }
    my $coderef;
    if ($coderef = $delegate->can ("_nodelegate_$routine")) {
    } elsif ($coderef = $delegate->can ($routine)) {
####	splice @args, 0, 1, $delegate;	# Not $_[0] = $delegate!!!
	$args[0] = $delegate;
    } else {
	croak <<eod;
Error - Can not call $routine because it is not supported by
        class @{[ref $delegate]}
eod
    }
    return $coderef->(@args);
}

sub DESTROY {
    my $self = shift;
    $self = undef;
    return;
}

1;
__END__

=back

=head1 BUGS

Bugs can be reported to the author by mail, or through
L<https://github.com/trwyant/perl-Astro-Coord-ECI/issues/>.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
