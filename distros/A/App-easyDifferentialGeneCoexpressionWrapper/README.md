# easyDifferentialGeneCoexpressionWrapper
easyDifferentialGeneCoexpressionWrapper is a wrapper program for the easyDifferentialGeneCoexpression.r R script (<a href="https://github.com/davidechicco/easyDifferentialGeneCoexpression" target="_blank" rel="noopener noreferrer">developed by Davide Chicco</a>).

## Summary
<p>This is a wrapper program for the easyDifferentialGeneCoexpression.r whose function is to detect pairings of genes/probesets with the highest, significant differential coexpression. For more information, (<a href="https://cran.r-project.org/web/packages/easyDifferentialGeneCoexpression/index.html" target="_blank" rel="noopener noreferrer">see this description manual</a>).</p>

## easyDifferentialGeneCoexpressionWrapper dependencies
The dependencies (<i>i.e.</i> packages) used by easyDifferentialGeneCoexpressionWrapper are:

<p><ul><li>strict</li></ul></p>
<p><ul><li>warnings</li></ul></p>
<p><ul><li>Term::ANSIColor</li></ul></p>
<p><ul><li>Getopt::Long</li></ul></p>
<p><ul><li>File::Basename</li></ul></p>
<p><ul><li>File::HomeDir</li></ul></p>


## Installation
easyDifferentialGeneCoexpressionWrapper can be used on any Linux, macOS, or Windows machines. On the Windows operating system you will need to install the Windows Subsystem for Linux (WSL) compatibility layer (<a href="https://docs.microsoft.com/en-us/windows/wsl/install" target="_blank" rel="noopener noreferrer">quick installation instructions</a>). Once WSL is launched, the user can follow the easyDifferentialGeneCoexpressionWrapper installation instructions described below.

To run the program, you need to have the following programs installed on your computer:

<p><ul><li><b>Perl</b> (version 5.8.0 or later)</li></ul></p>
<p><ul><li><b>cURL</b> (version 7.68.0 or later)</li></ul></p>
<p><ul><li><b>R programming language</b> (version 4 or later)</li></ul></p>
By default, Perl is installed on all Linux or macOS operating systems. Likewise, cURL is installed on all macOS versions. cURL/R may not be installed on Linux/macOS. They would need to be manually installed through your operating system's software centres. cURL will be installed automatically on Linux Ubuntu by easyDifferentialGeneCoexpressionWrapper.
<p></p>

<b>Manual install:</b>
```diff
perl Makefile.PL
make
make install
```

On Linux Ubuntu, you might need to run the last command as a superuser
(`sudo make install`) and you will need to manually install (if not
already installed in your Perl 5 configuration) the following packages:

libfile-homedir-perl

```diff
sudo apt-get install -y libfile-homedir-perl
```

cpanminus

```diff
sudo apt -y install cpanminus
```

<b>CPAN install:</b>

```diff
cpanm App::easyDifferentialGeneCoexpressionWrapper
```

<b>To uninstall:</b>

```diff
cpanm --uninstall App::easyDifferentialGeneCoexpressionWrapper
```
On Linux Ubuntu, you might need to run the two previous CPAN commands as a superuser (`sudo cpanm App::easyDifferentialGeneCoexpressionWrapper` and `sudo cpanm --uninstall App::easyDifferentialGeneCoexpressionWrapper`).

## Execution instructions
The command for running easyDifferentialGeneCoexpressionWrapper is:

```diff
easyDifferentialGeneCoexpressionWrapper -a "PROBESETS_OR_GENE_SYMBOLS" -f "INPUT_FILE" -d "GEO_DATASET_CODE" -v "FEATURE_NAME" -v1 "CONDITION_1" -v2 "CONDITION_2" -o "OUTPUT_FILE"
```

An example usage command for computing the differential coexpression of probesets in the (<a href="https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE30201" target="_blank" rel="noopener noreferrer">GSE30201 gene expression dataset</a>) is: 

```diff
easyDifferentialGeneCoexpressionWrapper -a "PROBESETS" -f "dc_probeset_list03.csv" -d "GSE30201" -v "source_name_ch1" -v1 "Patient" -v2 "Normal" -o result.out
```
When using this command, the output files of easyDifferentialGeneCoexpressionWrapper will be found in the `~/easyDifferentialGeneCoexpressionWrapper_files/results/` directory, created in the user's home directory.

The mandatory command line options are described below:

-a <PROBESETS_OR_GENE_SYMBOLS>

A flag to indicate type of data (probesets or gene symbols) being read during execution

-f <INPUT_FILE>

The name of the CSV file listing the probesets or the gene symbols

-d <GEO_DATASET_CODE>

GEO dataset code of the microarray platform for which the probeset-gene symbol mapping should be done

-v <FEATURE_NAME>

Name of the feature of the dataset that contains the two conditions to investigate

-v1 <CONDITION_1>

Name of the first condition in the feature to discriminate (for example, "healthy")

-v2 <CONDITION_2>

Name of the second condition in the feature to discriminate (for example, "can-
cer")

-o <OUTPUT_FILE>

Name of the output file where the output data for the differential coexpression of probesets are written


<p>Help information can be read by typing the following command:</p>

```diff
easyDifferentialGeneCoexpressionWrapper -h
```

<p>This command will print the following instructions:</p>

```diff
Usage: easyDifferentialGeneCoexpressionWrapper -h

Mandatory arguments:
	-a                    GENE_SYMBOLS
	-f                    user-specified CSV file
	-d                    GEO dataset code
	-v                    feature name
	-v1                   condition 1
	-v2                   condition 2
	-o                    output results file
	-h                    show help message and exit
```

## Copyright and License

Copyright 2022 by Abbas Alameer (Kuwait University)

This program is free software; you can redistribute it and/or modify
it under the terms of the <a href="http://www.gnu.org/licenses/gpl-2.0-standalone.html" target="_blank" rel="noopener noreferrer">GNU General Public License, version 2 (GPLv2).</a>

## Contact
<p>easyDifferentialGeneCoexpressionWrapper was developed by:<br>
<a href="http://kuweb.ku.edu.kw/biosc/People/AcademicStaff/Dr.AbbasAlameer/index.htm" target="_blank" rel="noopener noreferrer">Abbas Alameer</a> (Kuwait University)</br>

For information, please contact Abbas Alameer at abbas.alameer(AT)ku.edu.kw</p>
