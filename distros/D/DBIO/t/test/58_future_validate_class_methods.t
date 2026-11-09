use strict;
use warnings;
use Test::More;

use DBIO::Future ();
use DBIO::Future::Immediate ();
use DBIO::Test::Future ();

# DBIO::Future->validate checks the class methods core calls on a storage's
# future_class, not only the instance methods a caller of *_async uses
# (karr k284). Core builds Futures of that class itself -- done, fail and
# needs_all (every async path, txn_do_async's wait for its statements) -- so a
# class with the five instance methods and none of those would pass a validate
# that then fails at the first transaction. `new` is not asked for: a Future
# that is never pending, DBIO::Future::Immediate, has none.

my @instance = qw(then catch get is_ready is_failed);
my @class    = qw(done fail needs_all);

sub _package_with {
  my ($name, @methods) = @_;
  no strict 'refs';
  *{"${name}::$_"} = sub { 1 } for @methods;
  return $name;
}

for my $missing (@class) {
  my $pkg = _package_with(
    "Fake::Future::Without::$missing",
    @instance, grep { $_ ne $missing } @class,
  );

  for my $form (
    [ class    => $pkg ],
    [ instance => bless({}, $pkg) ],
  ) {
    my ($kind, $subject) = @$form;
    eval { DBIO::Future->validate($subject); 1 };
    like $@, qr/does not implement \Q$missing\E\b/,
      "$kind without $missing is rejected, naming the method";
  }
}

{
  my $pkg = _package_with('Fake::Future::InstanceOnly', @instance);
  eval { DBIO::Future->validate($pkg); 1 };
  like $@, qr/does not implement (?:done|fail|needs_all)/,
    'a class with only the five instance methods is rejected';
}

for my $missing (@instance) {
  my $pkg = _package_with(
    "Fake::Future::WithoutInstance::$missing",
    (grep { $_ ne $missing } @instance), @class,
  );
  eval { DBIO::Future->validate($pkg); 1 };
  like $@, qr/does not implement \Q$missing\E\b/,
    "class without $missing is still rejected";
}

ok eval { DBIO::Future->validate('DBIO::Future::Immediate') },
  'DBIO::Future::Immediate passes as a class';
ok eval { DBIO::Future->validate(DBIO::Future::Immediate->done(1)) },
  'DBIO::Future::Immediate passes as an instance';
ok eval { DBIO::Future->validate('DBIO::Test::Future') },
  'DBIO::Test::Future passes as a class';
ok eval { DBIO::Future->validate(DBIO::Test::Future->done(1)) },
  'DBIO::Test::Future passes as an instance';

{
  my $pkg = _package_with('Fake::Future::NoNew', @instance, @class);
  ok !$pkg->can('new'), 'the mock has no new';
  ok eval { DBIO::Future->validate($pkg) },
    'a Future class without new passes: new is not required';
}

done_testing;
