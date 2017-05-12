package Class::Proxy::Lite;

use strict;
use vars qw($VERSION);

$VERSION = '1.01';

use constant TOKEN    => 0;
use constant RESOLVER => 1;
use constant CACHED   => 2;

sub AUTOLOAD {
	my $self_or_class = shift();
	
	(my $method = $Class::Proxy::Lite::AUTOLOAD) =~ s/(.*):://;
	
	my $is_class_method = ref($self_or_class) eq '';
	
	# --- Check for special cases and non-references
	return undef if $method eq 'DESTROY';
	return undef if $method eq 'import' and $is_class_method;
	
	# --- XXX Try to deal with can and isa?
	
	# --- Emulate class method new()
	if ($is_class_method) {
		die "Can't call a class method on Class::Proxy::Lite or a subclass"
			unless $method eq 'new'
			and UNIVERSAL::isa($self_or_class, __PACKAGE__);
		# --- Create a proxy
		my ($token, $resolver, $cached) = @_;
		my @self;
		$self[TOKEN]    = $token;
		$self[RESOLVER] = $resolver;
		$self[CACHED]   = $cached if defined $cached;
		return bless \@self, $self_or_class;
	}
	
	# --- Reject attempts to call functions in Class::Proxy::Lite
	die "No such function: $Class::Proxy::Lite::AUTOLOAD"
		if $is_class_method
		and $self_or_class ne 'Class::Proxy::Lite';
	
	# --- Resolve the token
    my ($token, $resolver, $cached) = @$self_or_class[TOKEN, RESOLVER, CACHED];
    my $target;
	if ($cached) {
        $target = $$cached ||= $resolver->($token);
	}
	else {
	    $target = $resolver->($token);
	}
	die "Couldn't resolve proxy target"
		unless defined $target and ref $target;

# --- These don't work -- see under `Default UNIVERSAL methods'
#     in perlobj for an explanation
#	return ref($target)->isa(shift) if $method eq 'isa';
#	return ref($target)->can(shift) if $method eq 'can';
	
	# --- Invoke the method of the same name on the target object
	#     goto &{UNIVERSAL::can($target, $method)} won't work,
	#     because $target might rely upon its own AUTOLOAD!!
	no strict 'refs';
	return wantarray
		? @{ [ $target->${method}(@_) ] }
		:      $target->${method}(@_)
		;
}


1;


=head1 NAME

Class::Proxy::Lite - Simple, lightweight object proxies

=head1 SYNOPSIS

    # Make a proxy to a particular object
    $proxy = Class::Proxy::Lite->new($token, \&resolver);
    
    # Make a caching proxy
    $proxy = Class::Proxy::Lite->new($token, \&resolver, \$cache);

    # Methods invoked on the proxy are passed to the target object
    $proxy->foo(...);
    $proxy->bar(...);
    $proxy->etc(...);

=head1 DESCRIPTION

Each instance of this class serves as a proxy to a target object.  The proxy
is constructed from a I<token> and a I<resolver>.  The resolver is a code
reference called with the token as its only argument; its job is to resolve
the token into a reference to the desired target object.

The proxy doesn't hold a reference to its target; instead, the token must be
resolved each time a method call is made on the proxy.

=head1 METHODS

=head2 new

    $proxy = Class::Proxy::Lite->new($token, \&resolver);
    $proxy = Class::Proxy::Lite->new($token, \&resolver, \$cache);

Construct a proxy.  The resolver is expected to return an object exactly
equivalent (if not identical) to the desired target object.  This constraint
can't be formally enforced by this module, so your resolver must be written
in such a way as to meet the constraint itself.

If you want one-time resolution, you may pass a reference to an undefined scalar
variable as a third argument to the C<new> method; this will be used to cache
the target object the first time it's resolved, and as a result the target
object won't need to be resolved again.  Or you might pass a reference to a tied
variable that implements caching with some sort of expiry.

(There's a lot of room for clever hacks here.  For instance, you could use a
resolver that returns a different object each time it's called.  Also,
consider passing a closure as the resolver rather than a plain old reference
to a function.)

