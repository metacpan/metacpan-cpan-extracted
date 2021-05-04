use Test2::V0 -no_srand => 1;
use Clang::CastXML;
use Path::Tiny qw( path );
use Test::XML;
use 5.022;
use experimental qw( postderef );

subtest 'basic' => sub {

  my $xml;

  is(
    $xml = Clang::CastXML->new->introspect('int add1(int,int); extern "C" int add2(int,int);'),
    object {
      call [ isa => 'Clang::CastXML::Container' ] => T();
      call result => object {
        call [ isa => 'Clang::CastXML::Wrapper::Result' ] => T();
      };
      call source => object {
        call [ isa => 'Path::Tiny' ] => T();
        call basename => match qr/\.C$/;
      };
      call dest => object {
        call [ isa => 'Path::Tiny' ] => T();
        call basename => match qr/\.xml$/;
      };
    },
  );

  is_well_formed_xml($xml->to_xml);

  my $perl = $xml->to_href;

  my %func = map { $_->{name} => $_ } grep { $_->{_class} eq 'Function' } $perl->{inner}->@*;

  is(
    \%func,
    hash {
      field add1 => hash {
        field mangled => T();
        etc;
      };
      field add2 => hash {
        field mangled => DNE();
        etc;
      };
      etc;
    },
    'work around name mangle bug',
  );

};

subtest 'top-level variables' => sub {

  is(
    { map { $_->{name} => $_ } grep { $_->{_class} eq 'Variable' } Clang::CastXML->new->introspect(q{
      int foo;
      extern "C" int bar;
      namespace ns {
        int baz;
        extern "C" int frooble;
      }
    })->to_href->{inner}->@*},
    hash {
      field foo => hash {
        field mangled => DNE();
        etc;
      };
      field bar => hash {
        field mangled => DNE();
        etc;
      };
      field baz => hash {
        field mangled => T();
        etc;
      };
      field frooble => hash {
        field mangled => DNE();
        etc;
      };
      etc;
    }
  );

};

subtest 'bad xml' => sub {

  require Clang::CastXML::Container;
  require Clang::CastXML::Wrapper::Result;

  my $xml;

  is(
    dies {
      $xml = Clang::CastXML::Container->new(
        result => Clang::CastXML::Wrapper::Result->new(
          wrapper => Clang::CastXML::Wrapper->new,
          out => '',
          err => "error: some error\n",
          args => [],
          ret => 0,
          sig => 0,
        ),
        source => do {
          Path::Tiny->tempfile;
        },
        dest => do {
          my $dest = Path::Tiny->tempfile;
          $dest->spew("<foo></bar>");
          $dest;
        },
      );
    },
    F(),
  );

  my $ex;

  is(
    $ex = dies {
      $xml->to_href;
    },
    object {
      call [ isa => 'Clang::CastXML::Exception' ] => T();
      call [ isa => 'Clang::CastXML::Exception::ParseException' ] => T();
    },
  );

  note $ex;

};

done_testing;
