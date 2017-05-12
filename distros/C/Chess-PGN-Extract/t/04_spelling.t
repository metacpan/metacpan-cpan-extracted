use strict;
use Test::More;

eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for pod spell check" if $@;

add_stopwords (<DATA>);
all_pod_files_spelling_ok ();

__END__
Bitbucket
Mitsuhiro
Nakamura
PGN
basicer
pgn
