use Test2::V0 -no_srand => 1;
use Clang::CastXML::Wrapper;

subtest basic => sub {

  my $wrapper = Clang::CastXML::Wrapper->new;
  isa_ok $wrapper, 'Clang::CastXML::Wrapper';

  my $exe = $wrapper->exe;
  note "exe = $exe";
  ok -x $exe, "exe is executable";

  my $version = $wrapper->version;
  note "version = $version";
  is $version, D();

};

subtest raw => sub {

  my $wrapper = Clang::CastXML::Wrapper->new;

  is(
    $wrapper->raw('--version'),
    object {
      call [ isa => 'Clang::CastXML::Wrapper::Result' ] => T();
      call wrapper => object {
        call [ isa => 'Clang::CastXML::Wrapper' ] => T();
      };
      call args => [ '--version' ];
      call is_success => T();
      call out => match qr/castxml version/;
      call err => D();
      call ret => 0;
      call sig => 0;
    },
    'success',
  );

  is(
    $wrapper->raw('--bogus'),
    object {
      call [ isa => 'Clang::CastXML::Wrapper::Result' ] => T();
      call wrapper => object {
        call [ isa => 'Clang::CastXML::Wrapper' ] => T();
      };
      call args => [ '--bogus' ];
      call is_success => F();
      call out => D();
      call err => D();
      call ret => T();
      call sig => 0;
    },
    'fail',
  );

};

done_testing;
