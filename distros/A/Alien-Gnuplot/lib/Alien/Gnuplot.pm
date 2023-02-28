=head1 NAME

Alien::Gnuplot - Find and verify functionality of the gnuplot executable.

=head1 SYNOPSIS

 package MyGnuplotter;

 use strict;

 use Alien::Gnuplot;

 $gnuplot = $Alien::Gnuplot::executable;

 `$gnuplot < /tmp/plotfile`;

 1;

=head1 DESCRIPTION

Alien::Gnuplot verifies existence and sanity of the gnuplot external
application.  It only declares one access method,
C<Alien::Gnuplot::load_gnuplot>, which does the actual work and is
called automatically at load time.  Alien::Gnuplot doesn't have any
actual plotting methods - making use of gnuplot, once it is found and
verified, is up to you or your client module.

Using Alien::Gnuplot checks for existence of the executable, verifies
that it runs properly, and sets several global variables to describe
the properties of the gnuplot it found:

=over 3

=item * C<$Alien::Gnuplot::executable> 

gets the path to the gnuplot executable.

=item * C<$Alien::Gnuplot::version> 

gets the self-reported version number of the executable.

=item * C<$Alien::Gnuplot::pl> 

gets the self-reported patch level.

=item * C<@Alien::Gnuplot::terms> 

gets a list of the names of all supported terminal devices.

=item * C<%Alien::Gnuplot::terms> 

gets a key for each supported terminal device; values are the 1-line
description from gnuplot.  This is useful for testing whether a
particular terminal is supported.

=item * C<@Alien::Gnuplot::colors> 

gets a list of the names of all named colors recognized by this gnuplot.

=item * C<%Alien::Gnuplot::colors> 

gets a key for each named color; values are the C<#RRGGBB> form of the color.
This is useful for decoding colors, or for checking whether a particular color
name is recognized.  All the color names are lowercase alphanumeric.

=back

You can point Alien::Gnuplot to a particular path for gnuplot, by
setting the environment variable GNUPLOT_BINARY to the path.  Otherwise
your path will be searched (using File::Spec) for the executable file.

If there is no executable application in your path or in the location
pointed to by GNUPLOT_BINARY, then the module throws an exception.
You can also verify that it has not completed successfully, by
examining $Alien::Gnuplot::version, which is undefined in case of
failure and contains the gnuplot version string on success.

If you think the global state of the gnuplot executable may have
changed, you can either reload the module or explicitly call
C<Alien::Gnuplot::load_gnuplot()> to force a fresh inspection of
the executable.

=head1 INSTALLATION STRATEGY

When you install Alien::Gnuplot, it checks that gnuplot itself is
installed as well.  If it is not, then Alien::Gnuplot attempts to 
use one of several common package managers to install gnuplot for you.
If it can't find one of those, if dies (and refuses to install), printing
a friendly message about how to get gnuplot before throwing an error.

In principle, gnuplot could be automagically downloaded and built, 
but it is distributed via Sourceforge -- which obfuscates interior
links, making such tools surprisingly difficult to write.

=head1 CROSS-PLATFORM BEHAVIOR

On POSIX systems, including Linux and MacOS, Alien::Gnuplot uses
fork/exec to invoke the gnuplot executable and asynchronously monitor
it for hangs.  Microsoft Windows process control is more difficult, so
if $^O contains "MSWin32", a simpler system call is used, that is
riskier -- it involves waiting for the unknown executable to complete.

=head1 REPOSITORIES

Gnuplot's main home page is at L<https://gnuplot.sourceforge.net/>.

Alien::Gnuplot development is at L<https://github.com/drzowie/Alien-Gnuplot>.

A major client module for Alien::Gnuplot is PDL::Graphics::Gnuplot, which
can be found at L<https://github.com/PDLPorters/PDL-Graphics-Gnuplot>.
PDL is at L<https://pdl.perl.org/>.

=head1 AUTHOR

Craig DeForest <craig@deforest.org>

