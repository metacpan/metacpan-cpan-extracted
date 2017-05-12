# $Source: /home/aplonis/Chart-EPS_graph/Chart/EPS_graph/Test.pm $
# $Date: 2006-08-15 $

package Chart::EPS_graph::Test;

use strict;
use warnings;
use Carp qw(carp croak);
use Chart::EPS_graph;
use Config;
use English qw(-no_match_vars);
require File::Find; # Win32 only needs this.

our ($VERSION) = '$Revision: 0.01 $' =~ m{ \$Revision: \s+ (\S+) }xm;

my $EMPTY = q{};

# For author's use when testing on different OS environs.
# while (my ($key,$val) = each %ENV) { print "$key = $val \n"}

# Select an user's own home space to write test files into.
# Must untaint that path as apporiate for whicever OS as this
# program is called in CPAN module test </t/99_try_out.t> on build.
sub home_dir {
	my $home_dir = $ENV{HOME}; # Must untaint.
	if ( $Config::Config{'osname'} =~ m/(MS)?Win32/im ) {

		# Do for Win32 users. Tested only on WinXP
		$ENV{PATH} = 'C:\Perl\bin';
		$home_dir = $ENV{USERPROFILE};
		$home_dir =~ s/\\/\//gm;
		# Untaint it.
		if ($home_dir =~ m/(C:\/Documents and Settings)\/(.*)/m) {
			$home_dir = "$1/$2/Desktop";
		} else {
			$home_dir = 'C:/';
		}
	} else {

		# Assume everybody else is UNIX. Tested only on NetBSD
		$ENV{PATH} = '/bin:/usr/bin:/usr/pkg/bin';
		if ($home_dir =~ m/(\/home)\/(.*)/m) {
			$home_dir = "$1/$2"
		} else {
			$home_dir = '/tmp'
		}
	}
	return $home_dir;
}

# Test if scalar is tainted.
sub is_tainted {
	my $arg = shift;
	my $nada = substr $arg, 0, 0;
	local $EVAL_ERROR = 0; # Perl::Critic errs about localization.
	eval { eval "# $nada"}; # Perl::Critic errs about the quotes.
	return length $EVAL_ERROR != 0;
}

sub new {
	ref( my $class = shift ) and croak 'Oops! Method new() is class, not instance.';
	my $self = {};
	$self->{dir} = shift;
	$self->{results} = $EMPTY;
	bless $self, $class;
	return $self;
}

# Wipe out any earlier EPS and PNG test files in same dir.
sub clean_up_dir {
	ref( my $self = shift ) or croak 'Oops! Method clean_up_dir() is instance, not class.';
	unlink "$self->{dir}/foo.eps.png";
	unlink "$self->{dir}/foo.eps";                
	return 'Pthhht! to Perl::Critic';
}

# Generate one unique curve of mock data.
sub curve_gen {
	ref( my $self = shift ) or croak 'Oops! Method curve_gen() is instance, not class.';
	my ($i, $j, $r) = @_;
	$self->{data}[$i] = [];
	for (0 .. 12){
		${$self->{data}}[$i][$_] = $_ * $r + $j * $r;
 		$r *= -1 if $i != 0;
	}
	return 'Pthhht! to Perl::Critic';
}

# Generate a set of curves of mock data.
sub mk_mock_data {
	ref( my $self = shift ) or croak 'Oops! Method mk_mock_data() is instance, not class.';

	# There should be no other *.esp or *.png files in the module directory
	# at start of test as to create and check them is what shall be tested.
	unlink "$self->{dir}/foo.eps";
	unlink "$self->{dir}/foo.eps.png";

	# Mock channel names and a data aref as if from a read-in *.csv file.
	$self->{names} = ['Time (S)', 'LH A Y1', 'Not Shown', 'LH B Y1', 'RH Y2'];
	$self->{data} = [];

	# A linear time-base and four unique zig-zags.
	$self->curve_gen(0,   0,  1);
	$self->curve_gen(1,   7,  3);
	$self->curve_gen(2,  15, -7);
	$self->curve_gen(3, -31, 15);
	$self->curve_gen(4, 256, 31);
	return 'Pthhht! to Perl::Critic';
}

