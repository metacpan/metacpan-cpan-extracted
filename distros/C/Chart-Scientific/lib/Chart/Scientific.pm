
package Chart::Scientific;

use warnings;
use strict;

require Exporter;

use Carp;
use Data::Dumper;
use PDL;
use PDL::NiceSlice;
use PDL::Graphics::PGPLOT;
use Tie::IxHash;

our @ISA = qw(Exporter);
our $VERSION = '0.16';

our @EXPORT_OK = qw/make_plot/;

# TODO: 
#    Add option to force display to a geometric square on the screen, so 
#      circles will appear circular
#    Add fuction-plotting ability.  Default it to nopoints
#    Class methods clear and restore_defaults don't work right (don't seem to 
#      reset the data associate with the instance!).
#


################################################################################
# Class methods:
#

sub make_plot {
    my $plotter = Chart::Scientific->new ( @_ );
    $plotter->plot ();
}

sub default_args {
    return {
        title            => '',
        subtitle         => undef,
        x_label          => '',
        y_label          => '',
        residuals_label  => '',
        residuals_pos    =>  0,
        nolegend         => 0,
        legend_location  => '.02,-.05',
        residuals_size   => 0.25,

        x_range          => undef,
        y_range          => undef,
        x_log             => 0,
        y_log             => 0,
        colors           => 'black,red,green,blue,cyan,magenta,gray',
        symbols          =>  [ 3, 0, 5, 4, 6..99 ],

        font             => '1',
        char_size        => '1',
        line_width       => '2',

        nopoints         => 0,
        noline           => 0,
        axis             => 0,
        axis_residuals   => 0,

        filename         => undef,
        split            => undef,

        device           => '/xs',
        only             => 'only',
        defaults         => 0,
        verbose          => 0,
        help             => 0,
        usage            => 0,
        version          => 0,
    };
}

# Class hash member and member method to determine if 
#   a given input is allowed or not:
#
our %legal_inputs = (
    axis            => 1,
    axis_residuals  => 1,
    char_size       => 1,
    colors          => 1,
    defaults        => 1,
   #derived_legend  => 1,
    device          => 1,
    filename        => 1,
    font            => 1,
    function        => 1,
    group_col       => 1,
    help            => 1,
    legend_location => 1,
    legend_text     => 1,
   #limits          => 1,
    line_width      => 1,
    nopoints        => 1,
    nolegend        => 1,
    noline          => 1,
   #only            => 1,
   #opts            => 1,
   #pdls            => 1,
   #PlotPosition    => 1,
   #points          => 1,
    residuals       => 1,
    residuals_label => 1,
    residuals_pos   => 1,
    residuals_size  => 1,
    split           => 1,
    subtitle        => 1,
    symbols         => 1,
    title           => 1,
    usage           => 1,
    verbose         => 1,
   #win             => 1,
#
#   [xy]_                 # [xy][^_] These should be fixed before testing now.
#
    x_col           => 1, # xcol      => 1,
    x_data          => 1, # xdata     => 1,
    x_label         => 1, # xlabel    => 1,
    x_log           => 1, # xlog      => 1,
    x_range         => 1, # xrange   => 1,
    y_col           => 1, # ycol      => 1,
    y_data          => 1, # ydata    => 1,
    y_err_col       => 1, # yerr_col  => 1,
    y_err_data      => 1, # yerr_data => 1,
    y_label         => 1, # ylabel    => 1,
    y_log           => 1, # ylog      => 1,
    y_range         => 1, # yrange    => 1,
);

our %depreciated_options = (
    # These options originally had this spelling, instead of [xy]_.
    #    It was inconsistent and confusing!
    #
    xlabel    => 1,
    xlog      => 1,
    xrange    => 1,
    yerr_col  => 1,
    yerr_data => 1,
    ylabel    => 1,
    ylog      => 1,
    yrange    => 1,
);

sub is_legal_input {
    return exists $legal_inputs{ $_[0] };
}

sub is_depreciated_option {
    return exists $depreciated_options{ $_[0] };
}

sub newstyle_option {
    my ( $option_name ) = @_;
    substr ( $option_name, 1, 0, "_" );
    return $option_name;
}

################################################################################
# Object methods:
#

sub new {
    my $proto = shift;
    my $class = ref ( $proto ) || $proto;
    my @args  = @_;

    # Set defaults:
    #
    my $self = default_args ();
    bless $self, $class;

    # Use the initial arguments to set up member variables:
    #
    $self->setvars ( @args );
    $self->massage_args ();

    $self->read_points () if !$self->points_loaded () && !$self->pdls_loaded ();
    $self->make_pdls   () if  $self->points_loaded () && !$self->pdls_loaded ();
    $self->make_pdl_residuals () if $self->{residuals};

    return $self;
}

sub clear {
    my $self = shift () or die "no self";
    $self = {};
}

sub restore_defaults {
    my $self = shift () or die "no self";
    $self = default_args ();
}

sub DESTROY {
    my $self = shift () or die "no self";
    undef $self;
}

sub points_loaded {
    my $self = shift () or die "no self in points_loaded";
    return defined $self->{points};
}

sub pdls_loaded {
    my $self = shift () or die "no self in pdls_loaded";
    return defined $self->{pdls};
}

sub setvars {
    my $self = shift () or die "no self";
    my @args = @_;

    while ( @args ) {
        my $arg = shift ( @args );

        if ( 'HASH' ne ref $arg ) {
            $arg = newstyle_option ( $arg )
                if is_depreciated_option ( $arg );
            die "Attempting to set illegal data member $arg\n"
                if ! is_legal_input ( $arg );
            $self->{$arg} = shift ( @args );
        }
        else {
            foreach ( keys %$arg ) {
                my $new_key = is_depreciated_option ( $_ )
                                  ? newstyle_option ( $_ ) 
                                  : $_;

                die "Attempting to set illegal data member $_\n"
                    if ! is_legal_input ( $new_key );
                $self->{$new_key} = $arg->{$_};
            }
        }
    }
    $self->death_or_help_if_necessary ();
}

sub death_or_help_if_necessary {
    my $self = shift () or die "no self";

    die "Chart::Scientific version $VERSION"
        if $self->{version};

    die "Cannot specify x_data/y_data if filename has been specified"
        if $self->{filename} && 
           exists $self->{y_data};

    die "Must specify y_data if filename has not been specified " .
        "(are you trying to call the constructor without plot data?)\n"
        if ! defined $self->{y_data} && 
           ! $self->{filename};

    # Die if defaults are requested
    #
    die Data::Dumper->Dump( [ $self ], [ qw( Chart::Scientific ) ] ),
       "Printing defaults and exiting on user request"
            if $self->{defaults};

    help ( 1 ) if $self->{help};
    help ( 2 ) if $self->{usage};
}