(with special thanks to Chris Marshall, Juergen Mueck, and
Sisyphus for testing and debugging on the Microsoft platform)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Craig DeForest

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Alien::Gnuplot;

use strict;
our $DEBUG = 0; # set to 1 for some debugging output

use parent qw( Alien::Base );

use File::Spec;
use File::Temp qw/tempfile/;
use File::Which;
use Time::HiRes qw/usleep/;
use POSIX ":sys_wait_h";
use Fcntl qw/SEEK_SET/;
use Env qw( @PATH );

# VERSION here is for CPAN to parse -- it is the version of the module itself.  But we
# overload the system VERSION to compare a required version against gnuplot itself, rather
# than against the module version.

our $VERSION = '1.040';

# On install, try to make sure at least this version is present.
our $GNUPLOT_RECOMMENDED_VERSION = '4.6';  

our $executable;  # Holds the path to the found gnuplot
our $version;     # Holds the found version number
our $pl;          # Holds the found patchlevel
our @terms;
our %terms;
our @colors;
our %colors;

sub VERSION {
    my $module =shift;
    my $req_v = shift;
    # Need this line when using
    #
    #   use Alien::Gnuplot 4.4;
    #
    # to check Gnuplot version.
    $module->load_gnuplot unless $version; # already have version
    unless($req_v <= $version) {
	die qq{

Alien::Gnuplot: Found gnuplot version $version, but you requested $req_v. 
You should upgrade gnuplot, either by reinstalling Alien::Gnuplot or 
getting it yourself from L<https://gnuplot.sourceforge.net/>.

};
    }
}

sub exe {
##############################
# Search the path for the executable
#
    my ($class) = @_;
    $class ||= __PACKAGE__;

    my $exec_path;
    # GNUPLOT_BINARY overrides at runtime
    if($ENV{'GNUPLOT_BINARY'}) {
	$exec_path = $ENV{'GNUPLOT_BINARY'};
    } else {
	local $ENV{PATH} = $ENV{PATH};
	unshift @PATH, $class->bin_dir;
	$exec_path = which("gnuplot");
    }

    return $exec_path;
}

sub load_gnuplot {
  my ($class) = @_;
  $class ||= __PACKAGE__;

  my $exec_path = $class->exe;
  $class->check_gnuplot($exec_path);
}

