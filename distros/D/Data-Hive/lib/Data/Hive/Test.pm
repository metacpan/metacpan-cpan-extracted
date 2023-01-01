use strict;
use warnings;
package Data::Hive::Test 1.015;
# ABSTRACT: a bundle of tests for Data::Hive stores

use Data::Hive;
use Data::Hive::Store::Hash;

use Test::More 0.96; # subtest without tests

#pod =head1 SYNOPSIS
#pod
#pod   use Test::More;
#pod
#pod   use Data::Hive::Test;
#pod   use Data::Hive::Store::MyNewStore;
#pod
#pod   Data::Hive::Test->test_new_hive({ store_class => 'MyNewStore' });
#pod
#pod   # rest of your tests for your store
#pod
#pod   done_testing;
#pod
#pod =head1 DESCRIPTION
#pod
#pod Data::Hive::Test is a library of tests that should be passable for any
#pod conformant L<Data::Hive::Store> implementation.  It provides a method for
#pod running a suite of tests -- which may expand or change -- that check the
#pod behavior of a hive store by building a hive around it and testing its behavior.
#pod
#pod =method test_new_hive
#pod
#pod   Data::Hive::Test->test_new_hive( $desc, \%args_to_NEW );
#pod
#pod This method expects an (optional) description followed by a hashref of
#pod arguments to be passed to Data::Hive's C<L<NEW|Data::Hive/NEW>> method.  A new
#pod hive will be constructed with those arguments and a single subtest will be run,
#pod including subtests that should pass against any conformant Data::Hive::Store
#pod implementation.
#pod
#pod If the tests pass, the method will return the hive.  If they fail, the method
#pod will return false.
#pod
#pod =method test_existing_hive
#pod
#pod   Data::Hive::Test->test_existing_hive( $desc, $hive );
#pod
#pod This method behaves just like C<test_new_hive>, but expects a hive rather than
#pod arguments to use to build one.
#pod
#pod =cut

sub test_new_hive {
  my ($self, $desc, $arg) = @_;

  if (@_ == 2) {
    $arg  = $desc;
    $desc = "hive tests from Data::Hive::Test";
  }

  my $hive = Data::Hive->NEW($arg);

  test_existing_hive($desc, $hive);
}

sub _set_ok {
  my ($hive, $value) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is($hive->SET($value), $value, "we return new value from SET");
}

