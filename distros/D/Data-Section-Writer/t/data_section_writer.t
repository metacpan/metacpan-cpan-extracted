use Test2::V0 -no_srand => 1;
use Data::Section::Writer;
use Test::Builder ();  # required for Test::Differences + Test2 le sigh
use Test::Differences;

is(
  Data::Section::Writer->new,
  object {
    prop isa => 'Data::Section::Writer';
    call perl_filename => object {
      prop isa => 'Path::Tiny';
      call stringify => __FILE__;
    };
    call render_section => "__DATA__\n";
  },
  'defaults',
);

is(
  Data::Section::Writer->new( perl_filename => 'Foo/Bar.pm' ),
  object {
    prop isa => 'Data::Section::Writer';
    call perl_filename => object {
      prop isa => 'Path::Tiny';
      call stringify => 'Foo/Bar.pm';
    };
    call render_section => "__DATA__\n";
  },
  'upgrade perl_filename',
);

my $perl_filename = Path::Tiny->tempfile;

my $writer = Data::Section::Writer->new(
  perl_filename => $perl_filename,
);

my $section = "__DATA__\n" .
              "\@\@ bar.bin (base64)\n" .
              "Rm9vIEJhciBCYXo=\n" .
              "\@\@ foo.txt\n" .
              "Foo Bar Baz\n";
is(
  $writer,
  object {
    prop isa => 'Data::Section::Writer';
    call [add_file => 'foo.txt', "Foo Bar Baz"] => object {
      prop isa => 'Data::Section::Writer';
    };
    call [add_file => 'bar.bin', "Foo Bar Baz", 'base64'] => object {
      prop isa => 'Data::Section::Writer';
    };
    call render_section => $section;

    call unchanged => U();

    call update_file => object {
      prop isa => 'Data::Section::Writer';
    };

    call unchanged => F();

    call update_file => object {
      prop isa => 'Data::Section::Writer';
    };

    call unchanged => T();

  },
  'add_section_file',
);

unlink $perl_filename;
$writer->update_file;
is($perl_filename->slurp_utf8, $section, 'create new file');

my $program = "print \"hello world\"";
$perl_filename->spew_utf8("$program\n");
$writer->update_file;
eq_or_diff($perl_filename->slurp_utf8, "$program\n$section", 'correctly formed text file');

$perl_filename->spew_utf8("$program");
$writer->update_file;
eq_or_diff($perl_filename->slurp_utf8, "$program\n$section", 'missing trailing \n');

$perl_filename->spew_utf8("$program\n__DATA__\nfoo\n");
$writer->update_file;
eq_or_diff($perl_filename->slurp_utf8, "$program\n$section", 'replace');

$perl_filename->spew_utf8("$program\n __DATA__\nfoo\n");
$writer->update_file;
eq_or_diff($perl_filename->slurp_utf8, "$program\n __DATA__\nfoo\n$section", '__DATA__ at start of line');

$perl_filename->spew_utf8("__DATA__\nfoo\n");
$writer->update_file;
eq_or_diff($perl_filename->slurp_utf8, "$section", 'JUST a data section');

done_testing;
