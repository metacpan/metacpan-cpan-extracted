use strict;
use warnings;
use Test::More;
use File::Spec;
use lib File::Spec->rel2abs('t/lib');

require_ok 'Alien::Web::Foo';

{
  my $path = Alien::Web::Foo->path;
  
  ok -d $path, "path returns a directory path";
  note "path is $path";
  
  ok -f "$path/example.js", "directory contains example.js";
};

{
  my $dir = Alien::Web::Foo->dir;
  
  isa_ok $dir, 'Path::Class::Dir';
  
  ok -d $dir, "dir returns a directory path";
  note "dir is $dir";
  
  my $file = $dir->file('example.js');
  
  ok -f $file, "dir contains example.js";
  like( $file->slurp, qr{/\* some javasscript perhaps \*/}, 'content of example.js' );

}

done_testing;
