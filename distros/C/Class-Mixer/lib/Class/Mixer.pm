package Class::Mixer;
use strict;
use Class::C3;
use base;
our $VERSION = '0.54';

sub new
{
	my $class = shift;
	$class = ref $class if ref $class;
	$Class::Mixer::DEBUG ||= 0;

	$class->remix_class;

	my $self = bless {},$class;
	$self->init(@_) if $self->can('init');
	return $self;
}


# this will remix the class the first time it is instantiated,
# after that, the class is considered closed.
sub remix_class
{
	my $self = shift;
	my $class = ref $self || $self;
	no strict 'refs';
	return if ${"$class\::REMIX"};

	${"$class\::REMIX"} = 1;
	@{"$class\::WASA"} = @{"$class\::ISA"};

	if ($Class::Mixer::DEBUG) {
		print "REMIXING $class...\n";
		my @classes = Class::C3::calculateMRO($class);
		print "before: @classes\n";
	}

	my $con = {}; # constraints
	$self->remix_collect($class,$con);

	if ($Class::Mixer::DEBUG > 2) {
		require Data::Dumper;
		$Data::Dumper::Sortkeys = 1;
		print Data::Dumper::Dumper($con);
	}

	$self->mixdown($con);
	print qq{\@$class\::ISA = @{"$class\::ISA"}\n} if $Class::Mixer::DEBUG > 1;

	Class::C3::reinitialize();
	if ($Class::Mixer::DEBUG) {
		my @classes = Class::C3::calculateMRO($class);
		print "after: @classes\n";
	}
}

sub remix_collect
{
	my $self = shift;
	my $class = ref $self || $self;
	no strict 'refs';

	my $subclass = shift;
	my $con = shift;
	return if exists $con->{$subclass};
	$con->{$subclass} = {};

	my @ISA = @{"$subclass\::WASA"} ?
			@{"$subclass\::WASA"} :
			@{"$subclass\::ISA"};
	my @mixers = @{"$subclass\::MIXERS"};

	my $type = 'before';
	for my $mixer (@ISA,@mixers) {
		if ($mixer =~ m/^(before|after|isa|requires?|optional)$/) {
			$type = $mixer;
			$type = 'requires' if $type eq 'require';
			next;
		}

		$con->{$subclass}->{$type} ||= [];
		push @{$con->{$subclass}->{$type}}, $mixer;

		remix_require($mixer);
		$self->remix_collect($mixer,$con);
	}
}


# "borrowed" from base.pm
sub remix_require
{
	no strict 'refs';
	my $base = shift;

	my $vglob = ${$base.'::'}{VERSION};
	if ($vglob && *$vglob{SCALAR}) {
            ${$base.'::VERSION'} = '-1, set by Class::Mixer'
              unless defined ${$base.'::VERSION'};
        } else {
            local $SIG{__DIE__};
            eval "require $base";
            # Only ignore "Can't locate" errors from our eval require.
            # Other fatal errors (syntax etc) must be reported.
            die $@ if $@ && $@ !~ /^Can't locate .*? at \(eval /;
            unless (%{"$base\::"}) {
                require Carp;
                Carp::croak(<<ERROR);
Base class package "$base" is empty.
    (Perhaps you need to 'use' the module which defines that package first.)
ERROR

            }
            ${$base.'::VERSION'} = "-1, set by Class::Mixer"
              unless defined ${$base.'::VERSION'};
        }
}


sub mixdown
{
	my $self = shift;
	my $class = ref $self || $self;
	my $con = shift;
	no strict 'refs';

	my @classes = ($class, grep $_ ne $class, keys %$con);
	my @BEA = @{"$class\::ISA"};

	# isa: when A isa B,
	#      substitute A for all B's
	for my $subclass (@classes) {
		next unless $con->{$subclass}->{isa};
		for my $isa (@{$con->{$subclass}->{isa}}) {
			for my $sub2 (@classes) {
				for my $k (keys %{$con->{$sub2}}) {
					next if $k eq 'isa';
					for (@{$con->{$sub2}->{$k}}) {
						$_ = $subclass if $_ eq $isa;
					}
				}
			}
		}
	}

	for my $subclass (@classes) {
		next unless $con->{$subclass}->{optional};
		my @opt = @{$con->{$subclass}->{optional}};
		$con->{$subclass}->{optional} = {};
		for my $o (@opt) {
			$con->{$subclass}->{optional}->{$o} = 1;
		}
	}
	# after: A after B means B before A, A is optional
	for my $subclass (@classes) {
		next unless $con->{$subclass}->{after};
		for my $mixer (@{$con->{$subclass}->{after}}) {
			$con->{$mixer}->{before} ||= [];
			push @{$con->{$mixer}->{before}}, $subclass;
			$con->{$mixer}->{optional}->{$subclass} = 1;
		}
	}
	if ($Class::Mixer::DEBUG > 5) {
		print "AFTER isa and after substitutions\n";
		print Data::Dumper::Dumper($con);
	}

	# make a tree
	for my $subclass (@classes) {
		$con->{$subclass}->{node} = { 
			class=>$subclass, 
			isa=>[],
			bef=>[],
			req=>[],
		};
	}
	for my $subclass (@classes) {
		push @{$con->{$subclass}->{node}->{req}},
			map { $con->{$_}->{node} } 
				@{$con->{$subclass}->{requires}};
		push @{$con->{$subclass}->{node}->{bef}},
			map { $con->{$_}->{node} } 
				@{$con->{$subclass}->{before}};
		# isa should bind tightest
		push @{$con->{$subclass}->{node}->{isa}},
			map { $con->{$_}->{node} } 
				@{$con->{$subclass}->{isa}};
			;
	}
	if ($Class::Mixer::DEBUG > 4) {
		print Data::Dumper::Dumper($con->{$class}->{node});
	}

	# reverse depth first traversal
	@BEA = depth_first_traverse($con->{$class}->{node});
	shift @BEA;  # remove self

	@{"$class\::ISA"} = @BEA;
}