sub check_gnuplot {
    my $exec_path = pop @_;

    unless(-x $exec_path) { 
	die q{
Alien::Gnuplot: no executable gnuplot found!  If you have gnuplot,
you can put its exact location in your GNUPLOT_BINARY environment 
variable or make sure your PATH contains it.  If you do not have
gnuplot, you can reinstall Alien::Gnuplot (and its installation 
script will try to install gnuplot) or get it yourself from L<https://gnuplot.sourceforge.net/>.
};
    }
    
##############################
# Execute the executable to make sure it's really gnuplot, and parse
# out its reported version.  This is complicated by gnuplot's shenanigans
# with STDOUT and STDERR, so we fork and redirect everything to a file.
# The parent process gives the daughter 2 seconds to report progress, then
# kills it dead.
    my($pid);
    my ($undef, $file) = tempfile();

    # Create command file
    open FOO, ">${file}_gzinta";
    print FOO "show version\nset terminal\n\n\n\n\n\n\n\n\n\nprint \"CcColors\"\nshow colornames\n\n\n\n\n\n\n\nprint \"FfFinished\"\nexit\n";
    close FOO;

    if($^O =~ /MSWin32/i) {

	if( $exec_path =~ m/([\"\*\?\<\>\|])/ ) {
	    die "Alien::Gnuplot: Invalid character '$1' in path to gnuplot -- I give up" ;
	}
	
	# Microsoft Windows sucks at IPC (and many other things), so
	# use "system" instead of civilized fork/exec.
	# This leaves us vulnerable to gnuplot itself hanging, but 
	# sidesteps the problem of waitpid hanging on Strawberry Perl.
	open FOO, ">&STDOUT";
	open BAR, ">&STDERR";
	open STDOUT,">$file";
	open STDERR,">$file";
	system(qq{"$exec_path" < ${file}_gzinta});
	open STDOUT,">&FOO";
	open STDERR,">&BAR";
	close FOO;
	close BAR;
    } else {
	$pid = fork();
	if(defined($pid)) {
	    if(!$pid) {
		# daughter
		open BAR, ">&STDERR"; # preserve stderr
		eval { 
		    open STDOUT, ">$file";
		    open STDERR, ">&STDOUT";
		    open STDIN, "<${file}_gzinta";
		    seek STDIN, 0, SEEK_SET;
		    no warnings; 
		    exec($exec_path);
		    print BAR "Execution of $exec_path failed!\n";
		    exit(1);
		}; 
		print STDERR "Alien::Gnuplot: Unknown problems spawning '$exec_path' to probe gnuplot.\n";
		exit(2); # there was a problem!
	    } else {
		# parent
		# Assume we're more POSIX-compliant...
		if($DEBUG) { print "waiting for pid $pid (up to 20 iterations of 100ms)"; flush STDOUT; }
		for (1..20) {
		    if($DEBUG) { print "."; flush STDOUT; }
		    if(waitpid($pid,WNOHANG)) {
			$pid=0;
			last;
		    }
		    usleep(1e5);
		}
		if($DEBUG) { print "\n"; flush STDOUT; }
		
		if($pid) {
		    if( $DEBUG) { print "gnuplot didn't complete.  Killing it dead...\n"; flush STDOUT; }
		    kill 9,$pid;   # zap
		    waitpid($pid,0); # reap
		}
	    } #end of parent case
	} else {
	    # fork returned undef - error.
	    die "Alien::Gnuplot: Couldn't fork to test gnuplot! ($@)\n";
	}
    }
    
##############################
# Read what gnuplot had to say, and clean up our mess...
    open FOO, "<$file";
    my @lines = <FOO>;
    close FOO;
    unlink $file;
    unlink $file."_gzinta";
    
##############################
# Whew.  Now parse out the 'GNUPLOT' and version number...
    my $lines = join("", map { chomp $_; $_} @lines);
    $lines =~ s/\s+G N U P L O T\s*//  or  die qq{
Alien::Gnuplot: the executable '$exec_path' appears not to be gnuplot,
or perhaps there was a problem running it.  You can remove it or set
your GNUPLOT_BINARY variable to an actual gnuplot.
};
    
    $lines =~ m/Version (\d+\.\d+) (patchlevel (\d+))?/ or die qq{
Alien::Gnuplot: the executable file $exec_path claims to be gnuplot, but 
I could not parse a version number from its output.  Sorry, I give up.

};
    
    $version = $1;
    $pl = $3;
    $executable = $exec_path;
    
##############################
# Parse out available terminals and put them into the 
# global list and hash.
    @terms = ();
    %terms = ();
    my $reading_terms = 0;
    for my $line(@lines) {
	last if($line =~ m/CcColors/);
	if(!$reading_terms) {
	    if($line =~ m/^Available terminal types\:/) {
		$reading_terms = 1;
	    }
	} else {
	    $line =~ s/^Press return for more\:\s*//;
	    $line =~ m/^\s*(\w+)\s(.*[^\s])\s*$/ || next;
	    push(@terms, $1);
	    $terms{$1} = $2;
	}
    }
    
##############################
# Parse out available colors and put them into that global list and hash.
    @colors = ();
    %colors = ();
    
    for my $line(@lines) {
	last if($line =~ m/FfFinished/);
	next unless( $line =~ m/\s+([\w\-0-9]+)\s+(\#......)/);
	$colors{$1} = $2;
    }
    @colors = sort keys %colors;
}

sub import {
    my $pkg = shift;
    $pkg->SUPER::import(@_);
    $pkg->load_gnuplot();
};


1;

