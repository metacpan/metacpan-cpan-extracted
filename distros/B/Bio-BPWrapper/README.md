[![Build Status](https://travis-ci.org/rocky/p5-bpwrapper.png)](https://travis-ci.org/rocky/p5-bpwrapper)

# Description
Here we have command-line utilities that are wrappers of popular BioPerl classes (`Bio::SeqIO`, `Bio::Seq`, `Bio::AlignIO`, `Bio::SimpleAlign`, etc). The motivation is to relieve BioPerl users from writing full-blown scripts for routine manipulations of sequences, alignments, trees, and others. For common operations of sequences and alignments, bp-utils make it easy to create workflows with a single BASH script containing a combination of bp-utils calls (and no Perl or BioPerl coding is necessary).

Internally, the programs follow a "Wrap, don't Write" design principle. That is, we have full faith in the robustness of the BioPerl development framework. As such, bp-utils methods should ALL be wrappers to BioPerl methdos so that exceptions can be handled properly by BioPerl.

However, some methods are new and unique to this package. In the future, all non-wrapper methods in bp-utils should ideally be re-factored into BioPerl class methods. This way, the bp-utils layer could be as thin as possibe and new methods could be added with minimal coding.

See [BioUtils](http://diverge.hunter.cuny.edu/labwiki/Bioutils) for
more information.

# Dependencies
* Perl 5.10.0 or higher
* BioPerl 1.6.924 or higher
* Module::Build
* Test::More

You can check your version of perl using

```
perl -v
```

and your version of BioPerl using

```
perl -MBio::Root::Version -Mversion -e 'print version->parse($Bio::Root::Version::VERSION)->normal,"\n"'
```

in a terminal.

# Install & Test from git:

    $ git clone https://github.com/bioperl/bp-utils
	$ cd bp-utils
	$ cpan Module::Build  # may need sudo
	$ perl ./Build.PL
	$ ./Build installdeps
	$ ./Build
	$ make check  # runs both Perl and Bash test scripts
	$ ./Build install # may require sudo or root access

# Install & Test (assuming a UNIX/Linux-like environment)
* Go to repository: https://github.com/bioperl/bp-utils
* Download current release: https://github.com/bioperl/bp-utils/releases/download/v1.0/bp-utils-release-v1.0.tar.gz
* Unzip and untar

        tar -zxf bp-utils-current-release.tar.gz

* Add "bp-utils" directory to your `$PATH`:

        # Add this line to your .profile (or equivalent) to make it permanent
        export PATH=$PATH:/path/to/bputils

* Run test scripts: `./Test-bioseq` and `./Test-bioaln`

# Get Help
* Run `perldoc`: e.g., `perldoc bioseq`; `perldoc bioaln`
* Run with `--help` or `--man`: e.g., `bioseq --help`; `bioaln --help`
* A help file with use cases is maintained at: http://diverge.hunter.cuny.edu/labwiki/Bioutils

# Developers, Contact, Citation
* Yozen Hernandez
* Pedro Pagan
* Girish Ramrattan
* Weigang Qiu, City University of New York, Hunter College (Correspondence: weigang@genectr.hunter.cuny.edu)
* If you find the tools useful, please cite: Hernandez Y., P. Pagan,  G. Ramrattan, & W.-G. Qiu. (2015). Bp-utils (Release 1.0): BioPerl-based command-line utilities for manipulating sequences, alignments, and phylogenetic trees. URL: https://github.com/bioperl/bp-utils.
