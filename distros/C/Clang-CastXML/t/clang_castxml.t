use Test2::V0 -no_srand => 1;
use Clang::CastXML;
use Path::Tiny qw( path );
use Test::XML;

subtest basic => sub {

  my $castxml;

  is(
    $castxml = Clang::CastXML->new,
    object {
      call [ isa => 'Clang::CastXML' ] => T();
      call wrapper => object {
        call [ isa => 'Clang::CastXML::Wrapper' ] => T();
      };
    },
  );

  my @tests = (
    { source => path('corpus/src/simple.C'),             name => 'from file (Path::Tiny)' },
    { source => path('corpus/src/simple.C')->slurp_utf8, name => 'from file (Path::Tiny)' },
  );

  foreach my $t (@tests)
  {
    subtest $t->{name} => sub {
      my $xml;

      is(
        $xml = $castxml->introspect($t->{source}),
        object {
          call [ isa => 'Clang::CastXML::Container' ] => T();
        },
      );

      is_well_formed_xml($xml->to_xml);
      note $xml->to_xml;
    };
  }

};

subtest 'usage error' => sub {

  my $castxml = Clang::CastXML->new,
  my $ex;

  is(
    $ex = dies { $castxml->introspect([]) },
    object {
      call [ isa => 'Clang::CastXML::Exception' ] => T();
      call [ isa => 'Clang::CastXML::Exception::UsageException' ] => T();
    },
  );

  note $ex->to_string;

};

subtest 'castxml error' => sub {

  my $castxml = Clang::CastXML->new,
  my $ex;

  is(
    $ex = dies { $castxml->introspect('this is some bad c') },
    object {
      call [ isa => 'Clang::CastXML::Exception' ] => T();
      call [ isa => 'Clang::CastXML::Exception::ProcessException::IntrospectException' ] => T();
    },
  );

  note $ex->to_string;

};

done_testing;
