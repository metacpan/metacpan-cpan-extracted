## in a separate test file

use strict;
use Test::More;

eval {
    require Test::Spelling;
    Test::Spelling->import();
};

plan( skip_all => 'Test::Spelling not installed; skipping' ) if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();


__END__
Dowideit
SvenDowideit
Foswiki
foswiki
irc
Serialise