sub getvars {
    croak 'usage : $p->getvars( $var )'
        if scalar @_ < 2;
    my ( $self, @vars ) = @_;
    return map { $self->{$_} } @vars;
}

sub read_points {
    my $self = shift () or die "no self in read_points";

    # If we're here, we must be reading from a file:
    #
    die "Can't find $self->{filename}"
        if not ( -f $self->{filename} || 'stdin' eq $self->{filename} );

    # If $self->{split} has been specified, assume the data file is delimitted
    #   by that.  Otherwise, assume it's a RDB (or tab-delimitted) file:
    #
    ( defined $self->{split} )
        ? $self->read_file ()
        : $self->read_RDB  ();

    print "read-in points: ", Dumper $self->{points}, "\n",
          "Legend array: ",   Dumper $self->{derived_legend}
              if $self->{verbose} > 1;
}

sub read_RDB {
    my $self = shift () or die "no self in read_RDB";

    print "reading with RDB.pm\n"
        if $self->{verbose} > 0;

    my $rdb = RDB->new ( $self->{filename} )
                  or die "RDB open failed on file '$self->{filename}' $!";

    my $r_line  = {};

    $self->{derived_legend} = {};
    tie %{$self->{derived_legend}}, "Tie::IxHash";

    # Read each line of the RDB file, and stuff it into the
    #   $self->{points}{$group_col}[$i] structure:
    #
    while ( $rdb->read( $r_line ) ) {

        my $brk = ( defined $self->{group_col} )
                      ? $r_line->{$self->{group_col}}
                      : $self->{only};

        push @{$self->{points}{$brk}{x}}, $r_line->{$self->{x_col}};

        foreach ( 0 .. scalar @{$self->{y_col}} - 1 ) {

            print "read: $_ $r_line->{$self->{y_col}[$_]} $self->{y_col}[$_]\n"
                if $self->{verbose} > 3;

            push @{$self->{points}{$brk}{y}[   $_]},
                 $r_line->{$self->{y_col}[   $_]};
            push @{$self->{points}{$brk}{y_err}[$_]},
                 $r_line->{$self->{y_err_col}[$_]}
                     if defined $self->{y_err_col};

            my $leg_key = $self->{y_col}[$_];
            $leg_key .= $brk
                if $brk ne $self->{only};

            $self->{derived_legend}{$leg_key} = 1;
        }
    }
    $self->{derived_legend} = [ keys %{$self->{derived_legend}} ];
}

sub get_fh {
    my $self = shift () or die "no self";

    # If a filename is given, read from it; otherwise, read from STDIN:
    #
    my $fh;
    if ( 'stdin' eq $self->{filename} ) {
        $fh = 'STDIN';
    }
    else {
        open $fh, $self->{filename} or die "can't open $self->{filename}: $!"
            if $self->{filename} ne 'stdin';
    }
    return $fh;
}

sub read_file {
    my $self = shift () or die "no self in read_file";

    print "reading from regular file\n"
        if $self->{verbose} > 0;

    my ( $fh, @col_names, %col_number ) = ( $self->get_fh (), (), () );
    $self->{derived_legend} = {};
    tie %{$self->{derived_legend}}, "Tie::IxHash";

    while ( <$fh> ) {
        next if /^#/ || /^[#SNM\t]+$/; # skip comments and definition lines (if
                                       #    you're kludge-reading an RDB file)

        chomp ( my @vals = split /$self->{split}/, $_ );
        die "Split returned less than 2 items per line-- abort!\n"
            if 2 > scalar @vals;

        # Read in the names from the first line, if applicable:
        #
        if ( 0 == scalar @col_names ) {
            @col_names  = @vals;
            %col_number = map {$col_names[$_] => $_} 0..scalar @col_names-1;
            next;
        }
        my $brk =  ( defined $self->{group_col} )
                      ? $vals[ $col_number{ $self->{group_col} } ]
                      : $self->{only};
        push @{$self->{points}{$brk}{x}},
             $vals[ $col_number{ $self->{x_col} } ];

        foreach ( 0 .. scalar @{$self->{y_col}} - 1 ) {
            my $cur_ycol = $col_number{ $self->{y_col}[$_] };
            my $cur_ecol = $col_number{ $self->{y_err_col}[$_] }
                if defined $self->{y_err_col};

            push @{$self->{points}{$brk}{y}[   $_]}, $vals[ $cur_ycol ];
            push @{$self->{points}{$brk}{y_err}[$_]}, $vals[ $cur_ecol ]
                if defined $self->{y_err_col};

            my $leg_key = $self->{y_col}[$_] .
                          ( $brk eq $self->{only} ? "" : ", $brk:" );
            $self->{derived_legend}{$leg_key} = 1;
        }
    }
    $self->{derived_legend} = [ keys %{$self->{derived_legend}} ];

    close $fh if $self->{filename} ne 'stdin';
}

sub plot {
    my $self = shift () or die "no self in draw_points";

    $self->make_pdls () if ! $self->pdls_loaded ();
    $self->make_pdl_residuals () if $self->{residuals};
    $self->logify_pdls () if $self->{x_log} || $self->{y_log};

    $self->setup_win  ();
    $self->get_limits ( 0 );
    $self->set_window ();

    $self->points_draw_loop ( );

    my $font_charsize_opts = {
        Font      => $self->{font},
        HardFont  => $self->{font},
        CharSize  => $self->{char_size},
        HardCH    => $self->{char_size},
    };
    $self->{win}->label_axes (
        ( defined $self->{residuals}
              ? ( "",      @{$self}{'y_label','title'} )
              : ( @{$self}{'x_label','y_label','title'} ) ),
        $font_charsize_opts
    );
    PGPLOT::pgmtxt ( 'T', 0.5, 0.5, 0.5, $self->{subtitle} )
        if defined $self->{subtitle};

    $self->write_legend () if ! $self->{nolegend};

    $self->plot_residuals ( $font_charsize_opts )
        if defined $self->{residuals};

    $self->{win}->close ();
}

