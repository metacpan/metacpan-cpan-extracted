#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

{
    package Local::Test;

    use Mouse;
    use BackPAN::Index::Types;

    has file =>
      is	=> 'ro',
      isa	=> 'Path::Class::File',
      coerce	=> 1,
    ;

    has dir =>
      is	=> 'ro',
      isa	=> 'Path::Class::Dir',
      coerce	=> 1,
    ;
}


note "test file and dir coercion"; {
    my $obj = Local::Test->new(
	file => "/foo/bar/baz.txt",
	dir  => "/what/stuff",
    );
    isa_ok $obj->file, "Path::Class::File";
    isa_ok $obj->dir,  "Path::Class::Dir";

    is $obj->file, Path::Class::File->new("", "foo","bar","baz.txt");
    is $obj->dir,  Path::Class::File->new("", "what", "stuff");
}

done_testing;
