use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Try

=cut

=abstract

Try Class for Perl 5

=cut

=includes

method: call
method: callback
method: catch
method: default
method: execute
method: finally
method: maybe
method: no_catch
method: no_default
method: no_finally
method: no_try
method: result

=cut

=synopsis

  use strict;
  use warnings;
  use routines;

  use Data::Object::Try;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {
    # try something

    return time;
  });

  $try->catch('Example::Exception', fun ($caught) {
    # caught an exception

    return;
  });

  $try->default(fun ($caught) {
    # catch the uncaught

    return;
  });

  $try->finally(fun (@args) {
    # always run after try/catch

    return;
  });

  my @args;

  my $result = $try->result(@args);

=cut

=attributes

invocant: ro, opt, Object
arguments: ro, opt, ArrayRef
on_try: rw, opt, CodeRef
on_catch: rw, opt, ArrayRef[CodeRef]
on_default: rw, opt, CodeRef
on_finally: rw, opt, CodeRef

=cut

=description

This package provides an object-oriented interface for performing complex try/catch operations.

=cut

=method call

The call method takes a method name or coderef, registers it as the tryable
routine, and returns the object. When invoked, the callback will received an
C<invocant> if one was provided to the constructor, the default C<arguments> if
any were provided to the constructor, and whatever arguments were provided by
the invocant.

=signature call

call(Str | CodeRef $arg) : Object

=example-1 call

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    return [@args];
  });

=cut

=method callback

The callback method takes a method name or coderef, and returns a coderef for
registration. If a coderef is provided this method is mostly a passthrough.

=signature callback

callback(Str | CodeRef $arg) : CodeRef

=example-1 callback

  my $try = Data::Object::Try->new;

  $try->callback(fun (@args) {

    return [@args];
  });

=example-2 callback

  package Example;

  use Moo;

  fun test(@args) {

    return [@args];
  }

  package main;

  my $try = Data::Object::Try->new(
    invocant => Example->new
  );

  $try->callback('test');

=cut

=method catch

The catch method takes a package or ref name, and when triggered checks whether
the captured exception is of the type specified and if so executes the given
callback.

=signature catch

catch(Str $isa, Str | CodeRef $arg) : Any

=example-1 catch

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    die $try;
  });

  $try->catch('Data::Object::Try', fun (@args) {

    return [@args];
  });

=cut

=method default

The default method takes a method name or coderef and is triggered if no
C<catch> conditions match the exception thrown.

=signature default

default(Str | CodeRef $arg) : Object

=example-1 default

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    die $try;
  });

  $try->default(fun (@args) {

    return [@args];
  });

=cut

=method execute

The execute method takes a coderef and executes it with any given arguments.
When invoked, the callback will received an C<invocant> if one was provided to
the constructor, the default C<arguments> if any were provided to the
constructor, and whatever arguments were passed directly to this method.

=signature execute

execute(CodeRef $arg, Any @args) : Any

=example-1 execute

  my $try = Data::Object::Try->new(
    invocant => Example->new,
    arguments => [1,2,3]
  );

  $try->execute(fun (@args) {

    return [@args];
  });

=cut

=method finally

The finally method takes a package or ref name and always executes the callback
after a try/catch operation. The return value is ignored. When invoked, the
callback will received an C<invocant> if one was provided to the constructor,
the default C<arguments> if any were provided to the constructor, and whatever
arguments were provided by the invocant.

=signature finally

finally(Str | CodeRef $arg) : Object

=example-1 finally

  my $try = Data::Object::Try->new(
    invocant => Example->new,
    arguments => [1,2,3]
  );

  $try->call(fun (@args) {

    return $try;
  });

  $try->finally(fun (@args) {

    $try->{'$finally'} = [@args];
  });

=cut

=method maybe

The maybe method registers a default C<catch> condition that returns falsy,
i.e. an empty string, if an exception is encountered.

=signature maybe

maybe() : Object

