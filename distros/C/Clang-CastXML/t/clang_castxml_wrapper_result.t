use Test2::V0 -no_srand => 1;
use Clang::CastXML::Wrapper::Result;

is(
  Clang::CastXML::Wrapper::Result->new(
    wrapper => (bless {}, 'Clang::CastXML::Wrapper'),
    args    => ['--foo', '--bar'],
    out     => '',
    err     => '',
    ret     => 0,
    sig     => 0,
  ),
  object {
    call [ isa => 'Clang::CastXML::Wrapper::Result' ] => T();
    call is_success => T();
  },
);

is(
  Clang::CastXML::Wrapper::Result->new(
    wrapper => (bless {}, 'Clang::CastXML::Wrapper'),
    args    => ['--foo', '--bar'],
    out     => '',
    err     => '',
    ret     => 10,
    sig     => 0,
  ),
  object {
    call [ isa => 'Clang::CastXML::Wrapper::Result' ] => T();
    call is_success => F();
  },
);

is(
  Clang::CastXML::Wrapper::Result->new(
    wrapper => (bless {}, 'Clang::CastXML::Wrapper'),
    args    => ['--foo', '--bar'],
    out     => '',
    err     => '',
    ret     => 0,
    sig     => 8,
  ),
  object {
    call [ isa => 'Clang::CastXML::Wrapper::Result' ] => T();
    call is_success => F();
  },
);

done_testing;
