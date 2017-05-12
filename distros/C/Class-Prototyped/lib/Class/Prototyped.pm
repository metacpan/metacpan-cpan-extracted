#############################################################################
#
# Class::Prototyped - Fast prototype-based OO programming in Perl
#
# Author: Ned Konz and Toby Ovod-Everett
#############################################################################
# Copyright 2001-2004 Ned Konz and Toby Ovod-Everett.  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
#############################################################################

# Class::Prototyped - Fast prototype-based OO programming in Perl

package Class::Prototyped::Mirror;
sub PREFIX()        { 'PKG0x' }
sub PREFIX_LENGTH() { 5 }


package Class::Prototyped;
use strict;
use Carp();

$Class::Prototyped::VERSION = '1.13';

sub import {
	while (my $symbol = shift) {
		if ($symbol eq ':OVERLOAD') {
			unless (scalar keys %Class::Prototyped::overloadable_symbols) {
				eval "use overload";
				@Class::Prototyped::overloadable_symbols{ map { split }
						values %overload::ops } = undef;
			}
		}
		elsif ($symbol eq ':REFLECT') {
			*UNIVERSAL::reflect =
				sub { Class::Prototyped::Mirror->new($_[0]) };
		}
		elsif ($symbol eq ':EZACCESS') {
			no strict 'refs';

			foreach my $call (
				qw(addSlot addSlots deleteSlot deleteSlots getSlot getSlots super)
			) {
				*{$call} = sub {
					my $obj = shift->reflect;
					UNIVERSAL::can($obj, $call)->($obj, @_);
				};
			}
		}
		elsif ($symbol eq ':SUPER_FAST') {
			*Class::Prototyped::Mirror::super =
				\&Class::Prototyped::Mirror::super_fast;
		}
		elsif ($symbol eq ':NEW_MAIN') {
			*main::new = sub { Class::Prototyped->new(@_) };
		}
	}
}

# Constructor. Pass in field definitions.
sub new {
	my $class = shift;

	Carp::croak("odd number of slot parameters to new\n") if scalar(@_) % 2;

	$class->newCore('new', undef, @_);
}

sub newPackage {
	my $class   = shift;
	my $package = shift;

	Carp::croak("odd number of slot parameters to newPackage\n") if scalar(@_) % 2;

	$class->newCore('newPackage', $package, @_);
}

# Creates a copy of an object
sub clone {
	my $original = shift;

	Carp::croak("odd number of slot parameters to clone\n") if scalar(@_) % 2;

	$original->newCore('clone', undef, @_);
}

sub clonePackage {
	my $original = shift;
	my $package = shift;

	Carp::croak("odd number of slot parameters to clonePackage\n") if scalar(@_) % 2;

	$original->newCore('clonePackage', $package, @_);
}


sub newCore {
	my $class   = shift;
	my $caller  = shift;
	my $package = shift;

	my $isPackage = substr($caller, -7) eq 'Package';
	my $isNew = substr($caller, 0, 3) eq 'new';
	my $isClone = substr($caller, 0, 5) eq 'clone';

	Carp::croak("odd number of slot parameters to $caller\n") if scalar(@_) % 2;

	my $class_mirror = $class->reflect;

	my($self, $tied);
	{
		no strict 'refs';

		if ( $isPackage ) {
			if (scalar(keys %{"$package\::"})) {
				Carp::croak(
					"attempt to use newPackage with already existing package\n"
						. "package: $package");
			}
			my %self;
			tie %self, $class_mirror->tiedInterfacePackage();
			$tied = tied %self;
			$Class::Prototyped::Mirror::objects{$package} = $self = \%self;
		}
		else {
			$self = {};
			$package = Class::Prototyped::Mirror::PREFIX . substr("$self", 7, -1);    # HASH($package)

			tie %$self, $class->reflect->tiedInterfacePackage();

			$tied = tied %$self;
			*{"$package\::DESTROY"} = \&Class::Prototyped::DESTROY;
		}
	}

	$tied->package($package);
	@{ $tied->{isa} } = qw(Class::Prototyped);
	$tied->{vivified_parents} = 1;
	$tied->{vivified_methods} = 1;
	$tied->{defaults} = $class_mirror->_defaults;

	bless $self, $package;    # in my own package

	my $parsedSlots = scalar @_ || $isClone ?
			$self->reflect->addSlotsParser( ( $isClone ? $class->reflect->getSlots() : () ), @_ ) :
			[];

	if ( $isNew )	{
		my $classstar = ( ref($class) &&
				substr(ref($class), 0, Class::Prototyped::Mirror::PREFIX_LENGTH) ne 
					Class::Prototyped::Mirror::PREFIX
			) ? ref($class) : $class;   # allow object for named class to provide a class name

		if (!(grep { $_->[0] eq 'class*' } @$parsedSlots) && $classstar ne 'Class::Prototyped')
		{
			unshift(@$parsedSlots, @{$self->reflect->addSlotsParser('class*' => $classstar)});
		}
	}

	$self->reflect->addParsedSlots($parsedSlots) if scalar(@$parsedSlots);

	return $self;
}

sub reflect {
	return $Class::Prototyped::Mirror::mirrors{ $_[0] } || Class::Prototyped::Mirror->new($_[0]);
}

sub destroy {
	my $self   = shift;
	my $mirror = $self->reflect;
	my(@otherOrder) = @{$mirror->_otherOrder};
	$mirror->deleteSlots(@otherOrder);
}

# Remove my symbol table
sub DESTROY {
	my $self    = shift;
	my $package = ref($self);
	if ((substr($package, 0, Class::Prototyped::Mirror::PREFIX_LENGTH) eq
			Class::Prototyped::Mirror::PREFIX)
		&& ($package ne 'Class::Prototyped'))
	{
		no strict 'refs';

		my $tied        = tied(%$self) or return;
		my $parentOrder = $tied->{parentOrder};
		my $isa         = $tied->{isa};
		my $slots       = $tied->{slots};

		my (@deadIndices);
		foreach my $i (0 .. $#$parentOrder) {
			my $parent = $slots->{ $parentOrder->[$i] };
			my $parentPackage = ref($parent) || $parent;
			push (@deadIndices, $i)
				unless scalar(keys %{"$parentPackage\::"});
		}

		foreach my $i (@deadIndices) {
			delete($slots->{ $parentOrder->[$i] });
			splice(@$parentOrder, $i, 1);
			splice(@$isa,         $i, 1);
		}

		# this is required to re-cache @ISA
		delete ${"$package\::"}{'::ISA::CACHE::'};
		@$isa=@$isa;

		my $parent_DESTROY;
		my (@isa_queue) = @{"$package\::ISA"};
		my (%isa_cache);
		while (my $pkg = shift @isa_queue) {
			exists $isa_cache{$pkg} and next;
			my $code = *{"$pkg\::DESTROY"}{CODE};
			if (defined $code && $code != \&Class::Prototyped::DESTROY) {
				$parent_DESTROY = $code;
				last;
			}
			unshift (@isa_queue, @{"$pkg\::ISA"});
			$isa_cache{$pkg} = undef;
		}

		$self->destroy;    # call the user destroy function

		$parent_DESTROY->($self) if defined $parent_DESTROY;

		$self->reflect->deleteSlots($self->reflect->slotNames('PARENT'));

		foreach my $key (keys %{"$package\::"}) {
			delete ${"$package\::"}{$key};
		}

		# this only works because we're not a multi-level package:
		delete($main::{"$package\::"});

		delete($Class::Prototyped::Mirror::parents{$package});
	}
}

$Class::Prototyped::Mirror::ending = 0;
sub END { $Class::Prototyped::Mirror::ending = 1 }

package Class::Prototyped::Tied;
$Class::Prototyped::Tied::VERSION = '1.13';
@Class::Prototyped::Tied::DONT_LIE_FOR = qw(Data::Dumper);

sub TIEHASH {
	bless $_[1] || {
			package          => undef,
			isa              => undef,
			parentOrder      => [],
			otherOrder       => [],
			slots            => {},
			types            => {},
			attribs          => {},
			defaults         => undef,
			vivified_parents => 0,
			vivified_methods => 0,
		},
		$_[0];
}

sub FIRSTKEY {
	$_[0]->{dont_lie} = 0;
	my $caller = (caller(0))[0];
	foreach my $i (@Class::Prototyped::Tied::DONT_LIE_FOR) {
		$_[0]->{dont_lie} = $caller eq $i and last;
	}
	$_[0]->{iter}        = 1;
	$_[0]->{cachedOrder} = [@{ $_[0]->{parentOrder} }, @{ $_[0]->{otherOrder} }];

	unless ($_[0]->{dont_lie}) {
		my $slots = $_[0]->{slots};
		@{ $_[0]->{cachedOrder} } =
			grep { !UNIVERSAL::isa($slots->{$_}, 'CODE') }
			@{ $_[0]->{cachedOrder} };
	}
	return $_[0]->{cachedOrder}->[0];
}

sub NEXTKEY {
	return $_[0]->{cachedOrder}->[ $_[0]->{iter}++ ];
}

sub EXISTS {
	exists $_[0]->{slots}->{ $_[1] } or return 0;
	UNIVERSAL::isa($_[0]->{slots}->{ $_[1] }, 'CODE') or return 1;
	my $dont_lie = 0;
	my $caller   = (caller(0))[0];
	foreach my $i (@Class::Prototyped::Tied::DONT_LIE_FOR) {
		$dont_lie = $caller eq $i and last;
	}
	return $dont_lie ? 1 : 0;
}

sub CLEAR {
	Carp::croak("attempt to call CLEAR on the hash interface"
			. " of a Class::Prototyped object\n");
}

sub package {
	return $_[0]->{package} unless @_ > 1;
	no strict 'refs';
	$_[0]->{isa}     = \@{"$_[1]\::ISA"};
	$_[0]->{package} = $_[1];
}

#### Default Tied implementation
package Class::Prototyped::Tied::Default;
$Class::Prototyped::Tied::Default::VERSION = '1.13';
@Class::Prototyped::Tied::Default::ISA = qw(Class::Prototyped::Tied);

sub STORE {
	my $slots = $_[0]->{slots};

	Carp::croak(
		"attempt to access non-existent slot through tied hash object interface"
		)
		unless exists $slots->{ $_[1] };

	Carp::croak(
		"attempt to access METHOD slot through tied hash object interface")
		if UNIVERSAL::isa($slots->{ $_[1] }, 'CODE');

	Carp::croak(
		"attempt to modify parent slot through the tied hash object interface")
		if substr($_[1], -1) eq '*';

	$slots->{ $_[1] } = $_[2];
}

sub FETCH {
	my $slots = $_[0]->{slots};

	Carp::croak(
"attempt to access non-existent slot through tied hash object interface:\n"
			. "$_[1]")
		unless exists $slots->{ $_[1] };

	if (UNIVERSAL::isa($slots->{ $_[1] }, 'CODE')) {
		my $dont_lie = 0;
		my $caller   = (caller(0))[0];
		foreach my $i (@Class::Prototyped::Tied::DONT_LIE_FOR) {
			$dont_lie = $caller eq $i and last;
		}
		Carp::croak(
			"attempt to access METHOD slot through tied hash object interface")
			unless $dont_lie;
	}

	$slots->{ $_[1] };
}

sub DELETE {
	Carp::croak "attempt to delete a slot through tied hash object interface";
}

#### AutoVivifying Tied implementation
package Class::Prototyped::Tied::AutoVivify;
$Class::Prototyped::Tied::AutoVivify::VERSION = '1.13';
@Class::Prototyped::Tied::AutoVivify::ISA = qw(Class::Prototyped::Tied);

