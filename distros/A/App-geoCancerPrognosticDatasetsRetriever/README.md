# geoCancerPrognosticDatasetsRetriever
GEO Cancer Prognostic Datasets Retriever is a bioinformatics tool for cancer prognostic dataset retrieval from the GEO website.
## Summary
<p>Gene Expression Omnibus (GEO) Cancer Prognostic Datasets Retriever is a bioinformatics tool for cancer prognostic dataset retrieval from the GEO database. It requires a GeoDatasets input file listing all GSE dataset entries for a specific cancer (for example, bladder cancer), obtained as a download from the GEO database. This bioinformatics tool functions by applying two heuristic filters to examine individual GSE dataset entries listed in a GEO DataSets input file. The Prognostic Text filter flags for prognostic keywords (ex. “prognosis” or “survival”) used by clinical scientists and present in the title/abstract entries of a GSE dataset. If found, this tool retrieves those flagged datasets. Next, the second filter (Prognostic Signature filter) filters these datasets further by applying prognostic signature pattern matching (Perl regular expression signatures) to identify if the GSE dataset is a likely prognostic dataset.</p>

## Installation
geoCancerPrognosticDatasetsRetriever can be used on any Linux or macOS machines. To run the program, you need to have the following programs installed on your computer:

<p><ul><li><b>Perl</b> (version 5.30.0 or later)</li></ul></p>
<p><ul><li><b>cURL</b> (version 7.68.0 or later)</li></ul></p>
By default, Perl is installed on all Linux or macOS operating systems. Likewise, cURL is installed on all macOS versions. cURL may not be installed on Linux and would need to be manually installed through a Linux distribution’s software centre. It will be installed automatically on Linux Ubuntu by geoCancerPrognosticDatasetsRetriever.
<p></p>

Manual install:
```diff
perl Makefile.PL
make
make install
```

On Linux Ubuntu, you might need to run the last command as a superuser
(`sudo make install`) and to manually install the libfile-homedir-perl
package (`sudo apt-get install -y libfile-homedir-perl`), if not
already installed in your Perl 5 configuration.

CPAN install:

```diff
cpanm App::geoCancerPrognosticDatasetsRetriever
```

To uninstall:

```diff
cpanm --uninstall App::geoCancerPrognosticDatasetsRetriever
```

## Data file
The required input file is a GEO DataSets file obtainable as a download  from <a href="https://www.ncbi.nlm.nih.gov/gds/" target="_blank" rel="noopener noreferrer">GEO DataSets</a>, upon querying for any particular cancer (for example, bladder cancer) in geoCancerPrognosticDatasetsRetriever.

## Execution instructions
Run geoCancerPrognosticDatasetsRetriever with the following command:

```diff
geoCancerPrognosticDatasetsRetriever -d "CANCER_TYPE" -p "PLATFORMS_CODES"
```

An example command using "bladder cancer" as a query: 

```diff
geoCancerPrognosticDatasetsRetriever -d "bladder cancer" -p "GPL570 GPL97 GPL96"
```

The input and output files of geoCancerPrognosticDatasetsRetriever will be found in the `~/geoCancerPrognosticDatasetsRetriever_files/data/` and `~/geoCancerPrognosticDatasetsRetriever_files/results/` directories, respectively.

<p>Help information can be read by typing the following command:</p>  

```diff
geoCancerPrognosticDatasetsRetriever -h
```

<p>This command will print the following instructions:</p>

```diff
Usage: geoCancerPrognosticDatasetsRetriever -h

Mandatory arguments:
  CANCER_TYPE           type of the cancer as query search term
  PLATFORM_CODES        list of GPL platform codes

  Optional arguments:
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
