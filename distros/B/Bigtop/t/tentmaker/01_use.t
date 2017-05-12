use Test::More tests => 1;

BEGIN {
    eval { require Gantry; };
    my $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 1 if $skip_all;
        use_ok('Bigtop::TentMaker');
    }
}
