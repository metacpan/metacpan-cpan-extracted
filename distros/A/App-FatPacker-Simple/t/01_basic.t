use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;
use Config;

subtest basic => sub {
    my $guard = tempd;
    spew 1 => "hello.pl";
    chmod 0755, "hello.pl";
    run "hello.pl";
    ok -f "hello.fatpack.pl";
    ok system($^X, "-c", "hello.fatpack.pl") == 0;
    ok -x "hello.fatpack.pl";

    run "hello.pl", "--output", "foo.pl";
    ok -f "foo.pl";

    spew "1" => "output-test";
    run "output-test";
    ok -f "output-test.fatpack";
};

subtest dir => sub {
    my $guard = tempd;
    spew 1 => "hello.pl";
    spew_pm "Hoge1", "lib";
    spew_pm "Hoge2", "extlib";
    spew_pm "Hoge3", "local";
    spew_pm "Hoge4", "fatlib";
    run "hello.pl";
    ok -f "hello.fatpack.pl";
    for my $i (1..4) {
        ok contains("hello.fatpack.pl", "Hoge$i");
    }

    spew_pm "Hoge5", "other";
    run "hello.pl", "--dir", "other";
    for my $i (1..4) {
        ok !contains("hello.fatpack.pl", "Hoge$i");
    }
    ok contains("hello.fatpack.pl", "Hoge5");
};

subtest local_lib => sub {
    my $guard = tempd;
    spew 1 => "hello.pl";
    spew_pm "Hoge1", "lib";
    spew_pm "Hoge2", "extlib/lib/perl5";
    spew_pm "Hoge3", "local/lib/perl5";
    run "hello.pl";
    ok -f "hello.fatpack.pl";
    for my $i (1..3) {
        ok contains("hello.fatpack.pl", "Hoge$i");
    }
};

subtest non_pm => sub {
    my $guard = tempd;
    spew 1 => "hello.pl";
    spew 1 => "lib/foo.so";
    my $r = run "hello.pl";
    ok $r->success;
    like $r->err, qr/WARN/;

    $r = run "hello.pl", "--strict", "--output", "foo.pl";
    ok !$r->success;
    like $r->err, qr/ERROR/;
    ok !-f "foo.pl";
};

subtest handle_relative_and_abs_path => sub {
    my $guard = tempd;
    spew 1 => "hello.pl";
    spew_pm "Hoge1", "lib";
    spew_pm "Hoge2", "extlib/lib/perl5";
    spew_pm "Hoge3", "extlib/lib/perl5/$Config{archname}";
    {
        mkdir "test1";
        my $guard1 = pushd "test1";
        run "--dir", "../lib,../extlib", "../hello.pl";
        ok contains("hello.fatpack.pl", "Hoge1");
        ok contains("hello.fatpack.pl", "Hoge2");
        ok contains("hello.fatpack.pl", "Hoge3");
    }
    {
        mkdir "test2";
        my $guard2 = pushd "test2";
        run "--dir", "$guard/lib,$guard/extlib", "$guard/hello.pl";
        ok contains("hello.fatpack.pl", "Hoge1");
        ok contains("hello.fatpack.pl", "Hoge2");
        ok contains("hello.fatpack.pl", "Hoge3");
    }
};

subtest no_strip => sub {
    my $guard = tempd;
    spew 1 => "hello.pl";
    spew_pm "Hoge1", "lib";
    spew_pm "Hoge2", "extlib/lib/perl5";
    spew_pm "Hoge3", "local/lib/perl5";
    run "--no-strip", "hello.pl";
    ok -f "hello.fatpack.pl";
    for my $i (1..3) {
        ok contains("hello.fatpack.pl", "Hoge$i");
    }
    my $content = slurp("hello.fatpack.pl");
    like $content, qr/\Quse Hoge1; 1; # this is comment/;
    like $content, qr/\Quse Hoge2; 1; # this is comment/;
    like $content, qr/\Quse Hoge3; 1; # this is comment/;
};

subtest exclude_strip => sub {
    my $guard = tempd;
    spew 1 => "hello.pl";
    spew_pm "Hoge1", "lib";
    spew_pm "Hoge2", "extlib/lib/perl5";
    spew_pm "Hoge3", "local/lib/perl5";
    {
        run "--exclude-strip", "Hoge1", "hello.pl";
        ok -f "hello.fatpack.pl";
        for my $i (1..3) {
            ok contains("hello.fatpack.pl", "Hoge$i");
        }
        my $content = slurp("hello.fatpack.pl");
        like $content, qr/\Quse Hoge1; 1; # this is comment/;
        like $content, qr/\Quse Hoge2;1;/;
        like $content, qr/\Quse Hoge3;1;/;
    }
    {
        run "--exclude-strip", "^(?:local|extlib)", "hello.pl";
        ok -f "hello.fatpack.pl";
        for my $i (1..3) {
            ok contains("hello.fatpack.pl", "Hoge$i");
        }
        my $content = slurp("hello.fatpack.pl");
        like $content, qr/\Quse Hoge1;1;/;
        like $content, qr/\Quse Hoge2; 1; # this is comment/;
        like $content, qr/\Quse Hoge3; 1; # this is comment/;
    }
};

done_testing;
