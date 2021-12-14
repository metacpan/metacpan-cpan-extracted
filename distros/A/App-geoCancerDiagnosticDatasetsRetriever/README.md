# geoCancerDiagnosticDatasetsRetriever
GEO Cancer Diagnostic Datasets Retriever is a bioinformatics tool for cancer diagnostic dataset retrieval from the GEO website.
## Summary
<p>Gene Expression Omnibus (GEO) Cancer Diagnostic Datasets Retriever is a Bioinformatics tool for cancer diagnostic dataset retrieval from the GEO database. It requires a GeoDatasets input file listing all GSE dataset entries for a specific cancer (for example, myelodysplastic syndrome), obtained as a download from the GEO database. This Bioinformatics tool functions by applying keyword filters to examine individual GSE dataset entries listed in a GEO DataSets input file. The first Diagnostic text filter flags for diagnostic keywords (for example, “diagnosis” or “health”) used by clinical science researchers and present in the title/abstract entries. Next, a flagged dataset is examined (by a second Diagnostic text filter) for diagnostic keywords, which may be present in the "Overall design" section of a GSE dataset. If found, this tool outputs the GSE code of the likely diagnostic dataset. If not found by the second filter, a more intensive filtering stage is performed. Here, this tool runs an R script (`healthyControlsPresentInputParams.r`) whose function is to detect desired keywords in the .SOFT file of this dataset and identify if it is a likely diagnostic dataset.</p>

## geoCancerDiagnosticDatasetsRetriever dependencies
The dependencies (or packages) used by geoCancerDiagnosticDatasetsRetriever are:

<p><ul><li>strict</li></ul></p>
<p><ul><li>warnings</li></ul></p>
<p><ul><li>Term::ANSIColor</li></ul></p>
<p><ul><li>Getopt::Std</li></ul></p>
<p><ul><li>LWP::Simple</li></ul></p>
<p><ul><li>File::Basename</li></ul></p>
<p><ul><li>File::HomeDir</li></ul></p>
<p><ul><li>App::cpanminus</li></ul></p>
<p><ul><li>Net::SSLeay</li></ul></p>


## Installation
geoCancerDiagnosticDatasetsRetriever can be used on any Linux, macOS, or Windows machines. On the Windows operating system you will need to install the Windows Subsystem for Linux (WSL) compatibility layer (<a href="https://docs.microsoft.com/en-us/windows/wsl/install" target="_blank" rel="noopener noreferrer">quick installation instructions</a>). Once WSL is launched, the user can follow the geoCancerDiagnosticDatasetsRetriever installation instructions described below.

To run the program, you need to have the following programs installed on your computer:

<p><ul><li><b>Perl</b> (version 5.8.0 or later)</li></ul></p>
<p><ul><li><b>cURL</b> (version 7.68.0 or later)</li></ul></p>
<p><ul><li><b>Lynx</b> (version 2.9.0dev.5 or later)</li></ul></p>
<p><ul><li><b>R programming language</b> (version 4 or later)</li></ul></p>
By default, Perl is installed on all Linux or macOS operating systems. Likewise, cURL is installed on all macOS versions. cURL/R may not be installed on Linux/macOS or Lynx on macOS. They would need to be manually installed through your operating system's software centres. cURL and Lynx will be installed automatically on Linux Ubuntu by geoCancerDiagnosticDatasetsRetriever.
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
LWP::Simple

```diff
perl -MCPAN -e 'install "LWP::Simple"'
```

libnet-ssleay-perl

```diff
sudo apt-get install -y libnet-ssleay-perl
```

<b>CPAN install:</b>

```diff
cpanm App::geoCancerDiagnosticDatasetsRetriever
```

<b>To uninstall:</b>

```diff
cpanm --uninstall App::geoCancerDiagnosticDatasetsRetriever
```
On Linux Ubuntu, you might need to run the two previous CPAN commands as a superuser (`sudo cpanm App::geoCancerDiagnosticDatasetsRetriever` and `sudo cpanm --uninstall App::geoCancerDiagnosticDatasetsRetriever`).

