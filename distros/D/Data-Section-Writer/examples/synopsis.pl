use strict;
use warnings;
use Data::Section::Writer;
use Path::Tiny qw( path );

Data::Section::Writer
  ->new( perl_filename => "foo.pl" )
  ->add_file( "hello.txt", "hello world" )
  ->add_file( "a.out", path("a.out")->slurp_raw, 'base64' )
  ->update_file;
