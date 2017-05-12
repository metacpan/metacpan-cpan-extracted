use Test::More;

is $ENV{"APP_PROVE_PLUGIN_SETENV_TEST_$_"}, $_, "$_ env var set"
    foreach qw(FOO BAR);

done_testing();