## Data file
The required input file is a GEO DataSets file obtainable as a download  from <a href="https://www.ncbi.nlm.nih.gov/gds/" target="_blank" rel="noopener noreferrer">GEO DataSets</a>, upon querying for any particular cancer (for example, myelodysplastic syndrome) in geoCancerDiagnosticDatasetsRetriever.

## Execution instructions
The basic usage for running geoCancerDiagnosticDatasetsRetriever is:

```diff
geoCancerDiagnosticDatasetsRetriever -d "CANCER_TYPE"
```

An example basic usage command using "myelodysplastic syndrome" as a query: 

```diff
geoCancerDiagnosticDatasetsRetriever -d "myelodysplastic syndrome"
```
With the basic usage command, the mandatory -d (download) flag is used to download and then retrieve myelodysplastic syndrome diagnostic dataset(s) associated with the GPL570 platform code (default selection). When using this command, the input and output files of geoCancerDiagnosticDatasetsRetriever will be found in the `~/geoCancerDiagnosticDatasetsRetriever_files/data/` and `~/geoCancerDiagnosticDatasetsRetriever_files/results/` directories, respectively.

For specialized options, allowing more fine-grained user control, the following options are made available:

-p <list of GPL platform codes>

A list of GPL platform codes may be specified prior to execution, for expanding diagnostic datasets retrieval for a particular cancer (such as myelodysplastic syndrome). For example:

```diff
geoCancerDiagnosticDatasetsRetriever -d "myelodysplastic syndrome" -p "GPL570 GPL97 GPL96"
```

-f <user-specified absolute path to save results files>

A user-specified absolute path to save results files (overriding the default results directory) may by specified prior to execution. For example:

```diff
geoCancerDiagnosticDatasetsRetriever -d "myelodysplastic syndrome" -p "GPL570 GPL97 GPL96" -f "/Myelodysplastic_syndrome_files/"
```

With this command, the input files will be found in the same directory as a basic usage run's input files (`~/geoCancerDiagnosticDatasetsRetriever_files/data/`. The output files will be found in the user-specified directory (for example, "/Myelodysplastic_syndrome_files/"), created in the user's home directory.

-k <option to keep temporary files>

This option allows a user to keep large temporary/output files instead of them
being removed by default. For example:

```diff
geoCancerDiagnosticDatasetsRetriever -d "myelodysplastic syndrome" -p "GPL570 GPL97 GPL96" -f "/Myelodysplastic_syndrome_files/" -k
```

<p>Help information can be read by typing the following command:</p>

```diff
geoCancerDiagnosticDatasetsRetriever -h
```

<p>This command will print the following instructions:</p>

```diff
Usage: geoCancerDiagnosticDatasetsRetriever -h

Mandatory arguments:
  CANCER_TYPE           type of the cancer as query search term

Optional arguments:
  -p                    list of GPL platform codes
  -f                    user-specified absolute path to save results files
  -k                    option to keep temporary files
  -h                    show help message and exit
```

## Copyright and License

Copyright 2021 by Abbas Alameer (Kuwait University) and Davide Chicco (University of Toronto)

This program is free software; you can redistribute it and/or modify
it under the terms of the <a href="http://www.gnu.org/licenses/gpl-2.0-standalone.html" target="_blank" rel="noopener noreferrer">GNU General Public License, version 2 (GPLv2).</a>

## Contact
<p>geoCancerDiagnosticDatasetsRetriever was developed by:<br>
<a href="http://kuweb.ku.edu.kw/biosc/People/AcademicStaff/Dr.AbbasAlameer/index.htm" target="_blank" rel="noopener noreferrer">Abbas Alameer</a> (Kuwait University) and <a href="http://www.DavideChicco.it" target="_blank" rel="noopener noreferrer">Davide Chicco</a> (University of Toronto)</br>

For information, please contact Abbas Alameer at abbas.alameer(AT)ku.edu.kw or Davide Chicco at davidechicco(AT)davidechicco.it</p>
