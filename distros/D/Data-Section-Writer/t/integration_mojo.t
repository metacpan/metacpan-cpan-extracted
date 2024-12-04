use Test2::V0 -no_srand => 1;
use Test2::Require::Module 'Mojo::Loader';
use lib 't/lib';
use MyIntegration qw( run );
use Mojo::Loader 'data_section';
use Path::Tiny ();
use Data::Section::Writer;

my $script = Path::Tiny->tempfile;
$script->spew_utf8(data_section __PACKAGE__, 'example.pl');
Data::Section::Writer
  ->new( perl_filename => $script )
  ->add_file( 'a.txt', "Foo Bar Baz\n" )
  ->add_file( 'b.bin', "Foo Bar Baz\n", 'base64')
  ->add_file( 'c.txt', "Foo Bar Baz\n" )
  ->update_file;

note $script->slurp_utf8;

run $script, 'a.txt', "Foo Bar Baz\n", 'text';
run $script, 'b.bin', "Foo Bar Baz\n", 'base64';
run $script, 'c.txt', "Foo Bar Baz\n", 'EOF';

done_testing;

__DATA__

@@ example.pl
#!/usr/bin/perl

use strict;
use warnings;
use Mojo::Loader 'data_section';

print data_section(__PACKAGE__, $ARGV[0]);
