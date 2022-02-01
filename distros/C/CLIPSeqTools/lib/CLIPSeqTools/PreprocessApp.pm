# POD documentation - main docs before the code

=head1 NAME

CLIPSeqTools::PreprocessApp - Tools to process a fastq file with CLIP-Seq data into a database compatible with clipseqtools.

=head1 SYNOPSIS

Tools to process a fastq file with CLIP-Seq data into a database compatible with clipseqtools.

=head1 DESCRIPTION

CLIPSeqTools::PreprocessApp is primarily a collection of scripts and modules that can be used to process a fastq file with CLIP-Seq data into a database compatible with clipseqtools.
Contains tools to do the alignment, adaptor trimming, and other common tasks on a fastq file.

=head1 EXAMPLES

=cut


package CLIPSeqTools::PreprocessApp;
$CLIPSeqTools::PreprocessApp::VERSION = '1.0.0';

# Make it an App and load plugins
use Moose;
extends 'CLIPSeqTools::App';


1;
