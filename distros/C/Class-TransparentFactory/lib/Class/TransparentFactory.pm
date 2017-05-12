package Class::TransparentFactory;

use warnings;
use strict;

=head1 NAME

Class::TransparentFactory - Transparently choose a provider class with an automatic facade

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  package LooksLikeOneClass;
  use Class::TransparentFactory qw(new foo bar);
  sub impl {
      $class = today_is_a_weekday() ? "WeekdayProvider" : "WeekendProvider";
      require $class;
      return  $class;
  }

  package UserCode;
  use LooksLikeOneClass;
  LooksLikeOneClass->foo();  # WeekdayProvider::foo or WeekendProvider::foo
                             # depending on whether today_is_a_weekday().


=head1 DESCRIPTION

This module is intended for developers who find they need to refactor
code away from one provider of functionality to a factory + set of
API-compatible providers. It's not that factories are very difficult to
write or maintain, but code that uses them tends to be somewhat cluttered.

With Class-TransparentFactory, your user code remains exactly as it was
before you split off to several providers; the original module class
turns into a facade in which class methods are automatically turned into
proxies for the appropriate provider class.

To use Class-TransparentFactory in user code, no change is needed. (That
is the point!)  To use it in your libraries, you need to follow these
steps:

=over 4

=item Move all your actual implementation into another module.

Its name is not important to Class::TransparentFactory, but let's call
it C<ProviderOne> here. The old namespace by which the implementation
was known we will call C<Facade>.

=item Declare C<Facade> as a transparent factory.

See I<import> below for details. For a typical OOPish module with no
special class methods, this will suffice:

  package Facade;
  use Class::TransparentFactory qw(new);

=item Implement your factory.

See I<impl> for details. Here is where you put the business logic
that determines which provider is suitable and should be used for this
particular call.

=back

=head1 FUNCTIONS

=head2 import

The import directive is your declarative way of specifying which class
methods belong to the transparently facaded API. Supply a simple list of
names. Instance methods need not be specified here, since subsequent
method dispatches on objects created by provider classes will presumably
go to the correct place directly.

=cut

sub import {
    my($c, @funcs) = @_;
    my $caller = caller;
    for my $name (@funcs) {
        my $code = sub {
            my($class, @args) = @_;

            # the following is necessary since otherwise peeking at
            # (caller(1))[3] in impl won't work.
            # See http://perlmonks.org/?node_id=304883 .
            local *__ANON__ = $name;

            return $class->impl(@args)->$name(@args);
        };
        no strict;
        *{"$caller\::$name"} = $code;
    }
}

=head2 impl

This is not a method of Class::TransparentFactory, but rather one that
you must implement in your facade class yourself.

It is here that you do the actual factorty work. You have the actual
class method call arguments for your inspection if you need them. C<impl>
must do the following:

=over 4

=item Determine the appropriate provider for this call

You may base this decision on the method arguments, the call stack,
phase of the moon, or whatever you wish. Only you know why you needed
a variety of providers, so you should know how to pick among them.

=item Make sure it is loaded

You can use a C<require> or any other means. (In a static setup, it is
perfectly reasonable to say C<use ProviderOne; use ProviderTwo> etc. at
the top of the facade class and not worry about this step in C<impl>.)

=item Return it

Simply arrange for C<impl> to return a string with the class
name. Class::TransparentFactory will handle the dispatching.

=back

=head1 EXPERIMENTATIONAL STATUS

This module is highly experimental! I am looking for improvements, from
ideas for a better name via clever features. Please contact me at the
address below if you have a suggestion.

=head1 AUTHOR

Gaal Yahas, C<< <gaal at forum2.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-transparentfactory at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-TransparentFactory>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::TransparentFactory

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-TransparentFactory>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-TransparentFactory>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-TransparentFactory>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-TransparentFactory>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Zsban Ambrus for pointing me at the *__ANON__ hack for naming
closures, and to Yitzchak Scott-Thoennes for posting about it here:
L<http://perlmonks.org/?node_id=304883>.

Thanks also to Yuval Kogman, C<< <nothingmuch@woobling.org> >> for some
discussion. I stole none of his good ideas yet, so all suckage here is
my fault.

=head1 COPYRIGHT (The "MIT" License)

Copyright 2006 Gaal Yahas.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

1; # End of Class::TransparentFactory