sub plot_residuals {
    my $self = shift () or die "no self";
    my $font_charsize_opts = shift () or die "no font_charsize_opts";

    # Draw the residuals:
    #
    $self->get_limits ( 1 );
    $self->set_window ( 1 );

    $self->points_draw_loop( 1 );
    $self->{win}->label_axes (
        $self->{x_label},
        $self->{residuals_label},
        $font_charsize_opts
    );
}

sub points_draw_loop {
    my $self = shift () or die "no self";
    my $bRes = shift () || 0;

    my $opt_num = 0;
    my @syms = @{$self->{symbols}};
    my @colors = split /,/, $self->{colors};

    my ( $y_key, $e_key ) = $bRes ? qw/res_data res_errs/
                                  : qw/  y_data   y_errs/;

    foreach my $brk ( sort keys %{$self->{pdls}{x_data}} ) {
        foreach ( 0 .. scalar @{$self->{pdls}{$y_key}{$brk}} - 1 ) {

            $self->{opts}{pt_col}[$opt_num] =$colors[$opt_num % scalar @colors];
            $self->{opts}{symbol}[$opt_num] =$syms[  $opt_num % scalar @syms  ];
            $self->{opts}{ln_col}[$opt_num] =$colors[$opt_num % scalar @colors];
            $self->{opts}{ln_sty}[$opt_num] =1 + $opt_num % 5;

            my $pointsopt = { color     => $self->{opts}{pt_col}[$opt_num],
                              symbol    => $self->{opts}{symbol}[$opt_num],
                              linewidth => $self->{line_width} };
            my $lineopt   = { color     => $self->{opts}{ln_col}[$opt_num],
                              linestyle => $self->{opts}{ln_sty}[$opt_num],
                              linewidth => $self->{line_width} };

            my @plot_data = ( $self->{pdls}{x_data}{$brk},
                              $self->{pdls}{$y_key}{$brk}[$_] );
            my @errs_data;
            if  (  exists $self->{pdls}{$e_key} &&
                  defined $self->{pdls}{$e_key}{$brk}[$_] )
            {
                @errs_data = ( $self->{pdls}{$y_key}{$brk}[$_] -
                               $self->{pdls}{"${e_key}_lo"}{$brk}[$_],

                               $self->{pdls}{"${e_key}_hi"}{$brk}[$_] -
                               $self->{pdls}{$y_key}{$brk}[$_]  );
            }

            $self->{win}->line  ( @plot_data, $lineopt  ) if !$self->{noline};
            $self->{win}->points( @plot_data, $pointsopt) if !$self->{nopoints};
            $self->{win}->errb  ( @plot_data,
                                  undef,undef,
                                  @errs_data,
                                  $lineopt )
                if  exists $self->{pdls}{$e_key} &&
                   defined $self->{pdls}{$e_key}{$brk}[$_];
            ++$opt_num;
        }
        last if $bRes;
    }
}

sub make_pdls {
    my $self = shift () or die "no self in make_pdls";

    # Do x, y, and y_err:
    #
    foreach my $brk ( sort keys %{$self->{points}}) {
        $self->{pdls}{x_data}{$brk} = pdl $self->{points}{$brk}{x};

        foreach ( 0 .. scalar @{$self->{points}{$brk}{y}} - 1 ) {
            push @{$self->{pdls}{y_data}{$brk}},
                 pdl $self->{points}{$brk}{y}[$_];
            if ( defined $self->{y_err_col}[$_] ||
                 exists $self->{points}{$brk}{y_err}[$_] )
            {
                push @{$self->{pdls}{y_errs}{$brk}},
                     pdl $self->{points}{$brk}{y_err}[$_];
                push @{$self->{pdls}{y_errs_hi}{$brk}},
                     $self->{pdls}{y_data}{$brk}[-1] +
                     $self->{pdls}{y_errs}{$brk}[-1];
                push @{$self->{pdls}{y_errs_lo}{$brk}},
                     $self->{pdls}{y_data}{$brk}[-1] -
                     $self->{pdls}{y_errs}{$brk}[-1];
            }
        }
    }
    print Dumper $self->{pdls};
}

sub make_pdl_residuals {
    my $self = shift () or die "no self in make_pdl_residuals";

    die "No pdls exist in make_pdl_residuals"
        if ! $self->pdls_loaded ();

    my $first_key = (keys %{$self->{pdls}{y_data}})[0];
    my $nPdls = scalar @{$self->{pdls}{y_data}{$first_key}};

    # If there are two or more columns of y data, do the residuals between
    #    the first and the second columns.  Otherwise, use the grouping
    #    column, and make the residuals be between the first group and
    #    the second group.  If there is only one column of y-data, and
    #    the grouping flag hasn't been specified, we're in a world of
    #    hurt, and something's wrong in massage_args.
    #
    if ( $nPdls > 1 ) {
        $self->make_pdl_residuals_multicolumn ();
    }
    # Group column version-- need to interpolate set 1 to get to set 2:
    #
    elsif ( defined $self->{group_col} )  {
        $self->make_pdl_residuals_grouped ();
    }
    else {
        die "Panic in make_pdl_residuals.";
    }
}

sub make_pdl_residuals_multicolumn {
    my $self = shift () or die "no self";

    foreach my $brk ( sort keys %{$self->{pdls}{y_data}} ) {
        $self->{pdls}{res_data}{$brk} = [
            $self->{pdls}{y_data}{$brk}[0] -
            $self->{pdls}{y_data}{$brk}[1]
        ];

        # If there are errors, add them in quadrature:
        #
        if ( defined $self->{pdls}{y_errs}{$brk}[0] &&
             defined $self->{pdls}{y_errs}{$brk}[0]  )
        {
            $self->{pdls}{res_errs}{$brk} = undef;
            $self->{pdls}{res_errs}{$brk} = [
                sqrt ( $self->{pdls}{y_errs}{$brk}[0]**2 +
                       $self->{pdls}{y_errs}{$brk}[1]**2   )
            ];
            $self->{pdls}{res_errs_lo}{$brk} = [
                $self->{pdls}{res_data}{$brk}[0] -
                $self->{pdls}{res_errs}{$brk}[0],
            ];
            $self->{pdls}{res_errs_hi}{$brk} = [
                $self->{pdls}{res_data}{$brk}[0] +
                $self->{pdls}{res_errs}{$brk}[0],
            ];
        }
    }
}

