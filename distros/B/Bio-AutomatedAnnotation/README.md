# Bio-AutomatedAnnotation
Perl module to take in an genomic assembly and produce annoation

[![Build Status](https://travis-ci.org/sanger-pathogens/Bio-AutomatedAnnotation.svg?branch=master)](https://travis-ci.org/sanger-pathogens/Bio-AutomatedAnnotation)  
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-brightgreen.svg)](https://github.com/sanger-pathogens/Bio-AutomatedAnnotation/blob/master/GPL-LICENSE)   
[![status](https://img.shields.io/badge/MGEN-10.1099%2Fmgen.0.000083-brightgreen.svg)](http://mgen.microbiologyresearch.org/content/journal/mgen/10.1099/mgen.0.000083)

## Contents
  * [Introduction](#introduction)
  * [Installation](#installation)
    * [Required dependencies](#required-dependencies)
    * [From CPAN](#from-cpan)
    * [From source](#from-source)
    * [Running the tests](#running-the-tests)
  * [Usage](#usage)
  * [License](#license)
  * [Feedback/Issues](#feedbackissues)
  * [Citation](#citation)

## Introduction
Bio-AutomatedAnnotation is a Perl module that takes in a genomic assembly and produces annoation. The underlying software is [Prokka](https://github.com/tseemann/prokka).

## Installation
Bio-AutomatedAnnotation has the following dependencies:

### Required dependencies
* [parallel](https://www.gnu.org/software/parallel/)
* [prodigal](https://github.com/hyattpd/Prodigal)
* [HMMER](http://hmmer.org/)
* [BLAST+](https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download)

There are a number of ways to install Bio-AutomatedAnnotation and details are provided below. If you encounter an issue when installing Bio-AutomatedAnnotation please contact your local system administrator. If you encounter a bug please log it [here](https://github.com/sanger-pathogens/Bio-AutomatedAnnotation/issues) or email us at path-help@sanger.ac.uk.

### From CPAN
Install capnminus:   
  
`apt-get install cpanminus`   
  
Then install Bio::AutomatedAnnotation:   
  
`cpanm Bio::AutomatedAnnotation`   
   
### From source
Clone the repository:   
   
`git clone https://github.com/sanger-pathogens/Bio-AutomatedAnnotation.git`   
   
Move into the directory and install all dependencies using DistZilla:   
  
```
cd Bio-AutomatedAnnotation
dzil authordeps --missing | cpanm
dzil listdeps --missing | cpanm
./install_dependencies.sh
```
  
Run the tests:   
  
`dzil test`   
If the tests pass, install pipelines_reporting:   
  
`dzil install`   

### Running the tests
The test can be run with dzil from the top level directory:  
  
`dzil test`  

## Usage
Automated annotation of assemblies:
```
use Bio::AutomatedAnnotation;
my $obj = Bio::AutomatedAnnotation->new(
   assembly_file    => $assembly_file,
   annotation_tool  => $annotation_tool,
   sample_name      => $lane_name,
   accession_number => $accession,
   dbdir            => $dbdir,
   tmp_directory    => $tmp_directory
 );
$obj->annotate;
```

## License
Bio-AutomatedAnnotation is free software, licensed under [GPLv3](https://github.com/sanger-pathogens/Bio-AutomatedAnnotation/blob/master/GPL-LICENSE).

## Feedback/Issues
Please report any issues to the [issues page](https://github.com/sanger-pathogens/Bio-AutomatedAnnotation/issues) or email path-help@sanger.ac.uk.

## Citation
If you use this software please cite:

__Prokka: rapid prokaryotic genome annotation.__   
Seemann T., Bioinformatics. 2014 Jul 15;30(14):2068-9. doi: [10.1093/bioinformatics/btu153](https://www.ncbi.nlm.nih.gov/pubmed/24642063). Epub 2014 Mar 18.   

__Robust high throughput prokaryote de novo assembly and improvement pipeline for Illumina data__   
Page AJ, De Silva, N., Hunt M, Quail MA, Parkhill J, Harris SR, Otto TD, Keane JA, Microbial Genomics, 2016. doi: [10.1099/mgen.0.000083](http://mgen.microbiologyresearch.org/content/journal/mgen/10.1099/mgen.0.000083)