sub test_existing_hive {
  my ($self, $desc, $hive) = @_;

  if (@_ == 2) {
    $hive = $desc;
    $desc = "hive tests from Data::Hive::Test";
  }

  $desc = "Data::Hive::Test: $desc";

  my $passed = subtest $desc => sub {
    isa_ok($hive, 'Data::Hive');

    is_deeply(
      [ $hive->KEYS ],
      [ ],
      "we're starting with an empty hive",
    );

    subtest 'value of one' => sub {
      ok(! $hive->one->EXISTS, "before being set, ->one doesn't EXISTS");

      _set_ok($hive->one, 1);

      ok($hive->one->EXISTS, "after being set, ->one EXISTS");

      is($hive->one->GET,      1, "->one->GET is 1");
      is($hive->one->GET(10),  1, "->one->GET(10) is 1");

      is($hive->one->GET(sub { 2 }),  1, "->one->GET(sub{2}) is 1");
    };

    subtest 'value of zero' => sub {
      ok(! $hive->zero->EXISTS, "before being set, ->zero doesn't EXISTS");

      _set_ok($hive->zero, 0);

      ok($hive->zero->EXISTS, "after being set, ->zero EXISTS");

      is($hive->zero->GET,      0, "->zero->GET is 0");
      is($hive->zero->GET(10),  0, "->zero->GET(10) is 0");
    };

    subtest 'value of empty string' => sub {
      ok(! $hive->empty->EXISTS, "before being set, ->empty doesn't EXISTS");

      _set_ok($hive->empty, '');

      ok($hive->empty->EXISTS, "after being set, ->empty EXISTS");

      is($hive->empty->GET,     '', "->empty->GET is ''");
      is($hive->empty->GET(10), '', "->empty->GET(10) is ''");
    };

    subtest 'undef, existing value' => sub {
      ok(! $hive->undef->EXISTS, "before being set, ->undef doesn't EXISTS");

      _set_ok($hive->undef, undef);

      ok($hive->undef->EXISTS, "after being set, ->undef EXISTS");

      is($hive->undef->GET,      undef, "->undef->GET is undef");
      is($hive->undef->GET(10),     10, "->undef->GET(10) is 10");
      is($hive->undef->GET(sub{2}),  2, "->undef->GET(sub{2}) is 2");
    };

    subtest 'non-existing value' => sub {
      ok(! $hive->missing->EXISTS, "before being set, ->missing doesn't EXISTS");

      is($hive->missing->GET,    undef, "->missing is undef");

      ok(! $hive->missing->EXISTS, "mere GET-ing won't cause ->missing to EXIST");

      is($hive->missing->GET(10),  10, "->missing->GET(10) is 10");
      is($hive->missing->GET(sub{2}), 2, "->missing->GET(sub{2}) is 2");
    };

    subtest 'nested value' => sub {
      ok(
        ! $hive->two->EXISTS,
        "before setting ->two->deep, ->two doesn't EXISTS"
      );

      ok(
        ! $hive->two->deep->EXISTS,
        "before setting ->two->deep, ->two->deep doesn't EXISTS"
      );

      is(
        $hive->two->deep->GET,
        undef,
        "before being set, ->two->deep is undef"
      );

      _set_ok($hive->two->deep, '2D');

      ok(
        ! $hive->two->EXISTS,
        "after setting ->two->deep, ->two still doesn't EXISTS"
      );

      ok(
        $hive->two->deep->EXISTS,
        "after setting ->two->deep, ->two->deep EXISTS"
      );

      is(
        $hive->two->deep->GET,
        '2D',
        "after being set, ->two->deep->GET returns '2D'",
      );

      is(
        $hive->two->deep->GET(10),
        '2D',
        "after being set, ->two->deep->GET(10) returns '2D'",
      );
    };

    is_deeply(
      [ sort $hive->KEYS  ],
      [ qw(empty one two undef zero) ],
      "in the end, we have the right top-level keys",
    );

    is(
      $hive->two->deep->fake->whatever->ROOT->two->deep->GET,
      '2D',
      "we can get back to the root easily with ROOT",
    );

    subtest 'COPY_ONTO' => sub {
      _set_ok( $hive->copy->x->y->z, 1);
      _set_ok( $hive->copy->a->b, 2);
      _set_ok( $hive->copy->a->b->c->d, 3);

      my $target = Data::Hive->NEW({ store => Data::Hive::Store::Hash->new });

      $hive->copy->COPY_ONTO($target->clone);

      is_deeply(
        $target->STORE->hash_store,
        {
          'clone.x.y.z'   => '1',
          'clone.a.b'     => '2',
          'clone.a.b.c.d' => '3',
        },
        "we can copy structures",
      );
    };

    subtest 'DELETE' => sub {
      _set_ok($hive->to_delete->top, 10);
      _set_ok($hive->to_delete->top->middle, 20);
      _set_ok($hive->to_delete->top->middle->bottom, 20);

      $hive->to_delete->top->middle->DELETE;

      ok(
        $hive->to_delete->top->EXISTS,
        "delete middle, top is still there",
      );

      ok(
        ! $hive->to_delete->top->middle->EXISTS,
        "delete middle, so it is gone",
      );

      ok(
        $hive->to_delete->top->middle->bottom->EXISTS,
        "delete middle, bottom is still there",
      );
    };

    subtest 'DELETE_ALL' => sub {
      _set_ok($hive->doomed->alpha->branch->value, 1);
      _set_ok($hive->doomed->bravo->branch->value, 1);

      is_deeply(
        [ sort $hive->doomed->KEYS ],
        [ qw(alpha bravo) ],
        "created hive with two subhives",
      );

      $hive->doomed->alpha->DELETE_ALL;

      is_deeply(
        [ sort $hive->doomed->KEYS ],
        [ qw(bravo) ],
        "doing a DELETE_ALL gets rid of all deeper values",
      );

      is(
        $hive->doomed->alpha->branch->value->GET,
        undef,
        "the deeper value is now undef",
      );

      ok(
        ! $hive->doomed->alpha->branch->value->EXISTS,
        "the deeper value does not exist",
      );

      is(
        $hive->doomed->bravo->branch->value->GET,
        1,
        "the deep value on another branch is not gone",
      );
    };
  };

  return $passed ? $hive : ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Hive::Test - a bundle of tests for Data::Hive stores

=head1 VERSION

version 1.015

=head1 SYNOPSIS

  use Test::More;

  use Data::Hive::Test;
  use Data::Hive::Store::MyNewStore;

  Data::Hive::Test->test_new_hive({ store_class => 'MyNewStore' });

  # rest of your tests for your store

  done_testing;

=head1 DESCRIPTION

Data::Hive::Test is a library of tests that should be passable for any
conformant L<Data::Hive::Store> implementation.  It provides a method for
running a suite of tests -- which may expand or change -- that check the
behavior of a hive store by building a hive around it and testing its behavior.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 test_new_hive

  Data::Hive::Test->test_new_hive( $desc, \%args_to_NEW );

This method expects an (optional) description followed by a hashref of
arguments to be passed to Data::Hive's C<L<NEW|Data::Hive/NEW>> method.  A new
hive will be constructed with those arguments and a single subtest will be run,
including subtests that should pass against any conformant Data::Hive::Store
implementation.

If the tests pass, the method will return the hive.  If they fail, the method
will return false.

=head2 test_existing_hive

  Data::Hive::Test->test_existing_hive( $desc, $hive );

This method behaves just like C<test_new_hive>, but expects a hive rather than
arguments to use to build one.

=head1 AUTHORS

=over 4

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Ricardo Signes <cpan@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
