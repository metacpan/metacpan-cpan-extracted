package App::SeismicUnixGui::geopsy::dinver;
use Moose;
our $VERSION = '0.0.1';

=pod

=head1 DOCUMENTATION

=head2 SYNOPSIS

  PROGRAM NAME: Dinver
  AUTHOR:  Derek Goff
  DATE:  May 1 2015
  DESCRIPTION:  A package to use geopsy's dinver surface wave inversion program
  VERSION: 0.1

=head2 Use

=head2 Notes

	This Program derives from dinver in Geopsy
	'_note' keeps track of actions for use in graphics
	'_Step' keeps track of actions for execution in the system

=head2 Example

=head2 Dinver Notes

Usage: dinver [OPTIONS]

  Graphical user interface for Conditional Neighbourhood Algorithm
  (Inversion/Optimization).

Dinver options:
  -i <PLUGIN_TAG>           Select inversion plugin with tag PLUGIN_TAG, skip
                            first dialog box. See option '-plugin-list', to get
                            the list of available plugins and their tags.
  -env <FILE>               Load Dinver environment file .dinver. With option
                            '-run', only the current target and
                            parameterization are considered, the run
                            description is ignored. It replaces former options
                            '-target' and '-param'.
  -optimization             Starts one inversion run with target and
                            parameterization specified by options '-param' and
                            '-target'. No graphical user interface is started.
                            See '-h optimization' for all options.
  -importance-sampling <REPORT>
                            Starts one resampling run with parameterization
                            specified by options '-param'. REPORT is an
                            inversion report produced by option '-optimization'
                            or by graphical interface. No graphical user
                            interface is started. See '-h importanceSampling'
                            for all options.

Optimization options:
  -target <TARGET>          Set targets from file TARGET. It can be a .target
                            or a .dinver file. A .dinver file contains both
                            parameters and targets. Provide it to both options
                            '-param' and '-target'.
  -param <PARAM>            Set parameters from file PARAM. It can be a .param
                            or a .dinver file. A .dinver file contains both
                            parameters and targets. Provide it to both options
                            '-param' and '-target'.
  -itmax <ITMAX>            Number of iterations started by option -run
                            (default=50).
  -ns0 <NS0>                Number of initial models (default=50).
  -ns <NS>                  Number of models generated (default=50).
  -nr <NR>                  Number of best cells (default=50).
  -seed <SEED>              Set random seed to SEED. This option is for debug
                            only.
  -o <REPORT>               Ouput report (default='run.report'). To suppress
                            output to .report file, set option '-o' to "".
  -f                        Force overwrite if output report already exists.
  -resume                   If the output report file already exists, it is
                            imported into the parameter space before starting
                            the inversion. Better to set NS0 to zero in this
                            case. This way, it is possible to continue an
                            existing inversion adding new iterations.

Importance sampling options:
  -dof <DOF>                Set degrees of freedom for conversion from misfit
                            to a posteriori probability function.
  -param <PARAM>            Set parameters from file PARAM. It can be a .param
                            or a .dinver file. A .dinver file contains both
                            parameters and targets. Provide it to both options
                            '-param' and '-target'.
  -ns <NS>                  Number of models generated (default=5000).
  -seed <SEED>              Set random seed to SEED. This option is for debug
                            only.
  -o <REPORT>               Ouput report (default='run.report'). To suppress
                            output to .report file, set option '-o' to "".
  -f                        Force overwrite if output report already exists.
  -resume                   If the output report file already exists, add
                            generated models without warning.

Debug options:
  -debug-stream             Debug mode (redirect all logs to stdout)
  -plugin-list              Print the list of a available plugins
  -clear-plugins            Reset the list of a available plugins

