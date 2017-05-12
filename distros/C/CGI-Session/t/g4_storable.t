use strict;


use Test::More;
use File::Spec;
use CGI::Session::Test::Default;

eval { require Storable };
plan(skip_all=>"Storable is NOT available") if $@;

my $dir_name = File::Spec->tmpdir();

my $t = CGI::Session::Test::Default->new(
    dsn => "driver:file;serializer:Storable",
    args=>{Directory=>$dir_name});

plan tests => $t->number_of_tests;
$t->run();