# Create an EPS file
sub mk_eps_file {
	ref( my $self = shift ) or croak 'Oops! Method mk_eps_file() is instance, not class.';

	# Write a PostScript file of the graph.
	my $eps = Chart::EPS_graph->new(480, 480);

	# Give choices about EPS graph
	$eps->set(
		label_top   => 'Colorblind Test of Chart::EPS_graph.pm Module',
		label_y1    => 'Y1 Axis',
		label_y1_2  => $EMPTY,
		label_y2    => 'Y2 Axis',
		label_x     => 'Time (S)',
		label_x_2   => $EMPTY,
		names       => $self->{names},
		data        => $self->{data},
		y1          => [1,3],
		y2          => [4],
		font_name   => 'Helvetica-Oblique',
		font_size   => 11,
	    bg_color    => 'DarkOliveGreen',
	    fg_color    => 'HotPink',
	    web_colors  => ['Snow', 'Lime', 'Indigo', 'Gold', 'Red', 'Aqua'],
		verbosity   => 0,
	);

	$self->x_axis_switch($eps); # X axis sometimes channel data, other times fake.

	# Create an EPS graph of the CSV data.
	$eps->write_eps( "$self->{dir}/foo.eps" );

	return $eps;
}

# With or without 0th chan as X-axis. Time-based 50% probability.
sub x_axis_switch {
	ref( my $self = shift ) or croak 'Oops! Method x_axis_switch() is instance, not class.';
	my $eps = shift;
	if (time % 2) {
		shift @{$self->{data}}; # Shift only data, not names.
		$eps->set(
			label_x     => 'Data Points * 10',
			x_is_zeroth => 0,
			x_scale     => 1,
		);
		$self->{results} .= "Info: Simulated data being used X axis data\n"
	} else {
		$self->{results} .= "Info: Channel data being used X axis data\n"
	}                                                                      
	return 'Pthhht! to Perl::Critic';
}

sub ck_age_size {
	ref( my $self = shift ) or croak 'Oops! Method ck_age_size() is instance, not class. \n';
	my ($name, $min_bytes) = @_;
	if ( my @stats = stat "$self->{dir}/$name" ) {
		my $age = time - $stats[9];
		if ($age < 10) {
			$self->{results} .= "Okay: File '$name' looks fresh: $age seconds old. \n"
		} else {
			$self->{results} .= "Oops! File '$name' looks old: $age seconds old. \n"
		}
		my $size = $stats[7];
		if ($size > $min_bytes) {
			$self->{results} .= "Okay: File '$name' looks big enough, $size bytes. \n"
		} else {
			$self->{results} .= "Oops! File '$name' looks too small, $size bytes. \n"
		}
	} else {
		$self->{results} .= "Oops! File '$name' has no status. \n"
	}                                                                   
	return 'Pthhht! to Perl::Critic';
}

# Test the EPS file.
sub test_eps_file {
	ref( my $self = shift ) or croak 'Oops! Method test_eps_file() is instance, not class. \n';
	if (open my $fh, '<', "$self->{dir}/foo.eps") {
		if (
			(<$fh> =~ m/^%!PS-Adobe-2.0 EPSF-2.0$/m)
			&&
			(<$fh> =~ m/^%%Title: \(.*\/foo.eps\)$/m)) {
			$self->{results} .= "Okay: File 'foo.eps' has expected first two lines. \n";
		} else {
			$self->{results} .= "Oops! File 'foo.eps' lacks expected first two lines. \n";
		}
		close $fh;
    	$self->ck_age_size('foo.eps', 20 * 1024);
	} else {
		$self->{results} .= "Oops! File 'foo.eps' could not be read. \n";
	}
	return 'Pthhht! to Perl::Critic';
}

# On Win32 different versions may be located variously.
# Not knowing which version user has, we must seek it.
sub win32_seek {
	our ($reg_ex, $start_path) = @_;
	our $cmd_exe = $EMPTY;
	sub seek_exe { if (m/$reg_ex/m) {
		$cmd_exe = qq|"$File::Find::name"|};
		return 'Pthhht! to Perl::Critic';
	}
	File::Find::find(\&seek_exe, $start_path);
	$cmd_exe = qq|$cmd_exe|;
	$cmd_exe =~ s/\\/\//gm;
	return $cmd_exe;
}

