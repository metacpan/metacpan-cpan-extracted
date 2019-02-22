#!/usr/bin/env perl
#
# Here we test the subroutines in the App::Dpath module in relative
# isolation.
#
################################################################################

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 74;

BEGIN { use_ok 'App::DPath'; }

my $opt;
is App::DPath::_format_flat_inner_scalar ('a'), 'a',
    '_format_flat_inner_scalar scalar';
is App::DPath::_format_flat_inner_scalar (''), '',
    '_format_flat_inner_scalar empty';
is App::DPath::_format_flat_inner_scalar (undef), '',
    '_format_flat_inner_scalar undef to empty';
is App::DPath::_format_flat_inner_scalar (qw/a b/), 'a',
    '_format_flat_inner_scalar array first element';

$opt->{separator} = '_';
is App::DPath::_format_flat_inner_array ($opt, ['a']), 'a',
    '_format_flat_inner_array single value';
is App::DPath::_format_flat_inner_array ($opt, []), '',
    '_format_flat_inner_array empty';
is App::DPath::_format_flat_inner_array ($opt, undef), '',
    '_format_flat_inner_array undef to empty';
is App::DPath::_format_flat_inner_array ($opt, [qw/a b/]), 'a_b',
    '_format_flat_inner_array array';
is App::DPath::_format_flat_inner_array ($opt, [qw/a b c/]), 'a_b_c',
    '_format_flat_inner_array array > 2';
eval { App::DPath::_format_flat_inner_array ($opt, [ ['a'], 'b']); };
like $@, qr/unsupported innermost nesting/,
    '_format_flat_inner_array nested ref exception thrown';

is App::DPath::_format_flat_inner_hash ($opt, { a => 'z' }), 'a=z',
    '_format_flat_inner_hash one entry';
is App::DPath::_format_flat_inner_hash ($opt, {}), '',
    '_format_flat_inner_hash empty';
is App::DPath::_format_flat_inner_hash ($opt, undef), '',
    '_format_flat_inner_hash undef to empty';
like App::DPath::_format_flat_inner_hash ($opt, { a => 'z', b => 'y' }),
    qr/a=z_b=y|b=y_a=z/,
    '_format_flat_inner_hash multiple entries';
eval { App::DPath::_format_flat_inner_hash ($opt, { a => ['a'] }); };
like $@, qr/unsupported innermost nesting/,
    '_format_flat_inner_hash nested ref exception thrown';

is App::DPath::_format_flat_outer ($opt, 'a'), "a\n",
    '_format_flat_outer scalar';
is App::DPath::_format_flat_outer ($opt, { a => 'z' }), "a:z\n",
    '_format_flat_outer one hash entry';
is App::DPath::_format_flat_outer ($opt, ['a']), "a\n",
    '_format_flat_outer one array entry';
like App::DPath::_format_flat_outer ($opt, { a => ['z'], b => { c => 'y'} }),
    qr/a:z\nb:c=y|b:c=y\na:z/,
    '_format_flat_outer nested hash entry';
is App::DPath::_format_flat_outer ($opt, [['a'], { b => 'y' }]),
    "a\nb=y\n",
    '_format_flat_outer nested array entry';
$opt->{fb} = 1; # square brackets
$opt->{fi} = 1; # prefix array elements with index
is App::DPath::_format_flat_outer ($opt, [['a','b'], { b => 'y' }]),
    "0:[a_b]\n1:[b=y]\n",
    '_format_flat_outer nested array entry with brackets and prefix';

eval { App::DPath::_format_flat_outer ($opt); };
like $@, qr/can not flatten data structure/,
    '_format_flat_outer undef exception thrown';
eval { App::DPath::_format_flat_outer ($opt, \*opt); };
like $@, qr/can not flatten data structure/,
    '_format_flat_outer with other ref exception thrown';
eval { App::DPath::_format_flat_outer ($opt, [\*opt]); };
like $@, qr/can not flatten data structure/,
    '_format_flat_outer array with other ref exception thrown';
eval { App::DPath::_format_flat_outer ($opt, { a => \*opt}); };
like $@, qr/can not flatten data structure/,
    '_format_flat_outer hash with other ref exception thrown';

is App::DPath::_format_flat ({}, ['a', ['b', 'c'], { d => 'e' }]), 
    "a\nb\nc\nd:e\n",
    '_format_flat';

eval { App::DPath::read_in ("t/testdata.yaml", 'foo'); };
like $@, qr/unrecognized input format: foo/,
    'read_in with unknown type exception thrown';
eval { App::DPath::write_out ({ outtype => 'foo' }, ['a', 'b']); };
like $@, qr/unrecognized output format: foo/,
    'write_out with unknown outtype exception thrown';

my $data = App::DPath::read_in ("t/testdata.yaml");
ok (defined ($data), 'Default type YAML for reading');
my $output = App::DPath::write_out ({}, $data);
ok (defined ($output), 'Default type YAML for reading');

eval { App::DPath::read_in ("t/testdata.empty"); };
like $@, qr/no meaningful input to read/,
    'read_in with empty file exception thrown';
eval { App::DPath::read_in ("t/nosuchfile"); };
like $@, qr/cannot open input file/,
    'read_in with non-existent file exception thrown';

my @types = qw/cfggeneral dumper ini json tap xml yaml/;
for my $intype (@types) {
    $data = App::DPath::read_in ("t/testdata.$intype", $intype);
    ok (defined ($data), "$intype data read");
    for my $outtype (@types) {
        next if $outtype eq 'tap' || $outtype eq 'cfggeneral';
        next if ($intype eq 'tap' && $outtype eq 'ini');
        $output = App::DPath::write_out ({outtype => $outtype}, 
            ref $data eq 'ARRAY' ? $data : [$data]);
        ok (defined ($output), "$intype to $outtype converted");
    }
}