sub STORE {
	my $slots = $_[0]->{slots};

	Carp::croak(
		"attempt to modify parent slot through the tied hash object interface")
		if substr($_[1], -1) eq '*';

	if (exists $slots->{ $_[1] }) {
		Carp::croak(
			"attempt to access METHOD slot through tied hash object interface")
			if UNIVERSAL::isa($slots->{ $_[1] }, 'CODE');
	}
	else {
		my $slot = $_[1];
		$slots->{ $_[1] } = $_[2];
		my $implementation = bless sub {
			@_ > 1 ? $slots->{$slot} = $_[1] : $slots->{$slot};
		}, 'Class::Prototyped::FieldAccessor';
		no strict 'refs';
		local $^W = 0;    # suppress redefining messages.
		*{ $_[0]->package . "::$slot" } = $implementation;
		push (@{ $_[0]->{otherOrder} }, $slot);
		$_[0]->{types}->{$slot} = 'FIELD';
	}

	Carp::croak(
		"attempt to access non-existent slot through tied hash object interface"
		)
		unless exists $slots->{ $_[1] };

	$slots->{ $_[1] } = $_[2];
}

sub FETCH {
	my $slots = $_[0]->{slots};

	if (exists $slots->{ $_[1] }
		and UNIVERSAL::isa($slots->{ $_[1] }, 'CODE'))
	{
		my $dont_lie = 0;
		my $caller   = (caller(0))[0];
		foreach my $i (@Class::Prototyped::Tied::DONT_LIE_FOR) {
			$dont_lie = $caller eq $i and last;
		}
		Carp::croak(
			"attempt to access METHOD slot through tied hash object interface")
			unless $dont_lie;
	}

	$slots->{ $_[1] };
}

sub EXISTS {
	exists $_[0]->{slots}->{ $_[1] };
}

sub DELETE {
	my $slots = $_[0]->{slots};

	if (UNIVERSAL::isa($slots->{ $_[1] }, 'CODE')
		&& (caller(0))[0] ne 'Data::Dumper')
	{
		Carp::croak
			"attempt to delete METHOD slot through tied hash object interface";
	}

	my $package = $_[0]->package;
	my $slot    = $_[1];
	{
		no strict 'refs';
		my $name = "$package\::$slot";

		# save the glob...
		local *old = *{$name};

		# and restore everything else
		local *new;
		foreach my $type (qw(HASH IO FORMAT SCALAR ARRAY)) {
			my $elem = *old{$type};
			next if !defined($elem);
			*new = $elem;
		}
		*{$name} = *new;
	}
	my $otherOrder = $_[0]->{otherOrder};
	@$otherOrder = grep { $_ ne $slot } @$otherOrder;
	delete $slots->{$slot};    # and delete the data/sub ref
	delete $_[0]->{types}->{$slot};
}

# Everything that deals with modifying or inspecting the form
# of an object is done through a reflector.

package Class::Prototyped::Mirror;
$Class::Prototyped::Mirror::VERSION = '1.13';
$Class::Prototyped::Mirror::PROFILE::VERSION = '1.13';
$Class::Prototyped::Mirror::SUPER::VERSION = '1.13';

sub new {
	my $class = shift;
	my($entity) = @_;

	if ( ref($entity) ) {
		if (substr(ref($entity), 0, Class::Prototyped::Mirror::PREFIX_LENGTH) eq
				Class::Prototyped::Mirror::PREFIX)
		{
			return bless \$entity, 'Class::Prototyped::Mirror';
		}
		elsif ($Class::Prototyped::Mirror::objects{ ref($entity) } == $entity) {
			return $Class::Prototyped::Mirror::mirrors{ $entity } ||= bless \$entity, 'Class::Prototyped::Mirror';
		}
		else {
			return Class::Prototyped::Mirror::Normal->new($entity);
		}
	}

	my $object;
	unless ($object = $Class::Prototyped::Mirror::objects{ $entity }) {
		my (%self);
		my $tiepkg;
		if ($entity eq 'Class::Prototyped') {
			$tiepkg = 'Class::Prototyped::Tied::Default';
		}
		else {
			no strict 'refs';
			$tiepkg = eval { ${"$entity\::ISA"}[0]->reflect->tiedInterfacePackage() };
			$tiepkg = Class::Prototyped->reflect->tiedInterfacePackage() if $@;
		}
		tie %self, $tiepkg;
		$object = $Class::Prototyped::Mirror::objects{ $entity } = \%self;
		tied(%self)->package($entity);

		my $defaults;
		if ($entity eq 'Class::Prototyped') {
			$defaults = {FIELD => undef, METHOD => undef, PARENT => undef};
		}
		else {
			no strict 'refs';
			$defaults = eval { ${"$entity\::ISA"}[0]->reflect->_defaults() };
			$defaults = Class::Prototyped->reflect->_defaults() if $@;
		}

		tied(%self)->{defaults} = $defaults;

		bless $object, $entity;
	}
	return $Class::Prototyped::Mirror::mirrors{ $entity } ||= bless \$object, 'Class::Prototyped::Mirror';
}


#This code exists to support calling ->reflect->super on a "normal" object that
#is blessed into a C::P class.

package Class::Prototyped::Mirror::Normal;
$Class::Prototyped::Mirror::Normal::VERSION = '1.13';
@Class::Prototyped::Mirror::Normal::ISA = qw(Class::Prototyped::Mirror);

sub new {
	my $class = shift;
	my($entity) = @_;

	my $temp = Class::Prototyped::Mirror->new(ref($entity));

	my $self = bless \(my $o = ${$temp}), $class;
	$Class::Prototyped::Mirror::Normal::superselfs->{$self} = $entity;
	return $self;
}

sub super {
	my $mirror = shift;
	(bless \$Class::Prototyped::Mirror::Normal::superselfs->{$mirror}, 'Class::Prototyped::Mirror')->super(@_);
}

sub DESTROY {
	delete $Class::Prototyped::Mirror::Normal::superselfs->{$_[0]};
}

package Class::Prototyped::Mirror;

#### Interface to tied object

sub autoloadCall {
	my $mirror  = shift;

	my $package = $mirror->package();
	no strict 'refs';
	my $call = ${"$package\::AUTOLOAD"};
	$call =~ s/.*:://;
	return $call;
}

sub package {
	ref(${ $_[0] });
}

sub tiedInterfacePackage {
	my $self = shift;

	if ($_[0]) {
		my $package = {
			'default'    => 'Class::Prototyped::Tied::Default',
			'autovivify' => 'Class::Prototyped::Tied::AutoVivify',
		}->{$_[0]} || $_[0];

		if ($package eq $_[0] && scalar(keys %{"$package\::"}) == 0) {
			eval "use $package";
			Carp::croak "attempt to import package for :TIED_INTERFACE failed:\n$package"
				if $@;
		}

		tie %{ ${ $self } }, $package, tied(%{ ${ $self } });
		return $package;
	}
	else {
		return ref(tied(%{ ${ $self } }));
	}
}

sub defaultAttributes {
	my $mirror = shift;

	tied(%{ ${ $mirror } })->{defaults} = $_[0] if scalar(@_);
	my $defaults = $mirror->_defaults;

	my $retval = {};
	$retval->{FIELD}  = defined $defaults->{FIELD} ? {%{$defaults->{FIELD}}} : undef;
	$retval->{METHOD} = defined $defaults->{METHOD} ? {%{$defaults->{METHOD}}} : undef;
	$retval->{PARENT} = defined $defaults->{PARENT} ? {%{$defaults->{PARENT}}} : undef;
	return $retval;
}

sub _isa {
	tied(%{ ${ $_[0] } })->isa;
}

sub _parentOrder {
	my $tied = tied(%{ ${ $_[0] } });
	$_[0]->_autovivify_parents unless $tied->{vivified_parents};
	$tied->{parentOrder};
}

sub _otherOrder {
	my $tied = tied(%{ ${ $_[0] } });
	$_[0]->_autovivify_methods unless $tied->{vivified_methods};
	$tied->{otherOrder};
}

sub _slotOrder {
	my $tied = tied(%{ ${ $_[0] } });
	$_[0]->_autovivify_parents unless $tied->{vivified_parents};
	$_[0]->_autovivify_methods unless $tied->{vivified_methods};
	[@{ $tied->{parentOrder} }, @{ $tied->{otherOrder} }];
}

sub _slots {
	my $tied = tied(%{ ${ $_[0] } });
	$_[0]->_autovivify_parents unless $tied->{vivified_parents};
	$_[0]->_autovivify_methods unless $tied->{vivified_methods};
	$tied->{slots};
}

sub _types {
	tied(%{ ${ $_[0] } })->{types};
}

sub _attribs {
	tied(%{ ${ $_[0] } })->{attribs};
}

sub _defaults {
	tied(%{ ${ $_[0] } })->{defaults};
}

sub _vivified_parents {
	@_ > 1 ? tied(%{ ${ $_[0] } })->{vivified_parents} = $_[1] :
		tied(%{ ${ $_[0] } })->{vivified_parents};
}

sub _vivified_methods {
	@_ > 1 ? tied(%{ ${ $_[0] } })->{vivified_methods} = $_[1] :
		tied(%{ ${ $_[0] } })->{vivified_methods};
}

#The following returns package, _isa, _parentOrder, _otherOrder,
#_slots, _types, _attribs, and _defaults;
sub _everything {
	my $tied = tied(%{ ${ $_[0] } });
	$_[0]->_autovivify_parents unless $tied->{vivified_parents};
	$_[0]->_autovivify_methods unless $tied->{vivified_methods};

	return (
		ref(${ $_[0] }),
		$tied->{isa},
		$tied->{parentOrder},
		$tied->{otherOrder},
		$tied->{slots},
		$tied->{types},
		$tied->{attribs},
		$tied->{defaults},
	);
}

#### Autovivifivation support

sub _autovivify_parents {
	my $tied = tied(%{ ${ $_[0] } });
	return if $tied->{vivified_parents};

	my $mirror = shift;
	$tied->{vivified_parents} = 1;

	my($package, $isa, $parentOrder, $otherOrder, $slots, $types, $attribs, undef) =
		$mirror->_everything;

	if (scalar(grep { UNIVERSAL::isa($_, 'Class::Prototyped') } @$isa)
		&& $isa->[-1] ne 'Class::Prototyped')
	{
		push (@$isa, 'Class::Prototyped');
		no strict 'refs';
		delete ${"$package\::"}{'::ISA::CACHE::'};    # re-cache @ISA
		@$isa=@$isa;
	}

	if (@{$parentOrder}) {
		Carp::croak("attempt to autovivify in the "
				. "presence of an existing parentOrder\n" . "package: $package");
	}
	my @isa = @$isa;
	pop (@isa) if scalar(@isa) && $isa[-1] eq 'Class::Prototyped';

	foreach my $parentPackage (@isa) {
		my $count = '';
		my $slot  = "$parentPackage$count*";
		while (exists $slots->{$slot} || $slot eq 'self*') {
			$slot = $parentPackage . (++$count) . '*';
		}
		push (@$parentOrder, $slot);
		$slots->{$slot} = $parentPackage;
		$types->{$slot} = 'PARENT';
	}
}

sub _autovivify_methods {
	my $tied = tied(%{ ${ $_[0] } });
	return if $tied->{vivified_methods};

	my $mirror = shift;
	$tied->{vivified_methods} = 1;

	my($package, $isa, $parentOrder, $otherOrder, $slots, $types, $attribs, undef) =
		$mirror->_everything;

	no strict 'refs';
	foreach my $slot (grep { $_ ne 'DESTROY' } keys %{"$package\::"}) {
		my $code = *{"$package\::$slot"}{CODE} or next;
		ref($code) =~ /^Class::Prototyped::FieldAccessor/ and next;
		Carp::croak("the slot self* is inviolable") if $slot eq 'self*';

		if (exists $slots->{$slot}) {
			Carp::croak("you overwrote a slot via an include $slot")
				if !UNIVERSAL::isa($slots->{$slot}, 'CODE')
				|| $slots->{$slot} != $code;
		}
		else {
			push (@$otherOrder, $slot);
			$slots->{$slot} = $code;
			$types->{$slot} = 'METHOD';
		}
	}
}

