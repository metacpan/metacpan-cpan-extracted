package Class::DispatchToAll;

# ABSTRACT: DEPRECATED - dispatch a method call to all inherited methods
our $VERSION = '0.13'; # VERSION

use 5.006;
use strict;
use warnings;

warn __PACKAGE__ .' is DEPRECATED, please do not use this module anymore';

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = (qw(dispatch_to_all));

#-----------------------------------------------------------------
# dispatch_to_all
#-----------------------------------------------------------------
sub dispatch_to_all {
    my $self=shift;
    my $method=shift;
    my $attributes=shift;
    my @result_set;

    my $data={
        self=>$self,
        class=>ref($self)||$self,
        method=>$method,
        attribs=>$attributes,
        result_set=>\@result_set,
    };

    _dispatcher($data,@_);
    return wantarray?@result_set:\@result_set;
}


#-----------------------------------------------------------------
# dispatcher
#-----------------------------------------------------------------
sub _dispatcher {
    my $data=shift;

    # dispatch to own package
    no strict "refs";
    my $call=$data->{'class'}."::".$data->{'method'};

    if ($data->{'attrib'}{'no_collect'}) {
        $call->($data->{'self'},@_) if *$call{CODE};
    } else {
        push(@{$data->{'result_set'}},$call->($data->{'self'},@_)) if *$call{CODE};
    }

    my @isa=eval "@".$data->{'class'}."::ISA";
    foreach my $parent (@isa) {
        $data->{'class'}=$parent;
        _dispatcher($data,@_);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::DispatchToAll - DEPRECATED - dispatch a method call to all inherited methods

=head1 VERSION

version 0.13

=head1 SYNOPSIS

  DEPRECATED - Do not use this module anymore!

  package My::Class;
  our @ISA=qw(SomeClass SomeOtherClass More::Classes);
  use Class::DispatchToAll qw(dispatch_to_all);

  my $self=bless {},My::Class  # not a proper constructor, I know..

  # this calls 'some_method' in all Classes My::Class inherits from
  # and all classes those classes inherit from, and all ... you get
  # the point.
  $self->dispatch_to_all('some_method');

  # saves all return values from all calls in an array
  my @returns=$self->dispatch_to_all('some_method');

=head1 DESCRIPTION

DEPRECATED - Do not use this module anymore!

But here are the old docs, anyway:

See the Docs of Damian Conways Module Class::Delegation for a good
introduction about Dispatching vs. Inheritance.

Class::DispatchToAll enables you to call B<all> instantances of a
method in your inheritance tree (or labyrinth..).

The standard Perl behaviour is to call only the lefternmost instance
it can fing doing a depth first traversial.

Imagine the following class structure:

              C
             /
   A    B  C::C
    \  / \ /
   A::A   D
       \ /
     My::Class

Perl will try to find a method in this mess in this order:

 My::Class -> A::A  ->  A  ->  B  ->  D  -> B  -> C::C -> C

(Note that it will look twice in C<B> because C<B> is a parent of both
C<A::A> and C<D>))

As soon as Perl finds the method somewhere, it will short-circuit out
of it's search and invoke the method.

And that is exactly the behaviour C<Class::DispatchToAll> changes.

If you use C<dispatch_to_all> (provided by C<Class::DispatchToAll>) to
call your method, Perl will look in all of the aforementioned packages
and run all the methods it can find. It will even collect all the
return values and return them to you as an array, if you want it too.

=head2 dispatch_to_all

Call it either as a function:

  dispatch_to_all($self,
                  $method_to_call,
                  \%attribs,
                  @params_passed_to_method);

or as a method

  $self->dispatch_to_all($method_to_call,
                         \%attribs,
                         @params_passed_to_method);

=over

=item *

C<$self> is the object you want the method to be invoked on

=item *

C<$method_to_call> is the name of the method to be called

Eg. instead of C<$self-E<gt>do_something> say
C<$self-E<gt>dispatch_to_all('do_something')>

=item *

C<%attribs> is an optional hash (has to be passed by reference) of
attributes to alter C<Class:DispatchToAll>s behaviour. If you want to
pass arguments to the methods but do not want to set any attributes,
you B<have to pass undef> (c.f. the way
C<DBH-E<gt>do($query,undef,@bind_params)> works, if you know it..)

Currently there is only one attribute implemented:

=over

=item * no_collect

set it to a true value, and the return values of the method calls
won't be collected. This may save some memory and CPU over just
discarding the return value of C<dispatch_to_all>.

=back

=item *

C<@params_passed_to_method> will be passed to the methods as is.

=back

If you didn't set C<no_collect>, C<dispatch_to_all> will return an
array or ARRAYREF (depending on what you were calling for, so watch
your context) where each element is the return value of a
method. (B<NOTA BENE:> If one method returns more than one value, this
might lead to some confusion.. See L<TODO>).

Currently, the first called method (i.e. the one Perl would originally
call) will be the first value of this array, followed by all other
values. If a method doesn't exist in any class, B<no> value will be
returned (maybe C<undef> would be better, don't know now..).

What you do with this values and how to decide which one to use (if
you only need one) is up to you.

One thing I do (and the reason for writing this module) is to
condensate different config values to one, e.g.:

  A::config="test";
  A::A::config="test2";
  My::Class::config="test3";

  # assuming a method get_config not implemented in this example
  print join(",",@{$self->dispatch_to_all('get_config')});
  # prints: test3,test2,test

Or this, merging a hash:

  A::hash={foo=>'foo'};
  C::hash={bar=>'bar'};
  A::A::hash={foo=>'FOO'};
  My::Class::hash={even=>'more'};

  # assuming a method get_hash not implemented in this example
  my @v=$self->dispatch_to_all('get_hash');
  my %hash=();
  foreach (reverse @v) {
      %hash=(%hash,%$_);
  }

  # %hash now looks like: { foo=>'FOO', # from A::A, overriding A
  # bar=>'bar', # from C even=>'more', # from My::Class }

Please note the C<reverse>. This enables the overriding of values
"further away" from the calling class by values that are "nearer"

See the test script for more examples.

=head1 TODO

=over

=item * handling of methods that return more than one value

=item * different methods of traversal (right to left, width before
depth)

=item * preventing multiple access to the same method (caused by a
"diamond" class hierarchy)

=back

=head1 SEE ALSO

Class::Delegation, NEXT

This thread on perlmonks:
http://www.perlmonks.org/index.pl?node_id=180852

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 - 2006 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
