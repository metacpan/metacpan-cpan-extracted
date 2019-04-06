# Bio-RNA-RNAaliSplit 0.10

Bio::RNA::RNAaliSplit is a distribution of Perl modules for splitting
and deconvoluting structural RNA multiple sequence alignments
(MSAs). Its primary purpose is to partition a MSA into subsets of
sequences that have a common consensus structure which is different
from the consesus structure of the other set. Another application is
cleaning MSAs from sequence that do not fold into or prohibit folding
into a common consensus structure.

This distribution is shipped with a set of executables within the
'scripts' folder. RNAalisplit.pl, takes a RNA MSA in ClustalW format
and performs the deconvolution. The eval_alignment.pl executable is a
lightweight evaluator for structural alignments of RNA.

## THIRD PARTY DEPENDENCIES

This module depends heavily on third party RNA bioinformatics software.

It requires the ViennaRNA Package v2.3.4 or above (available from
http://www.tbi.univie.ac.at/RNA ). Specifically, the 'RNAalifold',
'AnalyseDists' executables as well as the RNA Perl module shipped with
ViennaRNA are used by RNAaliSplit.

RNAz v2.1 (availale from http://www.tbi.univie.ac.at/~wash/RNAz) is
used for classification of split subalignments.

R-scape v1.2.2 or above is used for computing statistically
significant covariation in base pairs. Download R-scape from
http://www.eddylab.org/R-scape .

Be sure to have all dependencies up and running on your system (and
available to the Perl interpreter) priot to installation of
Bio::RNA::RNAaliSplit.

## INSTALLATION

To install this module, run the following commands:

>	perl Makefile.PL
>	make
>	make test
>	make install

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Bio::RNA::RNAaliSplit

You can also look for information at:

    metaCPAN
        https://metacpan.org/release/Bio-RNA-RNAaliSplit

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-RNA-RNAaliSplit

## LICENSE AND COPYRIGHT

Copyright (C) 2017-2019 Michael T. Wolfinger

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Affero General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
http://www.gnu.org/licenses/.
