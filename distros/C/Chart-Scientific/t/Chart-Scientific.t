# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Chart-Scientific.t'

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 1;
BEGIN { 
    use_ok ( 'PDL' );
};

__END__
use Test::More tests => 47;

BEGIN { 
    use_ok ( 'PDL' );
    use_ok ( 'Chart::Scientific' );
};


main ();

sub main { 
    make_test_images ();
    my @ref_data  = get_reference_data ();
    my @test_data = get_test_data ();

    die "uneven data: ", scalar  @ref_data, " reference images, ",
                         scalar @test_data, " test images"
        if scalar @ref_data != scalar @test_data;

    foreach ( 0 .. scalar @ref_data - 1 ) {
        is ( $ref_data[$_]{data},
             $test_data[$_]{data},
             "$ref_data[$_]{name} matches $test_data[$_]{name}"
        );
        unlink $test_data[$_]{name}
            or warn "can't delete $test_data[$_]{name}";
    }
}

sub get_test_data {
    my @file_names = <t/test*ps>;
    return get_data ( @file_names );
}

sub get_reference_data {
    my @file_names = <t/reference*ps>;
    return get_data ( @file_names );
}

sub get_data {
    my @file_names = @_;
    my @file_data;

    # Put the contents of each file into an array, one file per
    #   element:
    #
    foreach my $fname ( @file_names ) {
        open ( my $fh, $fname ) or die "can't open $fname: $!";
        my $data = "";
        while ( <$fh> ) {
            next if m(^%);
            $data .= $_;
        }
        push @file_data, { name => $fname, data => $data };
    }
    return @file_data;
}

sub make_test_images {
    my @pars = get_pars ();

    my @nums = ( scalar @ARGV > 0 )
                   ? map { $_ - 1 } @ARGV
                   : 0..scalar @pars - 1;

    foreach my $i ( @nums ) {
        my $dev = sprintf "t/test%02d.ps/cps", $i+1;
        eval {
            my $plt = Chart::Scientific->new ( $pars[$i] );
            $plt->setvars ( device => $dev );
            $plt->plot ();
        };
        #warn "$Plot ", $i+1, " error: $@\n" if $@;
    }
}

