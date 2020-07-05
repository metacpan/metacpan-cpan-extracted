use Test2::V0 -no_srand => 1;
use experimental qw( postderef );
use Const::Introspect::C::Constant;

subtest 'basic' => sub {

  is(
    Const::Introspect::C::Constant->new(
      c     => (bless {}, 'Bogus'),
      name  => 'Foo',
      type  => 'int',
      value => 1,
    ),
    object {
      call [ isa => 'Const::Introspect::C::Constant' ] => T();
      call c => object {
        call [ isa => 'Bogus' ] => T();
      };
      call raw_value => U();
      call value => 1;
      call type  => 'int';
    },
  );

};

subtest 'fallback' => sub {

  require Const::Introspect::C;

  my $c = Const::Introspect::C->new(
    headers => ['bar.h'],
    extra_cflags => ['-Icorpus/include'],
  );

  is(
    Const::Introspect::C::Constant->new(
      c => $c,
      name => 'MY_INT',
    ),
    object {
      call [ isa => 'Const::Introspect::C::Constant' ] => T();
      call type => 'int';
      call value => 4;
    },
  );

  is(
    Const::Introspect::C::Constant->new(
      c => $c,
      name => 'MY_STRING',
    ),
    object {
      call [ isa => 'Const::Introspect::C::Constant' ] => T();
      call type => 'string';
      call value => 'foo';
    },
  );

  is(
    Const::Introspect::C::Constant->new(
      c => $c,
      name => 'MY_OTHER',
    ),
    object {
      call [ isa => 'Const::Introspect::C::Constant' ] => T();
      call type => 'other';
      call value => U();
    },
  );

  note $_ for $c->diag->@*;

};

done_testing;