sub make_pdl_residuals_grouped {
    my $self = shift () or die "no self";

    my @brk = ( sort keys %{$self->{points}} )[0..1];

    foreach ( 0 .. scalar @{$self->{pdls}{y_data}{$brk[0]}} - 1 ) {
        $self->{pdls}{res_data}{$brk[0]}[$_]  =
            ( interpolate (
                  $self->{pdls}{x_data}{$brk[1]},
                  $self->{pdls}{x_data}{$brk[0]},
                  $self->{pdls}{y_data}{$brk[0]}[$_]
              )
            )[0] - $self->{pdls}{y_data}{$brk[1]}[$_];
        if ( $self->{pdls}{y_errs} ) {
            $self->{pdls}{res_errs}{$brk[0]}[$_] =
              $self->{pdls}{y_errs}{$brk[0]}[$_];
            $self->{pdls}{res_errs_lo}{$brk[0]}[$_] =
                 $self->{pdls}{y_data}{$brk[0]}[$_] -
                 $self->{pdls}{y_errs}{$brk[0]}[$_];
            $self->{pdls}{res_errs_hi}{$brk[0]}[$_] =
                 $self->{pdls}{y_errs}{$brk[0]}[$_] +
                 $self->{pdls}{y_errs}{$brk[0]}[$_];
        }
    }
    $self->{pdls}{res_data}{$brk[1]} = $self->{pdls}{res_data}{$brk[0]};
}

sub setup_win {
    my $self = shift () or die "no self in setup_win";

    $self->{win} =
        PDL::Graphics::PGPLOT::Window->new (
            Device     => $self->{device},
            WindowName => "plot created by $0",
            AxisColor  => 'black',
            Color      => 'black',
            Font       => $self->{font},
            HardFont   => $self->{font},
            CharSize   => $self->{char_size},
            HardCH     => $self->{char_size},
        );
}

sub set_window {
    my $self = shift () or die "no self in set_window";
    my $iWin = shift () || 0;

    my @env_pars = (
        @{$self->{limits}{x}}{'lo','hi'},
        @{$self->{limits}{y}}{'lo','hi'},
        {
            PlotPosition => $self->{PlotPosition}[$iWin],
            Axis         => [ 'BCNST', 'BCMSTV' ],
        }
    );

    if ( 0 == $iWin ) { # main window
        $env_pars[-1]{Axis} = [ "BCST", "BCSTNV" ]
            if $self->{residuals};

        if ( $self->{axis} ) {
            $env_pars[-1]{Axis}[0] .= 'A';
            $env_pars[-1]{Axis}[1] .= 'A';
        }
    }
    else { # residual window
        if ( $self->{residuals} ) {
            if ( $self->{axis_residuals} ) {
                $env_pars[-1]{Axis}[0] .= 'A';
                $env_pars[-1]{Axis}[1] .= 'A';
            }
        }
    }

    $env_pars[-1]{Axis}[0] .= 'L' if $self->{x_log};
    $env_pars[-1]{Axis}[1] .= 'L' if $self->{y_log};

    $env_pars[-1]{Axis}[1] =~ s/M/N/
        if ! $self->{residuals_pos};

    $self->{win}->env ( @env_pars );
}

sub write_legend {
    my $self = shift () or die "no self in write_legend";

    my @loc = ( $self->{limits}{x}{lo}, $self->{limits}{y}{hi} );

    my @deltas = ( $self->{limits}{x}{hi} - $self->{limits}{x}{lo},
                   $self->{limits}{y}{hi} - $self->{limits}{y}{lo} );

    @{$self->{legend_location}} = [ .1, -.1 ]
        if ! $self->{legend_location};

    @loc = map { $loc[$_] + $self->{legend_location}[$_] * $deltas[$_] } 0..1;

    # Legend Usage:
    #
    # [ names ],
    # x,y
    # { option hash }
    #
    my $text = ( $self->{legend_text}
                   ? $self->{legend_text}
                   : $self->{derived_legend} );
    $self->{win}->legend (
        $text, @loc,
        {
            LineStyle => $self->{opts}{ln_sty},
            Color     => $self->{opts}{ln_col},
        },
    );
    $self->{win}->legend (
        $text, @loc,
        {
            Symbol    => $self->{opts}{symbol},
            LineStyle => $self->{opts}{ln_sty},
            Color     => $self->{opts}{ln_col},
            LineWidth => [ 50, 50 ],
            TextShift => 0,
            Font      => $self->{font},
            HardFont  => $self->{font},
            CharSize  => $self->{char_size},
            HardCH    => $self->{char_size},
            Fraction  => 0.5,
        }
    );
}

sub logify_pdls {
    my $self = shift () or die "no self";

    if ( $self->{x_log} ) {
        foreach ( keys %{$self->{pdls}{x_data}} ) {
            $self->{pdls}{x_data}{$_}->inplace->log10;
        }
    }

    if ( $self->{y_log} ) {
        foreach my $y_type ( $self->all_ydata_names ()  ) {
            foreach my $brk ( keys %{$self->{pdls}{$y_type}} ) {
                foreach ( @{$self->{pdls}{$y_type}{$brk}} ) {
                    $_->inplace->log10;
                }
            }
        }
    }

    # Get the indices for finite-everywhere elements use only those
    #   elements from ALL piddles:
    #
    my $fin_indx = $self->get_finite_indices ();

    $self->{pdls}{x_data}{$_} = $self->{pdls}{x_data}{$_}->( $fin_indx )
        foreach keys %{$self->{pdls}{x_data}};

    foreach my $y_type ( $self->all_ydata_names () ) {
        foreach my $brk ( keys %{$self->{pdls}{$y_type}} ) {
            foreach ( @{$self->{pdls}{$y_type}{$brk}} ) {
                $_ = $_->( $fin_indx );
            }
        }
    }
}

sub all_ydata_names {
    my $self = shift () or die "no self";
    return grep { $_ ne 'x_data' } keys %{$self->{pdls}};
}

sub get_finite_indices {
    my $self = shift () or die "no self";

    # Make a mask that includes only elements where the piddle elements are
    #    finite in all piddles.
    #
    my $size = $self->first_x_pdl_size ();
    my $finite_mask = ones ( $size );

    $finite_mask = $finite_mask & $self->{pdls}{x_data}{$_}->isfinite
        foreach keys %{$self->{pdls}{x_data}};

    foreach my $y_type ( $self->all_ydata_names () ) {
        foreach my $brk ( keys %{$self->{pdls}{$y_type}} ) {
            foreach ( @{$self->{pdls}{$y_type}{$brk}} ) {
                $finite_mask = $finite_mask & $_->isfinite;
            }
        }
    }
    my $inds = $finite_mask->which;

    print STDERR "Negative data excluded after logarithm\n"
        if $self->{verbose} >= 0  &&
           $size != $inds->nelem  &&
           ($self->{y_log} || $self->{x_log});
    die "None of the data is finite after logarithm operation-- quitting."
        if $inds->nelem < 1;

    return $inds;
}