# From an already created EPS file, create a PNG file and test it.
sub mk_png_file {
	ref( my $self = shift ) or croak 'Oops! Method mk_png_file() is instance, not class.';
	my $eps = shift;
	my $result = "Okay: Ghostscript called to create 'foo.eps.png'. \n";
	if ( $Config::Config{'osname'} =~ m/Win/im ) {
		if (my $gs_path = win32_seek('gswin32\.exe$','C:/Program Files/gs/')) {
			$eps->display('GS');
		} else {
			$result = "Oops! Ghostscript is needed but not installed. \n"
		}
	}
	else {
		$result = "Note: Ghostscript assumed installed on non Win32 platforms. \n";
		$eps->display('GS');
	}
	$self->{results} .= $result;
	sleep 1;
	return 'Pthhht! to Perl::Critic';
}

sub test_png_file {
	ref( my $self = shift ) or croak 'Oops! Method test_png_file() is instance, not class.';
	unless ($self->{results} =~ m/Oops!/m) {
    	$self->ck_age_size('foo.eps.png', 40 * 1024);
	}
	return 'Pthhht! to Perl::Critic';
}

sub pass_judgement {
	ref( my $self = shift ) or croak 'Oops! Method pass_judgement() is instance, not class.';
	$self->{results} .= "\n";
	if ($self->{results} =~ m/Oops!/m) {
		$self->{results} .= "Woe & Lament! Not all is well for Chart::EPS_graph. \n"
	} else {
		$self->{results} .= "Glad Tidings! All tests okay for Chart::EPS_graph. \n"
	}
	return "\n" . $self->{results} . "\n";
}

# Fully exercise the EPS_Graph module just as a user would.
sub full_test {
	my $tainted = 0; # Assume called by user, not CPAN build test.
	ref( my $class = shift ) and croak 'Oops! Method full_test() is class, not instance.';
	my $self = {};
	bless $self, $class;
	$self->{dir} = shift;
	$self->{results} = $EMPTY;

    # CPAN build test </t/99_try_out.t> calls sans args in taint mode.
	unless ($self->{dir}) {
		$tainted = 1;
		$self->{dir} = home_dir();
	}

	$self->{dir} =~ s/\/+$//m;
	if ($self->{dir} =~ m/Chart\/EPS_graph/m) {
		$self->clean_up_dir();
		$self->{results} .= "Ahem! Writing test graphs to '$self->{dir}'. \n";
	}
	$self->clean_up_dir();
	$self->mk_mock_data();
	my $eps = $self->mk_eps_file();
	$self->test_eps_file();

    # Can't run tainted because File::Find will hunt for Ghostscript on Win32.
	unless ($tainted) {
		$self->mk_png_file($eps);
		$self->test_png_file($eps);
		$eps->display();
	}

	if ($self->{dir} =~ m/Chart\/EPS_graph/m) {
		$self->{results} .= "Ahem! Deleting test graphs from '$self->{dir}'. \n";
		$self->clean_up_dir();
		$self->{results} .= "Note: Next time, specify '/some/dir/' for the test. \n";
	} else {
		my $foo_path = "$self->{dir}/foo.eps*";
		$foo_path =~ s/\//\\/gm if $Config::Config{'osname'} =~ m/Win/im;
		$self->{results} .= "Done: Lacking any oopses, you may look at '$foo_path'. \n";
	}
	return $self->pass_judgement(); # RE the string for "Oops!" as failure.
}

1;

__END__

=head1 NAME

Chart::EPS_graph::Test.pm

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

From the CLI, call as below where C<'/some/dir/'> is any directory you have
permission to write to.

C<perl -e "use Chart::EPS_graph::Test; \ >

C<print Chart::EPS_graph::Test-E<gt>full_test('/some/dir');">

From anywhere else call...

C<use Chart::EPS_graph::Test;>

C<print Chart::EPS_graph::Test-E<gt>full_test(/some/dir);>