Qt options:
  -nograb                   Tells Qt that it must never grab the mouse or the
                            keyboard
  -dograb                   Running under a debugger can cause an implicit
                            -nograb, use -dograb to override
  -sync                     Switches to synchronous mode for debugging
  -style <style>            Sets the application GUI style. Possible values are
                              motif
                              windows
                              platinum
                            If you compiled Qt with additional styles or have
                            additional styles as plugins these will be
                            available to the -style command line option
  -session <session>        Restore the application from an earlier session
  -reverse                  Sets the application's layout direction to right to
                            left
  -display <display>        Sets the X display (default is $DISPLAY)
  -geometry <geometry>      Sets the client geometry of the first window that
                            is shown
  -fn, -font <font>         Defines the application font. The font should be
                            specified using an X logical font description
  -bg, -background <color>  Sets the default background color and an
                            application palette (light and dark shades are
                            calculated)
  -fg, -foreground <color>  Sets the default foreground color
  -btn, -button <color>     Sets the default button color
  -name <name>              Sets the application name
  -title <title>            Sets the application title
  -visual TrueColor         Forces the application to use a TrueColor visual on
                            an 8-bit display
  -ncols <count>            Limits the number of colors allocated in the color
                            cube on an 8-bit display, if the application is
                            using the QApplication::ManyColor color
                            specification. If count is 216 then a 6x6x6 color
                            cube is used (i.e. 6 levels of red, 6 of green, and
                            6 of blue); for other values, a cube approximately
                            proportional to a 2x3x1 cube is used
  -cmap <count>             Causes the application to install a private color
                            map on an 8-bit display
  -im <XIM server>          Sets the input method server (equivalent to setting
                            the XMODIFIERS environment variable)
  -noxim                    Disables the input method framework ("no X input
                            method")
  -inputstyle <inputstyle>  Defines how the input is inserted into the given
                            widget. Possible values are:
                              onTheSpot makes the input appear directly in the
                              widget
                              offTheSpot
                              overTheSpot makes the input appear in a box
                              floating over the widget

Generic options:
  -h, -help [<SECTION>]     Shows help. SECTION may be empty or: all, html,
                            latex, generic, debug, debug, dinver,
                            importanceSampling, optimization, qt
  -version                  Shows version information
  -app-version              Shows short version information
  -j, -jobs <N>             Allows a maximum of N simulteneous jobs for
                            parallel computations (default=8).

Debug options:
  -nobugreport              Does not generate bug reports in case of error.
  -reportbug                Starts bug report dialog, information about bug is
                            passed through stdin. This option is used
                            internally to report bugs if option -nobugreportreport is
                            not specified.
  -reportint                Starts bug report dialog, information about
                            interruption is passed through stdin. This option
                            is used internally to report interruptions if
                            option -nobugreport is not specified.

See also:
  More information at http://www.geopsy.org

Authors:
  Marc Wathelet
  Marc Wathelet (LGIT, Grenoble, France)
  Marc Wathelet (ULg, Liège, Belgium)

=cut

my $Dinver = {
    _Step        => '',
    _note        => '',
    _nobugreport => '',
    _plug        => '',
    _target      => '',
    _param       => '',
    _itmax       => '',
    _ns0         => '',
    _ns          => '',
    _nr          => '',
    _output      => '',
    _force       => '',
    _resume      => '',
};

=pod

=head1 Description of Subroutines

=head2 Subroutine clear
	
	Sets all variable strings to '' (nothing) 

=cut

sub clear {
    $Dinver->{_Step}        = '';
    $Dinver->{_nobugreport} = '';
    $Dinver->{_note}        = '';
    $Dinver->{_plug}        = '';
    $Dinver->{_target}      = '';
    $Dinver->{_param}       = '';
    $Dinver->{_itmax}       = '';
    $Dinver->{_ns0}         = '';
    $Dinver->{_ns}          = '';
    $Dinver->{_nr}          = '';
    $Dinver->{_output}      = '';
    $Dinver->{_force}       = '';
    $Dinver->{_resume}      = '';
}

=head2 Subroutine nobugreport

	no error messages out during running

=cut

sub nobugreport {
    my ( $sub, $nobugreport ) = @_;
    $Dinver->{_nobugreport} = $nobugreport if defined($nobugreport);
    $Dinver->{_note} =
      $Dinver->{_note} . ' -nobugreport ' . $Dinver->{_nobugreport};
    $Dinver->{_Step} =
      $Dinver->{_Step} . ' -nobugreport ' . $Dinver->{_nobugreport};
}

=pod

=head2 Subroutine Plug

	Designates one inversion to run:
		-optimization
	Select Dinver plugin to use
	Options are:
	Surface Wave Inversion (tag = DispersionCurve)
	External Forward Computation (tag = DinverExt)
	Matlab Forward Computation (tag = DinverMatlab)
	
=cut

sub plug {
    my ( $sub, $plug ) = @_;
    $Dinver->{_plug} = $plug if defined($plug);
    $Dinver->{_note} =
      $Dinver->{_note} . ' -i ' . $Dinver->{_plug} . ' -optimization ';
    $Dinver->{_Step} =
      $Dinver->{_Step} . ' -i ' . $Dinver->{_plug} . ' -optimization ';
}

####

=pod

=head2 Subroutine target

	Filename of Dispersion Curve to be inverted
	
=cut

sub target {
    my ( $sub, $target ) = @_;
    $Dinver->{_target} = $target if defined($target);
    $Dinver->{_note}   = $Dinver->{_note} . ' -target ' . $Dinver->{_target};
    $Dinver->{_Step}   = $Dinver->{_Step} . ' -target ' . $Dinver->{_target};
}

####

=pod

=head2 Subroutine Param

	Choose parameter file to constrain inversion
		Constrained variables consist of thickness, Vs, Vp,
		poisson's ratio, & density

=cut

sub param {
    my ( $sub, $param ) = @_;
    $Dinver->{_param} = $param if defined($param);
    $Dinver->{_note}  = $Dinver->{_note} . ' -param ' . $Dinver->{_param};
    $Dinver->{_Step}  = $Dinver->{_Step} . ' -param ' . $Dinver->{_param};
}

####

=pod

=head2 Subroutine itmax

	Number of iterations for inversion to run
	0 iterations = Pure Monte Carlo

=cut

sub itmax {
    my ( $sub, $itmax ) = @_;
    $Dinver->{_itmax} = $itmax if defined($itmax);
    $Dinver->{_note}  = $Dinver->{_note} . ' -itmax ' . $Dinver->{_itmax};
    $Dinver->{_Step}  = $Dinver->{_Step} . ' -itmax ' . $Dinver->{_itmax};
}

####

=pod

=head2 Subroutine ns0

	Number of random initial models
	created before first iteration.
	Default = 50

=cut

sub ns0 {
    my ( $sub, $ns0 ) = @_;
    $Dinver->{_ns0}  = $ns0 if defined($ns0);
    $Dinver->{_note} = $Dinver->{_note} . ' -ns0 ' . $Dinver->{_ns0};
    $Dinver->{_Step} = $Dinver->{_Step} . ' -ns0 ' . $Dinver->{_ns0};
}

####

=pod

=head2 Subroutine ns

	Number of models generated for each iteration.
	Default = 50

=cut

sub ns {
    my ( $sub, $ns ) = @_;
    $Dinver->{_ns}   = $ns if defined($ns);
    $Dinver->{_note} = $Dinver->{_note} . ' -ns ' . $Dinver->{_ns};
    $Dinver->{_Step} = $Dinver->{_Step} . ' -ns ' . $Dinver->{_ns};
}

####

=pod

=head2 Subroutine nr
	
	Number of best solution models to consider when resampling
	(higher is more explorative)
	Default = 50

=cut

sub nr {
    my ( $sub, $nr ) = @_;
    $Dinver->{_nr}   = $nr if defined($nr);
    $Dinver->{_note} = $Dinver->{_note} . ' -nr ' . $Dinver->{_nr};
    $Dinver->{_Step} = $Dinver->{_Step} . ' -nr ' . $Dinver->{_nr};
}

=pod

=head2 Subroutine output

	Filename for inversion report
	Default = 'run.report' (may add run #)
	set option -o to "" (nothing) to suppress report

=cut

sub output {
    my ( $sub, $output ) = @_;
    $Dinver->{_output} = $output if defined($output);
    $Dinver->{_note}   = $Dinver->{_note} . ' -o ' . $Dinver->{_output};
    $Dinver->{_Step}   = $Dinver->{_Step} . ' -o ' . $Dinver->{_output};
}

=pod

=head2 Subroutine force

	If output file already exists, overwrite

=cut

sub force {
    my ( $sub, $force ) = @_;
    $Dinver->{_force} = ' -f ' if defined($force);
    $Dinver->{_note}  = $Dinver->{_note} . $Dinver->{_force};
    $Dinver->{_Step}  = $Dinver->{_Step} . $Dinver->{_force};
}

=pod

=head2 Subroutine resume

	If output file already exists, it is improted before starting inversion
	Safer to set ns0 -> 0 for this case
	Adds new iterations to existing inversion

=cut

sub resume {
    my ( $sub, $resume ) = @_;
    $Dinver->{_resume} = $resume if defined($resume);
    $Dinver->{_note}   = $Dinver->{_note} . ' -resume ' . $Dinver->{_resume};
    $Dinver->{_Step}   = $Dinver->{_Step} . ' -resume ' . $Dinver->{_resume};
}

=pod

=head2 Subroutine Step

	Keeps track of actions for execution in the system

=cut

sub Step {
    $Dinver->{_Step} = 'dinver' . $Dinver->{_Step};
    return $Dinver->{_Step};
}

=pod

=head2 Subroutine note

	Keeps track of actions for possible use in graphics

=cut

sub note {
    $Dinver->{_note} = $Dinver->{_note};
    return $Dinver->{_note};
}

=pod

=head3 Warnings for programmers

 packages must end with
 1;

=cut

1;
