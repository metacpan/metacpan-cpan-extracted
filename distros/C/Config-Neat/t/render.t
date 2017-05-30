#!/usr/bin/perl

use strict;

BEGIN {
    use File::Spec::Functions qw(rel2abs catfile);
    use File::Basename;
    unshift(@INC, catfile(dirname(rel2abs($0)), '../lib'));
}

$| = 1; # disable output buffering;

use Test::More 0.94;

use_ok('Config::Neat');
use_ok('Config::Neat::Render');

my $c = Config::Neat->new();
ok($c, '$c is defined');

my $r = Config::Neat::Render->new();
ok($r, '$r is defined');

my $data = {
    'word' => 'Hello',
    'string_with_spaces' => 'Hello, world!',
    'simple_array' => [1, '2 3', '4 5', 6, 7],
    'wrappable_string' => 'Vestibulum ullamcorper leo quam, vel adipiscing tellus. '.
                          'Phasellus placerat dolor sit amet lorem mattis dictum. '.
                          'Vestibulum luctus malesuada risus, et porttitor lectus lobortis et.',
    'wrappable_array' => [
        'this particular array item will not wrap since it contains spaces and thus is enclosed in backticks',
        'Aa','Bb','Cc','Dd','Ee','Ff','Gg','Hh','Ii','Jj','Kk','Ll','Mm','Nn','Oo','Pp','Qq','Rr',
        'Ss','Tt','Uu','Vv','Ww','Xx','Yy','Zz',
    ],
    'subsection_1' => {
        'etc' => 'foo bar',
        'pwd' => ['foo', 'foo bar', 'ba``z', '`'],
    },
    'subsection_2' => {
        'true_parameter'  => 1,
        'false_parameter' => undef,
        'subtree' => {
            'empty_string' => '',
            'array_of_empty_strings' => ['', '', ''],
        },
    },
    'array_of_hashes' => [
        {
            'param1' => 'value1',
        },
        {
            'param2' => 'value2',
        },
        {
            'param3' => 'value3',
        },
    ],
};

my @order = qw(
    word string_with_spaces simple_array wrappable_string
    wrappable_array subsection_1 subsection_2 array_of_hashes

    etc pwd

    true_parameter false_parameter subtree

    empty_string array_of_empty_strings
);

#my $sort = undef; # unsorted
#my $sort = 1; # sorted alphabetically
my $sort = \@order; # sort in the order

my $options = {
    sort      => $sort,
    align_all => 1,
};

my $text1 = $r->render($data, $options);
ok($text1, '$text1 is defined');

my $data1 = $c->parse($text1);
ok($data1, '$data1 is defined');

my $text2 = $r->render($data1, $options);
ok($text2, '$text2 is defined');

is($text1, $text2, 'Text from two passes should be the same');

my $reference_text = read_file(catfile(dirname(rel2abs($0)), 'data/render/output.nconf'));
is($text1, $reference_text, 'Text should be equal to reference file contents');

done_testing();

sub read_file {
    my $filename = shift;
    open(IN, $filename);
    binmode(IN, ':utf8');
    my $text = join('', <IN>);
    close(IN);
    return $text;
}