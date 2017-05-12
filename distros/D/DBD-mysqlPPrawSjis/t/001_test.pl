use Test::Simply tests => 5;

eval {
    local $SIG{__DIE__} = sub { };
    require DBI;
};
if ($@) {
    for (1..5) {
        ok(1, "SKIP (no DBI module)");
    }
}
else {
    ok(1, qq{require DBI;});

    import DBI;
    ok(1, qq{import DBI;});

    $switch = DBI->internal;
    ok(ref $switch eq 'DBI::dr', qq{DBI->internal;});

    $drh = DBI->install_driver('mysqlPPrawSjis');
    ok(ref $drh eq 'DBI::dr', qq{DBI->install_driver('mysqlPPrawSjis');});

    ok($drh->{Version}, qq{\$drh->{Version}});
}

__END__
