use strict;
use ExtUtils::MakeMaker;

sub parseversion
{
    my $version;
  open GP, 'lib/Alien/Gnuplot.pm' or die "Couldn't open lib/Alien/Gnuplot.pm";
  for(<GP>){
      if(m/our \$VERSION = \'([\d\.]+b?)\'/) {$version = $1;}
      last if($version);
  }
  die "Couldn't parse version from Gnuplot.pm" unless($version);
  close GP;
  return $version;
}

sub MY::libscan
{
    package MY;

    my ($self, $file) = @_;

    # Don't install the README.pod or any .pl file
    return undef if $file =~ /\.pl$|^README.pod/;
    return $self->SUPER::libscan ($file);
}


########################################
########################################	
# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
my $POD_header = <<EOF;
=head1 OVERVIEW

Alien::Gnuplot is intended for distribution via CPAN.  This repository
stores the history for the Alien::Gnuplot module on CPAN. Install the
module via CPAN.

=cut
EOF
if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  open MOD, 'lib/Alien/Gnuplot.pm' or die "Couldn't open main module";
  open README, '>README.pod'       or die "Couldn't open README.pod";

  print README $POD_header;

  while (<MOD>)
  {
    if (/^=/../^=cut/)
    { print README; }
  }
}


################################################################################
################################################################################
## Here we check for a working gnuplot.  What better way to do that than by
## executing our own library?  

{
    my $get_msg = '';

    eval q{ do q{./lib/Alien/Gnuplot.pm}; $get_msg = $@;};
    
    unless($get_msg) {
	if($Alien::Gnuplot::GNUPLOT_RECOMMENDED_VERSION > $Alien::Gnuplot::version) {
	    $get_msg = qq{
Gnuplot seems to exist on your system, but it is version $Alien::Gnuplot::version.
The minimum recommended version is $Alien::Gnuplot::GNUPLOT_RECOMMENDED_VERSION.

}
	}

    }

    if($get_msg) {
	print $get_msg ;

	my $install_flag;

	if( (-t STDIN  or $^O =~ m/MSWin/) and 
	      ! (  $ENV{AUTOMATED_TESTING} or $ENV{PERL_MM_USE_DEFAULT}  ) 
	    ) {

	    print "\nGnuplot seems to not exist on your system.  Shall I try to install it? [Y/n]> ";
	    $a = <STDIN>;
	    $install_flag = !($a =~ m/^\s*n/i);
	    
	    unless($install_flag) {
		print qq{

Okay, I won't install gnuplot. You can still install the Alien::Gnuplot module,
but it will fail on load until you install the gnuplot executable yourself.

};
	    }

	} else {

	    if($ENV{PERL_MM_USE_DEFAULT}) {
		$install_flag = 1;
		print qq{

Gnuplot seems to not exist on your system, and you set PERL_MM_USE_DEFAULT --
so I'll try to install it for you.

};
	    } else {
		print qq{

Gnuplot seems to not exist on your system, and this is not an interactive 
session, so I can't ask if you want to install it.  I'll install the module,
but it'll fail on load until you install the gnuplot executable yourself.

};
	    }
	}

	if($install_flag) {

	    print "Attempting to install/upgrade gnuplot on your system....\n\n";

	    if( install_gnuplot_binary() ) {
		print "\nGnuplot installation was successful!\n";
	    } else {
		die qq{

Couldn't find gnuplot, and couldn't get it from the standard package managers.
I'd try to download the packages from sourceforge, but there are roadblocks that
make it hard to automate.  

You can get gnuplot from the DOWNLOAD link here: "http://gnuplot.info". 

};
	    } # end of binary conditional 
	} # end of prompt conditional
    } # end of get_msg condition
} # end of convenience block	

##############################
##############################
## 
## install_gnuplot_binary routine -- called
## from deep in the install conditional above.
##
## The strategy is to try to get a late-model
## binary from the Usual Suspects, and fall back
## to compiling it.
## 
## On success, return 1; on failure return 0.
## Try not to crash.

sub install_gnuplot_binary {
    local($|) = 1;

    ##############################
    # 
    if($^O eq 'darwin') {
	##############################
	# Binary distros on mac - try macports, fink, homebrew
	for my $manager( ['macports','port','http://macports.org'],
			 ['fink','fink','http://www.finkproject.org'],
			 ['homebrew','brew','http://mxcl.github.com/homebrew/']
	    ) {
	    print "Trying $manager->[0] (you can get it at $manager->[2])...";
	    my $l = `which $manager->[1]`;
	    if($l) {
		print "\n";
		print STDERR `$manager->[1] install gnuplot`;
		my $msg;
		eval q{ do q{lib/Alien/Gnuplot.pm}; $msg = $@; } ;
		
		if( (!$msg) and ($Alien::Gnuplot::version >= $Alien::Gnuplot::GNUPLOT_RECOMMENDED_VERSION)) {
		    print "Success!\n";
		    return 1;               # Success - return 1
		} else {
		    return 0;               # Failure - give up (once you find one package manager don't use any other)
		}

	    } else {
		print "no $manager->[0]\n";
	    }
	} # end of manager loop
	
	return 0;  
    } # end of macos case
    
    elsif($^O eq 'linux') {
	# The linux package managers generally ask for keyboard feedback (e.g. yum),
	# so we have to spawn, exec, and wait to make sure the manager gets that feedback.

	for my $manager( 'yum','apt-get' ) {
	    print "Trying $manager...";
	    my $l = `which $manager`;
	    
	    if($l) {
		
		my $pid = fork();
		die "Couldn't fork!" unless(defined($pid));
		
		unless($pid) {
		    ## daughter
		    exec "$manager install gnuplot";
		    
		    exit(-1); # never get here
		}
		
		waitpid($pid,0);  # wait for the install to finish
		
		my $msg;
		eval q{ do q{lib/Alien/Gnuplot.pm}; $msg = $@ };
		
		if( (!$msg) and ($Alien::Gnuplot::version >= $Alien::Gnuplot::GNUPLOT_RECOMMENDED_VERSION) ) {
		    print "Success!\n";
		    return 1;              # Success - return 1
		} else {
		    print "Hmmm, that didn't seem to work.\n";
		    return 0;              # Failure - give up (once you find one package manager don't use any other)
		}
	    } # end of found-this-manager conditional
	} # end of manager loop

	return 0;
    } # end of linux case
    
    else {
	return 0;  ## We're not a system where we know how to do binary installs
    }

}



##############################
##############################
## Write a generic Makefile that puts the module in place.  Include a postamble
## that will also make the source code, if necessary.

WriteMakefile(
    NAME                => 'Alien::Gnuplot',
    AUTHOR              => 'Craig DeForest <craig@deforest.org>',
    VERSION             => parseversion(),
    ABSTRACT_FROM       => 'lib/Alien/Gnuplot.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
     ? ('LICENSE'=> 'perl')
     : ()),
    PREREQ_PM => { 'Time::HiRes' => 0,
		   'File::Temp'  => 0,
		   'HTTP::Tiny'  => 0,
		   'POSIX'       => 0,
		   'File::Spec'  => 0
		       
    },
    META_ADD => {
	resources => {
	    homepage => 'http://github.com/drzowie/Alien-Gnuplot',
	    repository => 'git://github.com/drzowie/Alien-Gnuplot.git',
	    bugtracker => 'craig@deforest.org'
	}
    },		  

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Alien-Gnuplot-* src/*[0-9]' },
	);