sub first_x_pdl_size {
    my $self = shift () or die "no self";
    my $key = (keys %{$self->{pdls}{x_data}})[0];
    return $self->{pdls}{x_data}{$key}->nelem;
}

sub has_errs {
    my $self  = shift () or die "no self";
    my ( $brk, $e_key ) = @_;

    return  exists $self->{pdls}{$e_key} &&
           defined $self->{pdls}{$e_key}{$brk}[$_];
}

sub get_ylimits {
    my $self = shift () or die "no self";
    my ( $y_key, $e_key, $brk, $i ) = @_;

    my %y_data = (
        lo => $self->{pdls}{$y_key}{$brk}[$i]->copy,
        hi => $self->{pdls}{$y_key}{$brk}[$i]->copy,
    );
    if ( $self->has_errs ( $brk, $e_key ) ) {
        $y_data{lo} = $self->{pdls}{"${e_key}_lo"}{$brk}[$i]->copy;
        $y_data{hi} = $self->{pdls}{"${e_key}_hi"}{$brk}[$i]->copy;
    }

    return ( $y_data{lo}->min, $y_data{hi}->max )
        if not defined $self->{x_range};

    return (
        where (
            $y_data{lo},
            ( $self->{pdls}{x_data}{$brk} > $self->{x_range}[0] ) &
            ( $self->{pdls}{x_data}{$brk} < $self->{x_range}[1] )
        )->min(),
        where (
            $y_data{hi},
            ( $self->{pdls}{x_data}{$brk} > $self->{x_range}[0] ) &
            ( $self->{pdls}{x_data}{$brk} < $self->{x_range}[1] )
        )->max()
    );
}

sub limits_exist {
    my $self = shift () or die "no self";
    my $axis = shift () or die "no axis in limits_exist";
    return exists $self->{limits}{$axis};
}

sub try_new_limits {
    my $self = shift () or die "no self";
    my ( $axis, @vals ) = @_;

    foreach ( @vals ) {
        if ( ! $self->limits_exist ( $axis ) ) {
            $self->{limits}{$axis}{lo} = $_;
            $self->{limits}{$axis}{hi} = $_;
        }
        else {
            $self->{limits}{$axis}{lo} = $_ if $_ < $self->{limits}{$axis}{lo};
            $self->{limits}{$axis}{hi} = $_ if $_ > $self->{limits}{$axis}{hi};
        }
    }
}

sub get_limits {
    my $self      = shift () or die "no self";
    my $bRes = shift () || 0;

    $self->{limits} = undef if 0 != $bRes;
    # Format of limits data member: $self->{limits}{x,y}{lo,hi}
    #
    # Get data extremes, and make them the limits:
    #
    my @brks = sort keys %{$self->{pdls}{x_data}};
    @brks = @brks[0,1]
        if $bRes && $self->{group_col};
    my ( $y_key, $e_key ) = $bRes ? qw/res_data res_errs/
                                  : qw/  y_data   y_errs/;

    foreach my $brk ( @brks ) {
        $self->try_new_limits (
            'x',
            $self->{pdls}{x_data}{$brk}->min,
            $self->{pdls}{x_data}{$brk}->max,
        );

        foreach ( 0 .. scalar @{$self->{pdls}{$y_key}{$brk}} - 1 ) {
            $self->try_new_limits (
                'y',
                $self->get_ylimits ( $y_key, $e_key, $brk, $_ )
            );
        }
    }
    $self->pad_limits ();
}

sub limits {
    my $self = shift () or die "no self";
    return $self->{limits};
}

sub limits_width {
    my ( $self, @axes ) = @_;
    return map {
               die "No limits for $_"
                   if ! exists $self->{limits}{$_};
               $self->{limits}{$_}{hi} -
               $self->{limits}{$_}{lo}
           } @axes;
}

sub pad_limits {
    my $self = shift () or die "no self";

    my ( $dx, $dy ) = map { $_/10.0 } $self->limits_width ( 'x', 'y' );

    # Pad limits to create pleasing margins:
    #
    $self->{limits}{x}{lo} -= $dx;
    $self->{limits}{x}{hi} += $dx;
    $self->{limits}{y}{lo} -= $dy;
    $self->{limits}{y}{hi} += $dy;

    # Override if user-specified limits exist:
    #
    if ( defined $self->{x_range} ) {
        $self->{limits}{x}{lo} = $self->{x_range}[0];
        $self->{limits}{x}{hi} = $self->{x_range}[1];
    }
    if ( defined $self->{y_range} ) {
        $self->{limits}{y}{lo} = $self->{y_range}[0];
        $self->{limits}{y}{hi} = $self->{y_range}[1];
    }

    # Give a 2-unit range is either axis's range is zero:
    #
    my $epsilon = 1.0e-9;
    if ( not defined $self->{x_range} &&
         $self->limits_width ( 'x' ) < $epsilon )
    {
        $self->{limits}{x}{lo} -= .1;
        $self->{limits}{x}{hi} += .1;
    }
    if ( not defined $self->{y_range} &&
         $self->limits_width ( 'y' ) < $epsilon )
    {
        $self->{limits}{y}{lo} -= .1;
        $self->{limits}{y}{hi} += .1;
    }
}


sub massage_args {
    my $self = shift () or die "no self";

    # Package single y_data values in an array to allow y_data => $y_pdl
    #    syntax instead of cumbersome y_data => [ $y_pdl ]
    #
    $self->{y_data} = [ $self->{y_data} ]
        if $self->single_y_data ();

    $self->setup_RDB_split () if not defined $self->{split};
    $self->read_nonfile_points () if defined $self->{x_data};

    # Split data params on commas if they are defined:
    #
    foreach ( qw/y_col y_err_col x_range y_range legend_location legend_text/ ) {
        $self->{$_} = [ split /,/, $self->{$_} ]
            if  exists $self->{$_} &&
               defined $self->{$_};
    }

    die "Must have two y data columns or a group_col column to use residuals"
        if $self->{residuals} &&
           ( grep { defined $self->{$_} &&
                    scalar @{$self->{$_}} < 2 } qw/y y_data/ )
           && not defined $self->{group_col};

    $self->deduce_x_y_names ();
    $self->set_plot_position ();

    if ( $self->{filename} ) {
        $self->setvars ( x_label => "$self->{x_col}"    )
            if '' eq $self->{x_label};
        $self->setvars ( y_label => "@{$self->{y_col}}" )
            if '' eq $self->{y_label};
    }
    else {
        die "The x_col and y_col parameters are used only with the filename " .
            "parameter.  See the docs for examples."
            if $self->{x_col} || $self->{y_col};
    }

    $self->{residuals_label} = "deltas"
        if '' eq $self->{residuals_label};

    $self->setup_title ();
    $self->setup_subtitle ();

    print Dumper $self
        if $self->{verbose} > 3;
}

