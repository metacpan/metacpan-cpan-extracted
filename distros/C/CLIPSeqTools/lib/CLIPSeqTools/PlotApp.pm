# POD documentation - main docs before the code

=head1 NAME

CLIPSeqTools::PlotApp - Tools to create plots based on the output of CLIPSeqTools applications.

=head1 SYNOPSIS

CLIPSeqTools::PlotApp provides tools to create plots based on the output of CLIPSeqTools applications.

=head1 DESCRIPTION

CLIPSeqTools::PlotApp consists of a collection of scripts and modules that
can be used to create plots based on the output of CLIPSeqTools.
These tools basically use the output of CLIPSeqTools applications as input
and create plots for visualization. Most of these tools offer minimal
customization and are mostly used for rapid visualization of the
CLIPSeqTools output files.

=head1 EXAMPLES

=cut


package CLIPSeqTools::PlotApp;
$CLIPSeqTools::PlotApp::VERSION = '1.0.0';

# Make it an App and load plugins
use Moose;
extends 'CLIPSeqTools::App';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;


1;
