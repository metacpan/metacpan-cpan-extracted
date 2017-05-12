package App::Physics::ParticleMotion;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.01';

use Carp qw/croak carp/;
use Math::Symbolic qw/:all/;
use Math::Symbolic::Compiler;
use Math::RungeKutta qw//;
use Math::Project3D;
use Tk qw/DoOneEvent DONT_WAIT MainLoop/;
use Tk::Cloth;
use Time::HiRes qw/time sleep/;
use Config::Tiny;

# a short little helper
sub _def_or ($$) { defined( $_[0] ) ? $_[0] : $_[1] }

sub new {
	my $proto = shift;
	my $class = ref($proto)||$proto;

	my $self = {
		run => 0,
		config => Config::Tiny->new(),
	};
	bless $self => $class;

	return $self;
}


sub config {
	my $self = shift;
	my $name = shift;

	return $self->{config} if not defined $name;
	
	if (ref($name) eq 'Config::Tiny') {
		$self->{config} = $name;
		return $name;
	}

	eval {$self->{config} = Config::Tiny->read($name)};
	croak "Could not read file '$name': $@." if ($@);

	return $self->{config};
}

sub run {
	my $app = shift;
	die "Cannot run app more than once." if $app->{run};
	$app->{run} = 1;
	my $config = $app->config();
	
	# Coordinate and velocity variable names
	my @coords = qw( x  y  z  );
	my @speeds = qw( vx vy vz );
	
	# Extract particle options from configuration file
	my @particles = map { $config->{$_} }
	  sort { substr( $a, 1 ) <=> substr( $b, 1 ) }
	  grep { /^p\d+$/ }
	  keys %$config;
	
	# Default colors for particles
	$_->{color} = defined( $_->{color} ) ? $_->{color} : '#FFFFFF'
	  foreach @particles;
	$_->{colort} = defined( $_->{colort} ) ? $_->{colort} : '#000000'
	  foreach @particles;
	
	# General configuration options
	my $gen_conf     = $config->{_};
	my $dimensions   = $gen_conf->{dimensions} || 3;
	$app->{dimensions} = $dimensions;

	my $particles    = scalar(@particles);
	$app->{particles} = \@particles;
	my $free         = $dimensions * $particles;
	$app->{free} = $free;
	my $axiscolor    = $gen_conf->{axiscolor} || '#000000';
	$app->{axiscolor} = $axiscolor;
	my $displayscale = $gen_conf->{zoom} || 20;
	$app->{displayscale} = $displayscale;
	my $time_warp = $gen_conf->{timewarp} || 1;
	$app->{time_warp} = $time_warp;
	my $epsilon   = $gen_conf->{epsilon}  || 0.00000000001;
	$app->{epsilon} = $epsilon;
	my $trace     = $gen_conf->{trace};
	$app->{trace} = $trace;
	my $out_file  = $gen_conf->{output_file};
	$app->{out_file} = $out_file;
	
	# Projection plane (see Math::Project3D for details!)
	my $plane_basis_vector = [
	   _def_or( $gen_conf->{plane_base_x}, 0 ),
	   _def_or( $gen_conf->{plane_base_y}, 0 ),
	   _def_or( $gen_conf->{plane_base_z}, 0 ),
	];
	my $plane_direction1 = [
	   _def_or( $gen_conf->{plane_vec1_x}, 0.371391 ),
	   _def_or( $gen_conf->{plane_vec1_y}, 0.928477 ),
	   _def_or( $gen_conf->{plane_vec1_z}, 0 ),
	];
	my $plane_direction2 = [
	   _def_or( $gen_conf->{plane_vec2_x}, 0.371391 ),
	   _def_or( $gen_conf->{plane_vec2_y}, 0 ),
	   _def_or( $gen_conf->{plane_vec2_z}, 0.928477 ),
	];
	
	# Generate Math::Symbolic function objects from the functions
	# specified as differential equations of the particle's motion
	my @functions;
	foreach my $p (@particles) {
		foreach ( 0 .. $dimensions - 1 ) {
		    my $str = $p->{"func".$coords[$_]};
			my $temp;
			eval { $temp = Math::Symbolic->parse_from_string($str) };
			if ($@ or not defined $temp) {
				require Data::Dumper;
				my $part = Data::Dumper->Dump($p);
				croak "Could not parse function '$str' for particle\n$part";
			}
			push @functions, $temp;
		}
	}

	# Get starting values for the particles
	my @startx = map {
	    my $p = $_;
	    ( map { $p->{ $coords[$_] } } ( 0 .. $dimensions - 1 ) )
	} @particles;
	my @startv = map {
	    my $p = $_;
	    ( map { $p->{ $speeds[$_] } } ( 0 .. $dimensions - 1 ) )
	} @particles;
	
	my %const = %{ $config->{constants} };
	
	# Generate variable names from the number of particles and the
	# coordinate and velocity names specified above.
	my @vars;
	foreach my $pno ( 1 .. $particles ) {
	    push @vars, $coords[ $_ - 1 ] . $pno foreach 1 .. $dimensions;
	}
	foreach my $pno ( 1 .. $particles ) {
	    push @vars, $speeds[ $_ - 1 ] . $pno foreach 1 .. $dimensions;
	}
	
	my %vars = map { ( $_, undef ) } @vars;
	
	# Insert constants into the functions and make sure the
	# remaining variables are all particle coordinates or velocities
	# Compile functions to Perl code for speed.
	# (Evaluating the trees every time would be a couple orders of
	# magnitude slower!)
	foreach my $coord ( 0 .. $free - 1 ) {
	    $functions[$coord]->implement(
	        map { ( $_ => Math::Symbolic::Constant->new( $const{$_} ) ) }
	          keys %const
	    );
	
	    my @sig = $functions[$coord]->signature();
	    if ( grep { not exists $vars{$_} and not $_ eq 't' } @sig ) {
	        croak("Invalid function '" . $functions[$coord] . "'");
	    }
		
	    my ( $sub, $leftover ) =
	      Math::Symbolic::Compiler->compile_to_sub( $functions[$coord],
	        [ 't', @vars ] );
	    croak("Could not resolve all derivatives in function $functions[$coord].")
	      if not defined $sub
	      or (  defined $leftover and ref($leftover) eq 'ARRAY' and @$leftover );
		
	
    	$functions[$coord] = $sub;
	}
	$app->{functions} = \@functions;
	
	# Define the projection used for displaying 3D-motion on a 2D display.
	my $proj = Math::Project3D->new(
	    plane_basis_vector => $plane_basis_vector,
	    plane_direction1   => $plane_direction1,
	    plane_direction2   => $plane_direction2
	);
	$app->{proj} = $proj;
	
	#   plane_direction1   => [ 0.371391, 0.928477, 0 ],
	#   plane_direction2   => [ 0.371391, 0, 0.928477 ],
	
	# Open output file if defined in configuration
	my $out_filehandle;
	if ( defined $out_file and not $out_file eq '' ) {
	    open $out_filehandle, '>', $out_file
	      or croak "Cannot write to output file '$out_file': $!";
	}
	$app->{out_filehandle} = $out_filehandle;
	
	# Starting coordinates and velocities. The @y vector will be acted
	# upon by the runge-kutta integrator.
	# It will always contain the coords in the first half and the velocities
	# in the second.
	my @y = ( @startx, @startv );
	$app->{y} = \@y;
	
	$app->{started} = 0;
	
	# Tk setup
	my $top = MainWindow->new();
	$app->{top} = $top;
	
	my $button = $top->Button(
	    -height  => 1,
	    -text    => 'Run Simulation',
	    -command => sub {
	        # Only start if we haven't done so before
	        _draw($app) if $app->{started} == 0;
	    }
	);
	$button->pack( -fill => 'x', -expand => 0, -side => 'top' );
	
	my $cloth = $top->Scrolled('Cloth', -scrollbars => 'se');
	#my $cloth = $top->Cloth;
	$cloth->configure( -scrollregion => [-10000, -10000, 10000, 10000] );
	$cloth->configure( -height => 600, -width => 800 );
	$cloth->pack( -fill => 'both', -expand => 1, -side => 'top' );
	$app->{cloth} = $cloth;
	
	# Math::Project3D is meant to project arbitrary functions. If we
	# want to project discrete data, we just use the current contents
	# of three variables as functions.
	$proj->new_function( 'x,y,z', '$x', '$y', '$z' );
	$app->{axis} = [];
	
	# Run the sub for the first time.
	_draw_axis($app);
	
	# Print starting coordinates to file if required
	if ( defined $out_file ) {
	    foreach my $p_no ( 0 .. $#particles ) {
	        my @proj = @y[ $dimensions * $p_no .. $dimensions * ( $p_no + 1 ) - 1 ];
	        push @proj, (0) x ( 3 - scalar(@proj) ) if @proj != 3;
    	    print( $out_filehandle ( $p_no + 1 ) . " 0 @proj\n" );
	    }
	}
	
	# Run the TK MainLoop
	MainLoop;
}