sub depth_first_traverse
{
	my $node = shift;
	my $stem = shift || '';
	$stem = $stem.' '.$node->{class}.' ';
#print "$stem\n";

	# check for loops
	for (@{$node->{bef}},@{$node->{isa}}) {
		if ($stem =~ m/\s$$_{class}\s/) {
			die("inconsistent hierarchy ($stem $$_{class})");
		}
	}

	return if $node->{visited};
	$node->{visited} = 1;
	my @r;

	for (@{$node->{req}}, @{$node->{bef}}, @{$node->{isa}}) {
		unshift @r,depth_first_traverse($_,$stem);
	}
	#print $node->{class};
	#print " ";
	return $node->{class},@r;
}


# use Class::Mixer automatically adds Class::Mixer to ISA
# 	require all reference classes ala use base
#	XXX test: do not require optional classes
#	also force c3 semantics ala use Class::C3
sub import
{
	my $pkg = shift;
	return unless $pkg eq 'Class::Mixer';  # not for inheritors
	my $class = caller(0);

	# save off classes -- real work done in new()
	no strict 'refs';
	no warnings 'once';
	my @mixers = @{"$class\::MIXERS"} = @_;

	# require references classes
	my $type = 'before';
	for my $mixer (@mixers) {
		if ($mixer =~ m/^(before|after|isa|requires?|optional)$/) {
			$type = $mixer;
			$type = 'requires' if $type eq 'require';
			next;
		}

		remix_require($mixer) unless $type eq 'optional';
	}

	# force Class::Mixer into ISA, so our new() will be invoked
	push @{"$class\::ISA"}, $pkg;

	# from Class::C3::import
	if ($class ne 'main') {
		mro::set_mro($class, 'c3') if $Class::C3::C3_IN_CORE;
		$Class::C3::MRO{$class} = undef unless exists $Class::C3::MRO{$class};
	}
}

1;

__END__

=pod

=head1 NAME

Class::Mixer - Arrange class hierarchy based on dependency rules

=head1 SYNOPSIS

    package Base;
    use Class::Mixer;
    sub x { 'Base::x' }

    package Main;
    use Class::Mixer before => 'Base';
    sub x { 'Main::x' }

    my $obj = Main->new();
    print "@Main::ISA\n";  # prints "Base Class::Mixer"

    package Mixin;
    use Class::Mixer before => 'Base', after => 'Main';
    sub x { 'Mixin::x' }

    package NewMain; 
    use Class::Mixer isa => 'Main', requires => 'Mixin';
    sub x { 'NewMain::x' }
 
    my $obj = NewMain->new();
    print "@NewMain::ISA\n";  # prints "Main Mixin Base Class::Mixer"

=head1 DESCRIPTION

This module is designed to solve a problem which occurs when using inheritance
to mixin behaviors into a class hierarchy.  The dependencies between a 
number of mixin modules may be complex. When different components wrap the same
behavior, they often need to be in a specific order in the call chain, 
making it tricky to get the base classes to inherit in the right order.  

Then if you have a class Main which gets the inheritance right, and you want
to add a class Mixin which needs to go in the middle of the 
inheritance, you cannot simply do C<package NewMain; use base qw(Main Mixin);>
because Mixin will be put at the end of the inheritance chain.

Also, if you have a class Foo::Better which enhances the Foo behavior,
the same problem occurs trying to mixin Foo::Better.  And it is even worse
if some classes have done C<use base 'Foo';> to try to enforce the correct
hierarchy.

This module solves these problems by implementing a dependency-based hierarchy.
You declare the relations between the classes, and an order of inheritance
which will support those relations is determined automatically.

For example, if you have a Logging component and an Authentication component,
the Logging needs to be called first, because if Authentication fails, it will
never be called at all.  In the Logging class, one can declare the Mixer rule
C<< before=>'Authentication', optional=>'Authentication' >>, so that if Authentication
is in the class hierarchy, Logging will be placed before it, but it will not
complain if it is not there.  Alternatively, one could place the rule
C<< after=>'Logging' >> in the Authentication class to achieve the same result.

Logging could also be an abstract base class, and any class which declares
C<< isa=>'Logging' >> will be kept together with Logging in the inheritance chain.
This allows rules to refer to behavior classes without needing to know
exactly which behavior class will actually be used.

