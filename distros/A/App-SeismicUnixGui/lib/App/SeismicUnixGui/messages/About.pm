package App::SeismicUnixGui;

$VERSION = '0.82.0';
use strict;
use warnings;

=head2 NAME

App::SeismicUnixGui - A graphical user interface for Seismic Unix

=head2 DESCRIPTION

SeismicUnixGui (alpha) is a graphical user interface (GUI) 
to select parameters for Seismic Unix (SU) modules. 
Seismic Unix (Stockwell, 1999) is a widely distributed 
free software package for processing seismic reflection 
and signal processing. 
Perl/Tk is a mature, well-documented and free, 
object-oriented graphical user interface for Perl. 

=head2 EXTRA PACKAGES

If you want to additional fortran and c packages
run the following instruction post-installation:

sudo bash post_install_scripts.sh

If you can not find this file, then look for it with any of the
these instructions:

A.
  find / -path */App/SeismicUnixGui/script/post_install_scripts.sh 2>/dev/null

B.
  locate post_install_scripts.sh
