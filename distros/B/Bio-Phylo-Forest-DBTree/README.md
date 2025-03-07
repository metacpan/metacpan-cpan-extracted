[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1035856.svg)](https://doi.org/10.5281/zenodo.1035856)
![CPAN](https://img.shields.io/cpan/l/Bio-Phylo-Forest-DBTree?color=success)

DBTree - toolkit for megatrees in portable SQL databases
========================================================

![Figure 1](docs/fig1.svg)

An example mapping of a tree topology to a database table. The mapping is
created by processing a [Newick][12] tree file (infile.tre) as follows: 

    megatree-loader -i infile.tre -d outfile.db 
    
With this mapping, several topological queries can be performed quickly when 
loading the output file in [sqlite3][10] (or the excellent [SQLiteBrowser][11]).

```sql
-- select the most recent common ancestor of C and F
select MRCA.* from node as MRCA, node as C, node as F 
  where C.name='C' and F.name='F' 
  and MRCA.left < min(C.left,F.left) 
  and MRCA.right > max(C.right,F.right)
  order by MRCA.left desc limit 1;
 
-- select the descendants from node n2
select DESCENDANT.* from node as DESCENDANT, node as MRCA 
  where MRCA.name='n2' 
  and DESCENDANT.left > MRCA.left 
  and DESCENDANT.right < MRCA.right;
```

Using databases that are indexed in this way, significant performance increases can
be accomplished. For example, a very common usage of large, published, static 
phylogenies is to extract subtrees from them in order to use them for downstream 
analysis (e.g. in phylogenetic comparative studies). This application is so common that
it forms essentially the basis of the success of 
[Phylomatic](https://phylodiversity.net/phylomatic/) and the 
[PhyloTastic](http://phylotastic.org/) project.
A similar subtree extraction operation is also implemented by NCBI as the option to 
extract the '[common tree](https://www.ncbi.nlm.nih.gov/Taxonomy/CommonTree/wwwcmt.cgi)'
from the NCBI taxonomy. Here, this functionality is made available by the 
`megatree-pruner` program. To benchmark its performance in comparison with a naive 
approach that operates on Newick strings, a pruner script based on 
[DendroPy](https://dendropy.org/) was run side by side with the pruner on randomly
selected sets of tips from the OpenTree topology. The performance difference is shown
below:

![Figure 2](docs/fig2.svg)


Installation
------------

The following installation instructions describe three different ways to install the
package. Unless you know what you are doing, the first way is probably the best one.

### 1. From BioConda

On many Linux-like operating systems as well as MacOSX, the entire installation completes
with this single command:

    conda install -c bioconda perl-bio-phylo-forest-dbtree

### 2. From the Comprehensive Perl Archive Network (CPAN)

On many Linux-like operating systems as well as MacOSX, the entire installation completes
with this single command:

    sudo cpanm Bio::Phylo::Forest::DBTree

- **Advantages** - it's simple and all prerequisites are automatically installed. You will
  obtain the [latest stable release][5] from CPAN, which is [amply tested][6].
- **Disadvantages** - you will likely get code that is a lot older than the latest work
  on this package.

### 3. From GitHub

On many Linux-like operating systems as well as MacOSX, you can install the latest code
from the [repository][8] with this single command:

    sudo cpanm git://github.com/rvosa/bio-phylo-forest-dbtree.git

- **Advantages** - it's simple, all prerequisites are automatically installed. You will
  get the latest code, including any new features and bug fixes.
- **Disadvantages** - you will install untested, recent code, which might include new bugs 
  or other features, in your system folders.

### 4. From an archive snapshot

This is the approach you might take if you want complete control over the installation,
and/or if there is a specific archive (such as zenodo release [10.5281/zenodo.1035856][7])
you wish to install or verify. 

This approach starts by installing the prerequisites manually:

```bash
# do this only if you don't already have these already
sudo cpanm Bio::Phylo
sudo cpanm DBIx::Class
sudo cpanm DBD::SQLite
```

Then, unpack the archive, move into the top level folder, and issue the build commands:

```bash
perl Makefile.PL
make
make test
```

Finally, you can opt to install the built products (using `sudo make install`), or
keep them in the present location, which would require you to update two environment
variables:

```bash
# add the script folder inside the archive to the search path for executables
export PATH="$PATH":`pwd`/script
    
# add the lib folder to the search path for perl libraries
export PERL5LIB="$PERL5LIB":`pwd`/lib
```

BUGS
----
Please report any bugs or feature requests on the GitHub bug tracker:
https://github.com/rvosa/bio-phylo-forest-dbtree/issues

COPYRIGHT & LICENSE
-------------------
Copyright 2013-2019 Rutger Vos, All Rights Reserved. This program is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself, i.e.
a choice between the following licenses:
- [The Artistic License](COPYING)
- [GNU General Public License v3.0](LICENSE)

SEE ALSO
--------
Several curated, large phylogenies released by ongoing projects are made available as
database files that this distribution can operate on. These are:
- PhyloTree ([van Oven et al., 2009][1])   - [10.6084/m9.figshare.4620757.v1](http://doi.org/10.6084/m9.figshare.4620757.v1)
- D-Place ([Kirby et al., 2016][2])        - [10.6084/m9.figshare.4620217.v1](http://doi.org/10.6084/m9.figshare.4620217.v1)
- NCBI taxonomy ([Federhen, 2011][3])      - [10.6084/m9.figshare.4620733.v1](http://doi.org/10.6084/m9.figshare.4620733.v1)
- Green Genes ([DeSantis et al., 2006][4]) - [10.6084/m9.figshare.4620214.v1](http://doi.org/10.6084/m9.figshare.4620214.v1)
- ALLMB ([Smith & Brown, 2018][13])        - [10.6084/m9.figshare.9747638](https://doi.org/10.6084/m9.figshare.9747638)
- Open Tree ([Hinchliff et al.,2015][14])  - [10.6084/m9.figshare.9750509](https://doi.org/10.6084/m9.figshare.9750509)


[1]: http://doi.org/10.1002/humu.20921
[2]: http://doi.org/10.1371/journal.pone.0158391
[3]: http://doi.org/10.1093/nar/gkr1178
[4]: http://doi.org/10.1128/AEM.03006-05
[5]: https://metacpan.org/release/Bio-Phylo-Forest-DBTree
[6]: http://www.cpantesters.org/distro/B/Bio-Phylo-Forest-DBTree.html
[7]: https://doi.org/10.5281/zenodo.1035856
[8]: https://github.com/rvosa/bio-phylo-forest-dbtree
[9]: https://metacpan.org/pod/distribution/App-cpanminus/bin/cpanm
[10]: https://www.sqlite.org/index.html
[11]: https://sqlitebrowser.org/
[12]: http://evolution.genetics.washington.edu/phylip/newicktree.html
[13]: https://doi.org/10.1002/ajb2.1019
[14]: https://doi.org/10.1073/pnas.1423041112