sub single_y_data {
    my $self = shift () or die "no self";

    return   'PDL' eq ref $self->{y_data} ||
           'ARRAY' eq ref $self->{y_data} &&
                '' eq ref $self->{y_data}[0];
}

sub get_nonfile_points_datatype {
    my $self = shift () or die "no self";

    # Determine if given data are array refs or pdls, and make sure they're
    #   all the same kind:
    #
    my %refs;
    $refs{ ref $_ } = 1 foreach $self->{x_data}, @{$self->{y_data}};
    my @datatypes = keys %refs;

    die "x_data, y_data must all be the same datatype"
        if 1 != scalar @datatypes;
    die "x_data, y_data items must be either pdls or array refs"
        if 'ARRAY' ne $datatypes[0] && 'PDL' ne $datatypes[0];

    return $datatypes[0];
}

sub read_nonfile_points {
    my $self = shift () or die "no self";

    # Read data given with the x_data, y_data[, y_err_data] arguments.
    #
    die "no x_data given.  shouldn't be here!"
        if not exists $self->{x_data};
    die "if x_data is given, y_data must be given"
        if not exists $self->{y_data};

    # TODO: add support for multi-group data input, which will have
    #   to be in the form: x_data => [\@x1,\@x2], y_data => [\@y1,\@y2]
    #
    my $brk = $self->{only};

    my $datatype = $self->get_nonfile_points_datatype ();

    if ( 'ARRAY' eq $datatype ) {
        $self->{points}{$brk}{x} = [ @{$self->{x_data}} ];
        foreach (0 .. scalar @{$self->{y_data}} - 1) {
            $self->{points}{$brk}{y}[$_]     = [ @{$self->{y_data}[$_]}    ];
            $self->{points}{$brk}{y_err}[$_] = [ @{$self->{y_err_data}[$_]} ]
                if defined $self->{y_err_data};
        }
    }
    elsif ( 'PDL' eq $datatype ) {
        $self->{pdls}{x_data}{$brk} = $self->{x_data}->copy;
        foreach (0 .. scalar @{$self->{y_data}} - 1) {
            $self->{pdls}{y_data}{$brk}[$_] = $self->{y_data}[$_]->copy;
            if ( defined $self->{y_err_data} &&
                     defined $self->{y_err_data}[$_] )
            {
                $self->{pdls}{y_errs}{$brk}[$_] = $self->{y_err_data}[$_]->copy;
                $self->{pdls}{y_errs_hi}{$brk}[$_] =
                    $self->{pdls}{y_data}{$brk}[$_] +
                    $self->{pdls}{y_errs}{$brk}[$_];
                $self->{pdls}{y_errs_lo}{$brk}[$_] =
                    $self->{pdls}{y_data}{$brk}[$_] -
                    $self->{pdls}{y_errs}{$brk}[$_];
            }
        }
    }
    else {
        die "in read_nonfile_points: this should NEVER be reached";
    }
    $self->{derived_legend} = ( defined $self->{y_col} )
                                  ? [ split /,/, $self->{y_col} ]
                                  : [ map { "y$_" }
                                          0..scalar @{$self->{y_data}} - 1 ];
}

sub set_plot_position {
    my $self = shift () or die "no self";

    my $height = $self->{residuals_size} * ( 0.90 - 0.10 ) + 0.10;
    $self->{PlotPosition} = [ [ 0.1, 0.9, 0.1, 0.9 ] ];

    if ( defined $self->{residuals} ) {
        $self->{PlotPosition} = [ 
            [ 0.1, 0.9, $height, 0.9 ],
            [ 0.1, 0.9, 0.1, $height ] 
        ];
    }
}

sub setup_title {
    my $self = shift () or die "no self";

    if (     exists $self->{x_data} &&
             exists $self->{y_data} &&
         not exists $self->{x_col}  &&
         not exists $self->{y_col}   )
    {
        $self->{x_col} = "x";
        $self->{y_col} = [ map { "y$_" }
                           0 .. scalar @{$self->{y_data}} - 1 ];
    }
    if ( '' eq $self->{title} ) {
        $self->{title}  = "@{$self->{y_col}} vs $self->{x_col}";
        $self->{title} .= " grouped by $self->{group_col}"
            if $self->{group_col};
    }
}

sub setup_subtitle {
    my $self = shift () or die "no self";
    if ( defined $self->{subtitle} ) {
        eval { require PGPLOT };
        if ( my $err = $@ ) {
            $self->{title} .= $self->{subtitle};
            undef $self->{subtitle};
            print STDERR "$err: PGPLOT.pm not found.  PGPLOT.pm is ",
                         "required for subtitles.  The subtitle text ",
                         "will be appended to title.\n";
        }
    }
}

# Determine if user wants to use RDB.pm.  Include it if it exists,
#   otherwise, set split to '\t', warn user, and hope for the best.
#
sub setup_RDB_split {
    my $self = shift () or die "no self";
    if ( not defined $self->{split} ) {
        eval { require RDB };
        if ( $@ ) {
            $self->{split} = "\t";
            print STDERR "RDB.pm not found, splitting on tabs.\n"
                if $self->{verbose} > 0;
        }
    }
}

