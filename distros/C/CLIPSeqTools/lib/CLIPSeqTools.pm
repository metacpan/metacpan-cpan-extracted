# POD documentation - main docs before the code

=head1 NAME

CLIPSeqTools - A collection of tools for the analysis of CLIP-Seq data.

=head1 SYNOPSIS

CLIPSeqTools provides tools for the analysis of CLIP-Seq data. Such datasets may come from HITS-CLIP, PAR-CLIP or iCLIP.

=head1 DESCRIPTION

CLIPSeqTools is primarily a collection of scripts and execuables that can be used for the analysis of CLIP-Seq data.
The tools cover a wide range of analysis, from general statistics like genome coverage to more complex analysis like the relative positioning of reads for two libraries.
The toolbox is under heavy development and new tools are added on a daily basis.

Source code: The source has been deposited in GitHub L<https://github.com/palexiou/GenOO-CLIP>.
Contribute:  Please fork the GitHub repository and provide patches, features or tests.
Bugs:        Please open issues in the GitHub repository L<https://github.com/palexiou/GenOO-CLIP/issues>

=cut

# Let the code begin...


package CLIPSeqTools;
$CLIPSeqTools::VERSION = '1.0.0';
use Modern::Perl;

1;
