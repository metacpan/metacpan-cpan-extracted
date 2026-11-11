use strict;
use warnings;
use Test::More;

use App::optex::up;

# Test grid option parsing
subtest 'grid parsing' => sub {
    my $config = Getopt::EX::Config->new(
        'grid'         => undef,
        'pane-width'   => 85,
        'pane'         => undef,
        'row'          => undef,
        'border-style' => 'heavy-box',
        'line-style'   => undef,
        'pager'        => 'less',
        'no-pager'     => undef,
    );

    # Test 2x3 format
    $config->{grid} = '2x3';
    if (my $grid = $config->{grid}) {
        my($c, $r) = $grid =~ /^(\d+)[x,](\d+)$/;
        $config->{pane} //= $c;
        $config->{row}  //= $r;
    }
    is $config->{pane}, 2, 'grid 2x3: pane is 2';
    is $config->{row}, 3, 'grid 2x3: row is 3';

    # Test 3,2 format
    $config->{grid} = '3,2';
    $config->{pane} = undef;
    $config->{row} = undef;
    if (my $grid = $config->{grid}) {
        my($c, $r) = $grid =~ /^(\d+)[x,](\d+)$/;
        $config->{pane} //= $c;
        $config->{row}  //= $r;
    }
    is $config->{pane}, 3, 'grid 3,2: pane is 3';
    is $config->{row}, 2, 'grid 3,2: row is 2';
};

# Test pager option handling
subtest 'pager options' => sub {
    my $pager;

    $pager = 'less';
    $pager .= ' -F +Gg' if $pager =~ /\bless\b/;
    is $pager, 'less -F +Gg', 'less gets -F +Gg options';

    $pager = '/usr/bin/less';
    $pager .= ' -F +Gg' if $pager =~ /\bless\b/;
    is $pager, '/usr/bin/less -F +Gg', '/usr/bin/less gets -F +Gg options';

    $pager = 'more';
    $pager .= ' -F +Gg' if $pager =~ /\bless\b/;
    is $pager, 'more', 'more does not get less options';

    $pager = 'lv';
    $pager .= ' -F +Gg' if $pager =~ /\bless\b/;
    is $pager, 'lv', 'lv does not get less options';
};

# Test term_size function exists
subtest 'take_option' => sub {
    my $take = sub { App::optex::up::take_option($_[0], 'P', 'page') };
    for my $t ([ [qw(-P 60 -w 100)],   60, [qw(-w 100)] ],
               [ [qw(--page 40)],      40, [] ],
               [ [qw(--page=80 -V)],   80, [qw(-V)] ],
               [ [qw(-w 100 -P50)],    50, [qw(-w 100)] ],
               [ [qw(-w 100)],      undef, [qw(-w 100)] ],
               [ [qw(-P)],          undef, [qw(-P)] ]) {
        my($argv, $page, $rest) = @$t;
        my $name = "@$argv";
        is $take->($argv), $page, "page of $name";
        is_deeply $argv, $rest, "rest of $name";
    }
};

subtest 'take_option for width' => sub {
    my @argv = qw(file -w 170 --page=40);
    is App::optex::up::take_option(\@argv, 'w', 'width'), 170, 'width';
    is_deeply \@argv, [qw(file --page=40)], 'rest';
};

subtest 'term_size' => sub {
    can_ok 'App::optex::up', 'term_size';
};

done_testing;