# main routine that doesn't end.
sub _draw {
	my $app = shift;
	$app->{started} = 0;
	
	my $trace = $app->{trace};
	my $cloth = $app->{cloth};
	my $epsilon = $app->{epsilon};
	my @functions = @{$app->{functions}};
	my @particles = @{$app->{particles}};
	my $particles = scalar @particles;
	my $dimensions = $app->{dimensions};
	my $out_file = $app->{out_file};
	my $out_filehandle = $app->{out_filehandle};
	my $displayscale = $app->{displayscale};
	my $time_warp = $app->{time_warp};
	my @y = @{$app->{y}};
	my $proj = $app->{proj};

	# Starting time and time steps. $dt will be adjusted by the integrator
	my $t = 0;
	my $dt = 0.1;

    # @prevlines holds line objects from the previous iterations.
    my @prevlines = ();

    # Previous values for line drawing
    my @prev_x = ();
    my @prev_y = ();

    # Start time of the simulation for speed adjustment on fast systems
    my $timeref = time();

    # main loop
    while (1) {

        # Delete old lines if we don't want to keep traces.
        # Change their color otherwise
        if ( not $trace ) {
            $cloth->delete($_) foreach @prevlines;
            @prevlines = ();
        }
        else {
            $_->configure( -state => 'disabled' ) foreach @prevlines;

            # Won't have to keep the objects around for modification:
            @prevlines = ();
        }

        # Integrate the next step. (I'm open for speed improvements!)
        ( $t, $dt, @y ) = Math::RungeKutta::rk4_auto(
            \@y,
            sub {
                my $t    = shift;
                my @dydt = @_[ @_ / 2 .. $#_ ];
                foreach ( 0 .. $#functions ) {
                    push @dydt, $functions[$_]->( $t, @_ );
                }
                return @dydt;
            },
            $t,
            $dt,
            $epsilon
        );

        # Project and draw
        foreach my $p_no ( 0 .. $particles - 1 ) {
            my @proj =
              @y[ $dimensions * $p_no .. $dimensions * ( $p_no + 1 ) - 1 ];
            push @proj, (0) x ( 3 - scalar(@proj) ) if @proj != 3;

            # File output
            print( $out_filehandle ( $p_no + 1 ) . " $t @proj\n" )
              if defined $out_file;

            my ( $x, $y ) = $proj->project(@proj);

            if ( defined $prev_x[$p_no] ) {
                my $coords =
                  [ _transform( $app, $prev_x[$p_no], $prev_y[$p_no], $x, $y ) ];
                @$coords = map { int $_ } @$coords;
                $coords->[2] -= 1 while abs( $coords->[0] - $coords->[2] ) < 1;
                $coords->[3] -= 1 while abs( $coords->[1] - $coords->[3] ) < 1;

                my $line = $cloth->Line(
                    -coords       => $coords,
                    -fill         => $particles[$p_no]{color},
                    -disabledfill => $particles[$p_no]{colort},
                );
                push @prevlines, $line;    # if not $trace;
            }
            $prev_x[$p_no] = $x;
	        $prev_y[$p_no] = $y;
        }

        # Speed control.
        DoOneEvent(DONT_WAIT);
        my $endtime = $timeref + $t / $time_warp;
        while ( $endtime > time() ) {
            sleep(0.01);
            DoOneEvent(DONT_WAIT);
        }
    }
}





# transform calculates the window coordinates from the
# relative coordinates of the projected plane
sub _transform {
	my $app = shift;
	my $cloth = $app->{cloth};
	my $displayscale = $app->{displayscale};
    my $y_max_half = $cloth->cget('-height') / 2;
    my $x_max_half = $cloth->cget('-width') / 2;
    my @res;
    while (@_) {
        push @res, $x_max_half + shift(@_) * $displayscale,
          $y_max_half - shift(@_) * $displayscale;
    }
    return @res;
}

# draw_axis draws the n axis' as Tk::Cloth::Line objects.
sub _draw_axis {
	my $app = shift;
	my $axis = $app->{axis};
	my $proj = $app->{proj};
	my $dimensions = $app->{dimensions};
	my $axiscolor = $app->{axiscolor};
	my $cloth = $app->{cloth};
	my $displayscale = $app->{displayscale};
    my $max = 20000;
    $_->delete() foreach @$axis;
    foreach my $dim ( 0 .. $dimensions - 1 ) {
        my ( $x1, $y1 ) =
        	$proj->project( map { $_ == $dim ? -$max / $displayscale : 0 }
             0 .. 2 );
        my ( $x2, $y2 ) =
        	$proj->project( map { $_ == $dim ? $max / $displayscale : 0 }
             0 .. 2 );
		push @$axis,
	        $cloth->Line(
              -coords => [ _transform( $app, $x1, $y1, $x2, $y2 ) ],
              -fill   => $axiscolor,
        	);
    }
}


1;
__END__

=head1 NAME

App::Physics::ParticleMotion - Simulations from Differential Equations

=head1 SYNOPSIS

  # You can use the tk-motion.pl script instead.
  
  use App::Physics::ParticleMotion;
  my $app = App::Physics::ParticleMotion->new();
  $app->config('filename'); # Or pass a Config::Tiny object instead
  $app->run();

  # Using the script:
  # tk-motion.pl filename

=head1 DESCRIPTION

tk-motion (and its implementation App::Physics::ParticleMotion)
is a tool to create particle simulations from any number of
correlated second order differential equations. From a more mathematical
point of view, one could also say it helps visualize the numeric solution
of such differential equations.

The program uses a 4th-order Runge-Kutta integrator to find the numeric
solution of the specified differential equations. We will walk through
an example configuration file step by step to show how the process works.
The format of the configuration files is the ordinary ini file format
as understood by Config::Tiny. (Should be self explanatory.)

=head1 EXAMPLES

=head2 Long Example

The following B<extensive> example comes with the distribution as "ex1.ini".
See below for a minimal working example.

    # This will be a one-dimensional harmonic oszillator (in 2D-space)
    
    # Number of dimensions in simulation (up to three dimensions allowed)
    dimensions = 2
    
    # Given a sufficiently fast cpu, you can have the simulation run very fast
    # by setting this to a high value. Setting it to one makes the simualtion
    # pause after integration steps so that the total speed is no greater
    # than realtime.
    timewarp = 1
    
    # The sensitivity of the integrator.
    # Smaller is more accurate but more cpu intensive.
    epsilon = 0.0000001
    
    # Set to a true value to have the particle traces stay on screen.
    # Note, however, that this tends to increase memory usage with time - slowly.
    # This option may be omitted and defaults to false.
    trace = 0
    
    # Set this to any HTML color to change the axis' color.
    # This option may be omitted and defaults to black.
    axiscolor = #222277
    
    # This sets the zoom. It may be omitted and defaults to 20 for
    # backwards compatibility.
    zoom = 60
    
    # The following options specify the base point and the plane vectors
    # for the viewing plane. (That's the plane you project the 3D coordinates on.)
    # Make sure your vectors are normalized because otherwise your display will
    # be stretched.
    # The values in this example are at the same time the default values.
    plane_base_x = 0
    plane_base_y = 0
    plane_base_z = 0
    
    plane_vec1_x = 0.371391
    plane_vec1_y = 0.928477
    plane_vec1_z = 0
    
    plane_vec2_x = 0.371391
    plane_vec2_y = 0
    plane_vec2_z = 0.928477
    
    # You may omit this option. If you don't, however, all 3D data will be written
    # to the specified file for further processing. (For example with
    # tk-motion-img.pl.)
    # output_file = ex1.dat
    
    # This section contains any number of constants that may be used in the
    # formulas that define the differential equations. The section should
    # exist, but it may be empty.
    [constants]
    k = 1
    m = 1
    
    # This section defines the movement of the first particle (p1).
    [p1]
    
    # This is the differential equation of the first coordinate of the
    # first particle. It is of the form
    #      (d^2/dt^2) x1 = yourformula
    # "yourformula" may be any string that is correctly parsed by the
    # Math::Symbolic parser. It may contain the constants specified above
    # and any of the following variables:
    # x1 is the first (hence "x") coordinate of the first particle (hence "x1").
    # x2 is the x-coordinate of the second particle if it exists, and so on.
    # y3 therefore represents the second coordinate of the third particle whereas
    # z8 is the third coordinate of the eigth particle.
    # Note that this example simulation only has two dimensions and hence
    # "z8" doesn't exist.
    # vx1 is the x-component of the velocity of the first particle.
    # Therefore, vy3 represents the y-component of the velocity of the
    # third particle. You get the general idea...
    # All formulas may be correlated with other differential equations.
    # That means, "funcx" of the first particle may contain y2 and the
    # like. (Provided the dimensions and the particles exist.)
    # 
    # Our example is a simple oszillator
    funcx = - k/m * x1*(x1^2)^0.5
    
    # Diff. eq. for the second coordinate of the first particle
    # We want a 1-dimensional oszillator, so we set this to zero.
    funcy = 0
    
    # Initial values for the coordinates and velocity of the first particle.
    x = 0
    y = -0.5
    vx = -20
    vy = 0
    
    # Color of the current location of the particle (default: white)
    # HTML-style colors.
    color = #FF0000
    # Color of the particle's trace if trace == 1 (default: black)
    colort = #880000
    
    # Other particles are defined in the same fashion.

=head2 Short Example

This example pretty much reproduces the extensive example above omitting
any options that aren't mandatory (or required to make the examples
the same).

    # This will be a one-dimensional harmonic oszillator (in 2D-space)
    
    dimensions = 2
    zoom = 60
    
    [constants]
    k = 1
    m = 1
    
    [p1]
    funcx = - k/m * x1*(x1^2)^0.5
    funcy = 0
    
    x = 0
    y = -0.5
    vx = -20
    vy = 0

=head1 METHODS

=head2 new

Returns a new App::Physics::ParticleMotion object.

=head2 config

Returns the current configuration as a Config::Tiny object. If a first argument
is passed, it is used as the new configuration. It may be either a Config::Tiny
object to replace the old one or the name of a file to read from.

=head2 run

Runs the application. Can't be called more than once.

=head1 SEE ALSO

New versions of this module can be found on http://steffen-mueller.net or CPAN.

L<Math::Symbolic> implements the formula parser, compiler and evaluator.
(See also L<Math::Symbolic::Parser> and L<Math::Symbolic::Compiler>.)

L<Config::Tiny> implements the configuration reader.

L<Tk> in conjunction with L<Tk::Cloth> offer the GUI.

L<Math::RungeKutta> implements the integrator.

L<Math::Project3D> projects the 3D data onto a viewing plane.

=head1 AUTHOR

Steffen Mueller, E<lt>particles-module at steffen-mueller dot net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
