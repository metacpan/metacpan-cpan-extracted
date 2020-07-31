# POD documentation - main docs before the code

=head1 NAME

CLIPSeqTools::CompareApp - A collection of tools to compare two CLIP-Seq libraries.

=head1 SYNOPSIS

CLIPSeqTools::CompareApp provides tools to compare two CLIP-Seq libraries.

=head1 DESCRIPTION

CLIPSeqTools::CompareApp is primarily a collection of scripts and modules that can be used to compare two CLIP-Seq libraries.

=head1 EXAMPLES

=cut


package CLIPSeqTools::CompareApp;
$CLIPSeqTools::CompareApp::VERSION = '0.1.10';

# Make it an App and load plugins
use Moose;
extends 'CLIPSeqTools::App';


1;