B<NOTE:> Strictly speaking, the method C<new> doesn't exist as such: it isn't
actually defined.  Instead, it's emulated using C<AUTOLOAD> (see below) --
B<< but only when called as a class method! >>  This way, your target
objects' class(es) can safely implement a method C<new> that can be called
as either a class method or an object method:

    $obj1 = MyClass->new(...);
    $obj2 = $obj1->new(...);

See L<perltoot|perltoot> for information on how to implement this style of
constructor.

When C<new> is called as a class method on your own class,
L<Class::Proxy::Lite|Class::Proxy::Lite> isn't involved (unless you set up
your objects' classes to inherit from it, which is a very bad idea).  When
C<new> is called as an object method, the call is passed on to the target
object just as would happen for any other object method call.

=head2 AUTOLOAD

This is where the action takes place.  It simply calls the resolver to get a
reference to the target object, then passes the method call on to it.

The methods C<DESTROY> and C<import> are special-cased; the former is
ignored, while the latter is ignored if and only if it was invoked on an
object (i.e., not called implicitly as the result of a C<use> statement).

Except for C<import> and C<new>, all methods invoked on this class or a
subclass of it (as opposed to methods invoked on an actual object) result in
an exception being thrown.  An exception is also thrown if the resolver
returns C<undef> or a non-reference -- in other words, if it can't resolve
the token into an actual object.

B<WARNING:> Never call AUTOLOAD directly!

=head1 SUBCLASSING

Depending on your needs, it may not be necessary to subclass
L<Class::Proxy::Lite|Class::Proxy::Lite>.  If you do, however, your subclass
will probably look something like this:

    package MyObject::Proxy;
    @ISA = qw(Class::Proxy::Lite);
    sub new {
        my ($cls, $target) = @_;
        my $token = obj2token($target);
        my $resolver = \&token2obj;
        return $self->SUPER::new($token, $resolver);
    }
    sub obj2token { ... }
    sub token2obj { ... }

See F<t/proxy.t> for a slightly different example.

C<Class::Proxy::Lite> was designed to avoid method name clashes; the only
method defined for it is C<AUTOLOAD>.  If your subclass must inherit from
another class that uses AUTOLOAD, this is probably not the right solution
for you.

=head1 BACKGROUND

L<Class::Proxy|Class::Proxy> didn't fit my needs.  I was implementing an
object model in which objects are loaded dynamically and references to
loaded objects are stored in a master table.  I wanted a solution that
served both as a proxy and a reference (generally speaking) to an object. 
This module is what resulted.

=head1 LIMITATIONS

Apparently, it's not possible to catch calls to the C<can()> and C<isa()>
methods on B<instances> of C<Class::Proxy::Lite>.  This makes it impossible
to implement a true proxy without defining C<UNIVERSAL::isa> and
C<UNIVERSAL::can>, which I'm reluctant to do.

The following note in L<perlobj|perlobj> (under `Default UNIVERSAL methods')
appears to explain the problem:

   NOTE: `can' directly uses Perl's internal code for method
   lookup, and `isa' uses a very similar method and cache-ing
   strategy. This may cause strange effects if the Perl code
   dynamically changes @ISA in any package.

I might be wrong about all this, though; any insights on this problem are
welcome.

=head1 SEE ALSO

L<Class::Proxy|Class::Proxy> is a better alternative for more sophisticated
proxy capabilities.

=head1 VERSION

1.01

=head1 AUTHOR

Paul Hoffman <nkuitse AT cpan DOT org>.

=head1 CREDITS

Thanks to Kurt Starsinic (KSTAR) for L<Class::Delegate|Class::Delegate>,
which got me thinking, and to Murat Uenalan (MUENALAN) for
L<Class::Proxy|Class::Proxy>, which set a good example.

=head1 COPYRIGHT

Copyright 2003 Paul M. Hoffman. All rights reserved.

This program is free software; you can redistribute it and modify it under
the same terms as Perl itself.

=cut