sub deduce_x_y_names {
    my $self = shift () or die "no self";

    # Return if there isn't a filename (passing data in directly) or if the x
    #   and y names are already defined:
    #
    return if !$self->{filename} ||
              defined $self->{x_col} && defined $self->{y_col} ||
              defined $self->{x_col} && defined $self->{y_col};

    # If the data is coming from STDIN, write it to a file to grab the
    #   header.  There's GOT to be a better way to do this.
    #
    my $tmpfile = '.plot.hdr';
    if ( 'stdin' eq $self->{filename} ) {
        open my $write_fh, '>', $tmpfile;
        print $write_fh $_ while <>;
        close $write_fh;
        $self->{filename} = $tmpfile;
    }

    # Read in the first non-commented line as $definition_line.
    #
    open my $fh, $self->{filename};
    my $definition_line = '#';
    chomp ( $definition_line = <$fh> )
        while $definition_line =~ /^\s*#/;
    close $fh;

    # Parse out the column names, Non-RDB file case:
    #
    if ( defined $self->{split} ) {
        $self->{x_col} =   ( split /$self->{split}/, $definition_line )[0];
        $self->{y_col} = [ ( split /$self->{split}/, $definition_line )[1] ];
    }
    # Parse out the column names, RDB file case:
    #
    else {
        $self->{x_col} =   ( split /\t/, $definition_line )[0];
        $self->{y_col} = [ ( split /\t/, $definition_line )[1] ];
    }
}

sub help {
    my ( $verbose ) = @_;
    require IO::Page;
    require Pod::Usage;
    Pod::Usage::pod2usage ( { -exitval => 0, -verbose => $verbose } );
}

1;

=pod

=head1 NAME

Chart::Scientific - Generate simple 2-D scientific plots with logging, errbars, etc.

=head1 SYNOPSIS

=head2 Procedural interface

    use Chart::Scientific qw/make_plot/;
    make_plot ( x_data => \@x_values, y_data => \@yvalues );

The subroutine make_plot creates a Chart::Scientific object
passing along every argument it was given.  See B<OPTIONS> below
for a full list of allowed arguments.

=head2 Object Oriented interface

Plot data from two arrays:

    use Chart::Scientific;
    my $plt = Chart::Scientific->new (
        x_data => \@x_values,
        y_data => \@y_values,
    );
    $plt->plot ();

or piddles:

    use Chart::Scientific;
    my $plt = Chart::Scientific->new (
        x_data => $x_pdl,
        y_data => $y_pdl,
    );
    $plt->plot ();

Plot data from an arbitrarily-delimitted file (the data in columns "vel" and
"acc" vs the data in the column "time", with errorbars from the columns
"vel_err" and "acc_err"):

    my $plt = Chart::Scientific->new (
                  filename => 'data.tab-separated', 
                  split    => '\t',
                  x_col    => 'time',
                  y_col    => 'vel,acc',
                  err_col  => 'vel_err,acc_err',
                  x_label  => "time",
                  y_label  => "velocity and acceleration",
              );
    $plt->plot ();

Plot data in arrays:

    my $plt = Chart::Scientific->new (
                  x_data => \@height,
                  y_data => [ \@weight, \@body_mass_index  ],
              );
    $plt->plot ();

Plot data in pdls:

    my $plt = Chart::Scientific->new (
                  x_data => $pdl_x,
                  y_data => [ $pdl_y1, $pdl_y2 ],
              );
    $plt->plot ();

Plot the above data to a file:

    my $plt = Chart::Scientific->new (
                  x_data => $pdl_x,
                  y_data => [ $pdl_y1, $pdl_y2 ],
                  device => 'myplot.ps/cps',
              );
    $plt->plot ();

Generate multiple plots with the same object:

    my @x1 = 10..19;
    my @y1 = 20..29;
    my @y2 = 50..59;

    my $plt = Chart::Scientific->new (
                  x_data  => \@x1,
                  y_data  => \@y1,
                  x_label => "test x",
                  y_label => "test y",
              );
    $plt->setvars ( title => 'testa', device => '1/xs' );
    $plt->plot ();

    $plt->setvars ( title => 'testb', device => '2/xs' );
    $plt->plot ();

=head1 DESCRIPTION

B<Chart::Scientific> is a simple PDL-based plotter.  2-D plots can be easily
made from data in an array or PDL, or from a file containing columns of data.
The columns can be delimited with any character(s) or regular expression.

There are many plotting options:

Graph axes can be logged (non-finite data, i.e. negative data that is logged,
will be ignored, with a warning), error bars can be plotted, the axes can be
displayed, residuals can be plotted, font, line thickness, character size, plot
point style, and colors can all be adjusted, line or point plotting, or both,
can be supressed.  Labels can be written on either axis, and the x and y ranges
can be specified.

=head1 PUBLIC METHODS

=head2 new ( %options | option-values list )

Creates a new Chart::Scientific object, and intializes it with the given
options.  The options defining plot data (I<i.e.> {filename,x_col,y_col} or
{x_data,y_data}) B<must> be specified in the constructor.  All other options
can be given either as a hash or a simple list of option => value pairs.  Legal
options are given in the B<OPTIONS> section.

=head2 setvars ( %options | option-values list )

Sets new options for a Chart::Scientific instance or overwrites existing
options.  The input format is identical to the Constructor's.  See the
B<OPTIONS> section for a complete list of options.

=head2 plot

Create the plot.  The plot is written the the existing device, 
whether it is a window or a file.

=head2 getvars ( option list )

Returns a list of the values of the options listed in the argument. 

=head2 restore_defaults

Restore the Chart::Scientific object to the default settings.

=head2 clear

Completely clear the Chart::Scientific object, setting it equal to 
an empty hashref. Arguably less useful than restore_defaults.

=head1 OPTIONS

=over 8

=item I<Data from arrays or piddles>

Plotting data may come from either arrays, piddles, or a file, but
all data must be of the same type.
       
=over 8

=item B<x_data>

An array or piddle that contains the x-data for this plot.
The x_data, y_data, and y_err_data specified must be of the same datatype,
arrays or piddles.

=item B<y_data>

An array or piddle that contains the y-data for this plot.
Multiple sets of y-data to plot against the same x-data can be specified
with an array of arrays or an array of piddles.
The x_data, y_data, and y_err_data specified must be of the same datatype,
arrays or piddles.

=item B<y_err_data>

An array or piddle that contains the error bars for the y-data.

There must be the same number of y_err_data as there are y_data, e.g.,

    y_data => [ \@y_data1, \@y_data2 ]

cannot be acompanied by:

    y_err_data => [ \@y_err ]

but 

    y_err_data => [ \@y_err1, \@y_err2  ]

would be allowed.

The x_data, y_data, and y_err_data specified must be of the same datatype,
arrays or piddles.

=back

=item I<Options concerning data from a file>

=over 8

=item B<filename>