=example-1 maybe

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    die $try;
  });

  $try->maybe;

=cut

=method no_catch

The no_catch method removes any configured catch conditions and returns the
object.

=signature no_catch

no_catch() : Object

=example-1 no_catch

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    die $try;
  });

  $try->catch('Data::Object::Try', fun (@args) {

    return [@args];
  });

  $try->no_catch;

=cut

=method no_default

The no_default method removes any configured default condition and returns the
object.

=signature no_default

no_default() : Object

=example-1 no_default

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    die $try;
  });

  $try->default(fun (@args) {

    return [@args];
  });

  $try->no_default;

=cut

=method no_finally

The no_finally method removes any configured finally condition and returns the
object.

=signature no_finally

no_finally() : Object

=example-1 no_finally

  my $try = Data::Object::Try->new(
    invocant => Example->new,
    arguments => [1,2,3]
  );

  $try->call(fun (@args) {

    return $try;
  });

  $try->finally(fun (@args) {

    $try->{'$finally'} = [@args];
  });

  $try->no_finally;

=cut

=method no_try

The no_try method removes any configured C<try> operation and returns the
object.

=signature no_try

no_try() : Object

=example-1 no_try

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    return [@args];
  });

  $try->no_try;

=cut

=method result

The result method executes the try/catch/default/finally logic and returns
either 1) the return value from the successfully tried operation 2) the return
value from the successfully matched catch condition if an exception was thrown
3) the return value from the default catch condition if an exception was thrown
and no catch condition matched. When invoked, the C<try> and C<finally>
callbacks will received an C<invocant> if one was provided to the constructor,
the default C<arguments> if any were provided to the constructor, and whatever
arguments were passed directly to this method.

=signature result

result(Any @args) : Any

=example-1 result

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    return [@args];
  });

  $try->result;

=example-2 result

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    return [@args];
  });

  $try->result(1..5);

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'call', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Try');
  is_deeply $result->result(1..4), [1..4];

  $result
});

$subs->example(-1, 'callback', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is ref $result, 'CODE';
  is_deeply $result->(1..4), [1..4];

  $result
});

$subs->example(-2, 'callback', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is ref $result, 'CODE';
  is_deeply $result->(1..4), [1..4];

  $result
});

$subs->example(-1, 'catch', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Try');
  is_deeply $result->result, [$result];

  $result
});

$subs->example(-1, 'default', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Try');
  is_deeply $result->result, [$result];

  $result
});

$subs->example(-1, 'execute', 'method', fun($tryable) {
  ok my $result = $tryable->result(4,5);
  ok $result->[0]->isa('Example');
  is $result->[1], 1;
  is $result->[2], 2;
  is $result->[3], 3;

  $result
});

$subs->example(-1, 'finally', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Try');
  my $returned = $result->result(4,5);

  ok $returned->isa('Data::Object::Try');
  my $finally = $returned->{'$finally'};

  ok $finally->[0]->isa('Example');
  is $finally->[1], 1;
  is $finally->[2], 2;
  is $finally->[3], 3;

  $result
});

$subs->example(-1, 'maybe', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Try');
  is $result->result, '';

  $result
});

$subs->example(-1, 'no_catch', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Try');

  my $error = do { eval { $result->result }; $@ };
  ok $error->isa('Data::Object::Try');

  $result
});

$subs->example(-1, 'no_default', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Try');

  my $error = do { eval { $result->result }; $@ };
  ok $error->isa('Data::Object::Try');

  $result
});

$subs->example(-1, 'no_finally', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Try');

  my $returned = $result->result;
  ok $returned->isa('Data::Object::Try');
  ok not exists $returned->{'$finally'};

  $result
});

$subs->example(-1, 'no_try', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Try');
  ok not defined $result->on_try;

  $result
});

$subs->example(-1, 'result', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

$subs->example(-2, 'result', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [1..5];

  $result
});

ok 1 and done_testing;
