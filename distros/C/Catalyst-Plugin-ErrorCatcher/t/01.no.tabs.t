use strict;
use warnings;
use Test::More;

eval "use Test::NoTabs";

plan skip_all => "install Test::NoTabs to enable this test" if $@;

plan q{no_plan};
all_perl_files_ok( qw<lib t/lib> );
