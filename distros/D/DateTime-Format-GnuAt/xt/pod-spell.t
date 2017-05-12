use strict;
use warnings;
use Test::More;

eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;

my @ignore = ("DateTime", "Fandi\xf1o", "Formaci\xf3n",
              "POSIX", "Qindel", "Servicios");

local $ENV{LC_ALL} = 'C';
add_stopwords(@ignore);
all_pod_files_spelling_ok();

