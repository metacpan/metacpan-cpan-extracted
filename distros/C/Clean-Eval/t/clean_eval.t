use Test2::V0;

use Clean::Eval qw/clean_eval clean_string_eval last_error/;

subtest block_success => sub {
    my $ev = clean_eval { 42 };
    isa_ok($ev, ['Clean::Eval'], "object returned even on success");
    ok($ev, "true in boolean context");
    is($ev->{ok}, 1, "ok field set");
    is($ev->ok, 1, "ok accessor matches");
    is($ev->{out}, 42, "out field holds scalar result");
    is($ev->out, 42, "out accessor matches");
    ok(!exists $ev->{error}, "error key not present");
    is("$ev", "", "stringifies to empty string on success");
};

subtest block_success_false_value => sub {
    my $ev = clean_eval { 0 };
    ok($ev, "true even though block returned 0");
    is($ev->out, 0, "out captured 0 faithfully");
    ok(exists $ev->{out}, "out key exists for 0");

    $ev = clean_eval { undef };
    ok($ev, "true even though block returned undef");
    is($ev->out, undef, "out captured undef");
    ok(exists $ev->{out}, "out key exists for undef");
};

subtest block_scalar_context => sub {
    my $ev = clean_eval { (1, 2, 3) };
    is($ev->out, 3, "list collapsed to scalar context (last element of comma)");

    $ev = clean_eval { my @x = (1, 2, 3); @x };
    is($ev->out, 3, "array in scalar context yields count");
};

subtest block_failure => sub {
    my $ev = clean_eval { die "boom\n" };
    ok(!$ev, "false in boolean context");
    is($ev->{ok}, 0, "ok field is 0");
    ok(!exists $ev->{out}, "out key absent on failure");
    is("$ev", "boom\n", "stringifies to error message");
    is($ev->to_string, "boom\n", "to_string method matches");
    is($ev->error, "boom\n", "error accessor matches");
    isa_ok($ev, ['Clean::Eval'], "blessed into Clean::Eval");
    is($ev->{error}, "boom\n", "error key set");
    ok(defined $ev->{package}, "package key set");
    ok(defined $ev->{file},    "file key set");
    like($ev->{line}, qr/^\d+$/, "line key is a number");
};

subtest string_success => sub {
    my $ev = clean_string_eval 'my $x = 1 + 1';
    isa_ok($ev, ['Clean::Eval'], "object returned");
    ok($ev, "true on success");
    is($ev->{ok}, 1, "ok field set");
    ok(!exists $ev->{out}, "out never set for string form even on success");
    is("$ev", "", "stringifies empty on success");
};

subtest string_failure => sub {
    my $ev = clean_string_eval 'die "kapow\n"';
    ok(!$ev, "false on failure");
    is($ev->{ok}, 0, "ok field 0");
    ok(!exists $ev->{out}, "out absent");
    is("$ev", "kapow\n", "stringifies to error message");
    isa_ok($ev, ['Clean::Eval'], "blessed into Clean::Eval");
};

subtest string_eval_line_directive => sub {
    my $line = __LINE__ + 1;
    my $ev = clean_string_eval 'this is not valid perl ][[';
    ok(!$ev, "compile error caught");
    like("$ev", qr/\Q@{[__FILE__]}\E/, "error mentions our file (via #line)");
    like("$ev", qr/line $line\b/, "error mentions our line");
};

subtest last_error_tracking => sub {
    my $before = clean_eval { die "first\n" };
    is(last_error(), $before, "last_error matches most recent failure");

    my $after = clean_eval { die "second\n" };
    is(last_error(), $after, "last_error updates");
    isnt(last_error(), $before, "previous error replaced");

    # success does not clear or set last_error
    my $ok_ev = clean_eval { 1 };
    ok($ok_ev, "success");
    is(last_error(), $after, "last_error unchanged after a success");
};

subtest caller_dollar_at_preserved => sub {
    local $@ = "caller-set\n";
    my $ev = clean_eval { die "trapped\n" };
    ok(!$ev, "failure returned");
    is($@, "caller-set\n", "outer \$@ untouched");

    $ev = clean_eval { 1 };
    ok($ev, "success returned");
    is($@, "caller-set\n", "outer \$@ still untouched");

    $ev = clean_string_eval 'die "trapped\n"';
    ok(!$ev, "string failure returned");
    is($@, "caller-set\n", "outer \$@ untouched by string form");
};

subtest object_error_preserved => sub {
    my $obj = bless { msg => "oops" }, "Some::Err";
    my $ev = clean_eval { die $obj };
    ok(!$ev, "failure");
    is($ev->{error}, $obj, "object error stored without stringification");
};

subtest exports => sub {
    package Clean::Eval::Test::NoImport;
    use Clean::Eval;
    ::ok(!__PACKAGE__->can('clean_eval'),        "clean_eval not imported by default");
    ::ok(!__PACKAGE__->can('clean_string_eval'), "clean_string_eval not imported by default");
    ::ok(!__PACKAGE__->can('last_error'),        "last_error not imported by default");
};

subtest synopsis_pattern => sub {
    my $msg;
    if (my $ev = clean_eval { "hello" }) {
        $msg = $ev->out;
    }
    else {
        die $ev;
    }
    is($msg, "hello", "synopsis pattern works");
};

done_testing;
