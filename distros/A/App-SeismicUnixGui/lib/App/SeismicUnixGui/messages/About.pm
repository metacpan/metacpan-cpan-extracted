package App::SeismicUnixGui;

$VERSION = '0.87.3';
use strict;
use warnings;

=head1 NAME

App::SeismicUnixGui - A graphical user interface for Seismic Unix

=head1 DESCRIPTION

SeismicUnixGui (alpha) is a graphical user interface (GUI) 
to select parameters for Seismic Unix (SU) modules. 
Seismic Unix (Stockwell, 1999) is a widely distributed 
free software package for processing seismic reflection 
and signal processing. 
Perl/Tk is a mature, well-documented and free, 
object-oriented graphical user interface for Perl.  

=head1 EXTRA PACKAGES

If you want to additional fortran and c packages,
run the following instruction post-installation:

bash post_install_scripts.sh

If you can not find this file, then look for it with any of the
these instructions:

A.
  find / -path */App/SeismicUnixGui/script/post_install_scripts.sh 2>/dev/null

B.
  locate post_install_scripts.sh

=head1 ENVIRONMENTAL VARIABLES

GLOBAL INSTALLATION:
It is advisable to have your environment variables
properly defined. That is you should already have active the
following definitions in your ".bashrc" file. For example:

#for using a SeismicUnixGui installed via cpan  

export SeismicUnixGui=/usr/local/share/perl/5.34.0/App/SeismicUnixGui 
 
export SeismicUnixGui_script=$SeismicUnixGui/script  

export PATH=$PATH::$SeismicUnixGui_script  

export PERL5LIB=$PERL5LIB:$SeismicUnixGui 

=head1 SeismicUnixGui Project Examples
