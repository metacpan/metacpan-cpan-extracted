=head1 NAME

CLIPSeqTools::Role::Option::Plot - Role to enable plot as command line option

=head1 SYNOPSIS

Role to enable plot as command line option

  Defines options.
      --plot            call plotting script to create plots.

=cut


package CLIPSeqTools::Role::Option::Plot;
$CLIPSeqTools::Role::Option::Plot::VERSION = '0.1.10';

#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use MooseX::App::Role;


#######################################################################
####################   Load CLIPSeqTools plotting   ###################
#######################################################################
use CLIPSeqTools::PlotApp;


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'plot' => (
	is            => 'rw',
	isa           => 'Bool',
	documentation => 'call plotting script to create plots.',
);


#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub validate_args {}


1;