sub get_pars {
    my @a1 =  0.. 9;
    my @b1 = 10..19; 
    my @c1 = reverse 20..29; 
    my @berr1 = map { 1.5 } @b1;
    my @cerr1 = map { 1.5 } @c1;

    my @a2 =  0.. 9;
    my @b2 = 10..19;

    my @arr = map { [10*$_ .. (10*$_ + 4)] } 0..9;
    my @err = map { [$_ .. ($_ + 4)] } 0..9;

    my @p1 = 0..9;
    my @p2 = map { 2**$_ } @p1;
    my @p3 = map { 3**$_ } @p1;

    my $pdlx1    = xvals(100);
    my $pdly1    = sin($pdlx1/5);
    my $pdly2    = cos($pdlx1/5);
    my $pdl_err1 = $pdlx1 * 0.0 + .4;
    my $pdl_err2 = $pdl_err1 - .1;

    my $pdlx2    = xvals(10) + .5;
    my $pdly3    = sin($pdlx2/5) + 2.5;
    my $pdly4    = cos($pdlx2/5) + 2.5;
    my $pdl_err3 = $pdlx2 * 0.0 + .4;
    my $pdl_err4 = $pdl_err3 - .1;

    my $logx = xvals ( 5 ) + 1.0;
    my $logy = 2 * $logx;
    my $logy2 = 3 * $logx;
    my $loge = zeroes ( $logx ) + 1.0;

    my $lowx = xvals ( 10 );
    my $lowy = ones  ( $lowx );
    my $lowe = ones  ( $lowy ) * .9999;

    my @axes_x  = -10 .. 10;
    my @axes_y1 = -8  .. 12;
    my @axes_y2 = reverse -8  .. 12;

    my @pars = (
        { #1
            x_data => \@a2,
            y_data => [\@b2],
            title  => 'test: x_data and single y_data',
        },
        { #2
            x_data => \@a1,
            y_data => [ \@b1, \@c1 ],
            yerr_data => [ \@berr1, \@cerr1 ],
            legend_text => 'LegendTestA,LegendTestB',
            title  => 'test: x_data and multiple y_data, yerr_data',
        },
        { #3
            filename => 't/data.dat',
            split    => '\t',
            x_col    => 'x',
            y_col    => 'y,z',
            yerr_col => 'err,err',
            xlabel   => 'range',
            ylabel   => 'data',
            title    => 'test: read x, multiple y, y_err from data file',
        },
        { #4
            filename => 't/data.dat',
            split    => '\t',
            x_col    => 'x',
            y_col    => 'y,z',
            yerr_col => 'err,err',
            xlabel   => 'range',
            ylabel   => 'data',
            title    => 'test: read x, multiple y, y_err from data file, w/ resid',
            residuals => 1,
        },
        { #5
            filename => 't/data.dat',
            split    => '\t',
            x_col    => 'x',
            y_col    => 'y,z',
            yerr_col => 'err,err',
            group_col=> 'group',
            xlabel   => 'range',
            ylabel   => 'data',
            title    => 'test: read x, multiple y, y_err from data file, GROUPED, with resid',
            residuals => 1,
        },
        { #6
            filename => 't/data.rdb',
            x_col    => 'x',
            y_col    => 'y,z',
            yerr_col => 'err,err',
            xlabel   => 'range',
            ylabel   => 'data',
            title    => 'test: read x, multiple y, y_err from RDB file',
        },
        { #7
            filename => 't/data.rdb',
            x_col    => 'x',
            y_col    => 'y,z',
            yerr_col => 'err,err',
            xlabel   => 'range',
            ylabel   => 'data',
            title    => 'test: read x, multiple y, y_err from RDB file, w/ resid',
            residuals => 1,
        },
        { #8
            filename => 't/data.rdb',
            x_col    => 'x',
            y_col    => 'y,z',
            yerr_col => 'err,err',
            group_col=> 'group',
            xlabel   => 'range',
            ylabel   => 'data',
            title    => 'test: read x, multiple y, y_err from RDB file, GROUPED, with resid',
            residuals => 1,
        },
        { #9
            x_data      => [0..4],
            y_data      => \@arr,
            yerr_data   => \@err,
            legend_text => 'test0,test1,test2,test3,test4,test5,test6,test7,test8,test9',
            xrange      => '-1,5.3',
            yrange      => '-45,220',
            xlabel      => 'monkey',
            ylabel      => 'brains',
            title       => 'test: x_data, ref to multi y_data, xrange and yrange set',
        },
        { #10
            x_data      => \@a1,
            y_data      => [ \@b1,    \@c1    ],
            yerr_data   => [ \@berr1, \@cerr1 ],
            legend_text => 'LegendTestA,LegendTestB',
            title       => 'test: x_data and multiple y_data, yerr_data, w/ resids & xrange',
            xrange      => '-.5,9.5',
            residuals   => 1,
        },
        { #11
            x_data => \@p1,
            y_data => [ \@p2, \@p3 ],
            legend_text => 'TwoPwrSeries,ThreePwrSeries',
            title  => 'test: x_data and multiple y_data',
        },
        { #12
            x_data => \@p1,
            y_data => [ \@p2, \@p3 ],
            legend_text => 'TwoPwrSeries,ThreePwrSeries',
            title  => 'test: x_data and multiple y_data +resids',
            residuals => 1,
        },
        { #13
            x_data => \@p1,
            y_data => [ \@p2, \@p3 ],
            legend_text => 'TwoPwrSeries,ThreePwrSeries',
            title  => 'test: x_data and multiple y_data with xlog',
            xlog   => 1,
        },
        { #14
            x_data => \@p1,
            y_data => [ \@p2, \@p3 ],
            legend_text => 'TwoPwrSeries,ThreePwrSeries',
            title  => 'test: x_data and multiple y_data with xlog, ylog on',
            xlog   => 1,
            ylog   => 1,
        },
        { #15
            x_data => \@p1,
            y_data => [ \@p2, \@p3 ],
            legend_text => 'TwoPwrSeries,ThreePwrSeries',
            title  => 'test: x_data and multiple y_data with ylog on',
            ylog   => 1,
        },
        { #16
            x_data => \@p1,
            y_data => [ \@p3, \@p2 ],
            legend_text => 'ThreePwrSeries,TwoPwrSeries',
            title  => 'test: x_data and multiple y_data with ylog on',
            ylog   => 1,
            residuals => 1,
        },
        { #17
            x_data => \@p1,
            y_data => [ \@p2, \@p3 ],
            legend_text => 'TwoPwrSeries,ThreePwrSeries',
            title  => 'test: x_data and multiple y_data with ylog on, plus resid',
            ylog   => 1,
            residuals => 1,
        },
        { #18
            x_data => $pdlx1,
            y_data => [$pdly1, $pdly2],
            legend_text => 'sin,cos',
            title => 'direct pdl inputs: 1 x_pdl 2 y_pdls',
        },
        { #19
            x_data => $pdlx1,
            y_data => [$pdly1, $pdly2],
            residuals => 1,
            legend_text => 'pdl sin x,pdl cos x',
            title => 'direct pdl inputs: 1 x pdl, 2 y pdls, w/ resid',
        },
        { #20
            x_data => $pdlx1,
            y_data => [$pdly1, $pdly2],
            residuals => 1,
            title => 'direct pdl inputs: 1 x pdl, 2 y pdls, w/ resid and xlog ylog',
            xlog => 1,
            ylog => 1,
        },
        { #21
            x_data => $pdlx1 + .5,
            y_data => [$pdly1 + 2.5, $pdly2 + 2.5],
            title => 'direct pdl inputs: 1 x pdl, 2 y pdls w/ xlog ylog',
            xlog => 1,
            ylog => 1,
        },
        { #22
            x_data      => $pdlx1 + .5,
            y_data      => [$pdly1 + 2.5, $pdly2 + 2.5],
            yerr_data   => [$pdl_err1,    $pdl_err2],
            title => 'direct pdl inputs: 1 x pdl, 2 y pdls w/ xlog ylog, and errs',
            xlog => 1,
            ylog => 1,
        },
        { #23
            x_data      => $pdlx2,
            y_data      => [$pdly3,    $pdly4   ],
            yerr_data   => [$pdl_err3, $pdl_err4],
            title => 'direct pdl inputs: 1 x pdl, 2 y pdls w/ resids and errs',
            residuals => 1,
        },
        { #24
            x_data      => $pdlx2,
            y_data      => [$pdly3,    $pdly4   ],
            yerr_data   => [$pdl_err3, $pdl_err4],
            xlog => 1,
            ylog => 1,
            title => 'direct pdls: 2 y pdls, xlog, ylog, errs',
        },
        { #25
            x_data      => $pdlx2,
            y_data      => [$pdly3,    $pdly4   ],
            yerr_data   => [$pdl_err3, $pdl_err4],
            ylog => 1,
            residuals => 1,
            title => 'direct pdls: 2 y pdls, xlog, ylog, errs, & res',
        },
        { #26
            x_data      => $pdlx2 + .5,
            y_data      => [$pdly3 + 2.5, $pdly4 + 2.5],
            yerr_data   => [$pdl_err3,    $pdl_err4],
            title => 'direct pdls: 2 y pdls, xlog, errs, & res',
            xlog => 1,
            residuals => 1,
        },
        { #27
            x_data      => $pdlx1 + .5,
            y_data      => [$pdly1 + 2.5, $pdly2 + 2.5],
            yerr_data   => [$pdl_err2,    $pdl_err2],
            title => 'direct pdl inputs: 1 x pdl, 2 y pdls w/ errs and resid',
            residuals => 1,
        },
        { #28
            filename => 't/data.dat',
            split    => '\t',
            x_col     => 'x',
            y_col     => 'ylogtest',
            yerr_col  => 'ylogtest_err',
            ylog      => 1,
            group_col => 'group',
        },
        { #29
            filename => 't/data.dat',
            split    => '\t',
            x_col     => 'x',
            y_col     => 'ylogtest',
            yerr_col  => 'ylogtest_err',
            group_col => 'group',
        },
        { #30
            filename => 't/data.rdb',
            x_col     => 'x',
            y_col     => 'ylogtest',
            yerr_col  => 'ylogtest_err',
            ylog      => 1,
            group_col => 'group',
        },
        { #31
            filename => 't/data.rdb',
            x_col     => 'x',
            y_col     => 'ylogtest',
            yerr_col  => 'ylogtest_err',
            group_col => 'group',
        },
        { #32
            x_data    => $logx,
            y_data    => [$logy],
            yerr_data => [$loge],
        },
        { #33
            x_data    => $logx,
            y_data    => [$logy],
            yerr_data => [$loge],
            ylog => 1,
        },
        { #34
            x_data    => $logx,
            y_data    => [$logy,$logy2],
            yerr_data => [$loge,$loge ],
            residuals => 1,
        },
        { #35
            x_data    => $lowx,
            y_data    => [$lowy],
            yerr_data => [$lowe ],
            ylog      => 1,
        },
        { #36
            x_data    => $logx,
            y_data    => [$logy,$logy2],
            yerr_data => [$loge,$loge ],
            residuals => 1,
            xlabel    => "label for x axis",
            ylabel    => "label for y axis",
            title     => "title",
            subtitle  => "subtitle",
        },
        { #37
            x_data    => $logx,
            y_data    => [$logy,$logy2],
            yerr_data => [$loge,$loge ],
            residuals => 1,
            xlabel    => "label for x axis",
            ylabel    => "label for y axis",
            title     => "title",
            subtitle  => "subtitle",
            nopoints  => 1,
        },
        { #38
            x_data    => $logx,
            y_data    => [$logy,$logy2],
            yerr_data => [$loge,$loge ],
            residuals => 1,
            xlabel    => "label for x axis",
            ylabel    => "label for y axis",
            title     => "title",
            subtitle  => "subtitle",
            noline    => 1,
        },
        { #39
            x_data    => $logx,
            y_data    => [$logy,$logy2],
            yerr_data => [$loge,$loge ],
            residuals => 1,
            xlabel    => "label for x axis",
            ylabel    => "label for y axis",
            title     => "title",
            subtitle  => "subtitle",
            noline    => 1,
            nolegend  => 1,
        },
        { #40
            x_data    => $logx,
            y_data    => [$logy,$logy2],
            yerr_data => [$loge,$loge ],
            residuals => 1,
            xlabel    => "label for x axis",
            ylabel    => "label for y axis",
            title     => "title",
            subtitle  => "subtitle",
            noline    => 1,
            nolegend  => 1,
            residuals_size => .75,
        },
        { #41
            x_data    => $logx,
            y_data    => [$logy,$logy2],
            yerr_data => [$loge,$loge ],
            residuals => 1,
            xlabel    => "label for x axis",
            ylabel    => "label for y axis",
            title     => "axis displayed, no resids",
            subtitle  => "subtitle",
            nolegend  => 1,
            axis      => 1,
            xrange    => '-1,6',
            yrange    => '-10,18',
        },
        { #42
            x_data      => [0..4],
            y_data      => \@arr,
            yerr_data   => \@err,
            legend_text => 'test0,test1,test2,test3,test4,test5,test6,test7,test8,test9',
            xrange      => '-1,5.3',
            yrange      => '-50,500',
            xlabel      => 'monkey',
            ylabel      => 'brains',
            title       => 'axis with resids, no axis_resids',
            residuals   => 1,
            axis        => 1,
        },
        { #43
            x_data      => [0..4],
            y_data      => \@arr,
            yerr_data   => \@err,
            legend_text => 'test0,test1,test2,test3,test4,test5,test6,test7,test8,test9',
            xrange      => '-1,5.3',
            yrange      => '-50,500',
            xlabel      => 'monkey',
            ylabel      => 'brains',
            title       => 'axis with resids and axis_resids',
            residuals   => 1,
            axis        => 1,
            axis_residuals => 1,
        },
        { #44
            x_data      =>   \@axes_x,
            y_data      => [ \@axes_y1, \@axes_y2 ],
            residuals   => 1,
            axis        => 1,
            title       => 'axis with resids, no axis_resids',
        },
        { #45
            x_data        => \@axes_x,
            y_data        => [ \@axes_y1, \@axes_y2 ],
            residuals     => 1,
            axis          => 1,
            axis_residuals => 1,
            title         => 'axis with resids and axis_resids',
        },
        { #46
            x_data        => \@axes_x,
            y_data        => [ \@axes_y1, \@axes_y2 ],
            residuals     => 1,
            axis_residuals => 1,
            title         => 'just axis_resids',
        },
        { #47
            x_data        => \@axes_x,
            y_data        => \@axes_y1,
            title         => 'single y_data syntax w/ array',
        },
        { #48
            x_data        => $logx,
            y_data        => $logy,
            title         => 'single y_data syntax w/ pdls',
        },
        { #49
            x_data   => \@axes_x,
            y_data   => \@axes_y1,
            filename => 't/data.dat',
            split    => '\t',
            x_col    => 'x',
            y_col    => 'y,z',
            title         => 'x_data AND filename-- what will happen?',
        },
        #{ #50
        #    filename => 'stdin',
        #    split    => ',',
        #    x_col    => 'x',
        #    y_col    => 'y',
        #    title    => 'read from stdin.  Works, but how to make a testcase?',
        #},
    );
    return @pars;
}
