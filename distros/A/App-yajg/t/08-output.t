#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;
use JSON;

my $data = {
    a  => 'b',
    c  => 0,
    d  => "\n\n",
    e  => q(\\'"'),
    '' => [undef, [1, 2, 3], { 1 => 2, 3 => 4 }]
};

subtest 'json' => sub {
    use_ok('App::yajg::Output::Json');
    my $output = App::yajg::Output::Json->new();
    isa_ok $output, 'App::yajg::Output::Json';
    isa_ok $output, 'App::yajg::Output';
    $output->data($data)->color(0)->max_depth(0);

    $output->minimal(1);
    my $out = $output->as_string;
    my $lines = () = $out =~ m/\n/g;
    ok (($lines == 0 or $lines == 1), 'minimal have only one or none lines');
    my $restored = eval { decode_json($out) };
    ok not($@), 'minimal makes valid json';
    is_deeply $restored, $data, 'minimal returns same data';

    $output->minimal(0);
    $out = $output->as_string;
    $restored = eval { decode_json($out) };
    ok not($@), 'valid json';
    is_deeply $restored, $data, 'returns same data';

    $output->max_depth(2);
    $out = $output->change_depth->as_string;
    $restored = eval { decode_json($out) };
    ok not($@), 'valid json';
    ok not ref $_ for @{ $restored->{''} };
};

subtest 'perl' => sub {
    use_ok('App::yajg::Output::Perl');
    my $output = App::yajg::Output::Perl->new();
    isa_ok $output, 'App::yajg::Output::Perl';
    isa_ok $output, 'App::yajg::Output';
    $output->data($data)->color(0)->max_depth(0);

    $output->minimal(1)->escapes(1);
    my $out = $output->as_string;
    my $lines = () = $out =~ m/\n/g;
    ok (($lines == 0 or $lines == 1), 'minimal have only one or none lines');
    my $restored;
    eval '$restored = ' . $out;
    ok not($@), 'minimal makes valid perl code';
    is_deeply $restored, $data, 'minimal returns same data';

    $output->minimal(0);
    $out = $output->as_string;
    eval '$restored = ' . $out;
    ok not($@), 'valid perl';
    is_deeply $restored, $data, 'returns same data';
};

subtest 'ddp' => sub {
  SKIP: {
        eval { require Data::Printer };
        skip 'Data::Printer not installed', 4 if $@;
        use_ok('App::yajg::Output::DDP');
        my $output = App::yajg::Output::DDP->new();
        isa_ok $output, 'App::yajg::Output::DDP';
        isa_ok $output, 'App::yajg::Output';

        $output->minimal(1)->escapes(1);
        my $out = $output->as_string;
        my $lines = () = $out =~ m/\n/g;
        ok (($lines == 0 or $lines == 1), 'minimal have only one or none lines');
    }
};

subtest 'yaml' => sub {
  SKIP: {
        eval { require YAML };
        skip 'YAML not installed', 5 if $@;
        use_ok('App::yajg::Output::Yaml');
        my $output = App::yajg::Output::Yaml->new();
        isa_ok $output, 'App::yajg::Output::Yaml';
        isa_ok $output, 'App::yajg::Output';

        $output->data($data)->color(0)->max_depth(0);
        my $out = $output->as_string;
        my $restored;
        eval { ($restored) = YAML::Load($out) };
        ok not($@), 'valid yaml';
        is_deeply $restored, $data, 'returns same data';
    }
};

subtest 'boolean and max_depth' => sub {
    my $true   = decode_json('[true]')->[0];
    my $false  = decode_json('[false]')->[0];
    my $data   = [$true, $true, $false, $false];
    my $output = App::yajg::Output::Json->new();
    for (0, 1, 2, 3) {
        my $json = $output->data($data)->max_depth($_)->change_depth->as_string;
        my $restored = eval { decode_json($json) };
        ok not($@), 'valid json depth ' . $_;
        # TODO: fails to restore true, false when depth 1
        #       but we can restore 1 or 0 or maybe 'true' 'false' (depend on version)
        if ($_ != 1) {
            is_deeply $restored, $data, 'same data for depth ' . $_;
        }
        else {
            for (0 .. $#$restored) {
                my $int = int(!!$data->[$_]);
                my $str = $data->[$_] ? 'true' : 'false';
                my $res = lc($restored->[$_]);
                ok ($res eq $int or $res eq $str);
            }
        }
    }
};

done_testing();
