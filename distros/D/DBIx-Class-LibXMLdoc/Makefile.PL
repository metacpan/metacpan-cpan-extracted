use strict;
use inc::Module::Install;

name "DBIx-Class-LibXMLdoc";
license "perl";
all_from "lib/DBIx/Class/LibXMLdoc.pm";

requires "XML::LibXML" => 1.63;
requires "DBIx::Class" => 0.08;
requires "HTML::Entities";
requires "parent";
    
build_requires "Test::More" => 0.5;

auto_install;
WriteAll;

__END__