sub object {
	$_[0]->_autovivify_parents;
	$_[0]->_autovivify_methods;
	${ $_[0] };
}

sub class {
	return $_[0]->_slots->{'class*'};
}

sub dump {
	eval "package main; use Data::Dumper;"
		unless (scalar keys(%Data::Dumper::));

	Data::Dumper->Dump([ $_[0]->object ], [ $_[0]->package ]);
}


sub slotStruct_name () {0};
sub slotStruct_value () {1};
sub slotStruct_type () {2};
sub slotStruct_attribs () {3};
sub slotStruct_implementor () {4};
sub slotStruct_filters () {5};
sub slotStruct_advisories () {6};


#### The support for attribute rationalization is not very fancy
$Class::Prototyped::Mirror::attributes = {
	FIELD => {
		constant => {
			type => 'implementor',
			code => sub {
				my($mirror, $slotName, $slotValue, $slotAttribs, $implementation, $slots) = @_;

				$slotAttribs->{constant} = 1;
				return bless sub {
					$slots->{$slotName};
				}, 'Class::Prototyped::FieldAccessor::Constant';
			}
		},

		autoload => {
			type => 'filter',
			rank => 50,
			code => sub {
				my($mirror, $slotName, $slotValue, $slotAttribs, $implementation, $slots) = @_;

				if ($slotAttribs->{autoload} = $slotAttribs->{autoload} ? 1 : undef) {
					my $self = $mirror->object;
					$implementation = bless sub {
						my $retval = &$slotValue;
						my $attribs = $self->reflect->_attribs->{$slotName};
						delete($attribs->{autoload});
						$self->reflect->addSlot([$slotName, %$attribs] => $retval);
						return $retval;
					}, 'Class::Prototyped::FieldAccessor::Autoload';
				}
				return $implementation;
			}
		},

		profile => {
			type => 'filter',
			rank => 80,
			code => sub {
				my($mirror, $slotName, $slotValue, $slotAttribs, $implementation, $slots) = @_;

				my $profileLevel = $slotAttribs->{profile};
				if ($profileLevel) {
					package Class::Prototyped::Mirror::PROFILE;
					my $old_implementation = $implementation;
					my $package = ref( ${ $mirror } );
					$implementation = sub {
						my $caller = '';
						if ($profileLevel == 2) {
							my($pack, $file, $line) = caller;
							$caller = "$file ($line)";
							$Class::Prototyped::Mirror::PROFILE::counts->{$package}->{$slotName}->{$caller}++;
						} else {
							$Class::Prototyped::Mirror::PROFILE::counts->{$package}->{$slotName}++;
						}
						goto &$old_implementation;
					};
				}
				return $implementation;
			},
		},

		'wantarray' => {
			type => 'filter',
			rank => 90,
			code => sub {
				my($mirror, $slotName, $slotValue, $slotAttribs, $implementation, $slots) = @_;

				if ($slotAttribs->{'wantarray'} = $slotAttribs->{'wantarray'} ? 1 : undef) {
					my $old_implementation = $implementation;
					$implementation = bless sub {
						my $retval = &$old_implementation;
						if (ref($retval) eq 'ARRAY' && wantarray) {
							return (@$retval);
						}
						else {
							return $retval;
						}
					}, 'Class::Prototyped::FieldAccessor::Wantarray';
				}
				return $implementation;
			}
		},

		description => {
			type => 'advisory',
		},
	},

	METHOD => {
		superable => {
			type => 'filter',
			rank => 10,
			code => sub {
				my($mirror, $slotName, $slotValue, $slotAttribs, $implementation, $slots) = @_;

				if ($slotAttribs->{superable} = $slotAttribs->{superable} ? 1 : undef) {
					package Class::Prototyped::Mirror::SUPER;
					my $old_implementation = $implementation;
					my $package = ref( ${ $mirror } );
					$implementation = sub {
						local $Class::Prototyped::Mirror::SUPER::package =
							$package;
						&$old_implementation;
					};
					package Class::Prototyped::Mirror;
				}
				return $implementation;
			}
		},

		profile => {
			type => 'filter',
			rank => 90,
			code => sub {
				my($mirror, $slotName, $slotValue, $slotAttribs, $implementation, $slots) = @_;

				my $profileLevel = $slotAttribs->{profile};
				if ($profileLevel) {
					package Class::Prototyped::Mirror::PROFILE;
					my $old_implementation = $implementation;
					my $package = ref( ${ $mirror } );
					$implementation = sub {
						my $caller = '';
						if ($profileLevel == 2) {
							my($pack, $file, $line) = caller;
							$caller = "$file ($line)";
							$Class::Prototyped::Mirror::PROFILE::counts->{$package}->{$slotName}->{$caller}++;
						} else {
							$Class::Prototyped::Mirror::PROFILE::counts->{$package}->{$slotName}++;
						}
						goto &$old_implementation;
					};
				}
				return $implementation;
			},
		},

		overload => {
			type => 'advisory',
		},

		description => {
			type => 'advisory',
		},
	},

	PARENT => {
		description => {
			type => 'advisory',
		},

		promote => {
			type => 'advisory',
		},
	},
};

