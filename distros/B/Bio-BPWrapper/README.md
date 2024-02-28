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

A help file with use cases is maintained at: http://diverge.hunter.cuny.edu/labwiki/Bioutils

# Install from CPAN

The git code generally has the newest code. If git is not your thing, you can also install the last release from CPAN:

```
   $ cpan install Bio::BPWrapper
   $ cpanm --sudo Bio::BPWrapper

```

A note on CPAN use with "sudo" (quote by Rocky):

 "sudo cpan" can have problems because "sudo"  runs as root but with the environment variables like PATH and PERL5LIB that were setas they were before "sudo" is run. 

In particular things like /root/.cpan/build/rlib-0.02-1 or anything under /root aren't going to be available because /root/.cpan is probably not going to be seen by the "cpan" command or whatever command is used to build the package. (Alternatives like , "cpanm", would have the same  problem too.).  So above we see a mismatched mixture of install places: some things /root/.cpan and some things /usr/share/perl/5.30. 

So something like "sudo su -" followed by cpan or cpanm probably would work better.  The dash is important here so that the root environment gets set which presumably would set PATH and PERL5LIB to have things in /root/.cpan.

If this is intended to be installed only for one person, better in my opinion would be for the user to install her/his own Perl rather than use the system Perl using Perlbrew and not use sudo su or root at all.

# Install and run from docker

Use the bpwrapper docker image. It includes `bioaln`, `biopop`, `bioseq`, and `biotree`.

To download the image so that docker recognizes it:

```console
docker pull rockyb/bpwrapper
```

For things other than getting help, you'll often need to pass a data in file to the program. Do that by sharing the
directory that the file is in on the `docker` invocation.

You'll need to pay attention to the permissions on the data file its
directory. The docker container runs as as a user that may not have
access to data. I've found however that if you put the data in `/tmp`
files will be seen inside the running docker container.

For example:

```console
$ cp test-data/cds.fas /tmp/cds.fas
$ docker run -it -v /tmp:/test-files rockyb/bpwrapper bioseq -l /test-files/cds.fas
DK2	120
W70332	120
M1608	108
F2
```

# Developers, Contact, Citation
* Yözen Hernández
* Pedro Pagan
* Girish Ramrattan
* Weigang Qiu, City University of New York, Hunter College (Correspondence: [weigang@genectr.hunter.cuny.edu)](mailto://weigang@genectr.hunter.cuny.edu))
* If you find the tools useful, please cite: Hernadez, Bernstein, et al (2018). BpWrapper::BioPerl-based sequence and tree utilities for rapid prototyping of bioinformatics pipelines. BMC Genomics 19:76. [Paper link](https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-018-2074-9).