In my own usage, in a structured wiki project, less essential classes usually
declare their rules in relation to more essential classes, such as Storage
and IO.  So for example, the Security class declares C<< before=>'Storage' >>
because it must be invoked before records are stored or retrieved, and also
C<< requires=>'Session' >> because it needs a session but does not share any
behavior methods with it.  Session declares C<< after=>'IO' >> because it needs IO
to process cookies and arguments before it can work.  The Index and Revision
classes both declare C<< before=>'Storage' >> but they do not care which of them
runs first.

Class::Mixer combines functions from base and Class::C3 to do its job.
It will C<require> the given classes (unless optional) similar to C<use base>.
And it attempts to force c3 semantices, so you should
do C<< $self->method::next >> instead of C<SUPER> for inheritance.

=head1 Inheritance rules

When you design your classes, instead of doing C<use base> or C<our @ISA>,
do something like the following:

    package Example;
    use Class::Mixer before => 'BaseClass', 'OtherClass',
                     after => 'SoAndSoClass',
                     isa => 'PreviousExample',
                     requires => 'OtherBehavior',
                     optional => 'OtherClass';

The Class::Mixer class provides a basic new() method, which will call init(), 
which your classes can override.

The actual inheritance is computed for a class the first time new() is called.

The inheritance rules are described here:


=head2 B<before>

The 'before' rule means this package must occur before some other
class in the method dispatch order, which means that if they both define
the same method, this class will be invoked before the other.
In the inheritance hierarchy, this class should be a descendant of the other.

This is exactly the same as what you would get if you did C<use base>
instead.  Which you can, and Class::Mixer will notice and use it.

If no rule type is given (e.g. C<use Class::Mixer 'BaseClass';> )
then the before rule is assumed.

=head2 B<after>

The 'after' rule means this package must occur after some other
class in the method dispatch order.
The other class will usually be a descendant of this one.
This is best if used rarely, but it is nice when it is necessary.

It is essentially the same as doing C<< before => 'this', optional => 'this' >>
in the other class.

=head2 B<isa>

The 'isa' rule establishes a very strong isa relationship between classes.
All the classes are related by C<@ISA>, of course, but this 'isa' means that
the particular behaviors implements by the classes are the same, and that
this one enhances the other.  

The classes are kept together as close as possible in the computed hierarchy,
and all rules which were applied to the other class will be applied to this
class as well.

=head2 B<requires>

The 'requires' rule says that this class needs the behavior from some other
class, but the inheritance order is not important.  Usually this is because
the two classes do not share any methods.

=head2 B<optional>

The 'optional' rule doesn't affect the class hierarchy.  It simply makes
the class not complain if the other class is not there.  

This is useful when we want to say, "I do not really need this other class,
but IF someone else does, I should be before (or after) the other class."

=head1 Why not Traits?

Traits are complementary to inheritance, and do not address situations where
one module needs to extend another by extending/wrapping/inheriting 
the same method.  Traits are more concerned with properly adding new
methods to a class, while Class::Mixer tries to solve some problems
with complex mixin-style inheritance trees.

For example, I have a C<write> method, and several optional behaviors
which happen when C<write> is called, such as an Index behavior and
an VersionControl behavior.  These will both override the C<write> method
and call the parent method before or after they do what they need to do.
But this violates the flattening property of traits.  
The C<write> method in Index and VersionControl are not conflicting; 
they need to inherit, perhaps in a specific order, so that
both with be called.

It may be that what I am actually describing is event-based, because write
is the event, and the behaviors are various things which need to happen
when that event occurs.  None of the event systems I have looked at have
contraints to allow ordering the behaviors relative to each other, so
even if I setup an event model, I would still need the solution which
Class::Mixer provides.

=head1 Comparison with Class::C3::Componentised

Class::C3::Componentised is used in DBIx::Class similarly to Class::Mixer
to implement the same sorts of mixin behaviors.  The difference is 
exemplified by this quote from DBIx::Class::Component, 

"The order in which is you load the components may be very important, 
depending on the component. If you are not sure, then read the docs 
for the components you are using and see if they mention anything about 
the order in which you should load them."

With Class::Mixer, the user never has to deal with the complexities of
component order.  Component ordering requirements are both documented
and *enforced* by the inheritance rules in each component.  So when
building his application class, he can list the desired component modules 
in any order, and let Class::Mixer put them in a correctly functioning order.

On the other hand, Class::Mixer has no way to override the
rules in the subclasses, so if the user decided he really wanted 
Authentication to happen before Logging, he would have to change the
rules in the subclasses in order to make that happen.

=head1 BUGS and TODO

Probably.

"optional" isn't fully implemented yet.

TODO?: implement a 'nota' rule, to prevent someone from putting this
class in the same hierarchy as another.

=head1 SEE ALSO

L<Class::C3>

L<Class::C3::Componentised>

L<base>

The snide comments in L<mixin> probably apply to this module as well.

=head1 AUTHOR

John Williams, E<lt>smailliw@gmail.comE<gt>

Thanks to Matt S Trout for help clarifying the documentation.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2009 by John Williams

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

