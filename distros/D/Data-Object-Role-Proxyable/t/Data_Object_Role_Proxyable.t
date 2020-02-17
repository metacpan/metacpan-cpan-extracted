use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Role::Proxyable

=cut

=abstract

Proxyable Role for Perl 5

=cut

=synopsis

  package Example;

  use Moo;

  with 'Data::Object::Role::Proxyable';

  sub build_proxy {
    my ($self, $package, $method, @args) = @_;

    if ($method eq 'true') {
      return sub {
        return 1;
      }
    }

    if ($method eq 'false') {
      return sub {
        return 0;
      }
    }

    return undef;
  }

  package main;

  my $example = Example->new;

=cut

=description

This package provides a wrapper around the C<AUTOLOAD> routine which processes
calls to routines which don't exist. Adding a C<build_proxy> method to the
consuming class acts as a hook into routine dispatching, which processes calls
to routines which don't exist. The C<build_proxy> routine is called as a method
and receives C<$self>, C<$package>, C<$method>, and any arguments passed to the
method as a list of arguments, e.g. C<@args>. The C<build_proxy> method must
return a routine (i.e. a callback) or the undefined value which results in a
"method missing" error.

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Data::Object::Role::Proxyable');
  is $result->true, 1;
  is $result->false, 0;

  my $error = do { eval { $result->not_true }; $@ };
  ok "$error" =~ /Can't.*locate.*"not_true".*"Example"/;

  $result
});

{
  package BadExample;

  use Moo;

  with 'Data::Object::Role::Proxyable';

  1;
}

subtest 'testing bad example', fun() {
  my $example = BadExample->new;
  my $error = do { eval { $example->true }; $@ };

  ok "$error" =~ /Can't.*locate.*"build_proxy".*"BadExample"/;
};

ok 1 and done_testing;