With the parent module (C<Chart::EPS_graph.pm>) loaded, call as below. The
C<$foo> may be either class or instance (of module C<Chart::EPS_graph>) as it
will be ignored. The test module auto-instanciates its own object without need
of a C<new()> method. It is just a test, after all.

C<$foo-E<gt>full_test('/some/dir');>

Then look for both C<foo.eps> and C<foo.eps.png> to be created in C</some/dir/>.

=head1 SUBROUTINES/METHODS

There is but a single method of interest as detailed in the synopsis above.

A special default is in effect if called without C<'/some/dir'> as an argument.
Then output will default to the C</home/your_id> directory on UNIX or the
desktop in Win32 with only the C<foo.eps> (and not the C<foo.eps.png>) being
written there. This default behavior exists to allow for the module to be called
as a test when first building the module freshly downloaded from CPAN.

In the ordinary, user-diven, case (when C</some/dir> is supplied as an argument)
then this module will allow itself a free hand to search for wherever it is that
I<Ghostscript> and/or I<The GIMP> have been installed. It calls the special Perl
module C<File::Find> to do this. It must because those programs may be installed
in various paths depending upon their version number.

But while being built as a brand new module freshly downloaded from CPAN, taint
mode will be in effect. This is a security precaution that disallows many an
unsafe condition. Taint mode will disallow that C<File::Find> be free to look
about where it likes. Thus, since at time of build we cannot know where
I<Ghostscript> and I<The GIMP> might be, and also cannot look for them, then
the test must do without them such that only C<foo.eps> and not C<foo.eps.png>
may be created during the test.


=head1 DESCRIPTION

For use only with the C<Chart::EPS_graph> module...as a full, user-like test
thereof.

How this test works is that two files, C<foo.eps> and C<foo.eps.png> will be
(over-)written into C</some/dir/>. The test itself will inspect each of these
files for date, size and content. Based upon what it finds it will return a
string as its pronouncement on the health of C<Chart::EPS_graph> as a module.
That string will contain several lines, all of which should start with "Okay:"
and none of which should start with "Oops!".

=head1 USAGE

Here is the output from calling this test module on the command line on
NetBSD UNIX OS. If, as below, you specify a file path between the parens
the output will be written there. Elsewise it will default to the user's home
directory on UNIX or their desktop on Win32.

C<baal: {666} perl -e "use Chart::EPS_graph::Test; \>

C<print Chart::EPS_graph::Test-E<gt>full_test('/ram');">

C<Testing Chart::EPS_graph.pm in path '/ram' >

C<Okay: File 'foo.eps' has expected first two lines. >

C<Okay: File 'foo.eps' looks fresh: 0 seconds old. >

C<Okay: File 'foo.eps' looks big enough, 28319 bytes. >

C<Okay: Ghostscript created 'foo.eps.png'. >

C<Okay: File 'foo.eps.png' looks fresh: 1 seconds old.>

C<Okay: File 'foo.eps.png' looks big enough, 105828 bytes. >

C<Glad Tidings! All tests okay for Chart::EPS_graph. >

C<baal: {667} >

Had there been a problem of any kind, one or more of the above lines would have
begun as C<Oops! ...> followed by a few terse details. You can also inspect the
example files personally via I<The GIMP> or I<ImageMagick> as you choose.

=head1 DIAGNOSTICS

A few of my design-phase, run-time diagnostics remain but are commented out
for the formal CPAN release so as not to impinge on general usage.

=head1 CONFIGURATION AND ENVIRONMENT

This module requires no configuration. It auto-searches for its dependencies
by calling to C<File::Find>.

My goal, as always, is OS-independence, but only have recources to design and
test on these two platforms only:

=over 4

=item NetBSD 2.0.2 running Perl 5.8.7

=item WinXP SP2 running ActiveState Perl 5.8.0.

=back

=head1 DEPENDENCIES

Refer to POD of parent module C<Chart::EPS_graph>.

=head1 INCOMPATIBILITIES

None known as yet.

=head1 BUGS AND LIMITATIONS

None known as yet.

=head1 AUTHOR

Gan Uesli Starling <F<gan@starling.us>>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 Gan Uesli Starling. All rights reserved.

This is free software; you may distribute and/or modify it under the same terms
as Perl itself.

=cut