sub addSlotsParser {
	my $mirror = shift;

	Carp::croak("odd number of arguments to addSlotsParser\n")
		if scalar(@_) % 2;

	my($package, undef, undef, undef, $slots, undef, undef, $defaults) =
		$mirror->_everything();

	my(@retvals);

	while (my($slotThing, $slotValue) = splice(@_, 0, 2)) {
		my($slotName, $slotType, $slotAttribs, $slotImplementor, $slotFilters, $slotAdvisories);
		my $isCode = UNIVERSAL::isa($slotValue, 'CODE');

		if (ref($slotThing) eq 'ARRAY') {
			$slotName = $slotThing->[0];

			my $temp = $slotThing->[1] || '';
			if ($temp eq 'METHOD' || $temp eq 'FIELD' || $temp eq 'PARENT') {
				$slotType = $temp;
				$temp = 2;
			}
			else {
				$slotType = $isCode ? 'METHOD' :
					(substr($slotName, -1) eq '*' ? 'PARENT' : 'FIELD');
				$temp = 1;
			}

			if ($#{$slotThing} >= $temp) {
				if ($#{$slotThing} == $temp) {
					$slotAttribs = defined $defaults->{$slotType}
							? { %{$defaults->{$slotType}}, $slotThing->[$temp] => 1 }
							: { $slotThing->[$temp] => 1 };
				}
				else {
					$slotAttribs = defined $defaults->{$slotType}
							? { %{$defaults->{$slotType}}, @{$slotThing}[$temp..$#{$slotThing}] }
							: { @{$slotThing}[$temp..$#{$slotThing}] };
				}
			}
			elsif (defined $defaults->{$slotType}) {
				$slotAttribs = { %{$defaults->{$slotType}} };
			}

			if ($slotType eq 'METHOD') {
				Carp::croak("it is not permitted to use '!' notation in conjunction with slot attributes")
					if substr($slotName, -1) eq '!';

				Carp::croak("method slots have to have CODE refs as values")
					if !$isCode;
			}
			elsif ($slotType eq 'PARENT') {
				Carp::croak("it is not permitted to use '**' notation in conjunction with slot attributes")
					if substr($slotName, -2, 1) eq '*';
			}
		}
		else {
			$slotName = $slotThing;
			$slotType = $isCode ? 'METHOD' :
				(substr($slotName, -1) eq '*' ? 'PARENT' : 'FIELD');

			if (defined $defaults->{$slotType}) {
				$slotAttribs = { %{$defaults->{$slotType}} };
			}

			# Slots that end in '!' mean that the method is superable
			if ($slotType eq 'METHOD' && substr($slotName, -1) eq '!') {
				$slotName = substr($slotName, 0, -1);
				$slotAttribs->{superable} = 1;
			}

			# Temporary support for &
			if ($slotType eq 'FIELD' && substr($slotName, -1) eq '&') {
				$slotName = substr($slotName, 0, -1);
				$slotAttribs->{constant} = 1;
			}

			# Slots that end in '**' mean to push the slot
			# to the front of the parents list.
			if ($slotType eq 'PARENT' && substr($slotName, -2) eq '**') {
				$slotName = substr($slotName, 0, -1);    # xyz** => xyz*
				$slotAttribs->{promote} = 1;
			}
		}

		if ($slotType eq 'METHOD' && exists($Class::Prototyped::overloadable_symbols{$slotName})) {
			$slotAttribs->{overload} = 1;
		}
		else {
			Carp::croak("can't use slot attribute overload for slots that aren't overloadable")
				if ($slotAttribs->{overload} && !exists($Class::Prototyped::overloadable_symbols{$slotName}));
		}

		Carp::croak("slots should end in * if and only if the type is parent")
			if ( (substr($slotName, -1) eq '*') != ($slotType eq 'PARENT') && !$slotAttribs->{overload} );

		if ($slotName eq '*') {
			$slotName = (ref($slotValue) || $slotValue) . $slotName;
		}

		if(scalar(keys(%{$slotAttribs}))) {
			my $attributes = $Class::Prototyped::Mirror::attributes->{$slotType};

			foreach my $attrib (keys %{$slotAttribs}) {
				Carp::croak("$slotType slots cannot have the '$attrib' attribute.")
					unless exists $attributes->{$attrib};

				my $atype = $attributes->{$attrib}->{type};
				if ($atype eq 'filter') {
					push(@{$slotFilters}, $attrib);
				}
				elsif ($atype eq 'advisory') {
					push(@{$slotAdvisories}, $attrib);
				}
				elsif ($atype eq 'implementor') {
					Carp::croak("slots cannot have more than one implementor.")
						if defined($slotImplementor);
					$slotImplementor = $attributes->{$attrib}->{code} if $slotAttribs->{$attrib};
				}
				else {
					Carp::croak("unknown attribute type '$atype' for '$attrib'.");
				}
			}

			if (defined $slotFilters) {
				@{$slotFilters} = map { $attributes->{$_}->{code} } sort {
						$attributes->{$a}->{rank} <=> $attributes->{$b}->{rank} || $a cmp $b
					} @{$slotFilters};
			}

			if (defined $slotAdvisories) {
				@{$slotAdvisories} = grep {defined} map { $attributes->{$_}->{code} } sort @{ $slotAdvisories };
			}
		}

		Carp::croak("the slot self* is inviolable") if $slotName eq 'self*';

		Carp::croak("Can only use operator names for method slots\nslot: $slotName")
			if ( exists($Class::Prototyped::overloadable_symbols{$slotName}) &&
						$slotType ne 'METHOD' );

		if ($slotType eq 'PARENT') {
			Carp::croak("parent slots cannot be code blocks") if ($isCode);

			unless (UNIVERSAL::isa($slotValue, 'Class::Prototyped')
				|| (ref(\$slotValue) eq 'SCALAR' && defined $slotValue))
			{
				Carp::croak("attempt to add parent that isn't a "
						. "Class::Prototyped or package name\n"
						. "package: $package slot: $slotName parent: $slotValue");
			}

			if (UNIVERSAL::isa($slotValue, $package)) {
				Carp::croak("attempt at recursive inheritance\n"
						. "parent $slotValue is a package $package");
			}
		}
		elsif ($slotType eq 'METHOD') {
			Carp::croak("cannot replace DESTROY method for unnamed objects")
				if ($slotName eq 'DESTROY' && substr($package, 0, PREFIX_LENGTH) eq PREFIX);
		}

		push(@retvals, [$slotName, $slotValue, $slotType, $slotAttribs, $slotImplementor, $slotFilters, $slotAdvisories]);
	}
	return \@retvals;
}

sub addParsedSlots {
	my $mirror = shift;

	my($package, $isa, $parentOrder, $otherOrder, $slots, $types, $attribs, undef) =
		$mirror->_everything();

	while (@{$_[0]}) {
		my($slotName, $slotValue, $slotType, $slotAttribs, $slotImplementor, $slotFilters, $slotAdvisories) = @{ shift @{$_[0]} };

		&deleteSlots($mirror, $slotName) if exists($slots->{$slotName});

		$slots->{$slotName} = $slotValue;    #everything goes into the slots!!!!!

		if ($slotType eq 'PARENT') {
			my $parentPackage = ref($slotValue) || $slotValue;

			if (substr($parentPackage, 0, PREFIX_LENGTH) eq PREFIX) {
				$Class::Prototyped::Mirror::parents{$package}->{$slotName} = $slotValue;
			}
			else {
				Carp::carp(
"it is recommended to use ->reflect->include for mixing in named files."
					)
					if $parentPackage =~ /\.p[lm]$/i;

				no strict 'refs';
				if (!ref($slotValue)
					&& !(scalar keys(%{"$parentPackage\::"})))
				{
					$mirror->include($parentPackage);
				}
			}

			my $splice_point = $slotAttribs->{promote} ? 0 : @$parentOrder;
			delete $slotAttribs->{promote};
			splice(@$isa, $splice_point, 0, $parentPackage);
			{
				#Defends against ISA caching problems
				no strict 'refs';
				delete ${"$package\::"}{'::ISA::CACHE::'};
				@$isa = @$isa;
			}
			splice(@$parentOrder, $splice_point, 0, $slotName);
		}
		else {
			my $implementation = defined $slotImplementor
				? $slotImplementor->($mirror, $slotName, $slotValue, $slotAttribs, undef, $slots)
				: ( $slotType eq 'METHOD' 
						? $slotValue
						: bless sub {
								@_ > 1 ? $slots->{$slotName} = $_[1] : $slots->{$slotName};
							}, 'Class::Prototyped::FieldAccessor'
					);

			if (defined $slotFilters) {
				foreach my $filter (@{ $slotFilters }) {
					$implementation =	$filter->($mirror, $slotName, $slotValue, $slotAttribs, $implementation, $slots);
				}
			}

			if (defined $slotAdvisories) {
				foreach my $advisory (@{ $slotAdvisories }) {
					$advisory->($mirror, $slotName, $slotValue, $slotAttribs, $implementation, $slots);
				}
			}

			if ($slotAttribs->{overload}) {
				eval "package $package;
					use overload '$slotName' => \$implementation, fallback => 1;
							bless \$object, \$package;";
				Carp::croak("Eval failed while defining overload\n"
						. "operation: \"$slotName\" error: $@")
					if $@;
			}
			else {
				no strict 'refs';
				local $^W = 0;    # suppress redefining messages.
				*{"$package\::$slotName"} = $implementation;
			}
			push (@$otherOrder, $slotName);
		}
		$attribs->{$slotName} = $slotAttribs;
		$types->{$slotName} = $slotType;
	}

	return $mirror;
}

sub addSlots {
	my $mirror = shift;
	$mirror->addParsedSlots( $mirror->addSlotsParser(@_) );
}

*addSlot = \&addSlots;            # alias addSlot to addSlots

# $obj->reflect->deleteSlots( name [, name [...]] );
sub deleteSlots {
	my $mirror = shift;
	my (@deleteSlots) = @_;

	my($package, $isa, $parentOrder, $otherOrder, $slots, $types, $attribs, undef) =
		$mirror->_everything;

	foreach my $slot (@deleteSlots) {
		$slot = substr($slot, 0, -1) if substr($slot, -2) eq '**';
		$slot = substr($slot, 0, -1) if substr($slot, -1) eq '!';

		next if !exists($slots->{$slot});

		my $value = $slots->{$slot};

		if (substr($slot, -1) eq '*') {    # parent slot
			my $index = 0;
			1 while ($parentOrder->[$index] ne $slot
				and $index++ < @$parentOrder);

			if ($index < @$parentOrder) {
				splice(@$parentOrder, $index, 1);
				splice(@$isa,         $index, 1);
				{
					#Defends against ISA caching problems
					no strict 'refs';
					delete ${"$package\::"}{'::ISA::CACHE::'};
					@$isa=@$isa;
				}
			}
			else {    # not found

				if (!$Class::Prototyped::Mirror::ending) {
					Carp::cluck "couldn't find $slot in $package\n";
					$DB::single = 1;
				}
			}

			if (defined($value)) {
				my $parentPackage = ref($value);
				if (substr($parentPackage, 0, PREFIX_LENGTH) eq PREFIX) {
					delete
						($Class::Prototyped::Mirror::parents{$package}->{$slot}
						);
				}
			}
			else {

				if (!$Class::Prototyped::Mirror::ending) {
					Carp::cluck "slot undef for $slot in $package\n";
					$DB::single = 1;
				}
			}
		}
		else {

			if (exists($Class::Prototyped::overloadable_symbols{$slot})) {
				Carp::croak(
					"Perl segfaults when the last overload is removed. Boom!\n")
					if (1 == grep {
						exists($Class::Prototyped::overloadable_symbols{$_});
					} keys(%$slots));

				eval "package $package;
					no overload '$slot';
							bless {}, \$package;"
					;    # dummy bless so that overloading works.
				Carp::croak("Eval failed while removing overload\n"
						. "operation: \"$slot\" error: $@")
					if $@;
			}
			else {     # we have a method by that name; delete it
				no strict 'refs';
				my $name = "$package\::$slot";

				# save the glob...
				local *old = *{$name};

				# and restore everything else
				local *new;
				foreach my $type (qw(HASH IO FORMAT SCALAR ARRAY)) {
					my $elem = *old{$type};
					next if !defined($elem);
					*new = $elem;
				}
				*{$name} = *new;
			}
			@$otherOrder = grep { $_ ne $slot } @$otherOrder;
		}
		delete $slots->{$slot};    # and delete the data/sub ref
		delete $types->{$slot};
		delete $attribs->{$slot};
	}

	return $mirror;
}

*deleteSlot = \&deleteSlots;       # alias deleteSlot to deleteSlots

sub super_slow {
	return shift->super_fast(@_)
		if ((caller(1))[0] eq 'Class::Prototyped::Mirror::SUPER');
	return shift->super_fast(@_)
		if ((caller(2))[0] eq 'Class::Prototyped::Mirror::SUPER');
	Carp::croak(
		"attempt to call super on a method that was defined without !\n"
			. "method: " . $_[1]);
}

*super = \&super_slow unless defined(*super{CODE});

sub super_fast {
	my $mirror  = shift;
	my $message = shift;

	$message or Carp::croak("you have to pass the method name to super");

	my $object = ${ $mirror };

	my (@isa);
	{
		no strict 'refs';
		@isa = @{ $Class::Prototyped::Mirror::SUPER::package . '::ISA' };
	}
	my $method;

	foreach my $parentPackage (@isa) {
		$method = UNIVERSAL::can($parentPackage, $message);
		last if $method;
	}
	$method
		or Carp::croak("could not find super in parents\nmessage: $message");
	$method->($object, @_);
}

sub slotNames {
	my $mirror = shift;
	my $type   = shift;

	my($package, $isa, $parentOrder, $otherOrder, $slots, $types, $attribs, undef) =
		$mirror->_everything;

	my @slotNames = (@$parentOrder, @$otherOrder);
	if ($type) {
		@slotNames = grep { $types->{$_} eq $type } @slotNames;
	}
	return wantarray ? @slotNames : \@slotNames;
}

sub slotType {
	my $mirror   = shift;
	my $slotName = shift;

	my $types = $mirror->_types;
	Carp::croak(
		"attempt to determine slotType for unknown slot\nslot: $slotName")
		unless exists $types->{$slotName};
	return $types->{$slotName};
}

# may return dups
sub allSlotNames {
	my $mirror = shift;
	my $type   = shift;

	my @slotNames;
	foreach my $parent ($mirror->withAllParents()) {
		my $mirror = Class::Prototyped::Mirror->new($parent);
		push (@slotNames, $mirror->slotNames($type));
	}
	return wantarray ? @slotNames : \@slotNames;
}

sub parents {
	my $mirror = shift;

	my $object = $mirror->object;
	my $slots  = $mirror->_slots;
	return map { $slots->{$_} } $mirror->slotNames('PARENT');
}

sub allParents {
	my $mirror = shift;
	my $retval = shift || [];
	my $seen   = shift || {};

	foreach my $parent ($mirror->parents) {
		next if $seen->{$parent}++;
		push @$retval, $parent;
		my $mirror = Class::Prototyped::Mirror->new($parent);
		$mirror->allParents($retval, $seen);
	}
	return wantarray ? @$retval : $retval;
}

sub withAllParents {
	my $mirror = shift;

	my $object = $mirror->object;
	my $retval = [$object];
	my $seen   = { $object => 1 };
	$mirror->allParents($retval, $seen);
}

# getSlot returns both the slotName and the slot in array context
# so that it can append !'s to superable methods, so that getSlots does the
# right thing, so that clone does the right thing.
# However, in scalar context, it just returns the value.

sub getSlot {
	my $mirror   = shift;
	my $slot = shift;
	my $format = shift;

	my($package, $isa, $parentOrder, $otherOrder, $slots, $types, $attribs, undef) =
		$mirror->_everything;

	my $value = ($slot ne 'self*') ? $slots->{$slot} : $mirror->object;

	return $value unless wantarray;

	$slot = [$slot, $types->{$slot}, %{$attribs->{$slot} || {}}];

	if (!defined $format || $format eq 'default') {
		return ($slot, $value);
	}
	elsif ($format eq 'simple') {
		return ($slot->[0], $value);
	}
	elsif ($format eq 'rotated') {
		return ($slot->[0], {
				attribs => { @{$slot}[2..$#{$slot}] },
				type => $slot->[1], 
				value => $value
			}
		);
	}
}

sub getSlots {
	my $mirror = shift;
	my $type   = shift;
	my $format = shift;

	my @retval;
	if (defined $type || defined $format) {
		@retval = map { $mirror->getSlot($_, $format) } $mirror->slotNames($type);
	}
	else {
		my($package, $isa, $parentOrder, $otherOrder, $slots, $types, $attribs, undef) =
			$mirror->_everything;
		@retval = map {
			([$_, $types->{$_}, %{$attribs->{$_} || {}}] => $slots->{$_})
		} (@$parentOrder, @$otherOrder);
	}

	return wantarray ? @retval : \@retval;
}

sub promoteParents {
	my $mirror = shift;
	my (@newOrder) = @_;

	my($package, $isa, $parentOrder, $otherOrder, $slots, $types, $attribs, undef) =
		$mirror->_everything;

	my %seen;
	foreach my $slot (@newOrder) {
		$seen{$slot}++;
		if ($seen{$slot} > 1 || !exists($slots->{$slot})) {
			Carp::croak("promoteParents called with bad order list\nlist: @_");
		}
		else {
			@{$parentOrder} = grep { $_ ne $slot } @{$parentOrder};
		}
	}

	@{$parentOrder} = (@newOrder, @{$parentOrder});

	@$isa =
		((map { ref($slots->{$_}) ? ref($slots->{$_}) : $slots->{$_} }
				@{$parentOrder}), 'Class::Prototype');

	# this is required to re-cache @ISA
	no strict 'refs';
	delete ${"$package\::"}{'::ISA::CACHE::'};
	@$isa=@$isa;
}

sub wrap {
	my $mirror        = shift;
	my $class         = $mirror->class || 'Class::Prototyped';
	my $wrapped       = $class->new;
	my $wrappedMirror = $wrapped->reflect;

	# add all the slots from the original object
	$wrappedMirror->addSlots($mirror->getSlots);

	# delete all my original slots
	# so that the wrapped gets called
	$mirror->deleteSlots($mirror->slotNames);
	$mirror->addSlots(@_, [qw(wrapped* promote)] => $wrapped);
	$mirror;
}

sub unwrap {
	my $mirror  = shift;
	my $wrapped = $mirror->getSlot('wrapped*')
		or Carp::croak "unwrapping without a wrapped\n";
	my $wrappedMirror = $wrapped->reflect;
	$mirror->deleteSlots($mirror->slotNames);
	$mirror->addSlots($wrappedMirror->getSlots);

	#  $wrappedMirror->deleteSlots( $wrappedMirror->slotNames );
	$mirror;
}

sub delegate {
	my $mirror = shift;

	while (my ($name, $value) = splice(@_, 0, 2)) {
		my @names = (UNIVERSAL::isa($name, 'ARRAY') ? @$name : $name);
		my @conflicts;

		foreach my $slotName (@names) {
			push (@conflicts, grep { $_ eq $slotName } $mirror->slotNames);
		}
		Carp::croak(
			"delegate would cause conflict with existing slots\n" . "pattern: "
				. join ('|',  @names) . " , conflicting slots: "
				. join (', ', @conflicts))
			if @conflicts;

		my $delegateMethod;
		if (UNIVERSAL::isa($value, 'ARRAY')) {
			$delegateMethod = $value->[1];
			$value          = $value->[0];
		}
		my $delegate = $mirror->getSlot($value) || $value;
		Carp::croak("Can't delegate to a subroutine\nslot: $name")
			if (UNIVERSAL::isa($delegate, 'CODE'));

		foreach my $slotName (@names) {
			my $method = defined($delegateMethod) ? $delegateMethod : $slotName;
			$mirror->addSlot(
				$slotName => sub {
					shift;    # discard original recipient
					$delegate->$method(@_);
					}
			);
		}
	}
}

sub findImplementation {
	my $mirror   = shift;
	my $slotName = shift;

	my $object = $mirror->object;
	UNIVERSAL::can($object, $slotName) or return;

	my $slots = $mirror->_slots;
	exists $slots->{$slotName} and return wantarray ? 'self*' : $object;

	foreach my $parentName ($mirror->slotNames('PARENT')) {
		my $mirror =
			Class::Prototyped::Mirror->new(
			scalar($mirror->getSlot($parentName)));
		if (wantarray) {
			my (@retval) = $mirror->findImplementation($slotName);
			scalar(@retval) and return ($parentName, @retval);
		}
		else {
			my $retval = $mirror->findImplementation($slotName);
			$retval and return $retval;
		}
	}
	Carp::croak("fatal error in findImplementation");
}

# load the given file or package in the receiver's namespace
# Note that no import is done.
# Croaks on an eval error
#
#   $mirror->include('Package');
#   $mirror->include('File.pl');
#
#   $mirror->include('File.pl', 'thisObject');
#   makes thisObject() return the object into which the include
#   is happening (as long as you don't change packages in the
#   included code)
sub include {
	my $mirror       = shift;
	my $name         = shift;
	my $accessorName = shift;

	$name = "'$name'" if $name =~ /\.p[lm]$/i;

	my $object  = $mirror->object;
	my $package = $mirror->package;
	my $text    = "package $package;\n";
	$text .= "*$package\::$accessorName = sub { \$object };\n"
		if defined($accessorName);

	#  $text .= "sub $accessorName { \$object };\n" if defined($accessorName);
	$text .= "require $name;\n";
	my $retval = eval $text;
	Carp::croak("include failed\npackage: $package include: $name error: $@")
		if $@;

	if (substr($name, -1) eq "'") {
		$mirror->_vivified_methods(0);
		$mirror->_autovivify_methods;
	}

	$mirror->deleteSlots($accessorName) if defined($accessorName);
}

1;
__END__

=head1 NAME

C<Class::Prototyped> - Fast prototype-based OO programming in Perl

=head1 SYNOPSIS

    use strict;
    use Class::Prototyped ':EZACCESS';

    $, = ' '; $\ = "\n";

    my $p = Class::Prototyped->new(
      field1 => 123,
      sub1   => sub { print "this is sub1 in p" },
      sub2   => sub { print "this is sub2 in p" }
    );

    $p->sub1;
    print $p->field1;
    $p->field1('something new');
    print $p->field1;

    my $p2 = Class::Prototyped->new(
      'parent*' => $p,
      field2    => 234,
      sub2      => sub { print "this is sub2 in p2" }
    );

    $p2->sub1;
    $p2->sub2;
    print ref($p2), $p2->field1, $p2->field2;
    $p2->field1('and now for something different');
    print ref($p2), $p2->field1;

    $p2->addSlots( sub1 => sub { print "this is sub1 in p2" } );
    $p2->sub1;

    print ref($p2), "has slots", $p2->reflect->slotNames;

    $p2->reflect->include( 'xx.pl' ); # includes xx.pl in $p2's package
    print ref($p2), "has slots", $p2->reflect->slotNames;
    $p2->aa();    # calls aa from included file xx.pl

    $p2->deleteSlots('sub1');
    $p2->sub1;

=head1 DESCRIPTION

This package provides for efficient and simple prototype-based programming
in Perl. You can provide different subroutines for each object, and also
have objects inherit their behavior and state from another object.

The structure of an object is inspected and modified through I<mirrors>, which
are created by calling C<reflect> on an object or class that inherits from
C<Class::Prototyped>.

=head2 Installation instructions

This module requires C<Module::Build 0.24> to use the automated installation 
procedures.  With C<Module::Build> installed:

  Build.PL
  perl build test
  perl build install

It can be installed under ActivePerl for Win32 by downloading the PPM from CPAN 
(the file has the extension C<.ppm.zip>).  To install, download the C<.ppm.zip> 
file, uncompress it, and execute:

  ppm install Class-Prototyped.ppd

The module can also be installed manually by copying C<lib/Class/Prototyped.pm> 
to C<perl/site/lib/Class/Prototyped.pm> (along with C<Graph.pm> if you want it).


=head1 WHEN TO USE THIS MODULE

When I reach for C<Class::Prototyped>, it's generally because I really need it.  
When the cleanest way of solving a problem is for the code that uses a module to 
subclass from it, that is generally a sign that C<Class::Prototyped> would be of 
use.  If you find yourself avoiding the problem by passing anonymous subroutines 
as parameters to the C<new> method, that's another good sign that you should be 
using prototype based programming.  If you find yourself storing anonymous 
subroutines in databases, configuration files, or text files, and then writing 
infrastructure to handle calling those anonymous subroutines, that's yet another 
sign.  When you expect the people using your module to want to change the 
behavior, override subroutines, and so forth, that's a sign.


=head1 CONCEPTS

=head2 Slots

C<Class::Prototyped> borrows very strongly from the language Self (see
http://www.sun.com/research/self for more information).  The core concept in
Self is the concept of a slot.  Think of slots as being entries in a hash,
except that instead of just pointing to data, they can point to objects, code,
or parent objects.

So what happens when you send a message to an object (that is to say, you make a
method call on the object)?  First, Perl looks for that slot in the object.  If it
can't find that slot in the object, it searches for that slot in one of the
object's parents (which we'll come back to later).  Once it finds the slot, if
the slot is a block of code, it evaluates the code and returns the return
value.  If the slot references data, it returns that data.  If you assign to a
data slot (through a method call), it modifies the data.

Distinguishing data slots and method slots is easy - the latter are references
to code blocks, the former are not.  Distinguishing parent slots is not so
easy, so instead a simple naming convention is used.  If the name of the slot
ends in an asterisk, the slot is a parent slot.  If you have programmed in
Self, this naming convention will feel very familiar.


=head2 Reflecting

In Self, to examine the structure of an object, you use a mirror.  Just like
using his shield as a mirror enabled Perseus to slay Medusa, holding up a
mirror enables us to look upon an object's structure without name space
collisions.

Once you have a mirror, you can add and delete slots like so:

    my $cp = Class::Prototyped->new();
    my $mirror = $cp->reflect();
    $mirror->addSlots(
      field1 => 'foo',
      sub1   => sub {
        print "this is sub1 printing field1: '".$_[0]->field1."'\n";
      },
    );

    $mirror->deleteSlot('sub1');

In addition, there is a more verbose syntax for C<addSlots> where the slot name
is replaced by an anonymous array - this is most commonly used to control the
slot attributes.

    $cp->reflect->addSlot(
      [qw(field1 FIELD)] => 'foo',
      [qw(sub1 METHOD)]  => sub { print "hi there.\n"; },
    );

Because the mirror methods C<super>, C<addSlot>(C<s>), C<deleteSlot>(C<s>), and
C<getSlot>(C<s>) are called frequently on objects, there is an import keyword
C<:EZACCESS> that adds methods to the object space that call the appropriate
reflected variants.


=head2 Slot Attributes

Slot attributes allow the user to specify additional information and behavior
relating to a specific slot in an extensible manner.  For instance, one might
want to mark a specific field slot as constant or to attach a description to a
given slot.

Slot attributes are divided up in two ways.  The first is by the type of slot - 
C<FIELD>, C<METHOD>, or C<PARENT>.  Some slot attributes apply to all three, 
some to just two, and some to only one.  The second division is on the type of
slot attribute:

=over 4

=item implementor

These are responsible for implementing the behavior of a slot.  An example is a 
C<FIELD> slot with the attribute C<constant>.  A slot is only allowed one 
implementor.  All slot types have a default implementor.  For C<FIELD> slots, it 
is a read-write scalar.  For C<METHOD> slots, it is the passed anonymous 
subroutine.  For C<PARENT> slots, C<implementor> and C<filter> slot attributes 
don't really make sense.

=item filter

These filter access to the C<implementor>.  The quintessential example is the 
C<profile> attribute.  When set, this increments a counter in 
C<$Class::Prototyped::Mirror::PROFILE::counts> every time the underlying C<FIELD> 
or C<METHOD> is accessed.  Filter attributes can be stacked, so each attribute
is assigned a rank with lower values being closer to the C<implementor> and
higher values being closer to the caller.

=item advisory

These slot attributes serve one of two purposes.  They can be used to store 
information about the slot (i.e. C<description> attributes), and they can be 
used to pass information to the C<addSlots> method (i.e. the C<promote> 
attribute, which can be used to promote a new C<PARENT> slot ahead of all the 
existing C<PARENT> slots).

=back

There is currently no formal interface for creating your own attributes - if you 
feel the need for new attributes, please contact the maintainer first to see if 
it might make sense to add the new attribute to C<Class::Prototyped>.  If not, 
the contact might provide enough impetus to define a formal interface.  The 
attributes are currently defined in C<$Class::Prototyped::Mirror::attributes>.

Finally, see the C<defaultAttributes> method for information about setting 
default attributes.  This can be used, for instance, to turn on profiling 
everywhere.


=head2 Classes vs. Objects

In Self, everything is an object and there are no classes at all.  Perl, for
better or worse, has a class system based on packages.  We decided that it
would be better not to throw out the conventional way of structuring
inheritance hierarchies, so in C<Class::Prototyped>, classes are first-class
objects.

However, objects are not first-class classes.  To understand this dichotomy, we 
need to understand that there is a difference between the way "classes" and the 
way "objects" are expected to behave.  The central difference is that "classes" 
are expected to persist whether or not that are any references to them.  If you 
create a class, the class exists whether or not it appears in anyone's C<@ISA> 
and whether or not there are any objects in it.  Once a class is created, it 
persists until the program terminates.

Objects, on the other hand, should follow the normal behaviors of
reference-counted destruction - once the number of references to them drops to
zero, they should miraculously disappear - the memory they used needs to be
returned to Perl, their C<DESTROY> methods need to be called, and so forth.

Since we don't require this behavior of classes, it's easy to have a way to get
from a package name to an object - we simply stash the object that implements
the class in C<$Class::Prototyped::Mirror::objects{$package}>.  But we can't do
this for objects, because if we do the object will persist forever because that
reference will always exist.

Weak references would solve this problem, but weak references are still
considered alpha and unsupported (C<$WeakRef::VERSION = 0.01>), and we didn't
want to make C<Class::Prototyped> dependent on such a module.

So instead, we differentiate between classes and objects.  In a nutshell, if an
object has an explicit package name (I<i.e.> something other than the
auto-generated one), it is considered to be a class, which means it persists
even if the object goes out of scope.

To create such an object, use the C<newPackage> method, like so (the 
encapsulating block exists solely to demonstrate that classes are not scoped):

    {
      my $object = Class::Prototyped->newPackage('MyClass',
          field => 1,
          double => sub {$_[0]->field*2}
        );
    }

    print MyClass->double,"\n";

Notice that the class persists even though C<$object> goes out of scope.  If
C<$object> were created with an auto-generated package, that would not be true.
Thus, for instance, it would be a B<very, very, very> bad idea to add the
package name of an object as a parent to another object - when the first object
goes out of scope, the package will disappear, but the second object will still
have it in it's C<@ISA>.

Except for the crucial difference that you should B<never, ever, ever> make use
of the package name for an object for any purpose other than printing it to the
screen, objects and classes are simply different ways of inspecting the same
entity.

To go from an object to a package, you can do one of the following:

    $package = ref($object);
    $package = $object->reflect->package;

The two are equivalent, although the first is much faster.  Just remember, if
C<$object> is in an auto-generated package, don't do anything with that
C<$package> but print it.

To go from a package to an object, you do this:

    $object = $package->reflect->object;

Note that C<$package> is simple the name of the package - the following code
works perfectly:

    $object = MyClass->reflect->object;

But keep in mind that C<$package> has to be a class, not an auto-generated
package name for an object.


=head2 Class Manipulation

This lets us have tons of fun manipulating classes at run time. For instance,
if you wanted to add, at run-time, a new method to the C<MyClass> class?
Assuming that the C<MyClass> inherits from C<Class::Prototyped> or that you
have specified C<:REFLECT> on the C<use Class::Prototyped> call, you simply
write:

    MyClass->reflect->addSlot(myMethod => sub {print "Hi there\n"});

If you want to access a class that doesn't inherit from C<Class::Prototyped>, 
and you want to avoid specifying C<:REFLECT> (which adds C<reflect> to the 
C<UNIVERSAL> package), you can make the call like so:

    my $mirror = Class::Prototyped::Mirror->new('MyClass');
    $mirror->addSlot(myMethod => sub {print "Hi there\n"});

Just as you can C<clone> objects, you can C<clone> classes that are derived from 
C<Class::Prototyped>. This creates a new object that has a copy of all of the 
slots that were defined in the class.  Note that if you simply want to be able 
to use C<Data::Dumper> on a class, calling C<< MyClass->reflect->object >> is 
the preferred approach.  Even easier would be to use the C<dump> mirror method.

The code that implements reflection on classes automatically creates slot
names for package methods as well as parent slots for the entries in C<@ISA>.
This means that you can code classes like you normally do - by
doing the inheritance in C<@ISA> and writing package methods.

If you manually add subroutines to a package at run-time and want the slot 
information updated properly (although this really should be done via the 
C<addSlots> mechanism, but maybe you're twisted:), you should do something like:

    $package->reflect->_vivified_methods(0);
    $package->reflect->_autovivify_methods;


=head2 Parent Slots

Adding parent slots is no different than adding normal slots - the naming
scheme takes care of differentiating.

Thus, to add C<$foo> as a parent to C<$bar>, you write:

    $bar->reflect->addSlot('fooParent*' => $foo);

However, keeping with our concept of classes as first class objects, you can
also write the following:

    $bar->reflect->addSlot('mixIn*' => 'MyMix::Class');

It will automatically require the module in the namespace of C<$bar> and
make the module a parent of the object.
This can load a module from disk if needed.

If you're lazy, you can add parents without names like so:

    $bar->reflect->addSlot('*' => $foo);

The slots will be automatically named for the package passed in - in the case
of C<Class::Prototyped> objects, the package is of the form C<PKG0x12345678>.
In the following example, the parent slot will be named C<MyMix::Class*>.

    $bar->reflect->addSlot('*' => 'MyMix::Class');

Parent slots are added to the inheritance hierarchy in the order that they
were added.  Thus, in the following code, slots that don't exist in C<$foo>
are looked up in C<$fred> (and all of its parent slots) before being looked up
in C<$jill>.

    $foo->reflect->addSlots('fred*' => $fred, 'jill*' => $jill);

Note that C<addSlot> and C<addSlots> are identical - the variants exist only
because it looks ugly to add a single slot by calling C<addSlots>.

If you need to reorder the parent slots on an object, look at
C<promoteParents>.  That said, there's a shortcut for prepending a slot to
the inheritance hierarchy.  Simply define C<'promote'> as a slot attribute
using the extended slot syntax.

Finally, in keeping with our principle that classes are first-class object,
the inheritance hierarchy of classes can be modified through C<addSlots> and
C<deleteSlots>, just like it can for objects.  The following code adds the
C<$foo> object as a parent of the C<MyClass> class, prepending it to the
inheritance hierarchy:

    MyClass->reflect->addSlots([qw(foo* promote)] => $foo);


=head2 Operator Overloading

In C<Class::Prototyped>, you do operator overloading by adding slots with the
right name.  First, when you do the C<use> on C<Class::Prototyped>, make sure
to pass in C<:OVERLOAD> so that the operator overloading support is enabled.

Then simply pass the desired methods in as part of the object creation like
so:

    $foo = Class::Prototyped->new(
        value => 3,
        '""'  => sub { my $self = shift; $self->value( $self->value + 1 ) },
    );

This creates an object that increments its field C<value> by one and returns
that incremented value whenever it is stringified.

Since there is no way to find out which operators are overloaded, if you add
overloading to a I<class> through the use of C<use overload>, that behavior
will not show up as slots when reflecting on the class. However, C<addSlots>
B<does> work for adding operator overloading to classes.  Thus, the following
code does what is expected:

    Class::Prototyped->newPackage('MyClass');
    MyClass->reflect->addSlots(
        '""' => sub { my $self = shift; $self->value( $self->value + 1 ) },
    );

    $foo = MyClass->new( value => 2 );
    print $foo, "\n";


=head2 Object Class

The special parent slot C<class*> is used to indicate object class.  When you 
create C<Class::Prototyped> objects by calling C<< Class::Prototyped->new() >>, 
the C<class*> slot is B<not> set.  If, however, you create objects by calling 
C<new> on a class or object that inherits from C<Class::Prototyped>, the slot 
C<class*> points to the package name if C<new> was called on a named class, or 
the object if C<new> was called on an object.

The value of this slot can be returned quite easily like so:

    $foo->reflect->class;


=head2 Calling Inherited Methods

Methods (and fields) inherited from prototypes or classes are I<not>
generally available using the usual Perl C<< $self->SUPER::something() >>
mechanism.

The reason for this is that C<SUPER::something> is hardcoded to the package in
which the subroutine (anonymous or otherwise) was defined.  For the vast
majority of programs, this will be C<main::>, and thus C<SUPER::> will look in
C<@main::ISA> (not a very useful place to look).

To get around this, a very clever wrapper can be automatically placed around
your subroutine that will automatically stash away the package to which the
subroutine is attached.  From within the subroutine, you can use the C<super>
mirror method to make an inherited call.  However, because we'd rather not
write code that attempts to guess as to whether or not the subroutine uses the
C<super> construct, you have to tell C<addSlots> that the subroutine needs to
have this wrapper placed around it.  To do this, simply use the extended
C<addSlots> syntax (see the method description for more information) and pass
in the slot attribute C<'superable'>.  The following examples use the minimalist
form of the extended syntax.

For instance, the following code will work:

    use Class::Prototyped;

    my $p1 = Class::Prototyped->new(
        method => sub { print "this is method in p1\n" },
    );

    my $p2 = Class::Prototyped->new(
        '*'                     => $p1,
        [qw(method superable)]' => sub {
            print "this is method in p2 calling method in p1: ";
            $_[0]->reflect->super('method');
        },
    );

To make things easier, if you specify C<:EZACCESS> during the import, C<super>
can be called directly on an object rather than through its mirror.

The other thing of which you need to be aware is copying methods from one
object to another.  The proper way to do this is like so:

    $foo->reflect->addSlot($bar->reflect->getSlot('method'));

When the C<getSlot> method is called in an array context, it returns both the
complete format for the slot identifier and the slot.  This ensures that slot
attributes are passed along, including the C<superable> attribute.

Finally, to help protect the code, the C<super> method is smart enough to 
determine whether it was called within a wrapped subroutine.  If it wasn't, it 
croaks indicating that the method should have had the C<superable> attribute set 
when it was added.  If you wish to disable this checking (which will improve the 
performance of your code, of course, but could result in B<very> hard to trace 
bugs if you haven't been careful), see the import option C<:SUPER_FAST>.


=head1 PERFORMANCE NOTES

It is important to be aware of where the boundaries of prototyped based 
programming lie, especially in a language like Perl that is not optimized for 
it.  For instance, it might make sense to implement every field in a database as 
an object.  Those field objects would in turn be attached to a record class. All 
of those might be implemented using C<Class::Prototyped>.  However, it would be 
very inefficient if every record that got read from the database was stored in a 
C<Class::Prototyped> based object (unless, of course, you are storing code in 
the database).  In that situation, it is generally good to choke off the 
prototype-based behavior for the individual record objects.  For best 
performance, it is important to confine C<Class::Prototyped> to those portions 
of the code where behavior is mutable from outside of the module.  See the 
documentation for the C<new> method of C<Class::Prototyped> for more information 
about choking off C<Class::Prototyped> behavior.

There are a number of performance hits when using C<Class::Prototyped>, relative 
to using more traditional OO code.  B<It is important to note> that these 
generally lie in the instantiation and creation of classes and objects and not 
in the actual use of them.  The scripts in the C<perf> directory were designed 
for benchmarking some of this material.

=head2 Class Instantiation

The normal way of creating a class is like this:

    package Pack_123;
    sub a {"hi";}
    sub b {"hi";}
    sub c {"hi";}
    sub d {"hi";}
    sub e {"hi";}

The most efficient way of doing that using "proper" C<Class::Prototyped> methodology looks like this:

    Class::Prototyped->newPackage("Pack_123");
    push(@P_123::slots, a => sub {"hi";});
    push(@P_123::slots, b => sub {"hi";});
    push(@P_123::slots, c => sub {"hi";});
    push(@P_123::slots, d => sub {"hi";});
    push(@P_123::slots, e => sub {"hi";});
    Pack_123->reflect->addSlots(@P_123::slots);

This approach ensures that the new package gets the proper default attributes 
and that the slots are created through C<addSlots>, thus ensuring that default 
attributes are properly implemented.  It avoids multiple calls to C<< 
->reflect->addSlot >>, though, which improves performance.  The idea behind
pushing the slots onto an array is that it enables one to intersperse code with
POD, since POD is not permitted inside of a single Perl statement.

On a Pent 4 1.8GHz machine, the normal code runs in 120 usec, whereas the 
C<Class::Prototyped> code runs in around 640 usec, or over 5 times slower.  A 
straight call to C<addSlots> with all five methods runs in around 510 usec.  
Code that creates the package and the mirror without adding slots runs in around 
135 usec, so we're looking at an overhead of less than 100 usec per slot.  In a 
situation where the "compile" time dominates the "execution" time (I'm using 
those terms loosely as much of what happens in C<Class::Prototyped> is 
technically execution time, but it is activity that traditionally would happen 
at compile time), C<Class::Prototyped> might prove to be too much overhead.  On 
the otherhand, you may find that demand loading can cut much of that overhead 
and can be implemented less painfully than might otherwise be thought.

=head2 Object Instantiation

There is no need to even compare here.  Blessing a hash into a class takes less 
than 2 usec.  Creating a new C<Class::Prototyped> object takes at least 60 or 70 
times longer.  The trick is to avoid creating unnecessary C<Class::Prototyped> 
objects.  If you know that all 10,000 database records are going to inherit all 
of their behavior from the parent class, there is no point in creating 10,000 
packages and all the attendant overhead.  The C<new> method for 
C<Class::Prototyped> demonstrates how to ensure that those state objects are 
created as normal Perl objects.

=head2 Method Calls

The good news is that method calls are just as fast as normal Perl method calls, 
inherited or not.  This is because the existing Perl OO machinery has been 
hijacked in C<Class::Prototyped>.  The exception to this is if C<filter> slot 
attributes have been used, including C<wantarray>, C<superable>, and C<profile>.  
In that situation, the added overhead is that for a normal Perl subroutine call 
(which is faster than a method call because it is a static binding)

=head2 Instance Variable Access

The hash interface is not particularly fast, and neither is it good programming 
practice.  Using the method interface to access fields is just as fast, however, 
as using normal getter/setter methods.


=head1 IMPORT OPTIONS

=over 4

=item C<:OVERLOAD>

This configures the support in C<Class::Prototyped> for using operator
overloading.

=item C<:REFLECT>

This defines C<UNIVERSAL::reflect> to return a mirror for any class.
With a mirror, you can manipulate the class, adding or deleting methods,
changing its inheritance hierarchy, etc.

=item C<:EZACCESS>

This adds the methods C<addSlot>, C<addSlots>, C<deleteSlot>, C<deleteSlots>,
C<getSlot>, C<getSlots>, and C<super> to C<Class::Prototyped>.

This lets you write:

  $foo->addSlot(myMethod => sub {print "Hi there\n"});

instead of having to write:

  $foo->reflect->addSlot(myMethod => sub {print "Hi there\n"});

The other methods in C<Class::Prototyped::Mirror> should be accessed through a
mirror (otherwise you'll end up with way too much name space pollution for
your objects:).

Note that it is bad form for published modules to use C<:EZACCESS> as you are 
polluting everyone else's namespace as well.  If you B<really> want C<:EZACCESS> 
for code you plan to publish, contact the maintainer and we'll see what we can 
about creating a variant of C<:EZACCESS> that adds the shortcut methods to a 
single class.  Note that using C<:EZACCESS> to do C<< $obj->addSlot() >> is 
actually slower than doing C<< $obj->reflect->addSlot() >>.

=item C<:SUPER_FAST>

Switches over to the fast version of C<super> that doesn't check to see
whether slots that use inherited calls were defined as superable.

=item C<:NEW_MAIN>

Creates a C<new> function in C<main::> that creates new C<Class::Prototyped>
objects.  Thus, you can write code like:

  use Class::Prototyped qw(:NEW_MAIN :EZACCESS);

  my $foo = new(say_hi => sub {print "Hi!\n";});
  $foo->say_hi;

=item C<:TIED_INTERFACE>

This is no longer supported.  Sorry for the very short notice - if you have
a specific need, please let me know and I will discuss your needs with you
and determine whether they can be addressed in a manner that doesn't require
you to rewrite your code, but still allows others to make use of less global
control over the tied interfaces used.  See
C<Class::Prototyped::Mirror::tiedInterfacePackage> for the preferred way of
doing this.

=back

=head1 C<Class::Prototyped> Methods

=head2 new() - Construct a new C<Class::Prototyped> object.

A new object is created.  If this is called on a class or object that inherits 
from C<Class::Prototyped>, and C<class*> is not being passed as a slot in the 
argument list, the slot C<class*> will be the first element in the inheritance 
list.

When called on named classes, either via the package name or via the object 
(i.e. C<< MyPackage->reflect->object() >>), C<class*> is set to the package 
name.  When called on an object, C<class*> is set to the object on which C<new> 
was called.

The passed arguments are handed off to C<addSlots>.

Note that C<new> calls C<newCore>, so if you want to override C<new>, but want 
to ensure that your changes are applicable to C<newPackage>, C<clone>, and 
C<clonePackage>, you may wish to override C<newCore>.

For instance, the following will define a new C<Class::Prototyped> object with
two method slots and one field slot:

    my $foo = Class::Prototyped->new(
        field1 => 123,
        sub1   => sub { print "this is sub1 in foo" },
        sub2   => sub { print "this is sub2 in foo" },
    );

The following will create a new C<MyClass> object with one field slot and with
the parent object C<$bar> at the beginning of the inheritance hierarchy (just
before C<class*>, which points to C<MyClass>):

    my $foo = MyClass->new(
        field1  => 123,
        [qw(bar* promote)] => $bar,
    );

The following will create a new object that inherits behavior from C<$bar> with 
one field slot, C<field1>, and one parent slot, C<class*>, that points to 
C<$bar>.

    my $foo = $bar->new(
        field1  => 123,
    );

If you want to create normal Perl objects as child objects of a 
C<Class::Prototyped> class in order to improve performance, implement your own 
standard Perl C<new> method:

    Class::Prototyped->newPackage('MyClass');
    MyClass->reflect->addSlot(
        new => sub {
            my $class = shift;
            my $self = {};
            bless $self, $class;
            return $self;
        }
    );

It is still safe to use C<< $obj->reflect->super() >> in code that runs on such 
an object.  All other reflection will automatically return the same results as
inspecting the class to which the object belongs.


=head2 newPackage() - Construct a new C<Class::Prototyped> object in a
specific package.

Just like C<new>, but instead of creating the new object with an arbitrary 
package name (actually, not entirely arbitrary - it's generally based on the 
hash memory address), the first argument is used as the name of the package.  
This creates a named class.  The same behavioral rules for C<class*> described 
above for C<new> apply to C<newPackage> (in fact, C<new> calls C<newPackage>).

If the package name is already in use, this method will croak.

=head2 clone() - Duplicate me

Duplicates an existing object or class and allows you to add or override
slots. The slot definition is the same as in B<new()>.

  my $p2 = $p1->clone(
      sub1 => sub { print "this is sub1 in p2" },
  );

It calls C<newCore> to create the new object*, so if you have overriden C<new>, 
you should contemplate overriding C<clone> in order to ensure that behavioral 
changes made to C<new> that would be applicable to C<clone> are implemented.  Or 
simply override C<newCore>.

=head2 clonePackage()

Just like C<clone>, but instead of creating the new object with an arbitrary 
package name (actually, not entirely arbitrary - it's generally based on the 
hash memory address), the first argument is used as the name of the package.  
This creates a named class.

If the package name is already in use, this method will croak.

=head2 newCore()

This implements the core functionality involved in creating a new object.  The 
first passed parameter will be the name of the caller - either C<new>, 
C<newPackage>, C<clone>, or C<clonePackage>.  The second parameter is the name 
of the package if applicable (i.e. for C<newPackage> and C<clonePackage>) calls, 
C<undef> if inapplicable.  The remainder of the parameters are any slots to be 
added to the newly created object/package.

If called with C<new> or C<newPackage>, the C<class*> slot will be prepended to 
the slot list if applicable.  If called with C<clone> or C<clonePackage>, all 
slots on the receiver will be prepended to the slot list.

If you wish to add behavior to object instantiation that needs to be present in 
all four of the instantiators (i.e. instance tracking), it may make sense to 
override C<newCore> so that you implement the code in only one place.

=head2 reflect() - Return a mirror for the object or class

The structure of an object is modified by using a mirror.  This is the
equivalent of calling:

  Class::Prototyped::Mirror->new($foo);

=head2 destroy() - The destroy method for an object

You should never need to call this method.  However, you may want to override
it.  Because we had to directly specify C<DESTROY> for every object in order
to allow safe destruction during global destruction time when objects may
have already destroyed packages in their C<@ISA>, we had to hook C<DESTROY>
for every object.  To allow the C<destroy> behavior to be overridden, users
should specify a C<destroy> method for their objects (by adding the slot),
which will automatically be called by the C<Class::Prototyped::DESTROY>
method after the C<@ISA> has been cleaned up.

This method should be defined to allow inherited method calls (I<i.e.> should
use "C<[qw(destroy superable)]>" to define the method) and should call
C<< $self->reflect->super('destroy'); >> at some point in the code.

Here is a quick overview of the default destruction behavior for objects:

=over 4

=item *

C<Class::Prototyped::DESTROY> is called because it is linked into the package
for all objects at instantiation time

=item *

All no longer existent entries are stripped from C<@ISA>

=item *

The inheritance hierarchy is searched for a C<DESTROY> method that is not
C<Class::Prototyped::DESTROY>.  This C<DESTROY> method is stashed away for
a later call.

=item *

The inheritance hierarchy is searched for a C<destroy> method and it is
called.  Note that the C<Class::Prototyped::destroy> method, which will
either be called directly because it shows up in the inheritance hierarchy or
will be called indirectly through calls to
C<< $self->reflect->super('destroy'); >>, will delete all non-parent slots from
the object.  It leaves parent slots alone because the destructors for the
parent slots should not be called until such time as the destruction of the
object in question is complete (otherwise inherited destructors might still
be executing, even though the object to which they belong has already been
destroyed).  This means that the destructors for objects referenced in
non-parent slots may be called, temporarily interrupting the execution
sequence in C<Class::Prototyped::destroy>.

=item *

The previously stashed C<DESTROY> method is called.

=item *

The parent slots for the object are finally removed, thus enabling the
destructors for any objects referenced in those parent slots to run.

=item *

Final C<Class::Prototyped> specific cleanup is run.

=back



=head1 C<Class::Prototyped::Mirror> Methods

These are the methods you can call on the mirror returned from a C<reflect> 
call. If you specify C<:EZACCESS> in the C<use Class::Prototyped> line, 
C<addSlot>, C<addSlots>, C<deleteSlot>, C<deleteSlots>, C<getSlot>, C<getSlots>, 
and C<super> will be callable on C<Class::Prototyped> objects as well.

=head2 new() - Creates a new C<Class::Prototyped::Mirror> object

Normally called via the C<reflect> method, this can be called directly to avoid 
using the C<:REFLECT> import option for reflecting on non C<Class::Prototyped> 
based classes.

=head2 autoloadCall()

If you add an C<AUTOLOAD> slot to an object, you will need to get the name of 
the subroutine being called. C<autoloadCall()> returns the name of the 
subroutine, with the package name stripped off.

=head2 package() - Returns the name of the package for the object

=head2 object() - Returns the object itself

=head2 class() - Returns the C<class*> slot for the underlying object

=head2 dump() - Returns a Data::Dumper string representing the object

=head2 addSlot() - An alias for C<addSlots>

=head2 addSlots() - Add or replace slot definitions

Allows you to add or replace slot definitions in the receiver.

    $p->reflect->addSlots(
        fred        => 'this is fred',
        doSomething => sub { print 'doing something with ' . $_[1] },
    );
    $p->doSomething( $p->fred );

In addition to the simple form, there is an extended syntax for specifying the
slot.  In place of the slotname, pass an array reference composed like so:

C<< addSlots( [$slotName, $slotType, %slotAttributes] => $slotValue ); >>

C<$slotName> is simply the name of the slot, including the trailing C<*> if it
is a parent slot.  C<$slotType> should be C<'FIELD'>, C<'METHOD'>, or
C<'PARENT'>.  C<%slotAttributes> should be a list of attribute/value pairs.  It
is common to use qw() to reduce the amount of typing:

    $p->reflect->addSlot(
        [qw(bar FIELD)] => "this is a field",
    );

    $p->reflect->addSlot(
        [qw(bar FIELD constant 1)] => "this is a constant field",
    );

    $p->reflect->addSlot(
        [qw(foo METHOD)] => sub { print "normal method.\n"; },
    );

    $p->reflect->addSlot(
        [qw(foo METHOD superable 1)] => sub { print "superable method.\n"; },
    );

    $p->reflect->addSlot(
        [qw(parent* PARENT)] => $parent,
    );

    $p->reflect->addSlot(
        [qw(parent2* PARENT promote 1)] => $parent2,
    );

To make using the extended syntax a bit less cumbersome, however, the following
shortcuts are allowed:

=over 4

=item *

C<$slotType> can be omitted.  In this case, the slot's type will be determined 
by inspecting the slot's name (to determine if it is a parent slot) and the 
slot's value (to determine whether it is a field or method slot).  The 
C<$slotType> value can, however, be used to supply a reference to a code object 
as the value for a field slot.  Note that this means that C<FIELD>, C<METHOD>, 
and C<PARENT> are not legal attribute names (since this would make parsing 
difficult).

=item *

If there is only one attribute and if the value is C<1>, then the value can be
omitted.

=back

Using both of the above contractions, the following are valid short forms for
the extended syntax:

    $p->reflect->addSlot(
        [qw(bar constant)] => "this is a constant field",
    );

    $p->reflect->addSlot(
        [qw(foo superable)] => sub { print "superable method.\n"; },
    );

    $p->reflect->addSlot(
        [qw(parent2* promote)] => $parent2,
    );

The currently defined slot attributes are as follows:

=over

=item C<FIELD> Slots

=over

=item C<constant> (C<implementor>)

When true, this defines the field slot as constant, disabling the ability to 
modify it using the C<< $object->field($newValue) >> syntax.  The value may 
still be modified using the hash syntax (i.e. C<< $object->{field} =
$newValue >>).  This is mostly useful if you have an object method call that takes 
parameters, but you wish to replace it on a given object with a hard-coded value 
by using a field (which makes inspecting the value of the slot through 
C<Data::Dumper> much easier than if you use a C<METHOD> slot to return the
constant, since code objects are opaque).

=item C<autoload> (C<filter>, rank 50)

The passed value for the C<FIELD> slot should be a subroutine that returns the 
desired value.  Upon the first access, the subroutine will be called, the return 
value hard-coded into the object by adding the slot (including all otherwise 
specified attributes), and the value then returned.  Useful for implementing 
constant slots that are costly to initialize, especially those that return lists 
of C<Class::Prototyped> objects!

=item C<profile> (C<filter>, rank 80)

If C<profile> is set to 1, increments C<< 
$Class::Prototyped::Mirror::PROFILE::counts->{$package}->{$slotName} >> 
everytime the slot is accessed.  If C<profile> is set to 2, increments C<< 
$Class::Prototyped::Mirror::PROFILE::counts->{$package}->{$slotName}->{$caller} >>
everytime the slot is accessed, where C<$caller> is C<"$file ($line)">.

=item C<wantarray> (C<filter>, rank 90)

If the field specifies a reference to an array and the call is in list context, 
dereferences the array and returns a list of values.

=item C<description> (C<advisory>)

Can be used to specify a description.  No real support for this yet beyond that!

=back

=item C<METHOD> Slots

=over

=item C<superable> (C<filter>, rank 10)

When true, this enables the C<< $self->reflect->super( . . . ) >> calls for this 
method slot.

=item C<profile> (C<filter>, rank 90)

See C<FIELD> slots for explanation.

=item C<overload> (C<advisory>)

Set automatically for methods that implement operator overloading.

=item C<description> (C<advisory>)

See C<FIELD> slots for explanation.

=back

=item C<PARENT> Slots

=over

=item C<promote> (C<advisory>)

When true, this parent slot is promoted ahead of any other parent slots on the 
object.  This attribute is ephemeral - it is not returned by calls to 
C<getSlot>.

=item C<description> (C<advisory>)

See C<FIELD> slots for explanation.

=back

=back

=head2 deleteSlot() - An alias for deleteSlots

=head2 deleteSlots() - Delete one or more of the receiver's slots by name

This will let you delete existing slots in the receiver. If those slots were 
defined in the receiver's inheritance hierarchy, those inherited definitions 
will now be available.

    my $p1 = Class::Prototyped->new(
        field1 => 123,
        sub1   => sub { print "this is sub1 in p1" },
        sub2   => sub { print "this is sub2 in p1" }
    );
    my $p2 = Class::Prototyped->new(
        'parent*' => $p1,
        sub1      => sub { print "this is sub1 in p2" },
    );
    $p2->sub1;    # calls $p2.sub1
    $p2->reflect->deleteSlots('sub1');
    $p2->sub1;    # calls $p1.sub1
    $p2->reflect->deleteSlots('sub1');
    $p2->sub1;    # still calls $p1.sub1

=head2 super() - Call a method defined in a parent

The call to a method defined on a parent that is obscured by the current one 
looks like so:

    $self->reflect->super('method_name', @params);

=head2 slotNames() - Returns a list of all the slot names

This is passed an optional type parameter.  If specified, it should be one of 
C<'FIELD'>, C<'METHOD'>, or C<'PARENT'>.  For instance, the following will print 
out a list of all slots of an object:

  print join(', ', $obj->reflect->slotNames)."\n";

The following would print out a list of all field slots:

  print join(', ', $obj->reflect->slotNames('FIELD')."\n";

The parent slot names are returned in the same order for which inheritance is
done.

=head2 slotType() - Given a slot name, determines the type

This returns C<'FIELD'>, C<'METHOD'>, or C<'PARENT'>.
It croaks if the slot is not defined for that object.

=head2 parents() - Returns a list of all parents

Returns a list of all parent object (or package names) for this object.

=head2 allParents() - Returns a list of all parents in the hierarchy

Returns a list of all parent objects (or package names) in the object's
hierarchy.

=head2 withAllParents() - Same as above, but includes self in the list

=head2 allSlotNames() - Returns a list of all slot names
defined for the entire inheritance hierarchy

Note that this will return duplicate slot names if inherited slots are
obscured.

=head2 getSlot() - Returns the requested slot

When called in scalar context, this returns the thing in the slot.  When called 
in list context, it returns both the complete form of the extended syntax for 
specifying a slot name and the thing in the slot.  There is an optional 
parameter that can be used to modify the format of the return value in list 
context.  The allowable values are:

=over

=item *

C<'default'> - the extended slot syntax and the slot value are returned

=item *

C<'simple'> - the slot name and the slot value are returned.  Note that in this 
mode, there is no access to any attributes the slot may have

=item *

C<'rotated'> - the slot name and the following hash are returned like so:

  $slotName => {
    attribs => %slotAttribs,
    type => $slotType,
    value => $slotValue
  },

=back

The latter two options are quite useful when used in conjunction with the 
C<getSlots> method.

=head2 getSlots() - Returns a list of all the slots

This returns a list of extended syntax slot specifiers and their values ready 
for sending to C<addSlots>.  It takes first the optional parameter passed to 
C<slotNames> which specifies the type of slot (C<'FIELD'>, C<'METHOD'>, 
C<'PARENT'>, or C<undef>) and then the optional parameter passed to C<getSlot>, 
which specifies the format for the return value.  If the latter is C<'simple'>, 
the returned values can be passed to C<addSlots>, but any non-default slot 
attributes (i.e. C<superable> or C<constant>) will be lost.  If the latter is
C<'rotated'>, the returned values are completely inappropriate for passing to
C<addSlots>.  Both C<'simple'> and C<'rotated'> are appropriate for assigning
the return values into a hash.

For instance, to add all of the field slots in C<$bar> to C<$foo>:

  $foo->reflect->addSlots($bar->reflect->getSlots('FIELD'));

To get a list of all of the slots in the C<'simple'> format:

  my %barSlots = $bar->reflect->getSlots(undef, 'simple');

To get a list of all of the superable method slots in the C<'rotated'> format:

  my %barMethods = $bar->reflect->getSlots('METHOD', 'rotated');
  foreach my $slotName (%barMethods) {
    delete $barMethods{$slotName}
      unless $barMethods{$slotName}->{attribs}->{superable};
  }

=head2 promoteParents() - This changes the ordering of the parent slots

This expects a list of parent slot names.  There should be no duplicates and
all of the parent slot names should be already existing parent slots on the
object.  These parent slots will be moved forward in the hierarchy in the order
that they are passed.  Unspecified parent slots will retain their current
positions relative to other unspecified parent slots, but as a group they will
be moved to the end of the hierarchy.

=head2 tiedInterfacePackage() - This specifies the tied interface package

This allows you to specify the sort of tied interface you wish to offer when
code accesses the object as a hash reference.  If no parameter is passed,
this will return the current tied interface package active for the object.
If a parameter is passed, it should specify either the package name or an
alias.  The currently known aliases are:

=over 4

=item default

This specifies C<Class::Prototyped::Tied::Default> as the tie class.  The
default behavior is to allow access to existing fields, but attempts to create
fields, access methods, or delete slots will croak.  This is the tie class
used by C<Class::Prototyped> (unless you do something very naughty and call
C<< Class::Prototyped->reflect->tiedInterfacePackage($not_default) >>), and
as such is the fallback behavior for classes and objects if they don't get a
different value from their inheritance.

=item autovivify

This specifies C<Class::Prototyped::Tied::AutoVivify> as the tie class.  The
behavior of this package allows access to existing fields, will automatically
create field slots if they don't exist, and will allow deletion of field slots.
Attempts to access or delete method or parent slots will croak.

=back

Calls to C<new> and C<clone> will use the tied interface in use on the
existing object/package.  When C<reflect> is called for the first time on a
class package, it will use the tied interface of its first parent class (i.e.
C<$ISA[0]>).  If that package has not yet had C<reflect> called on it, it
will check its parent, and so on and so forth.  If none of the packages in
the primary inheritance fork have been reflected upon, the value for
C<Class::Prototyped> will be used, which should be C<default>.

=head2 defaultAttributes() - get and set default attributes

This isn't particularly pretty.  The general syntax looks something like:

    my $temp = MyClass->reflect->defaultAttributes;
    $temp->{METHOD}->{superable} = 1;
    MyClass->reflect->defaultAttributes($temp);

The return value from C<defaultAttributes> is a hash with the keys C<'FIELD'>, 
C<'METHOD'>, and C<'PARENT'>.  The values are either C<undef> or hash references 
consisting of the attributes and their default values.  Modify the data 
structure as desired and pass it back to C<defaultAttributes> to change the 
default attributes for that object or class.  Note that default attributes are 
not inherited dynamically - the inheritance occurs when a new object is created, 
but from that point on changes to a parent object are not inherited by the 
child.  Global changes can be effected by modifying the C<defaultAttributes> for 
C<Class::Prototyped> in a sufficiently early C<BEGIN> block.  Note that making 
global changes like this is C<not> recommended for production modules as it may 
interfere with other modules that rely upon C<Class::Prototyped>.

=head2 wrap()

=head2 unwrap()

=head2 delegate()

delegate name => slot
name can be string, regex, or array of same.
slot can be slot name, or object, or 2-element array
with slot name or object and method name.
You can delegate to a parent.

=head2 include() - include a package or external file

You can C<require> an arbitrary file in the namespace of an object
or class without adding to the parents using C<include()> :

  $foo->include( 'xx.pl' );

will include whatever is in xx.pl. Likewise for modules:

  $foo->include( 'MyModule' );

will search along your C<@INC> path for C<MyModule.pm> and include it.

You can specify a second parameter that will be the name of a subroutine
that you can use in your included code to refer to the object into
which the code is being included (as long as you don't change packages in the
included code). The subroutine will be removed after the include, so
don't call it from any subroutines defined in the included code.

If you have the following in C<File.pl>:

    sub b {'xxx.b'}

    sub c { return thisObject(); }    # DON'T DO THIS!

    thisObject()->reflect->addSlots(
        'parent*' => 'A',
        d         => 'added.d',
        e         => sub {'xxx.e'},
    );

And you include it using:

    $mirror->include('File.pl', 'thisObject');

Then the C<addSlots> will work fine, but if sub C<c> is called, it won't find
C<thisObject()>.

=head1 AUTHOR

Written by Ned Konz, perl@bike-nomad.com and Toby Ovod-Everett, toby@ovod-everett.org. 5.005_03 porting by chromatic.

Toby Ovod-Everett is currently maintaining the package.

=head1 LICENSE

Copyright 2001-2004 Ned Konz and Toby Ovod-Everett.  All rights reserved. This 
program is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

L<Class::SelfMethods>

L<Class::Object>

L<Class::Classless>

=cut