The name of the file to read data from.  Specify 'stdin' to read from STDIN
(using the constructor or setvars).  If B<split> (see below) is not specified,
the file is assumed to be an RDB file (see
http://hea-www.harvard.edu/MST/simul/software/docs/rdb.html).  An kludgy
attempt to read the file if the RDB.pm module is not on the local system will
be made: RDB comments (leading '#'s) are stripped, the column definition line
is ignored, and the body of the file is split into columns on tabs.

=item B<split>

Used for non-RDB files,  B<split> specifies which character(s) (or regex) to
split the data from the file on.  For a comma-delimitted file, --split ','
would be the correct usage, or --split '\|' for a pipe-delimitted file (the
pipe is a special char in perl regexes, so we must escape it).  If the file
specified by B<filename> is an RDB file, this switch should not be used.

The first line of a file must list the names of the columns, delimmited
identically.

=item B<x_col>

The name of the x column.

=item B<y_col>

A comma-separated list of the name(s) of the y column(s).

=item B<y_err_col>

A comma-separated list of the name(s) of the y errorbar column(s).

=item B<group_col>

(Optional) The name of the grouping column.  The grouping column separates
a x_col or y_col into different datasets, based on the value of the grouping
column in each row.  For example, if x_col => x, y__col => y, group => g:

                     x   y   g
                     1   2   dataset1
                     2   3   dataset1
                     3   4   dataset1
                     4   5   dataset1
                     5   12  dataset2
                     6   13  dataset2
                     7   14  dataset2
                     8   15  dataset2

There would be two groups, dataset1 containing x = (1,2,3,4) and y = (2,3,4,5),
and dataset2 containing x = (5,6,7,8) and y = (12,13,14,15).  The two groups
of data would be plotted as separate lines on the plot.

=back

=item I<Plot limit Options>

=over 8

=item B<x_range >

Specify a comma-separated non-default range for the X values.  Example: an
x_range value of '-5,5' will plot the data from x=-5 to x=5.  If the I<x_log>
flag is on, the x_range values must be specified in powers of ten.  E.G. -x_log
-x -1,2 will plot the data on a logged X range from 0.1 to 100.

=item B<y_range>

Specify a comma-separated non-default range for the X values.  Example: a
y_range value of '-5,5' will plot the data from y=-5 to y=5.  If the I<y_log>
flag is on, the y_range values must be specified in powers of ten.  E.G. -y_log
-y -1,2 will plot the data on a logged Y range from 0.1 to 100.

=back

=item I<Output device options>

=over 8

=item B<device>

The PGPLOT plotting device.  Use "filename.ps/cps" to print to a postscript
file, or "filename.png/png" to print to a PNG file.  All plotting devices
supported by PDL::Graphics::PGPLOT are supported.  Defaults to '/xs', which
prints to a new window.

=back

=item I<Plot type options>

=over 8

=item B<nopoints>

Set to true to supress points plotting.  Points are plotted by
default.

=item B<noline>

Set to true to supress line drawing.  Lines are drawn by default.

=back

=item I<Logarithmic plot options>

=over 8

=item B<x_log>

Set to true to create a plot with a logged x axis.

=item B<y_log>

Set to true to create a plot with a logged y axis.

=back

=item I<Residual options>

=over 8

=item B<residuals>

If true, residuals will be calculated and drawn in a second pane.  The
residuals will be between the first two specified y-values (this needs an
upgrade).  The default is false.  

For plots that pull two or more y-data sets from the same rows (i.e., no
group_col column), the residuals are the difference of the first two specified
y-data columns.  For plots that use a group_col column, the residuals are
the interpolated differences between the first and the second group_col-column
sets of y-data.

=item B<residuals_size>

The fraction of the plotting area that the residuals occupy.
The default is 0.25, and the range is 0.0 to 1.0.

=back

=item I<Legend options>

=over 8

=item B<nolegend>

Setting this to a true value will suppress legend drawing.  The
default is 0.

=item B<legend_location>

A comma-separated list that to specify a location for the plot's
legend.  The default is .02,-.05.  The coordates are in the range
[0-1] for x, and [0,-1] for y, with the origin in the upper-left
corner of the plot.

=item B<legend_text>

A comma-separated list, with one item to specify the text for each
set of dependent data.  The list must be given in in the same order
as the data sets are given.

=back

=item I<Labelling options>

=over 8

=item B<title>

A string to specify the title of the plot.

=item B<subtitle>

A string to specify the subtitle of the plot.  If the PGPLOT.pm
module is not on the system, the subtitle will be appended to the
title.

=item B<x_label>

A string to specify the label for the x axis.

=item B<y_label>

A string to specify the label for the y axis.

=item B<residuals_label>

A string to specify the label for the residuals.  The default is
"deltas".

=item B<residuals_pos>

Setting this to a true value will move the numbering on the
residuals plot from the left to the right side of the pane.

=back

=item I<Formatting options>

=over 8

=item B<line_width>

The PGPlot line width.  The default is 2.

=item B<char_size>

The PGPlot character size.  The default is 1.

=item B<colors>

A comma-separated string that specifies the color set to use for
drawing points and lines.  For example, if 'red,blue,black' is the
argument, the first set of points will be drawn red, the second
blue, the third black, and then the fourth will be drawn red agan.
The default is 'black,red,green,blue,yellow,cyan,magenta,gray'.

=item B<font>

A PGPlot font integer.  The default is 1, and the range is 1-4.

=item B<symbols>

An anonymous array of PGPLOT symbol types, which specify the symbol set to use
for drawing points and lines.  For example, if [0,3,4] is the argument, the
first set of points will be drawn with symbol 0, the second with symbol 3, and
the third with symbol 4.  The fourth set of points will be drawn with symbol 0,
and so forth.  The default is [ 3, 0, 5, 4, 6..99 ].

=back

=item I<Axis drawing options>

=over 8

=item B<axis>

Setting this to true will draw the x=0 and y=0 axes on the main
plotting pane.

=item B<axis_residuals>

Setting this to true will draw the x=0 and y=0 axes on the residuals plotting
pane.

=back

=item I<Help and verbosity options>

=over 8

=item B<help>

Set this to true to print a short help message and exit.

=item B<usage>

Set this to true to print a lengthy help message and exit.

=item B<defaults>

Set this to true to print default values of the arguments and exit.

=item B<verbose>

A verbose setting of 0 results in nearly silent operation. -1 suppresses all
nonfatal output.  The range is -1 to 4, with increasing verbosity at each
level.

=back

=back

=head1 SEE ALSO

PDL, especially PDL::Graphics::PGPLOT, and PGPLOT.pm.

=head1 LICENSE

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html

=head1 AUTHOR

Kester Allen (kester@gmail.com)

=cut
