use Test::More;
use Baal::Parser;

my $document = <<END;
namespace Data.Hoge += Hoge.Fuga.* {
  /#
    hoge
  #/
  abstract entity Foo
  += FooBar
  {
    /# これはテストなのです #/
    Test: ! list of integer;
  }

  service HogeHoge {
    Hoge: <= !integer => !"Fo\u0020o\n";
  }
}
END

my $parser = Baal::Parser->new;
ok my $parsed_document = $parser->parse($document);

done_testing;
