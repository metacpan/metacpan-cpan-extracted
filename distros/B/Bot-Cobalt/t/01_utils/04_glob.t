use Test::More tests => 11;
use strict; use warnings;

BEGIN {
  use_ok( 'Bot::Cobalt::Utils', qw/
    glob_grep glob_to_re glob_to_re_str
  / );
}

## conversion:
my $globs = {
    'th*ngs+stuff' => 'th.*ngs\sstuff',
    '^an?chor$'    => '^an.chor$',
};

for my $glob (keys %$globs) {
    my $regex;
    ok( glob_to_re $glob, "glob_to_re");

    ok( $regex = glob_to_re_str $glob, "Convert glob" )
      or diag("Could not convert $glob to regex");

    ok( $regex eq $globs->{$glob}, "Compare glob<->regex" )
      or diag(
        "Expected: ".$globs->{$glob},
        "\nGot: ".$regex,
      );
}


## glob_grep:
my @array = ( "Test array", "Another item" );  

ok( glob_grep('^Anoth*', @array), "glob_grep against array" );
ok( glob_grep('*t+array$', \@array), "glob_grep against arrayref" );

ok( !glob_grep('Non*existant', @array), "negative glob_grep against array");
ok( !glob_grep('Non*existant', \@array), "negative glob_grep against ref");
