[![Build Status](https://travis-ci.org/bioperl/p5-bpwrapper.png)](https://travis-ci.org/bioperl/p5-bpwrapper)

# Description

Here we have command-line utilities for popular
[Bio::Perl](https://metacpan.org/pod/Bio::Perl) classes.

Specifically:

* [bioaln](https://github.com/bioperl/p5-bpwrapper/wiki/bioaln): [`Bio::SimpleAlign`](https://metacpan.org/pod/Bio::SimpleAlign) with additional methods
* [biopop](https://github.com/bioperl/p5-bpwrapper/wiki/biopop): [`Bio::PopGen`](https://metacpan.org/pod/Bio::PopGen) which can be converted from `Bio::SimpleAlign`; and additional methods
* [bioseq](https://github.com/bioperl/p5-bpwrapper/wiki/bioseq):  [`Bio::Seq`](https://metacpan.org/pod/Bio::Seq) with additional methods
* [biotree](https://github.com/bioperl/p5-bpwrapper/wiki/biotree): [`Bio::Tree`](https://metacpan.org/pod/Bio::Seq) with additional methods

The motivation is to allow users to perform routine BioPerl manipulations of sequences, alignments, and trees without having to write full-blown scripts. For common operations of sequences and alignments,
Bio::BPWrapper makes it easy to create workflows with a single BASH
script containing a combination command-line calls: no Perl or BioPerl
coding is necessary.

Internally, the programs follow a "Wrap, don't Write" design
principle. That is, we have full faith in the robustness of the
BioPerl development framework. As such, methods here should all be
wrappers to BioPerl methods so that exceptions can be handled properly
by BioPerl.

The Bio::BPWrapper module also include some useful methods which are not part of
Bio::Perl.

# Install & Test from git:

You need Perl 5.010 or later. There are other Perl dependencies, but the
package will check and install that.

```console
    $ git clone https://github.com/bioperl/p5-bpwrapper
    $ cd p5-bpwrapper
    $ cpan Module::Build  # may need sudo
    $ perl ./Build.PL
    $ ./Build installdeps
    $ ./Build
    $ make check
    $ ./Build install # may require sudo or root access
```

Each script, [`bioaln`](https://github.com/bioperl/p5-bpwrapper/wiki/bioaln), [`biopop`](https://metacpan.org/pod/distribution/Bio-BPWrapper/bin/biopop), [`bioseq`](https://github.com/bioperl/p5-bpwrapper/wiki/bioseq) and [`biotree`](https://github.com/bioperl/p5-bpwrapper/wiki/biotree) give shorter usage help when given command-line option `--help`. Manual-page help is also giving the option `--man`.

Documentation is maintained in [this project's wiki](https://github.com/bioperl/p5-bpwrapper/wiki).

A help file with use cases is maintained at: http://diverge.hunter.cuny.edu/labwiki/Bioutils

# Install from CPAN

The git code generally has the newest code. If git is not your thing, you can also install the last release from CPAN:

```
   $ cpan install Bio::BPWrapper
```

# Developers, Contact, Citation
* Yözen Hernández
* Pedro Pagan
* Girish Ramrattan
* Weigang Qiu, City University of New York, Hunter College (Correspondence: [weigang@genectr.hunter.cuny.edu)](mailto://weigang@genectr.hunter.cuny.edu))
* If you find the tools useful, please cite: Y. Hernández, P. Pagan,  G. Ramrattan, & W.-G. Qiu. (2015). Bp-utils (Release 1.0): BioPerl-based command-line utilities for manipulating sequences, alignments, and phylogenetic trees. URL: https://github.com/bioperl/bp-utils.
