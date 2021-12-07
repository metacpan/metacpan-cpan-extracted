# geoCancerPrognosticDatasetsRetriever
GEO Cancer Prognostic Datasets Retriever is a bioinformatics tool for cancer prognostic dataset retrieval from the GEO website.
## Summary
<p>Gene Expression Omnibus (GEO) Cancer Prognostic Datasets Retriever is a bioinformatics tool for cancer prognostic dataset retrieval from the GEO database. It requires a GeoDatasets input file listing all GSE dataset entries for a specific cancer (for example, bladder cancer), obtained as a download from the GEO database. This bioinformatics tool functions by applying two heuristic filters to examine individual GSE dataset entries listed in a GEO DataSets input file. The Prognostic Text filter flags for prognostic keywords (ex. “prognosis” or “survival”) used by clinical scientists and present in the title/abstract entries of a GSE dataset. If found, this tool retrieves those flagged datasets. Next, the second filter (Prognostic Signature filter) filters these datasets further by applying prognostic signature pattern matching (Perl regular expression signatures) to identify if the GSE dataset is a likely prognostic dataset.</p>

## geoCancerPrognosticDatasetsRetriever dependencies
The dependencies (i.e. packages) used by geoCancerPrognosticDatasetsRetriever are:

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
geoCancerPrognosticDatasetsRetriever can be used on any Linux, macOS, or Windows machines. On the Windows operating system you will need to install the Windows Subsystem for Linux (WSL) compatibility layer (<a href="https://docs.microsoft.com/en-us/windows/wsl/install" target="_blank" rel="noopener noreferrer">quick installation instructions</a>). Once WSL is launched, the user can follow the geoCancerPrognosticDatasetsRetriever installation instructions described below.

To run the program, you need to have the following programs installed on your computer:

<p><ul><li><b>Perl</b> (version 5.8.0 or later)</li></ul></p>
<p><ul><li><b>cURL</b> (version 7.68.0 or later)</li></ul></p>
By default, Perl is installed on all Linux or macOS operating systems. Likewise, cURL is installed on all macOS versions. cURL may not be installed on Linux and would need to be manually installed through a Linux distribution’s software centre. It will be installed automatically on Linux Ubuntu by geoCancerPrognosticDatasetsRetriever.
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
cpanm App::geoCancerPrognosticDatasetsRetriever
```

<b>To uninstall:</b>

```diff
cpanm --uninstall App::geoCancerPrognosticDatasetsRetriever
```
On Linux Ubuntu, you might need to run the two previous CPAN commands as a superuser (`sudo cpanm App::geoCancerPrognosticDatasetsRetriever` and `sudo cpanm --uninstall App::geoCancerPrognosticDatasetsRetriever`).

## Data file
The required input file is a GEO DataSets file obtainable as a download  from <a href="https://www.ncbi.nlm.nih.gov/gds/" target="_blank" rel="noopener noreferrer">GEO DataSets</a>, upon querying for any particular cancer (for example, bladder cancer) in geoCancerPrognosticDatasetsRetriever.

## Execution instructions
The basic usage for running geoCancerPrognosticDatasetsRetriever is:

```diff
geoCancerPrognosticDatasetsRetriever -d "CANCER_TYPE"
```

An example basic usage command using "bladder cancer" as a query: 

```diff
geoCancerPrognosticDatasetsRetriever -d "bladder cancer"
```
With the basic usage command, the mandatory -d (download) flag is used to download and then retrieve bladder cancer prognostic dataset(s) associated with the GPL570 platform code (default selection). When using this command, the input and output files of geoCancerPrognosticDatasetsRetriever will be found in the `~/geoCancerPrognosticDatasetsRetriever_files/data/` and `~/geoCancerPrognosticDatasetsRetriever_files/results/` directories, respectively.

For specialized options, allowing more fine-grained user control, the following options are made available:

-p <list of GPL platform codes>

A list of GPL platform codes may be specified prior to execution, for expanding prognostic datasets retrieval for a particular cancer (i.e. bladder cancer). For example:

```diff
geoCancerPrognosticDatasetsRetriever -d "bladder cancer" -p "GPL570 GPL97 GPL96"
```

-f <user-specified absolute path to save results files>

A user-specified absolute path to save results files (overriding the default results directory) may by specified prior to execution. For example:

```diff
geoCancerPrognosticDatasetsRetriever -d "bladder cancer" -p "GPL570 GPL97 GPL96" -f "/Bladder_cancer_files/"
```

With this command, the input files will be found in the same directory as a basic usage run's input files (`~/geoCancerPrognosticDatasetsRetriever_files/data/`. The output files will be found in the user-specified directory (for example, "/Bladder_cancer_files/"), created in the user's home directory.

-k <option to keep temporary files>

This option allows a user to keep large temporary/output files instead of them
being removed by default. For example:

```diff
geoCancerPrognosticDatasetsRetriever -d "bladder cancer" -p "GPL570 GPL97 GPL96" -f "/Bladder_cancer_files/" -k
```

<p>Help information can be read by typing the following command:</p>

```diff
geoCancerPrognosticDatasetsRetriever -h
```

<p>This command will print the following instructions:</p>

```diff
Usage: geoCancerPrognosticDatasetsRetriever -h

Mandatory arguments:
  CANCER_TYPE           type of the cancer as query search term

Optional arguments:
  -p                    list of GPL platform codes
  -f                    user-specified absolute path to save results files
  -k                    option to keep temporary files
  -h                    show help message and exit
```

## Copyright and License

Copyright 2021 by Abbas Alameer, Kuwait University

This program is free software; you can redistribute it and/or modify
it under the terms of the <a href="http://www.gnu.org/licenses/gpl-2.0-standalone.html" target="_blank" rel="noopener noreferrer">GNU General Public License, version 2 (GPLv2).</a>

## Contact
<p>geoCancerPrognosticDatasetsRetriever was developed by:<br>
<a href="http://kuweb.ku.edu.kw/biosc/People/AcademicStaff/Dr.AbbasAlameer/index.htm" target="_blank" rel="noopener noreferrer">Abbas Alameer</a> (Bioinformatics and Molecular Modelling Group, Kuwait University), in collaboration with <a href="http://www.DavideChicco.it" target="_blank" rel="noopener noreferrer">Davide Chicco</a> (University of Toronto)</br>

For information, please contact Abbas Alameer at abbas.alameer(AT)ku.edu.kw</p>
