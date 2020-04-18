![](https://cpants.cpanauthors.org/release/RVOSA/Bio-Phylo-CIPRES-v0.2.0.svg)

![](http://www.phylo.org/images/interface/logo_cipres.gif)

# Bio::Phylo::CIPRES
Phylogenomic analysis on the CIPRES REST portal

## Prerequisites
Usage of CIPRES requires a 
[DEVELOPER account](https://www.phylo.org/restusers/register.action) 
(not a normal user account) for the CIPRES REST API (CRA), and a 
[registration](https://www.phylo.org/restusers/createApplication!input.action) for the app 
`corvid19_phylogeny`.With the account and app key, you can then populate a YAML file 
`cipres_appinfo.yml` thusly, substituting the fields with pointy brackets with the 
appropriate values:

```yaml
---
URL: https://cipresrest.sdsc.edu/cipresrest/v1
KEY: <app key>
CRA_USER: <user>
PASSWORD: <pass>
```

Additional prerequisites, which should be resolved automatically during your chosen 
installation procedure (conda, cpanm) are listed under the `PREREQ_PM` field in the file 
[Makefile.PL](Makefile.PL).

## Installation

### CPANM

```bash
$ cpanm Bio::Phylo::CIPRES
```

## Example workflow

### 1. Aligning sequences

To align sequences in a FASTA file with 
[MAFFT](http://www.phylo.org/index.php/rest/mafft_xsede.html):

```bash
cipresrun \
     -t MAFFT_XSEDE \
     -p vparam.anysymbol_=1 \
     -i <infile> \
     -y cipres_appinfo.yml \
     -o output.mafft=/path/to/outfile.fasta
```

- By adding the `-v` (or `--verbose`) flag, the XML returned by the server is shown. In 
  the last status check, this will show additional values for `-o`, e.g. to retrieve 
  STDERR and other outputs.
- Most other parameters shown on the REST documentation page can also be used.
- The output is written to a file with the same name is the output field (i.e. in this 
  case a file called `output.mafft`), which optionally ends up in a `-wd` working 
  directory.

### 2. Inferring trees

To infer trees from an aligned FASTA file using 
[IQTree](http://www.phylo.org/index.php/rest/iqtree_xsede.html):

```bash
cipresrun \
    -t IQTREE_XSEDE \
    -p vparam.specify_runtype_=2 \
    -p vparam.specify_dnamodel_=HKY \
    -p vparam.bootstrap_type_=bb \
    -p vparam.use_bnni_=1 \
    -p vparam.num_bootreps_=1000 \
    -p vparam.specify_numparts_=1 \
    -i /path/to/outfile.fasta \
    -y cipres_appinfo.yml \    
    -o output.contree=/path/to/tree.dnd
```
