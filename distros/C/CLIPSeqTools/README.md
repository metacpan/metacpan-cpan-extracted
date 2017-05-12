[![Build Status](https://travis-ci.org/mnsmar/clipseqtools.svg?branch=master)](https://travis-ci.org/mnsmar/clipseqtools)

# Description

_CLIPSeqTools_ is a collection of command line applications used for the
analysis of CLIP-Seq datasets. CLIP-Seq stands for UV cross-linking and
immunoprecipitation coupled with high-throughput sequencing.

_CLIPSeqTools_ has applications for a wide range of analyses that will give an
in depth view of the analysed dataset. Examples of such analyses are: genome
read coverage, distibution of reads on genic elements, motif enrichment,
relative position of reads of two datasets, differential gene counts, etc).

_CLIPSeqTools_ is grouped in 4 toolboxes each of which performs a specific set
of analyses:

1. `clipseqtools`

	Application to analyse a single CLIP-Seq library.

2. `clipseqtools-compare`

	Application to compare two CLIP-Seq libraries. (Can be used after
	`clipseqtools` is run on each dataset).

3. `clipseqtools-plots`

	Helper application to create plots for the output of `clipseqtools` and
	`clipseqtools-compare`.  (Note: Usually the plotting functions are called
	from the analysis scripts themselves using the `--plot`).

4. `clipseqtools-preprocess`

	Application to process a FastQ file into files that are compatible with
	`clipseqtools`. (Among other things, it aligns the reads on the reference
	genome, annotate the alignments with genic, repeat masker and phastCons
	conservation information).

Below you can find installation instuctions and usage examples but for the
most up to date information please look in the project's
[website](http://mourelatos.med.upenn.edu/clipseqtools/)

# Installation

_CLIPSeqTools_ is a Perl module and should be compatible with any Unix style
operating system with the Perl programming language installed.  Chances are
that if you are working on a Mac or a Linux operating system you already have
Perl installed.

Although the installation is straighforward for people that have some
experience with command line installations it can be slightly cumbersome for
people with no such experience. For this, we suggest to contact your IT
department or someone able to help you with the installation process.

## Prerequisites

_CLIPSeqTools_ relies on a few external programs for things like the alignment
and the plotting functionality. To successfully install and use _CLIPSeqTools_
you will need to have the following tools installed and available in the users
path:

- `R`

	Language for statistical computing. To download R statistical package and
	for installation instructions refer to
	[http://www.r-project.org/](http://www.r-project.org/)

- `cutadapt`

	To remove 5' end adaptor sequence from reads (only if you use
	clipseq-tools preprocess). To download cutadapt and for installation
	instructions refer to
	[https://code.google.com/p/cutadapt/](https://code.google.com/p/cutadapt/)

- `STAR`

	For the alignment of reads on a reference genome (only if you use
	clipseqtools-preprocess). To download STAR and for installation
	instructions refer to
	[https://code.google.com/p/rna-star/](https://code.google.com/p/rna-star/)

- Memory

	If you plan on using `clipseqtools-preprocess` to do the alignment of
	reads on a reference genome you will need a machine with at least 16 GB of
	RAM. The reason is that this is the amount of memory required by the STAR
	aligner. The amount of required memory might be smaller for smaller
	genomes but don't take our word for it.

## Installing CLIPSeqTools

The simplest way to install _CLIPSeqTools_ is to use CPAN which is the a
package manager for Perl modules.  If you are the system administrator and
want to install the module system-wide, you need to switch to your root user.

To fire up the CPAN module, just get to your terminal (Command Line) and run
the following command:

    perl -MCPAN -e shell

If this is the first time you've run CPAN, it's going to ask you a series of
questions - in most cases the default answer is fine.

Once you find yourself staring at the `cpan>` command prompt type:

    install CLIPSeqTools

CPAN should take it from there and install _CLIPSeqTools_.

# Getting Started

## Download required files

_CLIPSeqTools_ relies on certain data and annotation files to function
properly. For the user's convenience, we provide the required files for 3
species - human (assembly: hg19), mouse (assembly: mm9) and fly (assembly:
dme3) on our public server.

You may access these file at this
[link](http://mourelatos.med.upenn.edu/clipseqtools/data/)

## Prepare your working directory

To keep things simle, in the following we assume you are using a working
directory named `clip` and that you work for human (hg19) species.

1. Create a new directory named `data` inside `clip/`.

	This creates the path `clip/data/`

2. Download file `hg19.tgz` from our public server using the link given
previously

3. Put the downloaded file into the new directory `clip/data/` and unzip it.

	This creates the path `clip/data/hg19/`.
	To save disk space you can now remove file `hg19.tgz`.

4. Assuming your CLIP-Seq data are for _proteinA_, create a new directory
named `proteinA` inside `clip/`.

	This creates the path `clip/proteinA/`

5. Move/Copy the FastQ file with the CLIP-Seq reads into `clip/proteinA/` and
rename it to _reads.fastq_.

	__Important:__ Unzip it, if it is zipped.

6. Open a terminal and navigate to your working directory.

        cd /path/to/clip/

7. List all directories and files with the following command.

        find .

	You should now have a working directory that looks like this:

        clip/
        clip/data/
        clip/data/hg19/
        clip/proteinA/
        clip/proteinA/reads.fastq

	Verify that everything is in place.

## Align and process FastQ files with `clipseqtools-preprocess`

To process the fastq file, align the reads on the reference genome, annotate
the alignments with genic, repeat masker and phastCons conservation
information run the following command substituting \<PLACEHOLDER\> with the
appropriate information.

- If you are running on a machine with **more** than 32GB RAM.

        clipseqtools-preprocess all \
          --adaptor <5_END_ADAPTOR> \
          --fastq proteinA/reads.fastq \
          --gtf data/hg19/annotation/UCSC_gene_parts_genename.gtf \
          --rmsk data/hg19/annotation/rmsk.bed \
          --star_genome data/hg19/STAR/index/ \
          --phyloP_dir data/hg19/phyloP/ \
          --rname_sizes data/hg19/chrom.sizes \
          --o_prefix clip/proteinA/ \
          -v

- If you are running on a machine with **more** than 16GB RAM.

        clipseqtools-preprocess all \
          --adaptor <5_END_ADAPTOR> \
          --fastq proteinA/reads.fastq \
          --gtf data/hg19/annotation/UCSC_gene_parts_genename.gtf \
          --rmsk data/hg19/annotation/rmsk.bed \
          --star_genome data/hg19/STAR/index-sparsed2/ \
          --phyloP_dir data/hg19/phyloP/ \
          --rname_sizes data/hg19/chrom.sizes \
          --o_prefix clip/proteinA/ \
          -v

The command above is doing a lot of things and it's going to take quite some
time. Most likely it will take at least a few hours, so be **patient** and **do
NOT close the terminal**.  When it finishes you will find all files required to
run `clipseqtools` in the next step under `clip/proteinA/`.

## Analyse a library with `clipseqtools`

To run `clipseqtools`.

    clipseqtools all \
      --database proteinA/reads.adtrim.star_Aligned.out.single.sorted.db \
      --gtf data/hg19/annotation/UCSC_gene_parts_genename.gtf \
      --rname_sizes data/hg19/chrom.sizes \
      --o_prefix clip/proteinA/ \
      --plot \
      -v

The command above is doing many things and is going to take some time,
probably a few hours so be **patient** and **do NOT close the terminal**.  When
it finishes you will find the result files (tables and figures) in
`clip/proteinA/`.

To view the table files (those with .tab extension) you can open them with a
spreadsheet program like MS Excel or copy & paste their content directly into
a spreadsheet.

## Compare two libraries with `clipseqtools-compare`

Assuming you have two libraries on which you have previously run
`clipseqtools` you can now use `clipseqtools-compare` to compare their
results.  For simplicity, we assume the two directories containing the
`clipseqtools` results for these two libraries are `clip/proteinA/` and
`clip/proteinB/`.  To compare the results for the two libraries run the
following command.

    clipseqtools-compare all \
      --database clip/proteinA/reads.adtrim.star_Aligned.out.single.sorted.db \
      --res_prefix clip/proteinA/ \
      --r_database clip/proteinB/reads.adtrim.star_Aligned.out.single.sorted.db \
      --r_res_prefix clip/proteinB/ \
      --rname_sizes data/hg19/chrom.sizes \
      --o_prefix clip/proteinA_vs_B/ \
      --plot \
      -v

Note that with the above command we are comparing library _proteinA_ against
the **reference** library _proteinB_.

The command is going to take some time so be patient. When it finishes you
will find the result files for the analyses in `clip/proteinA_vs_B/`.

# License
This library is free software and may be distributed under the same terms as perl itself.

This library is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of merchantability or fitness for a particular purpose.
