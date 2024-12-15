use Test2::V0 -no_srand => 1;
use Test2::Require::Module 'Data::Section::Pluggable';
use lib 't/lib';
use MyIntegration qw( run );
use Data::Section::Pluggable qw( get_data_section );
use Path::Tiny ();
use Data::Section::Writer;

my $script = Path::Tiny->tempfile;
$script->spew_utf8(get_data_section 'example.pl');
Data::Section::Writer
  ->new( perl_filename => $script )
  ->add_file( 'a.txt', "Foo Bar Baz\n" )
  ->add_file( 'b.txt', "Foo Bar Baz\n" )
  ->add_file( 'c.txt', "Frooble Bits", 'base64' )
  ->update_file;

note $script->slurp_utf8;

run $script, 'a.txt', "Foo Bar Baz\n", 'text';
run $script, 'b.txt', "Foo Bar Baz\n", 'at EOF';
run $script, 'c.txt', 'Frooble Bits', 'binary';

done_testing;

__DATA__

@@ example.pl
#!/usr/bin/perl

use strict;
use warnings;
use Data::Section::Pluggable qw( get_data_section );

print get_data_section($ARGV[0]);
