use Data::Dmp;
#use Test::More;

sub _merge($$;$) {
    my ($a, $b, $dm) = @_;
    $dm ||= Data::ModeMerge->new;
    my $res = $dm->merge($a, $b);
    #print "DEBUG: merge result: ".dmp([$res])."\n";
    $res;
}

sub mmerge_is($$$) {
    my ($a, $b, $config, $expected, $test_name) = @_;
    my $res = mode_merge($a, $b, $config);
    is_deeply($res->{result}, $expected, $test_name);
}

sub merge_is($$$$;$) {
    my ($a, $b, $expected, $test_name, $dm) = @_;
    my $res = _merge($a, $b, $dm);
    is_deeply($res->{result}, $expected, $test_name)
        or diag explain $res->{result};
}

sub merge_ok($$$;$) {
    my ($a, $b, $test_name, $dm) = @_;
    my $res = _merge($a, $b, $dm);
    ok($res && $res->{success}, $test_name);
}

sub mmerge_ok($$$$) {
    my ($a, $b, $config, $test_name) = @_;
    my $res = mode_merge($a, $b, $config);
    ok($res && $res->{success}, $test_name);
}

sub merge_fail($$$;$) {
    my ($a, $b, $test_name, $sn) = @_;
    my $res = _merge($a, $b, $sn);
    ok($res && !$res->{success}, $test_name);
}

sub mmerge_fail($$$$) {
    my ($a, $b, $config, $test_name) = @_;
    my $res = mode_merge($a, $b, $config);
    ok($res && !$res->{success}, $test_name);
}

1;
