#!perl

use 5.010;
use strict;
use warnings;

use Test::Exception;
use Test::More 0.98;

use Data::Section::Seekable::Writer;

# test empty is okay
{
    my $writer = Data::Section::Seekable::Writer->new;
    is($writer->as_string, <<'_');
Data::Section::Seekable v1

_
}

{
    my $writer = Data::Section::Seekable::Writer->new;
    $writer->add_part(part1 => "This is part1\n");
    $writer->add_part(part2 => "This is part\ntwo\n");

    dies_ok { $writer->add_part('' => "foo") } "part name must not be empty";
    dies_ok { $writer->add_part('a,b' => "foo") } "part name must not contain comma";

    is($writer->as_string, <<'_');
Data::Section::Seekable v1
part1,14,14
part2,42,17

### part1 ###
This is part1
### part2 ###
This is part
two
_
}

# test header, duplicate name, invalid part name & extra
{
    my $writer = Data::Section::Seekable::Writer->new(header=>"");
    is($writer->header, "", "header string 1");
    $writer->add_part(b => "This is part1\n");
    $writer->header("###\n");
    is($writer->header, "###\n", "header string 2");
    $writer->add_part(a => "This is part\ntwo\n", "extra");
    $writer->header(sub {"#\n"});
    is(ref($writer->header), "CODE", "header code 1");
    $writer->add_part(c => "");
    dies_ok { $writer->add_part("c" => "") } "add duplicate name -> dies";
    dies_ok { $writer->add_part("d\n" => "") } "part name cannot contain newline";
    dies_ok { $writer->add_part(e => "", "extra\n") } "extra cannot contain newline";

    is($writer->as_string, <<'_');
Data::Section::Seekable v1
b,0,14
a,18,17,extra
c,37,0

This is part1
###
This is part
two
#
_
}

done_testing;
