use Test2::V0 -no_srand => 1;
use Test2::Require::Module 'Data::Section';
use lib 't/lib';
use MyIntegration qw( run );
use Data::Section -setup;
use Path::Tiny ();
use Data::Section::Writer;
use stable qw( postderef );

my $script = Path::Tiny->tempfile;
$script->spew_utf8(__PACKAGE__->section_data('example.pl')->$*);
Data::Section::Writer
  ->new( perl_filename => $script )
  ->add_file( 'a.txt', "Foo Bar Baz\n" )
  ->add_file( 'b.txt', "Foo Bar Baz\n" )
  ->update_file;

note $script->slurp_utf8;

run $script, 'a.txt', "Foo Bar Baz\n", 'text';
run $script, 'b.txt', "Foo Bar Baz\n", 'at EOF';

done_testing;

__DATA__

__[ example.pl ]__
#!/usr/bin/perl

use strict;
use warnings;
use stable qw( postderef );
use Data::Section -setup => {
  header_re => qr/^@@ (.*?)$/,
};

print __PACKAGE__->section_data($ARGV[0])->$*;
