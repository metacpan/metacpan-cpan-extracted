# Synopsis

Read a molecular structure file and get everything in it back as a hash of
hashes — the header, the annotations, every chain, every residue, every atom,
and the single-letter sequence of each chain — in one call.

    use Chem::Structure::Parser;

    my $info = structure_info('1a22.ent.pdb');

    print $info->{id};                                  # 1A22
    print $info->{resolution};                          # 2.6
    print $info->{chains}{A}{sequence};                 # FPTIPLSRLFDNAMLRAHRLHQL...
    print $info->{chains}{A}{molecule};                 # GROWTH HORMONE
    print $info->{chains}{A}{residues}{54}{resname};    # PHE
    print $info->{chains}{A}{residues}{54}{atoms}{CA}{x};
    print $info->{chains}{A}{elements}{S};              # 7    sulphur atoms in chain A
    print $info->{stats}{elements}{S};                  # 17   and in the structure

    print structure_summary($info);

which prints

    1A22  HUMAN GROWTH HORMONE BOUND TO SINGLE RECEPTOR
      file        1a22.ent.pdb
      method      X-RAY DIFFRACTION
      resolution  2.6 A
      R / R-free  0.187 / -
      models      1
      atoms       3113 (69 hetatm, 69 water)
      chain A     protein      206 residues,  1492 atoms, 2 gaps
                  FPTIPLSRLFDNAMLRAHRLHQLAFDTYQEFEEAYIPKEQKYSFLQNPQTSLCFSESIPTP...
                  GROWTH HORMONE
      chain B     protein      235 residues,  1621 atoms, 2 gaps
                  PKFTKCRSPERETFSCHWTLGPIQLFYTRRNTQEWTQEWKECPDYVSAGENSCYFNSSFTS...
                  GROWTH HORMONE RECEPTOR

What the structure *is* comes back the same way, in one more call:

    my $f = structure_features($info);

    print $f->{sasa}{total};          # 17805.0  solvent-accessible surface, A^2
    print $f->{rg};                   # 22.85    radius of gyration, A
    print $f->{mass};                 # 41307.1  dalton
    print $f->{hydropathy};           # -0.452   mean Kyte-Doolittle hydropathy
    print $f->{aromatic_fraction};    # 0.1263   the F, W and Y share of the sequence
    print scalar @{ $f->{pi_stacking} };  # 2    stacked pairs of aromatic rings

    print $info->{chains}{A}{residues}{54}{rsa};   # 0.103  PHE 54 is mostly buried
    print $info->{chains}{A}{residues}{54}{ss};    # 'G'    and it is in a 3-10 helix

which is the Shrake-Rupley surface, the ring geometry, the radii and the masses
as mdtraj implements them and the two sequence indices as Biopython does. All of
it is in C, for the same reason the parse is.

The secondary structure comes back the other way round as well, which is the
shape to take a whole fold in at once:

    my $dssp = structure_info('1a22.ent.pdb', 'dssp');

    print scalar @{ $dssp->{A}{H} };   # 122   residues of chain A in alpha helix
    print scalar @{ $dssp->{B}{E} };   # 90    and of chain B in a strand

Chain, then DSSP letter, then where in that chain those residues are. It is
mdtraj's `compute_dssp()` letter for letter — see `structure_dssp`.

Two copies of a molecule are compared in one call, and an NMR ensemble is
compared against itself in the same one:

    my $d = structure_rmsd('before.pdb', 'after.cif');   # 1.83   angstrom

    my $r = structure_rmsd('2ll7.ent.pdb', model => 'all');
    print scalar @{ $r->{labels} };      # 20   models, compared with each other
    printf '%.2f', $r->{rmsd}[0][1];     # 3.61 A between models 1 and 2

Atoms are paired on the identity the file gives them and the superposition is
Theobald's quaternion characteristic polynomial, which agrees with gemmi's
`superpose_positions` to 5.65e-12 over 5,598 real superpositions — see
`structure_rmsd`.

The coordinate section is parsed in C, because across a directory of
structures it is millions of lines: the largest entry in PDBbind v2020 is
33 MB and 411,648 atom records, and it reads in about a second. The header
records are parsed in Perl, because they are irregular and there are only a
few dozen of them in a file.

The module is called `Chem::Structure::Parser` and not `PDB::Info` because the
shape of what it hands back has nothing to do with the format it came out of.
It reads PDB and mmCIF/PDBx; `formats()` says what it reads at any moment, and
a format it knows the name of but cannot read yet says so rather than
misreading it.

# PDB and mmCIF

Reading is the same call either way. `structure_info()` works out the format
from the file name — `.pdb`, `.ent`, `.cif`, `.mmcif`, `.pdbx` — and from the
first records in the file when the name gives nothing away, and the hash that
comes back has the same keys, the same nesting and the same values whichever
it was.

    my $a = structure_info('1a22.pdb');
    my $b = structure_info('1a22.cif');

    $a->{chains}{A}{sequence} eq $b->{chains}{A}{sequence};              # true
    $a->{chains}{A}{residues}{54}{atoms}{CA}{x}
    	== $b->{chains}{A}{residues}{54}{atoms}{CA}{x};                  # true

So no calling code branches on the format, and a script written against a
directory of `.pdb` files works unchanged on a directory of `.cif` ones.

Equality here means equality rather than approximately: `t/cif.t` reads
fixture pairs both ways and compares the whole coordinate half of the returned
structure with `is_deeply`, and `t/real_cif.t` converts real entries from the
PDB archive into mmCIF and asserts that every chain, residue, atom and count
comes back identical.

Two consequences are worth knowing.

**The identifiers are the auth_\* ones.** An mmCIF file carries two sets: the
`label_*` identifiers the archive assigns, and the `auth_*` ones the depositor
used. Only `auth_*` matches what the PDB record carried, so those are the
chain ids and residue numbers used throughout — in the coordinates and in the
annotations alike. A structure read from a `.cif` therefore has the same chain
`A` and the same residue `54` as the same structure read from a `.pdb`, not
the `label_asym_id` lettering that runs on through the waters.

**Values are converted, not passed through.** Where the two formats spell the
same fact differently, the mmCIF reader produces what the PDB reader would
have: `_atom_site.pdbx_formal_charge` of `-1` reads back as `'1-'`, and `.`
and `?` — mmCIF for "not applicable" and "unknown" — read back as the empty
field a PDB record would have had. A charge of `0` is kept as `'0'`, because
"the field said zero" and "the field was blank" are different answers and both
formats can say either.

What is *not* the same is what only one of the formats has. An mmCIF file has
no REMARK records, so `$info->{remarks}` is empty for one; a PDB file has no
`_entity` category, so a chain read from one may not know which entity it
belongs to. Every key is present in both cases, so reading one is a test of
what the file said and never of which format it was.

Where the same fact is filed under different names, it is folded into the same
key:

| `$info` key | PDB record | mmCIF category |
| --- | --- | --- |
| `title` | `TITLE` | `_struct.title` |
| `id` | `HEADER` | `_entry.id` |
| `experiment` | `EXPDTA` | `_exptl.method` |
| `resolution` | `REMARK 2`, then `REMARK 3` | `_refine.ls_d_res_high` |
| `r_work`, `r_free` | `REMARK 3` | `_refine.ls_R_factor_R_*` |
| `keywords` | `KEYWDS` | `_struct_keywords.text` |
| `authors` | `AUTHOR` | `_audit_author` |
| `journal` | `JRNL` | `_citation`, `_citation_author` |
| `compound`, `source` | `COMPND`, `SOURCE` | `_entity`, `_entity_src_*` |
| `seqres` | `SEQRES` | `_entity_poly`, `_entity_poly_seq` |
| `het` | `HET`, `HETNAM`, `FORMUL` | `_chem_comp`, `_pdbx_nonpoly_scheme` |
| `helix` | `HELIX` | `_struct_conf` |
| `sheet` | `SHEET` | `_struct_sheet_range` |
| `ssbond`, `link` | `SSBOND`, `LINK` | `_struct_conn` |
| `cispep` | `CISPEP` | `_struct_mon_prot_cis` |
| `modres` | `MODRES` | `_pdbx_struct_mod_residue` |
| `dbref` | `DBREF` | `_struct_ref`, `_struct_ref_seq` |
| `cryst1` | `CRYST1` | `_cell`, `_symmetry` |
| `n_models` | `MODEL` | `_atom_site.pdbx_PDB_model_num` |

# Installing

    perl Makefile.PL
    make
    make test
    make install

`make test` reads the fixtures in `t/data`. If a directory of real structures
is to hand it reads a sample of those too; point it somewhere with

    STRUCTURE_INFO_TEST_DIR=/path/to/pdbs  make test
    STRUCTURE_INFO_TEST_CIF_DIR=/path/to/cifs  make test
    STRUCTURE_INFO_TEST_ALL=1 STRUCTURE_INFO_TEST_DIR=/path make test   # all of them

`STRUCTURE_INFO_TEST_DIR` is used twice: `t/real.t` reads those files as PDB
and checks them against a second reader written in plain Perl, and
`t/real_cif.t` converts each one into mmCIF and asserts that reading it back
gives the same structure to the last digit.
`STRUCTURE_INFO_TEST_CIF_DIR` takes a directory of real `.cif` files, either
flat or one subdirectory per structure, and reads those directly.

With no such directory those tests skip, so the distribution builds on a
machine with no structures on it.

# Getting help

`h` prints any function's section of this document to `STDOUT` and returns, in
the spirit of R's `?function` at the prompt. It takes the name three ways:

    h('structure_info');    # by name
    h(*res_type);           # by name, unquoted
    h(\&aa3to1);            # by reference
    h();                    # the list of documented functions

    perl -MChem::Structure::Parser -e 'h(*structure_info)'   # straight from the shell

Note that `h(res_type)`, with no quotes and no sigil, cannot be made to work:
every function here is exported, so Perl parses the bareword as a call to
`res_type()` before `h` is ever reached. Use one of the three forms above.

# Functions/Subroutines

## structure_info

    my $info = structure_info($file, %options);
    my $dssp = structure_info($file, 'dssp', %options);
    my $tors = structure_info($file, 'torsions', %options);

Reads `$file` and returns a hash reference. The format is worked out from the
file name — `.pdb`, `.ent`, `.cif`, `.mmcif`, `.pdbx` — and from the first
records in the file when the name gives nothing away. `.gz` files are read as
they are, without unpacking to a temporary file.

A plain string in second place names a *view*, and asks for that and nothing
else: the file is read, the view is taken out of it, and the rest is thrown
away. There are two views today: `dssp` — see `structure_dssp` below — and
`torsions` (or `torsion`), described under "The same angles, by chain". The
options that follow are the reader's, the same ones the first form takes. The
two forms cannot be confused with one another: a file name followed by an even
number of arguments is an option list with an odd number of elements, which was
never anything but a mistake.

### What comes back

Laid out the way `tree` lays out a directory, this is `1a22.ent.pdb` — a real
file, real values, the long lists cut short:

    $info
    ├── file            '1a22.ent.pdb'          the path it was read from
    ├── format          'pdb'                   or 'mmcif'
    ├── id              '1A22'                  from HEADER, or from the file name
    ├── title           'HUMAN GROWTH HORMONE BOUND TO SINGLE RECEPTOR'
    ├── header
    │   ├── classification  'COMPLEX (HORMONE/RECEPTOR)'
    │   ├── deposit_date    '15-JAN-98'
    │   └── id_code         '1A22'
    ├── experiment      [ 'X-RAY DIFFRACTION' ]
    ├── resolution      2.6                     REMARK 2
    ├── r_work          0.187                   REMARK 3
    ├── r_free          undef                   this entry does not report one
    ├── temperature     287                     REMARK 200
    ├── ph              6.5
    ├── keywords        [ 'COMPLEX (HORMONE-RECEPTOR)', 'PITUITARY HORMONE', ... ]
    ├── authors         [ 'A.M.DE VOS', 'M.ULTSCH' ]
    ├── journal
    │   ├── auth        [ 'T.CLACKSON', 'M.H.ULTSCH', 'J.A.WELLS', 'A.M.DE VOS' ]
    │   ├── titl        'STRUCTURAL AND FUNCTIONAL ANALYSIS OF THE 1:1 GROWTH...'
    │   ├── ref         'J.MOL.BIOL.                   V. 277  1111 1998'
    │   ├── refn        'ISSN 0022-2836'
    │   ├── pmid        '9571026'
    │   └── doi         '10.1006/JMBI.1998.1669'
    ├── compound                                COMPND, by MOL_ID
    │   ├── 1
    │   │   ├── mol_id      '1'
    │   │   ├── molecule    'GROWTH HORMONE'
    │   │   ├── chain       [ 'A' ]
    │   │   ├── engineered  'YES'
    │   │   └── mutation    'YES'
    │   └── 2           { molecule 'GROWTH HORMONE RECEPTOR', chain [ 'B' ],
    │                     fragment 'EXTRACELLULAR DOMAIN', engineered 'YES' }
    ├── source                                  SOURCE, by MOL_ID
    │   └── 1           { organism_scientific 'HOMO SAPIENS', organism_common
    │                     'HUMAN', organism_taxid '9606', mol_id '1',
    │                     expression_system 'ESCHERICHIA COLI',
    │                     expression_system_taxid '562' }
    ├── entity_of_chain                         COMPND and SOURCE, by chain
    │   ├── A           { mol_id '1', molecule 'GROWTH HORMONE', fragment undef,
    │   │                 ec undef, organism 'HOMO SAPIENS', taxid '9606',
    │   │                 expressed_in 'ESCHERICHIA COLI' }
    │   └── B           { ..., fragment 'EXTRACELLULAR DOMAIN' }
    ├── seqres                                  what SEQRES says was in the crystal
    │   ├── A
    │   │   ├── sequence    'FPTIPLSRLFDNAMLRAHRLHQLAFDTYQEFEEAYIPKEQKYSFLQ...'
    │   │   ├── residues    [ 'PHE', 'PRO', 'THR', 'ILE', ... ]        191 of them
    │   │   └── length      191
    │   └── B               { sequence, residues, length 238 }
    ├── dbref
    │   └── A           [ { database 'UNP', accession 'P01241',
    │                       db_id 'SOMA_HUMAN', seq_begin '1', seq_end '191',
    │                       db_begin '27', db_end '217', chain 'A' } ]
    ├── seqadv          [ { chain 'A', resseq '120', resname 'ARG',
    │                       db_res 'GLY', db_seq '146', comment 'ENGINEERED' } ]
    ├── modres          { }                     no MSE-style residues here
    ├── het
    │   └── HOH         { het_id 'HOH', formula '69(H2 O)', water 1 }
    ├── hetnam          { }
    ├── formul          { }
    ├── helix           [ { id '1', class '1', length '29',
    │                       init_chain 'A', init_resname 'SER', init_resseq '7',
    │                       end_chain 'A', end_resname 'TYR', end_resseq '35' },
    │                     ... ]                                     12 of them
    ├── sheet           [ ... ]                                     12
    ├── ssbond          [ { chain1 'A', resseq1 '53',
    │                       chain2 'A', resseq2 '165', length '2.02' }, ... ]  5
    ├── link            [ ]
    ├── cispep          [ ]
    ├── site            [ ]
    ├── cryst1          { a '67.7', b '67.7', c '228',
    │                     alpha '90', beta '90', gamma '90',
    │                     sgroup 'P 43 21 2', z '8' }
    ├── biological_assembly  [ 32 lines of REMARK 350, verbatim ]
    ├── revdat          [ { num '3', date '18-APR-18', id '1A22',
    │                       type '1', what 'REMARK' }, ... ]
    ├── remarks                                 every REMARK, by number
    │   ├── 2           [ '', 'RESOLUTION.    2.60 ANGSTROMS.' ]
    │   ├── 350         [ ... ]                                     32 lines
    │   └── ...         1, 3, 4, 100, 200, 280, 290, 300, 465, 470, 500
    ├── conect          [ [ 448, 1255 ], ... ]                      10
    ├── records                                 every record type, counted
    │   ├── REMARK      365
    │   ├── SEQRES      34
    │   ├── HELIX       12
    │   └── ...         AUTHOR, COMPND, CONECT, CRYST1, DBREF, SOURCE, SSBOND, ...
    ├── n_models        1                       how many MODEL records the file has
    ├── model           1                       which one the chains below are
    ├── models                                  there only with model => 'all'
    ├── stats
    │   ├── n_atoms         3113    atoms kept: this model, less what was filtered
    │   ├── total_atoms     3113    atoms the file has, every model, unfiltered
    │   ├── n_hetatm        69      of n_atoms, the ones written as HETATM
    │   ├── n_hydrogens     0
    │   ├── n_water_atoms   69
    │   ├── n_lines         3605
    │   ├── n_atom_records  3044    ATOM lines seen, whether kept or not
    │   ├── n_hetatm_records 69     HETATM lines, likewise
    │   ├── n_anisou        0
    │   ├── n_skipped       0       coordinate lines the options threw away
    │   ├── elements        { C 1946, O 643, N 507, S 17 }
    │   │                           every element in the file, keyed by its IUPAC
    │   │                           symbol; the counts add up to n_atoms
    │   ├── bfactor         { min '2.7', max '85.39', mean 30.83, n 3113 }
    │   ├── bbox            { xmin '12.142', xmax '80.34', ymin '2.011', ... }
    │   └── center          [ '46.241', '29.135', '134.559' ]
    ├── chain_order     [ 'A', 'B' ]            the order the file has them in
    └── chains
        ├── A
        │   ├── id              'A'
        │   ├── type            'protein'   protein dna rna water hetero unknown
        │   ├── sequence        'FPTIPLSRLFDNAMLRAHRLHQLAFDTYQEFEEAYIPKEQ...'
        │   │                               single-letter, what has coordinates
        │   ├── seqres          'FPTIPLSRLFDNAMLRAHRLHQLAFDTYQEFEEAYIPKEQ...'
        │   ├── seqres_length   191
        │   ├── n_residues      206
        │   ├── n_polymer       180
        │   ├── n_water         26
        │   ├── n_ligand        0
        │   ├── n_atoms         1492
        │   ├── n_hetatm        26
        │   ├── elements        { C 938, O 301, N 246, S 7 }
        │   │                               the same tally for this chain alone;
        │   │                               adds up to the chain's n_atoms
        │   ├── n_missing       11          SEQRES less what was modelled
        │   ├── gaps            [ { after 129, before 136, missing 6 },
        │   │                     { after 148, before 154, missing 5 } ]
        │   ├── n_gaps          2
        │   ├── missing_residues
        │   │                   [ 130, 131, 132, 133, 134, 135,
        │   │                     149, 150, 151, 152, 153 ]
        │   ├── first           1           the first and last polymer residue keys
        │   ├── last            191
        │   ├── residue_types   { amino_acid 180, water 26 }
        │   ├── molecule        'GROWTH HORMONE'            from COMPND
        │   ├── organism        'HOMO SAPIENS'              from SOURCE
        │   ├── mol_id          '1'
        │   ├── dbref           [ { ... } ]     as in the top-level dbref
        │   │                                   ec and fragment are here too, in a
        │   │                                   chain whose file gives them
        │   ├── residue_order   [ '1', '2', '3', ... '574' ]        file order, 206
        │   └── residues                    keyed number + insertion code
        │       ├── 54
        │       │   ├── resname     'PHE'
        │       │   ├── number      54
        │       │   ├── icode       ''
        │       │   ├── key         '54'
        │       │   ├── chain       'A'
        │       │   ├── one         'F'     '' when there is no letter for it
        │       │   ├── type        'amino_acid'
        │       │   │                       nucleotide water ligand ion
        │       │   ├── standard    1       one of the twenty, or a standard base
        │       │   ├── modified    0       1 for MSE, still an M in the sequence
        │       │   ├── hetero      0       1 when it was written as HETATM
        │       │   ├── free                not here; 1 for a free amino acid
        │       │   │                       bound in a site (see below)
        │       │   ├── n_atoms     11
        │       │   ├── b_mean      22.55
        │       │   ├── center      [ 65.311, 17.127, 140.515 ]
        │       │   ├── atom_order  [ 'N', 'CA', 'C', 'O', 'CB', ... ]
        │       │   └── atoms
        │       │       ├── CA
        │       │       │   ├── name       'CA'
        │       │       │   ├── serial     450
        │       │       │   ├── element    'C'
        │       │       │   ├── charge     ''
        │       │       │   ├── x          '66.446'
        │       │       │   ├── y          '18.25'
        │       │       │   ├── z          '141.982'
        │       │       │   ├── occupancy  '1'
        │       │       │   ├── bfactor    '24.53'
        │       │       │   ├── altloc     ''
        │       │       │   ├── hetero     0
        │       │       │   └── altlocs    [ { altloc, x, y, z, occupancy,
        │       │       │                      bfactor }, ... ]
        │       │       │                  present only when the atom has
        │       │       │                  alternate conformers; every conformer
        │       │       │                  is listed, the chosen one included,
        │       │       │                  and one of them having no letter at
        │       │       │                  all does not take it off the list
        │       │       └── ...    N, C, O, CB, CG, CD1, CD2, CE1, CE2, CZ
        │       └── ...            1 .. 191, then the waters at 512 .. 574
        └── B                      the same again: 235 residues, 1621 atoms

A record that is not in the file reads as `undef`, and a list that is not in
the file reads as an empty arrayref — `title` being `undef` means there was no
TITLE, which is a different thing from a TITLE that was blank.

Everything the module does not take apart is still in `remarks` and in the
raw record counts, so nothing in the file is lost.

### The two sequences

`sequence` and `seqres` are the two different questions people mean by "the
sequence": what was modelled, and what was in the crystal. They differ
wherever a terminus or a loop went unmodelled, which is what `gaps` counts and
`n_missing` totals — eleven residues of chain A above, in two stretches.
`missing_residues` is the same eleven one number at a time, in ascending
order, for asking whether a particular residue was modelled without walking
the gap list.

Both are read off the numbering, so they see the loops a chain skips over and
not the residues that fell off either end — a terminus that went unmodelled
leaves no numbering behind to notice it by, and only `n_missing` counts those.
Numbering is not always sequential, either: an antibody numbered by the Kabat
scheme runs 27, 1027, 2027, 28, where the thousands are insertions after 27
and not a 999-residue hole. A chain can only be missing as many residues as
the span from its first polymer residue to its last leaves room for, so a jump
wider than that is taken for a change of numbering scheme and not counted.

A scheme that skips a few numbers on purpose is not caught, and cannot be:
a protein numbered by homology to a reference one — chymotrypsin numbering,
and the several conventions like it — leaves unused the numbers its reference
does not need, and the coordinates do not say which of those is a residue that
went unmodelled. 1ahx has all 396 of its SEQRES residues modelled and still
skips nine numbers, which both fields report. About one chain in twenty-five
is like this. Where a file has SEQRES and the two disagree, `n_missing` is the
one to trust: it counts residues, where `gaps` and `missing_residues` count
numbers.

### How residues are keyed

By residue number with the insertion code appended, so `100`, `100A` and
`100B` are three separate keys and nothing is silently overwritten. Waters and
ligands are in `residues` alongside the polymer, which is why chain A above
has 206 residues to its 191-long SEQRES.

The name is not part of a residue's identity. One position is sometimes
modelled in two chemical states at once, written as complementary altloc
groups — 3zeu has ten methionines that are MSE in altlocs A and B and MET in
C and D, a selenomethionine that only went halfway in — and those are one
residue, not two. It takes the name written first, counts the records of both
states, and keeps the atoms that tell them apart, so an MSE/MET like that has
both an SE and an SD, each carrying the conformers of its own state.

### Counting elements

Two tallies, the same shape: `$info->{stats}{elements}` is the whole structure
and `$info->{chains}{$id}{elements}` is one chain of it. Both count coordinate
records, which is what `n_atoms` counts, so both add up:

    use List::Util 'sum0';

    my $info = structure_info('1a22.ent.pdb');

    $info->{stats}{elements};              # { C => 1946, O => 643, N => 507, S => 17 }
    $info->{chains}{A}{elements};          # { C =>  938, O => 301, N => 246, S =>  7 }
    $info->{chains}{B}{elements};          # { C => 1008, O => 342, N => 261, S => 10 }

    sum0(values %{ $info->{chains}{A}{elements} }) == $info->{chains}{A}{n_atoms};  # true
    sum0(values %{ $info->{stats}{elements} })     == $info->{stats}{n_atoms};      # true

Both are tallies of what came back, so the `model`, `hydrogens`, `waters`,
`hetatm` and `chains` options are already in them: read an NMR ensemble with
the default `model => 1` and you get one model's worth. With `model => 'all'`
each model's chains carry their own tally, under `$info->{models}{$n}{chains}`.

The keys are IUPAC symbols — `Zn`, `Se`, `Cl`, `Fe` — not the shouted spelling
the file uses. A PDB file writes the element in columns 77-78 in capitals, an
mmCIF `type_symbol` is capitals as often as not, and an element worked out from
the atom name comes out of a table that is capitals throughout, so `ZN` is what
all three roads arrive with and `Zn` is what the periodic table calls it. The
correction runs on the symbol once, where it is settled, so the atom's own
`element`, the chain tally and the structure tally cannot disagree:

    $info->{chains}{A}{residues}{202}{atoms}{ZN}{element};   # 'Zn'
    $info->{chains}{A}{elements}{Zn};                        # 1

The atom is still keyed `ZN` in `atoms` there, because that key is the atom's
*name* out of columns 13-16, not its element.

Only the 118 named elements are corrected. A file whose element column holds
something that spells no element keeps it exactly as written — `XX` stays `XX`
rather than becoming a plausible-looking `Xx` — so a field the module does not
recognise is visibly not an element rather than quietly dressed up as one.

Each count is an unsigned integer. It is counted up from zero and never down,
so there is no sign for it to carry.

### Nothing points back up

A residue does not hold its chain and an atom does not hold its residue — the
names are there, `chain => 'A'` on the residue, but not the references. Parent
links would make the whole thing one reference cycle, and a cycle is a leak
that goes unnoticed until the ten-thousandth file.

### Options

    model     => 1          which MODEL to build chains from; 'all' fills in
                            {models} as well.  Default 1, which is also the
                            right answer for a file with no MODEL records
    altloc    => 'first'    which alternate conformer's coordinates win;
                            'highest' takes the highest occupancy instead
    hydrogens => 1          keep hydrogens and deuteriums
    waters    => 1          keep waters
    hetatm    => 1          keep HETATM records
    atoms     => 1          build the atom hashes; 0 stops at the residue
                            level, which is much smaller and faster
    features  => 1          compute the physical properties, into
                            {features} and onto the chains, residues and
                            atoms; see structure_features below
    meta      => 1          parse the header records
    anisou    => 0          keep ANISOU lines
    chains    => ['A','B']  read only these chains
    format    => 'pdb'      skip the format detection: 'pdb' or 'mmcif'
                            ('cif', 'pdbx' and 'ent' name the same two)
    dssp      => 0          also leave the secondary structure roll-up at
                            {dssp}, where structure_dssp() would find it

Every option is checked. A misspelled one is fatal, because an ignored typo is
a wrong answer that arrives without a word: `hydrogen => 0` that is quietly
dropped gives a structure with the hydrogens still in it and no clue why.

For a very large structure the options are the difference between a hash of
hashes that fits in memory and one that does not. The largest entry in PDBbind
v2020 is 2wy2: 33 MB, 64 models, 411,648 atom records.

    structure_info($f)                # model 1 only    47 MB    0.20 s
    structure_info($f, model => 'all')                 514 MB    1.06 s
    structure_info($f, model => 'all', atoms => 0)     408 MB    0.74 s

The chains are built from one model whichever of those is asked for — `models`
is the rest of them — so the physical properties in the first two rows cost the
same, and the third has none to compute.

`features` is the expensive one, and it is on by default because a structure's
surface, size and contacts are as much a part of what it is as its sequence, and
a caller who has to know to ask mostly does not. What it costs is measured, over
60 structures of PDBbind:

    structure_info($f, features => 0)         1.30 s   246,000 atoms/s
    structure_info($f)                       10.77 s    29,700 atoms/s    8.3x
    ... with interface => 0                  10.02 s    32,000 atoms/s    7.7x
    ... with sasa => 0                        3.80 s    84,000 atoms/s    2.9x

Nearly all of it is the solvent-accessible surface, at 960 sphere points per
atom; everything else together is 2.9 times the read. `interface => 0` drops the
per-chain surfaces, which is a fourteenth of the whole: an atom with no
neighbour outside its own chain has the same surface alone as it has in the
structure, and only the ones that do have such a neighbour are computed twice.

`features => 0` is what to reach for when reading a directory for its headers or
its sequences. `atoms => 0` turns them off on its own — there are no coordinates
to compute from — rather than dying, so `structure_sequences($f, atoms => 0)`
still works.

Filtering happens in the C, before a hydrogen or a water has become a Perl
value, so `hydrogens => 0` is cheaper than reading them and throwing them away.

What was filtered is still counted, so a structure knows how much of its file
it is. `stats.n_atoms` is what came back and `stats.total_atoms` is what the
file has -- every ATOM and HETATM record, every model, before any option had a
say -- and `total_atoms == n_atoms + n_skipped` however the options were set.
2wy2 above, read with the default `model => 1`, gives `n_atoms` 6,432 and
`total_atoms` 411,648.

## structure_info_string

    my $info = structure_info_string($text, %options);

The same, for a structure already in a string. A string has no name to go on,
so text that looks like nothing in particular is read as PDB; text that looks
like another format still gets a straight answer about it.

## structure_atoms

    my $atoms = structure_atoms($info);
    my $atoms = structure_atoms($info, 'A');

Every atom as a flat array of hash references, in file order, each carrying
the `chain`, `resname`, `resseq`, `icode` and `reskey` it came from. This is
the shape to hand to a distance calculation or to write out as a table; the
nested form is the shape to look things up in. The hashes are copies, so
writing to them does not scribble on the structure.

## structure_residues

    my $residues = structure_residues($info);
    my $residues = structure_residues($info, 'A');

Every residue in file order. These are the same hash references that are in
the nested structure, not copies, so walking them and looking one up agree.

## structure_ligands

    my $lig = structure_ligands($info);     # { 'NAG_A_301' => { ... } }

The heterogens that are neither water nor part of the polymer, keyed by
residue name, chain and number — which is what a binding-site table wants as
its row label.

## is_single_ion

    is_single_ion($info->{chains}{E});     # 1     a chain that is one zinc
    is_single_ion($info, 'E');             # 1     the same, by chain id
    is_single_ion($info->{chains}{A});     # ''    a chain with a polymer in it

    my @polymers = grep { !is_single_ion($info, $_) } @{ $info->{chain_order} };

True when a chain holds exactly one residue. An ion is often numbered into the
chain it sits in — the zinc of a zinc finger is residue 202 of chain A — and
just as often given a chain of its own, which is a chain with one residue in it
and no sequence to read. This is for the second kind, so that a loop over
`chain_order` can put them aside before it asks the rest for a sequence.

`single` counts residues in the chain, and nothing else:

    a chain that is one CL                  # 1
    a chain that is one SO4, five atoms     # 1
    a chain that is one BF4, five atoms     # 1
    a chain of two zincs                    # ''
    a protein chain with a zinc in it       # ''

So the number of atoms in the residue does not come into it, and a sulphate and
a perchlorate answer the same. Neither does the residue's `type`: that comes off
a table of names, and a table of names cannot be complete — SO4 is on the
module's list and BF4 is not, which is a fact about who wrote the list down and
not about the file. Counting residues asks the table nothing.

The residue is therefore not asked what it is, and a chain that is one sugar,
one buffer molecule, one water or one free amino acid reads true as well. In a
real file those are rare next to the ions and are the same nuisance to a caller
walking chains, but where the difference matters it is a lookup away:

    my $c = $info->{chains}{E};
    my $r = $c->{residues}{ $c->{residue_order}[0] };
    $r->{type} eq 'ion';        # ion, ligand, water, amino_acid, nucleotide
    $r->{resname};              # 'ZN'

`res_type` is where those types come from, and `$c->{type} eq 'water'` is the
narrower question about a chain of nothing but waters.

The argument is either one chain — `$info->{chains}{$id}`, or a chain out of
`$info->{models}` — or the structure and a chain id, which is the same question
written the way `chain_sequence()` takes it. Handing it the whole structure
without an id, or a residue, is fatal rather than false: all three are hash
references, and a wrong answer there would be taken at face value.

## structure_sequences

    my $seq  = structure_sequences($info);          # { A => 'FPTIPLSRL...' }
    my $same = structure_sequences('1ubq.pdb');     # read on the spot
    my $fast = structure_sequences('1ubq.pdb', atoms => 0, meta => 0);

The observed single-letter sequence of every chain that has one.

The first argument is either the hash reference from `structure_info()` or the
name of a file, which is read with the options given. `atoms => 0` is worth
knowing about here, since a sequence needs the residues and not their
coordinates. Options belong with a file name; passing them alongside a
structure that is already parsed is an error, because there is nothing left
for them to change.

## chain_sequence

    my $obs = chain_sequence($info, 'A');
    my $all = chain_sequence($info, 'A', 'seqres');

One chain's sequence: `observed` is the residues that have coordinates,
`seqres` is what SEQRES says was in the crystal.

## structure_summary

    print structure_summary($info);

A paragraph a person can read: id, title, method, resolution, models, atom
counts, and a line per chain with its type, size, sequence and molecule. The
example at the top of this document is its output.

## structure_features

    my $f = $info->{features};        # structure_info computed them already
    my $g = structure_features($info);   # the same hash, not a second walk

    $f->{sasa}{total};        # 17805.0   solvent-accessible surface, A^2
    $f->{sasa}{apolar};       # 8211.8    the carbon and sulphur part of it
    $f->{rg};                 # 22.85     radius of gyration, A
    $f->{rg_mass};            # 22.84     the same, weighted by mass
    $f->{mass};               # 41307.1   dalton
    $f->{hydropathy};         # -0.452    mean Kyte-Doolittle over the sequence
    $f->{aromatic_fraction};  # 0.1263    the F, W and Y share of it
    @{ $f->{pi_stacking} };   # the stacked pairs of aromatic rings
    @{ $f->{disulfides} };    # the SG-SG pairs close enough to be bonded
    @{ $f->{base_pairs} };    # the Watson-Crick and wobble base pairs

(1a22 again, the structure the summary at the top of this document is of.)

Everything the module can work out about a structure that is a number rather
than a name. One call, because all of it has to touch every atom and the
expensive part is walking the structure into coordinate arrays: asking for all
of it costs one walk.

`structure_info()` makes that call on the way past and leaves the answer in
`$info->{features}`, so most callers never name this function at all. With no
options it is a lookup — it hands back what is already there. Name any option
and it walks the structure again with that option in force. `features => 0` on
the read is how to skip the work; see `structure_info`'s options above.

The whole-structure figures come back in the hash. What is per-atom, per-residue
or per-chain is written into `$info` instead, where the atom, residue and chain
already are:

    $info->{chains}{A}{sasa};                          # 8450.6   the chain's surface
    $info->{chains}{A}{hydropathy};                    # -0.3144  and its mean hydropathy
    $info->{chains}{A}{aromatic_fraction};             # 0.1222
    $info->{chains}{A}{residues}{54}{sasa};            # 24.62    one residue's surface
    $info->{chains}{A}{residues}{54}{rsa};             # 0.103    ... as a fraction of its maximum
    $info->{chains}{A}{residues}{54}{atoms}{CZ}{sasa}; # one atom's

    $info->{chains}{A}{buried};                        # 1445.0   what it buries
    $info->{chains}{A}{residues}{54}{phi};             # -127.6   degrees
    $info->{chains}{A}{residues}{54}{psi};             #   20.5
    $info->{chains}{A}{residues}{54}{chi};             # [ -60.6, -82.9 ]
    $info->{chains}{A}{torsions}{phi};                 # every phi of the chain,
                                                       # by residue_order
    $info->{chains}{A}{residues}{54}{ss};              # 'G'      or H I E B T S ' '
    $info->{chains}{A}{residues}{54}{ss_simple};       # 'H'      or E or C
    $info->{chains}{A}{residues}{54}{hse_up};          # 12       half-sphere exposure
    $info->{chains}{A}{residues}{54}{n_contacts};      # 13
    $info->{chains}{A}{residues}{23}{disulfide};       # [ { chain, residue, distance } ]

A nucleic acid chain answers a different set of the same questions, and 1bna —
the Drew-Dickerson dodecamer, which is where B-DNA is usually quoted from — is
what these are of:

    $info->{chains}{A}{gc_fraction};                   # 0.6667   the C and G share of the strand
    $info->{chains}{A}{purine_fraction};               # 0.5      ... and the A and G share
    $info->{chains}{A}{base_counts};                   # { A => 2, C => 4, G => 4, T => 2 }
    $info->{chains}{A}{residues}{6}{alpha};            # -73.3    degrees; and beta 179.7,
    $info->{chains}{A}{residues}{6}{delta};            # 121.1    gamma 66.0, epsilon 173.7,
    $info->{chains}{A}{residues}{6}{zeta};             # -88.5    the six backbone torsions
    $info->{chains}{A}{residues}{6}{chi};              # -122.2   the glycosidic torsion
    $info->{chains}{A}{residues}{6}{glycosidic};       # 'anti'   or 'syn'
    $info->{chains}{A}{residues}{6}{nu};               # [ -48.1, 47.5, -29.9, 2.2, 29.0 ]
    $info->{chains}{A}{residues}{6}{pucker};           # "C1'-exo"  which shape those make it
    $info->{chains}{A}{residues}{6}{pucker_phase};     # 126.9    degrees, 0 to 360
    $info->{chains}{A}{residues}{6}{pucker_amplitude}; # 49.8     how far from flat

`store => 0` turns that off and leaves `$info` exactly as it was; the totals
still come back. Asking twice replaces what was stored rather than adding to it,
so a second call with a different probe radius leaves the second answer behind.

Three of the properties are *only* per-residue — the torsion angles (both
kinds), the half-sphere exposure and the secondary structure — so `store => 0`
does not compute them at all rather than computing them and dropping them on the
floor.
`structure_info()` always stores, so this is only reachable by calling
`structure_features()` yourself.

### What comes back

| key | what it is |
| --- | --- |
| `n_atoms` | atoms the walk found: the ones in `$info`, after whatever `structure_info()` was told to leave out |
| `n_residues`, `n_chains` | and how they were grouped |
| `n_no_element` | atoms whose element field spells no element this module knows; they get a 2.0 A radius and no mass |
| `sasa` | `total`, `apolar`, `polar`, and the `probe` and `points` used |
| `mass` | the sum of the atoms' standard atomic weights, in dalton |
| `rg` | radius of gyration about the centroid, in angstrom |
| `rg_mass` | the same, weighted by mass and taken about the centre of mass |
| `center`, `center_of_mass` | `[x, y, z]`, in angstrom |
| `hydropathy` | the mean Kyte-Doolittle index over the protein chains' observed sequences |
| `aromatic_fraction`, `n_aromatic` | how much of that sequence is phenylalanine, tryptophan or tyrosine |
| `sequence_length` | how long the sequence those two are over is |
| `gc_fraction` | the C and G share of the nucleic acid chains' observed sequences |
| `purine_fraction`, `n_gc` | the A and G share of the same, and how many bases the first counted |
| `nucleotide_length` | how long the sequence those are over is |
| `base_counts` | every letter of it tallied, ambiguous ones included |
| `pi_stacking` | the arrayref `structure_pi_stacking()` returns |
| `disulfides` | the arrayref `structure_disulfides()` returns |
| `base_pairs` | the arrayref `structure_base_pairs()` returns |
| `base_stacks` | the arrayref `structure_base_stacks()` returns |
| `contacts` | the arrayref `structure_contacts()` returns |
| `hbonds` | the arrayref `structure_hbonds()` returns |
| `dssp` | the hashref `structure_dssp()` returns |
| `shape` | `gyration_tensor`, `principal_moments`, `asphericity`, `acylindricity`, `anisotropy` |

`rg`, `center` and `center_of_mass` are absent from a structure with no atoms in
it, and `rg_mass` and `center_of_mass` from one whose atoms have no mass between
them, because there is no such number rather than because it is zero. The same
goes for `hydropathy` and `aromatic_fraction` when there is no protein, and for
`gc_fraction` and the three keys beside it when there is no nucleic acid.

The surface is of the structure as `$info` holds it. Reading with `waters => 0`
and asking for the surface afterwards gives the surface of a protein with no
water in the way, which is a different — and usually more useful — number than
the surface of the file. `hydrogens => 0` likewise: crystallographic structures
mostly have no hydrogens to begin with, and one that does will give a smaller
surface than its neighbours in the archive unless they are taken out.

### Options

| option | default | what it does |
| --- | --- | --- |
| `sasa` | 1 | compute the solvent-accessible surface |
| `pi_stacking` | 1 | look for stacked aromatic rings |
| `disulfides` | 1 | look for SG-SG pairs close enough to be bonded |
| `base_pairs` | 1 | look for Watson-Crick and wobble base pairs |
| `base_stacks` | 1 | score how far every nearby pair of bases is stacked |
| `interface` | 1 | also run the surface on each chain alone, for the buried area |
| `shape` | 1 | the gyration tensor and the descriptors built from it |
| `dihedrals` | 1 | phi, psi, omega and chi1-chi5 on an amino acid, alpha to zeta, chi and the pucker on a nucleotide, onto each residue and, as one array per angle, onto each chain |
| `contacts` | 1 | which residues touch which |
| `exposure` | 1 | half-sphere exposure, onto each amino acid residue |
| `hbonds` | 1 | backbone hydrogen bonds, by Kabsch and Sander's energy |
| `secondary` | 1 | secondary structure, onto each residue and as the `dssp` roll-up |
| `store` | 1 | write the per-atom, per-residue and per-chain figures into `$info` |
| `probe` | 1.4 | solvent probe radius, angstrom |
| `points` | 960 | sphere points per atom, from 1 to 10,000,000 |
| `face_distance` | 5.5 | face-to-face: the largest centroid separation, angstrom |
| `face_plane_min`, `face_plane_max` | 0, 35 | ... and the angle between the ring planes, degrees |
| `face_normal_min`, `face_normal_max` | 0, 33 | ... and between a ring's normal and the line joining the centroids |
| `edge_distance` | 6.5 | edge-to-face: the largest centroid separation, angstrom |
| `edge_plane_min`, `edge_plane_max` | 50, 90 | ... and the angle between the ring planes |
| `edge_normal_min`, `edge_normal_max` | 0, 30 | ... and between a normal and the centroid line |
| `edge_radius` | 1.5 | ... and how close to a centroid the two planes' shared line must pass |
| `disulfide_distance` | 3.0 | the largest SG-SG separation that counts as a bond, angstrom |
| `peptide_bond` | 1.8 | the largest C-to-N separation that still joins two residues, angstrom |
| `phosphodiester_bond` | 2.4 | the same for the O3'-to-P separation of two nucleotides |
| `base_pair_hbond` | 3.5 | the longest hydrogen bond a base pair may have, angstrom |
| `base_pair_stagger` | 2.6 | and the furthest one base may sit out of the other's plane |
| `base_stack_distance` | 5.0 | the furthest apart two stacked bases' centres of mass may be, angstrom |
| `base_stack_omega` | 50 | and the largest overlap angle that is still a stack, degrees |
| `contact_distance` | 4.5 | the largest heavy-atom separation that counts as a contact, angstrom |

A structure read with `atoms => 0` has no coordinates to work from, and saying
so is more use than reporting no surface:

    my $info = structure_info('1ubq.pdb', atoms => 0);
    structure_features($info);
    # dies: this structure has no atom hashes to work from;
    #       read it again without atoms => 0

### Shape, and what the chains bury

`$f->{shape}` is the gyration tensor and the three numbers built from its
eigenvalues, which are mdtraj's `geometry/shape.py`:

    $f->{shape}{principal_moments};   # [ 74.1, 92.6, 132.1 ]  A^2, ascending
    $f->{shape}{asphericity};         # 41.84   how far from a sphere
    $f->{shape}{acylindricity};       # 21.10   how far from a cylinder
    $f->{shape}{anisotropy};          # 0.0233  0 for a sphere, 1 for a line

The three moments sum to `rg` squared, which is the same sum read two ways.

`$f->{sasa}{buried}` is what the chains bury against each other — the surface
they have apart, less the surface they have together — and each chain carries
`sasa_alone` and `buried` of its own. A two-body interface is usually quoted as
half of the total, because the area is counted once on each side of it.

    $f->{sasa}{buried} / 2;              # 1471.2 A^2 of interface
    $info->{chains}{A}{buried};          # 1445.0 A^2, chain A's side of it

It costs one more surface calculation per chain, and a chain's calculation
touches only that chain's atoms, so all of them together cost about what the
first one cost rather than the number of chains times it. `interface => 0` turns
it off.

### Torsion angles

On each amino acid residue: `phi`, `psi` and `omega`, in degrees, and `chi` as a
list of chi1 upwards — mdtraj's `compute_phi`, `compute_psi`, `compute_omega` and
`compute_chi1` through `compute_chi5`.

An angle that would be measured across a chain break is not reported: the two
residues must be peptide-bonded first, at Biopython's `PPBuilder` radius of
1.8 Å. mdtraj takes the residue before this one to be whichever came before it
in the file and computes a phi across whatever gap is there, which is a number
rather than an answer. Four collinear atoms get no angle either, for the same
reason.

`omega` near zero is a cis peptide bond, which `$info->{cispep}` is the
depositor's own record of — two answers to one question, as with the disulfides.

### The same angles, by chain

Every angle written onto a residue is also gathered onto its chain, one array
per torsion, which is the form a Ramachandran plot or a rotamer census wants:

    my $t = $info->{chains}{A}{torsions};
    $t->{phi};       # [ undef, -64.2, -175.0, -127.6, ... ]
    $t->{psi};       # [ -167.5, 158.8, -149.5, 20.5, ... ]
    $t->{omega};     # [ -167.3, 177.7, -176.3, -177.5, ... ]
    $t->{chi};       # [ [ -132.6, -44.5 ], [ 79.3, -89.7 ], undef, ... ]

Each array is parallel to the chain's `residue_order`, one element per residue,
so `$t->{phi}[$i]` and `$info->{chains}{A}{residues}{ $c->{residue_order}[$i] }`
are the same residue. A residue that has no such torsion — the first of a chain
has no `phi`, glycine no `chi` — holds an `undef` there rather than being left
out: the position is what says which residue a value came from.

A key no residue in the chain has at all is absent instead, so a protein chain
carries `phi`, `psi`, `omega` and `chi`, a nucleic acid one `alpha` through
`zeta` and the pucker, and neither carries a dozen arrays of nothing. The
elements are copies, except that `chi` and `nu` are the residue's own lists
named a second time.

It is the same option as the angles themselves: `dihedrals => 0` leaves the
`torsions` hash off with them, and so does `store => 0`.

When the angles are all that is wanted, `structure_info($file, 'torsions')`
hands back these hashes alone, keyed by chain id, and throws the rest of the
structure away:

    my $t = structure_info('1a22.ent.pdb', 'torsions');
    keys %$t;                  # A, B: the hormone and its receptor
    $t->{A}{phi};              # [ undef, -57.8, -138.9, -67.7, ... ]
    $t->{A}{residue_order};    # [ 1, 2, 3, 4, ... ]  which residue each one is
    $t->{B}{residue_order};    # [ 233, 234, 235, 236, ... ]

Each chain keeps the keys its own residues have, so a file whose chain A is a
protein and whose chain B is a DNA strand comes back with `$t->{A}{phi}` and
`$t->{B}{alpha}`, and no `$t->{A}{alpha}`. A chain that holds both kinds has
both sets, with an `undef` at each residue an angle does not belong to. Every
chain also carries its `residue_order`, because the arrays mean
nothing without it and nothing else in the structure is kept. A chain with no
angle at all, such as a water chain or a lone ligand, is left out. The
torsion angles are features, so asking for this view of a file read with
`features => 0` dies rather than returning an empty hash.

A nucleotide gets a different set of torsions from the same option; they are
below.

### Nucleic acid torsions, and the sugar pucker

The same block answers the nucleic acid question, because a residue is one kind
or the other and both want the same walk. On every nucleotide, in degrees:

| key | what it is |
| --- | --- |
| `alpha` | O3' of the residue before, then P, O5', C5' |
| `beta` | P, O5', C5', C4' |
| `gamma` | O5', C5', C4', C3' |
| `delta` | C5', C4', C3', O3' |
| `epsilon` | C4', C3', O3', then P of the residue after |
| `zeta` | C3', O3', then P and O5' of the residue after |
| `chi` | O4', C1', then N9 and C4 of a purine or N1 and C2 of a pyrimidine |
| `nu` | the five torsions of the sugar ring itself, nu0 to nu4 |
| `pucker_phase` | the pseudorotation phase angle, 0 to 360 |
| `pucker_amplitude` | how far the ring is from flat |
| `pucker` | which of the ten envelope shapes that phase names |
| `glycosidic` | `anti` or `syn` |

The names and the atoms are the IUPAC-IUB Joint Commission on Biochemical
Nomenclature's (1983) *Abbreviations and symbols for the description of
conformations of polynucleotide chains*. `chi` is the same key an amino acid's
side chain torsions come back under and no residue has both — an amino acid has
no C1' and a nucleotide has no CB — but an amino acid's is a list of up to five
and a nucleotide's is one number.

`alpha`, `epsilon` and `zeta` each span two residues and are not reported across
a chain break, the way `phi` and `psi` are not: the two nucleotides must be
joined by a phosphodiester bond first, which is gemmi's test — an O3'-to-P
separation under 1.5 times the 1.6 Å ideal bond.

The pucker is Altona and Sundaralingam (1972) *J Am Chem Soc* 94(23):8205-12,
which describes the ring with two numbers instead of five on the observation
that the five `nu` are one sinusoid sampled at five points. It is the number
that tells the two helices apart, and it does so out loud: every ribose of
`t/data/rna.pdb`, six nucleotides of a real rRNA hairpin, is C3'-endo, and every
deoxyribose of `t/data/duplex.pdb`, four base pairs of the Drew-Dickerson
dodecamer, is in the southern half of the cycle where C2'-endo is.

    C3'-endo    0-36     C4'-exo    36-72    O4'-endo   72-108
    C1'-exo   108-144    C2'-endo  144-180   C3'-exo   180-216
    C4'-endo  216-252    O4'-exo   252-288   C1'-endo  288-324
    C2'-exo   324-360

`glycosidic` bisects `chi` at 90° either side of zero, which is Saenger's
division and what DSSR reports. It has two names and no third, so the band
around -90° that the literature calls high-anti comes back as `syn`; `chi`
itself is beside it for a caller who wants to say so.

Which bases are paired is a separate question and a separate answer;
`structure_base_pairs` below has it.

### Half-sphere exposure

`hse_up` and `hse_down` on each residue: the CA atoms of other residues within
12 Å, split by which side of the plane through this residue's CA they fall —
`hse_up` towards the side chain. It says something the accessible surface does
not, because a residue can be buried and still have its side chain pointing into
a cavity. This is Biopython's `Bio.PDB.HSExposure.HSExposureCB`, and the two
agree exactly.

Only the twenty standard amino acids, because Biopython's is built on
`CaPPBuilder` with `aa_only`, so a selenomethionine is invisible to it — it
neither gets a figure nor counts towards anybody else's. Glycine gets the
virtual CB Biopython builds for it.

## structure_sasa

    my $s = structure_sasa($info);
    $s->{total};                                # 17805.0 A^2
    $info->{chains}{A}{residues}{54}{rsa};      # 0.103 -- mostly buried

    my $vdw = structure_sasa($info, probe => 0);   # the van der Waals surface
    my $fast = structure_sasa($info, points => 100);

The solvent-accessible surface and nothing else: the same calculation
`structure_features()` runs, without the ring geometry. It returns the `sasa`
hash and writes the per-atom, per-residue and per-chain surfaces into `$info`
the same way. `store`, `probe` and `points` are the options it takes.

A water molecule is a sphere about 1.4 A across, which is where the default
probe comes from; rolling a larger one gives a larger surface, because it cannot
reach into the dips. `probe => 0` gives the van der Waals surface, which is the
smallest of them.

`points` is accuracy against time. The area of an atom is 4*pi*r^2 times the
share of its sphere points no neighbour covers, so one point is worth about
0.13 A^2 for a carbon at 960 points and ten times that at 96; the whole surface
of a small protein moves by well under a percent between the two, and any single
atom can move by rather more.

### Relative accessibility

`rsa` is a residue's surface as a fraction of the most it could have — the
number the buried-or-exposed question is actually asked of, since 130 A^2 is
most of an alanine and a sliver of a tryptophan. It is on every amino acid
residue and on nothing else: the single-letter codes of the nucleotides are
amino acid codes too, and a guanine divided by glycine's maximum would be a
number rather than an answer.

A residue can come out above 1. The maxima are of a Gly-X-Gly tripeptide
stretched out, and a residue at the end of a chain with nothing next to it can
beat that.

`apolar` is the part of the surface belonging to carbon and sulphur atoms and
`polar` is everything else, which is the split Chothia made when he first added
a protein's buried surface up. Only the element symbol decides it, so a sulphur
in a sulphate counts as apolar; the per-atom figures are there for anyone who
wants a chemistry-aware split.

## structure_pi_stacking

    for my $s (@{ structure_pi_stacking($info) }) {
        printf "%s %s%s %s and %s %s%s %s are %s stacked, %.2f A apart\n",
            $s->{chain1}, $s->{resname1}, $s->{residue1}, $s->{ring1},
            $s->{chain2}, $s->{resname2}, $s->{residue2}, $s->{ring2},
            $s->{type}, $s->{distance};
    }
    # A TRP5 6 and A HIS64 5 are face stacked, 3.70 A apart
    # A PHE66 6 and A PHE226 6 are edge stacked, 5.36 A apart

Every pair of aromatic rings in the structure that is stacked on the other, as
an arrayref of hashes. Two arrangements count, and they are the two ProLIF and
mdtraj look for: *face*, two rings lying flat on each other, and *edge*, one
ring pointing its edge at the other's face.

| key | what it is |
| --- | --- |
| `type` | `face` or `edge` |
| `chain1`, `residue1`, `resname1`, `ring1` | the first ring: its chain, the residue key it is keyed by in `$info`, the residue name, and `6` or `5` for the ring's size |
| `chain2`, `residue2`, `resname2`, `ring2` | the second |
| `distance` | between the two ring centroids, angstrom |
| `plane_angle` | between the two ring planes, degrees, folded into 0 to 90 |
| `normal_angle1`, `normal_angle2` | between each ring's normal and the line joining the centroids, likewise |
| `intersect_distance` | edge stacks only: how far the line where the two planes meet passes from the nearer centroid |

It writes nothing into `$info`, and takes the eleven geometry options in the
table above and none of the others.

### Which rings

The rings are the ones the format's own atom naming fixes: phenylalanine and
tyrosine's six-membered ring, tryptophan's six and five, histidine's five
(including the HID/HIE/HIP and HSD/HSE/HSP spellings a force field leaves
behind), the six- and five-membered rings of adenine and guanine, and the
six-membered ring of cytosine, thymine and uracil, in DNA and in RNA.

A ligand contributes none. Working out that a ligand has an aromatic ring means
perceiving its bonds, and this module never reads a CONECT record or guesses a
bond — so a stack between a drug and a tyrosine is not something it can find,
and it says so here rather than quietly finding nothing.

A ring missing any of its atoms is skipped, and the two rings of one tryptophan
or one purine are never paired with each other: they are fused into one aromatic
system, not two systems stacked.

### On the face-to-face distance

`face_distance` defaults to 5.5 **angstrom**. mdtraj's `pi_stacking()`, which
this is a translation of, has `max_face_to_face_centroid_distance=5.5` in a
function whose other three distances are nanometres — 55 A, far enough that any
two aromatic rings in a small protein would qualify on distance alone. ProLIF,
whose geometry mdtraj's is taken from, has 5.5 A, and mdtraj's other three
distances are ProLIF's converted. So 5.5 A is what was meant, and it is what
this uses. `face_distance => 55` gets the number mdtraj ships.

## structure_contacts

    for my $c (@{ structure_contacts($info) }) {
        printf "%s%s - %s%s  %.2f A\n",
            $c->{chain1}, $c->{residue1}, $c->{chain2}, $c->{residue2}, $c->{distance};
    }

Which residues touch which: pairs whose closest heavy atoms are within
`contact_distance`, with that distance. `$residue->{n_contacts}` counts them per
residue. Hydrogens are left out, which is what makes the number comparable
between a structure that has them and one that does not.

This is mdtraj's `compute_contacts()` with its default `closest-heavy` scheme.
mdtraj's `all` pairs up residues in the same chain that are three or more apart
in it; this reports those and the neighbouring and cross-chain pairs too,
because a caller looking at a complex wants the interface and dropping it
silently would be strange. `t/features.t` compares the subset mdtraj has an
opinion about, and finds the same distances.

## structure_hbonds

    for my $b (@{ structure_hbonds($info) }) {
        printf "%s%s N-H ... O=C %s%s  %.2f kcal/mol\n",
            $b->{donor_chain}, $b->{donor_residue},
            $b->{acceptor_chain}, $b->{acceptor_residue}, $b->{energy};
    }

The backbone hydrogen bonds, by Kabsch and Sander's electrostatic definition:
a charge of -0.42 e on the carbonyl oxygen and +0.20 e on the amide hydrogen,
their opposites on the carbon and the nitrogen, and the four-way Coulomb sum as
the energy. Anything below -0.5 kcal/mol is a bond.

The amide hydrogen is not read from the file, it is placed — one angstrom from
N along the previous residue's C=O — which is what lets the definition be used
on a crystal structure that has no hydrogens in it. Proline has no amide
hydrogen and never donates. Each nitrogen keeps its two best acceptors.

This is mdtraj's `kabsch_sander()`, and the two agree exactly: over 1A42, 1A22,
1AHW and 3AU6 they find the same bonds and the same energies to 4e-5 kcal/mol,
which is float32 rounding on mdtraj's side.

These are not the bonds the secondary structure is read from. `structure_dssp()`
builds a second table, to mdtraj's rules rather than to this module's, and the
two differ by a handful of bonds per structure; the section below says why.

## structure_dssp

    my $dssp = structure_dssp($info);
    my $dssp = structure_info($file, 'dssp');       # the same, from a file

    for my $i (@{ $dssp->{A}{H} }) {                # every helical residue of A
        my $order = $info->{chains}{A}{residue_order};
        my $r     = $info->{chains}{A}{residues}{ $order->[$i] };
        printf "%s%s is in a helix\n", $r->{resname}, $r->{number};
    }

The secondary structure, chain by chain and letter by letter: a hash of hashes
whose keys are chain ids and then DSSP letters, and whose values are the
positions in that chain's `residue_order` of the residues that have the letter,
in order.

This is `t/data/fold.pdb`, a stretch of carbonic anhydrase II that folds and has
no strand in it, so five of the eight letters appear:

    {
        A => {
            'H' => [ 9, 10, 11, 12 ],               alpha helix
            'G' => [ 17, 18, 19, 20, 31, 32, 33 ],  3-10 helix
            'T' => [ 5, 6, 7, 13, 14, 15, ... ],    turns
            'S' => [ 3, 4, 8, 21, 25, 34 ],         bends
            ' ' => [ 0, 1, 2, 16, 24, ... ],        coil
        },
    }

An index is a position and not a residue number: `residue_order` is what it
indexes, and so is `structure_residues($info, $chain)`, which is the same
residues in the same order. A chain with no assigned residue in it is not a key,
and neither is a letter no residue of the chain has — so a nucleic acid chain,
or a chain of waters, is simply absent.

The eight letters are the Kabsch–Sander dictionary's:

| letter | what it is |
| --- | --- |
| `H` | alpha helix |
| `G` | 3-10 helix |
| `I` | pi helix |
| `E` | extended strand |
| `B` | isolated beta bridge |
| `T` | hydrogen-bonded turn |
| `S` | bend |
| ` ` | none of them |

The same assignment is on the residues themselves, which is where to read it
when you are walking them anyway: `$residue->{ss}` is the letter and
`$residue->{ss_simple}` is the three-state reduction of it — `H` for the three
helices, `E` for the two sheet letters, `C` for everything else. A residue with
no backbone gets neither, because it is not coil, it is not protein.

There is nothing to tune, so `structure_dssp()` takes no options: DSSP is the
hydrogen bonds and the two constants Kabsch and Sander chose for them.
`structure_info($file, dssp => 1)` leaves the same hash at `$info->{dssp}` for a
caller who wants the structure as well.

### Against mdtraj

This is mdtraj's `compute_dssp()`, letter for letter. It is not the 1983 paper
read afresh: `mdtraj/geometry/src/dssp.cpp` — itself DSSP 2.2.0 ported by
Robert T. McGibbon — is transcribed function for function, together with the
`kabsch_sander()` it calls and the float32 arithmetic both compute in, down to
the order the four terms of the energy are summed in. `t/features.t` demands
equality on every residue of every structure in `t/data` rather than bounding a
disagreement.

Measured over every tenth entry of PDBbind v2020 — 1,011 of the 1,012 read, the
other being a file mdtraj will not open at all — the two give the same letter
for all 619,067 residues that have a backbone. Not most of them; all of them.

There is one place where that agreement is luck rather than construction, and it
is mdtraj's end. It places an amide hydrogen from the residue before in its
array without checking that that residue has a carbonyl; where it has none,
`ks_assign_hydrogens()` indexes the coordinate array with -1 and reads whatever
lies in front of it. What it finds is not a structure, and the hydrogen it
places from it bonds to nothing — which is what this code does on purpose. If it
ever found something, the two would part company there.

Two things follow from matching it that are worth knowing about.

The first is that the hydrogen bonds underneath are not the ones
`structure_hbonds()` reports. Those are the same energy over a table built to
this module's own rules: a donor has to be peptide-bonded to the residue whose
carbonyl its hydrogen was placed from. mdtraj asks for no such thing — the
residue before in its array will do, bonded or not, same chain or not — and DSSP
is defined on mdtraj's table. A table built to be right and a table built to be
mdtraj's cannot be the same table, so there are two.

The second is where one chain stops and the next begins, which DSSP needs
because no turn, bridge or bend may cross a chain. mdtraj starts a new chain at
every `TER` record and every change of chain id, so a chain's ligands and its
waters are chains of their own; this module keeps an author chain whole. The
division is made here instead, by cutting an author chain after the last residue
of its polymer — which is the same line the `TER` draws, and is drawn from the
residues themselves rather than from a record only one of the two formats has.
That is what keeps `1cka.pdb` and `1cka.cif` answering the same.

## structure_disulfides

    for my $b (@{ structure_disulfides($info) }) {
        printf "%s%s - %s%s  %.2f A\n",
            $b->{chain1}, $b->{residue1}, $b->{chain2}, $b->{residue2}, $b->{distance};
    }
    # A23 - A88    2.01 A
    # A134 - A194  2.04 A

    $info->{chains}{A}{residues}{23}{disulfide};
    # [ { chain => 'A', residue => '88', distance => 2.011 } ]

The disulfide bonds the coordinates show: pairs of cysteines whose SG atoms are
close enough to be bonded. Each bond is also written onto both of its residues,
as a list naming the partner — a list because a cysteine that appears to hold
two bonds means something is wrong with the entry, and reporting both is more
use than dropping one.

The rule is a cysteine with an `SG` and no `HG`, paired with another under 3.0 Å.
The `HG` test is what separates a cysteine whose thiol hydrogen was modelled — so
it is reduced, and holds no bond — from one that was not; a crystal structure
with no hydrogens has no `HG` anywhere and every cysteine is a candidate, which
is right. `disulfide_distance` moves the cutoff.

Only residues named `CYS`. AMBER and CHARMM rename a bonded cysteine to `CYX`,
and a structure that has been through a force field needs its residues named the
way the archive names them.

### Against what the file says

`$info->{ssbond}` is the other answer: what the depositor wrote in an SSBOND
record, or in an mmCIF `_struct_conn` row of type `disulf`. Neither is the
authority, and comparing them is worth doing:

    my $key = sub {
        my ($c1, $r1, $c2, $r2) = @_;
        return join '|', sort "$c1/$r1", "$c2/$r2";
    };
    my %found = map { $key->(@{$_}{qw(chain1 residue1 chain2 residue2)}) => $_->{distance} }
                @{ structure_disulfides($info) };
    my %said  = map { $key->(@{$_}{qw(chain1 resseq1 chain2 resseq2)}) => $_->{length} }
                @{ $info->{ssbond} };
    my @undeclared = grep { !exists $said{$_}  } keys %found;
    my @unseen     = grep { !exists $found{$_} } keys %said;

Over a 60-entry spread of PDBbind the two agree on every entry that has
disulfides, and where both name the same bond their lengths agree to the two
decimals SSBOND is written in. Over a wider sweep they agree on 21 of 22; the
one that does not is 1A4K, a Fab that is in the file twice, whose SSBOND records
cover one copy and whose coordinates show both. A disagreement is a fact about
the entry, not about either answer.

## structure_base_pairs

    for my $p (@{ structure_base_pairs($info) }) {
        printf "%s%s %s - %s%s %s  %s, Saenger %d\n",
            $p->{chain1}, $p->{residue1}, $p->{resname1},
            $p->{chain2}, $p->{residue2}, $p->{resname2},
            $p->{type}, $p->{saenger};
    }
    # A2648 G - A2672 U  G-U, Saenger 28
    # A2649 C - A2671 G  C-G, Saenger 19
    # A2650 U - A2670 A  U-A, Saenger 20
    # A2651 C - A2669 G  C-G, Saenger 19
    # A2652 C - A2668 G  C-G, Saenger 19

    $info->{chains}{A}{residues}{2648}{base_pair};
    # [ { chain => 'A', residue => '2672', resname => 'U',
    #     type => 'G-U', saenger => 28 } ]

(`t/data/wobble.pdb`, twelve nucleotides of 1MSY.)

The base pairs the coordinates show. Like the disulfides, this is geometry and
not something the file declares, and each pair is written onto both of its
residues as well as returned.

Only the canonical pairing, which is three geometries:

| `saenger` | `type` | hydrogen bonds |
| --- | --- | --- |
| 19 | G-C | O6···N4, N1···N3, N2···O2 |
| 20 | A-U, A-T | N6···O4, N1···N3 |
| 28 | G-U, G-T — the wobble | O6···N3, N1···O2 |

`type` names the two bases in the order the record reports them, so a `C-G` and
a `G-C` are the same pair read from the two ends; `saenger` does not depend on
the order. The numbers are Saenger's, from the table of twenty-eight pair types
in *Principles of Nucleic Acid Structure* chapter 6, and are the same numbers
the archive uses in `_ndb_struct_na_base_pair.hbond_type_28`.

Each pair also carries the geometry it was found by:

| key | what it is |
| --- | --- |
| `hbonds` | one `{ atom1, atom2, distance }` per bond above, in the order the table gives them |
| `distance` | between the two bases' six-membered ring centroids, angstrom |
| `plane_angle` | between the two ring planes, 0 to 90 degrees |
| `stagger` | how far one base sits out of the other's plane, angstrom |

Two bases are a pair when every one of that type's hydrogen bonds is at most
`base_pair_hbond` long and the stagger is at most `base_pair_stagger`. The
stagger is what tells a pair from the base stacked above or below it, which
brings the same atoms within reach but sits a helical rise away rather than
beside it.

### Where the thresholds come from

There is no reader on hand with an opinion about which bases are paired — not
mdtraj, not gemmi, not Biopython — so the rule is measured against the
annotation the wwPDB deposits with the entry itself, which is 3DNA's. Forty
archive entries carrying an `_ndb_struct_na_base_pair` loop hold 1372 pairs of
Saenger type 19, 20 or 28 between them, and 1354 of those are between two
unmodified bases. The defaults find all 1354 and miss none:

- the longest hydrogen bond in one of them is 3.4941 Å and the shortest one in
  a candidate the annotation does not call a pair is 3.5144 Å, so 3.5 Å — which
  is also the conventional heavy-atom hydrogen bond distance — falls between;
- the largest stagger in one of them is 2.5408 Å and the smallest in a rejected
  candidate 2.6983 Å, with the stacked contacts proper beginning near 3.0 Å.

The eighteen pairs it does not see are not geometry. Eleven have a modified base
on one side — `5MC`, `2MG`, `BRU`, `DDG` — which has no single-letter code to
match the table with. The other seven are in entries whose asymmetric unit holds
one strand of a self-complementary duplex and whose second strand is a
crystallographic symmetry mate: this reads the coordinates as deposited, where
the two are thirty and forty angstrom apart.

Two pairs are found that the annotation does not list, and both are worth
reading. 1JJ2's C2542–G2617 is a G-C with all three bonds under 2.94 Å and half
an angstrom of stagger that appears nowhere in that entry's 1121 annotated rows.
3SWP's DT4–DA24 is in a 4.11 Å structure whose annotation pairs its DT4 with
DA25 instead and cannot put a Saenger number on that pair either.

Every base in those forty entries came out of the rule with at most one partner.
That is what the geometry did rather than something imposed, so a residue's
`base_pair` is a list all the same: nothing in the rule forbids a second, and
a second would say something about the entry worth not hiding.

### What is not here

A base pair that is none of those three. There are twenty-eight in Saenger's
table and rather more in the Leontis–Westhof classification, and telling them
apart is a different kind of work: the canonical three are defined by which
atoms hydrogen-bond to which, and the rest need the base reference frames and
the six pair parameters that `_ndb_struct_na_base_pair` carries. What comes back
here is the double helix, not the whole of RNA structure. `t/data/wobble.pdb`
holds one of the others — the U2647·G2673 pair 1MSY's annotation records and
cannot classify — and this leaves it alone, which is the test that it does.

## structure_base_stacks

    for my $s (@{ structure_base_stacks($info) }) {
        printf "%s%s %s - %s%s %s  d0 %.2f  omega %.1f  Xi %.1f  %.0f%%\n",
            $s->{chain1}, $s->{residue1}, $s->{resname1},
            $s->{chain2}, $s->{residue2}, $s->{resname2},
            $s->{distance}, $s->{omega}, $s->{xi}, $s->{score};
    }
    # B13 C - B14 G  d0 4.53  omega 40.7  Xi 17.3   33%
    # B14 G - B15 C  d0 3.94  omega 23.3  Xi  7.8  100%
    # B15 C - B16 G  d0 4.34  omega 36.1  Xi 17.1   48%
    # B16 G - B17 A  d0 4.34  omega 34.8  Xi 13.9   51%
    # B17 A - B18 A  d0 3.91  omega 29.3  Xi 18.0   91%

    $info->{chains}{B}{residues}{14}{base_stack};
    # [ { chain => 'B', residue => '13', resname => 'C', type => 'G-C',
    #     distance => 4.5286, omega => 40.740, xi => 17.307,
    #     score => 32.518, side => "3'" },
    #   { chain => 'B', residue => '15', resname => 'C', type => 'G-C',
    #     distance => 3.9353, omega => 23.292, xi => 7.833,
    #     score => 100, side => "5'" } ]

(`t/data/aform.pdb`, six nucleotides of 157D.)

How stacked every nearby pair of nucleobases is, on the three variables the RNA
literature scores stacking with — the distance d0 between the two bases, the
overlap angle ω, and the angle Ξ between their planes — and as one score built
out of them. Like the base pairs this is geometry rather than anything the file
declares, and each stack is written onto both of its residues as well as
returned.

The definition is section 2.4 of

    Condon, D E; Kennedy, S D; Mort, B C; Kierzek, R; Yildirim, I;
    Turner, D H (2015) "Stacking in RNA: NMR of Four Tetramers Benchmark
    Molecular Dynamics", J Chem Theory Comput 11(6):2729-2742,
    doi:10.1021/ct501025q

which is where the criteria, the thresholds and the score come from; the
implementation its numbers were produced with is the same authors'
[PDB_stacker](https://github.com/hhg7/PDB_stacker). The paper benchmarks AMBER
force fields by comparing four RNA tetramers against NMR, and these three
numbers are how it decides which bases a simulation had stacked.

### The three variables

Each base gets a centre of mass over its heavy atoms and two vectors `a` and `b`
from there to two atoms far apart on the ring, chosen so that the pair spans the
base and out-of-plane distortion moves their cross product as little as
possible. `a` × `b` and `b` × `a` are the base's two normal vectors, one above
the plane and one below.

| key | what it is |
| --- | --- |
| `distance` | d0, between the two bases' centres of mass, angstrom |
| `omega` | ω, "oh-mega" for overlap: how far the 3' base sits off the 5' base's face, degrees |
| `xi` | Ξ, the angle between the two bases' normals: 0 is parallel, 90 a T-shape, degrees |
| `score` | the three of them as one percentage, -100 to 100 |
| `stacked` | 1 when `score` is over 50, which is what the paper calls stacked |

ω is the angle at the 5' base's centre of mass in the triangle whose sides are
d0, the length of that base's normal vector, and the distance from the tip of
whichever of its two normals lands nearer the 3' base's centre of mass. It is
small when one base sits over the other's face and large when it sits beside it
— the angle between the steps of a staircase. Ξ tells a parallel stack from a
T-shape, which is a different interaction and scores negative rather than being
dropped.

The pair is ordered, because ω is measured from one base and not the other. The
5' base is the one the file lists first, which along a strand written 5' to 3' —
as both formats and the archive write one — is the chemical order. Two bases in
different chains have no 5'/3' relation at all, and there the order is the chain
order. Each residue's own `base_stack` entry says which end of the pair it is,
in `side`, so that a residue's ω can be read the right way round.

### The score

Two points, one for the distance and one for the overlap, reported as a
percentage of two:

- d0 at or under 4 Å scores 1, and falls off as r^-3 from there to the
  `base_stack_distance` cutoff;
- ω at or under 25 degrees scores 1, and falls linearly to 0 at the
  `base_stack_omega` cutoff;
- Ξ over 45 degrees multiplies the whole thing by -1, which is a T-shape rather
  than a stack.

Every pair inside `base_stack_distance` is reported, stacked or not, because the
three variables are the answer and the score is a summary of them: a run of
tetramer snapshots wants the pair that scored 12% as much as the one that scored
98%. A pair whose ω is past `base_stack_omega` carries no `xi` — the paper does
not compute it there — and scores 0.

| option | default | what it does |
| --- | --- | --- |
| `base_stack_distance` | 5.0 | the furthest apart two centres of mass may be, angstrom |
| `base_stack_omega` | 50 | the largest overlap angle that is still a stack, degrees |

Both are the paper's, which took the distance from CCSD(T) calculations on
stacked uracil and adenine dimers and the angle from X-ray statistics. The two
knees between them — 4 Å and 25 degrees — are the shape of the score rather than
a threshold, and are not options.

### Which bases

Every residue this module gives a single-letter code of `A`, `C`, `G`, `I`, `T`
or `U` and calls a nucleotide, which is DNA and RNA alike and the sixty-odd
spellings `res1()` knows: a `PSU` is measured as a uridine, a `7MG` as a
guanosine, a `DA` and an `A` the same way. Four sets of atoms serve the six
letters — adenine's, guanine's (which inosine shares, having the same ring and
the same O6), cytosine's and uracil's (which thymine shares) — and each names
the two atoms its `a` and `b` run to:

| base | `a` | `b` |
| --- | --- | --- |
| A | C8 | N6 |
| G, I | C8 | O6 |
| C | O2 | N4 |
| U, T | O2 | O4 |

A base missing any of the atoms its entry names has no frame and is in no pair,
the same way an incomplete ring has no plane. That covers a `4SU`, whose O4 is a
sulphur, as well as a base whose density ran out; no geometry is invented for
either.

### Against the paper's worked example

Figure 4 of the paper illustrates the three variables on residues 13 (C) and 14
(G) of chain B of 157D and reports d0 = 4.5 Å, ω = 40.7 degrees and Ξ = 17.3
degrees. Those six residues are `t/data/aform.pdb`, exactly as deposited, and
`t/stacking.t` checks this against all three: it answers 4.5286, 40.7402 and
17.3071.

That one pair is the whole of the cross-validation, and it settles more than it
looks like. Three things about the definition are ambiguous on the printed page,
and the caption picks one reading of each:

- **Equation 10** is a minimum of two arcsines that differ only in the sign of a
  cross product, so the two are equal and the minimum is a formality; and taken
  literally it is the angle between the two normals with no reference to where
  the bases are, which gives 9.5 degrees for this pair. `PDB_stacker` instead
  compares the 5' base's normal with the 3' base's normal *redrawn from the 5'
  base's centre of mass*, and takes the smaller of the two answers its two
  normals give. That gives 17.31 degrees, so that is what Ξ means here.
- **Guanine's centre of mass** is over ten atoms and not eleven: N2, the
  exocyclic amino nitrogen, is not in `PDB_stacker`'s list, though adenine's N6
  and cytosine's N4 are in theirs. Including it gives d0 = 4.77 Å and ω = 43.56
  degrees against the caption's 4.5 and 40.7; leaving it out gives 4.53 and
  40.74.
- **The distance knee** is 3.5 Å in criterion I's text and 4 Å in
  `PDB_stacker`'s `$DISTANCE_MIN`. 4 is used, because it is the number the
  published percentages were computed with.

Each of those is marked at the site in `Parser.xs` with the measurement that
settles it.

### What is not here

Whether a stack is what holds a structure together. The score is a geometric
summary and not an energy: two bases at 100% are stacked in the sense the paper
counts stacks in an MD trajectory, which is what it was built to do. It says
nothing about what that stack is worth in kcal/mol, and the paper's own point is
that force fields which reproduce the geometry can still get the populations
wrong.

`structure_pi_stacking()` is the other question about the same atoms: mdtraj's
face-to-face and edge-to-face geometry over aromatic rings, ring by ring rather
than base by base, and over the aromatic amino acids as well. It answers whether
two rings are stacked; this answers how much.

## structure_rmsd

    my $d = structure_rmsd('before.pdb', 'after.cif');   # one number, in angstrom
    my $d = structure_rmsd($info1, $info2);              # or two structures already read

    # an NMR ensemble against itself: every model against every other model
    my $r = structure_rmsd('2ll7.pdb', model => 'all');
    printf "models 1 and 7 are %.2f A apart\n", $r->{rmsd}[0][6];

How far apart two copies of the same molecule are: the root mean square
deviation over the atoms they have in common, after the rigid-body move that
makes it as small as it can be.

Each argument is a file name or the hash reference `structure_info()` returned,
in any mix, and the options come after them. A structure read with
`model => 'all'` counts as one structure per model, which is what makes the
ensemble case a single call. **Every structure is compared with every other
one**: two of them give the number, more than two give the matrix.

An argument that is a file name is read for you, with `meta => 0` and
`features => 0` — the header records and the physical properties are most of
what a read costs and none of this looks at either.

### Which atom is which

Atoms are paired on the identity the file gives them: the chain, the residue as
this module keys it (its number and insertion code), and the atom name. Nothing
is aligned and nothing is guessed. An atom that is not in both structures under
the same name is not in the answer, and `$r->{n}` says how many were.

That is exactly right for two models of one ensemble, for a structure before
and after a minimisation, and for the same entry read as PDB and as mmCIF. It
is not right for two structures that number their residues differently or call
their chains by different letters, and there are three ways round that:
`chains` reads only some of them, `chain_map` says what a chain of the later
structures is called in the first, and `match => 'order'` pairs the *n*th atom
of each and ignores the names altogether.

    # the same domain, chain A in one file and chain H in the other
    structure_rmsd($apo, $holo, chain_map => { H => 'A' });

### What comes back

With two structures it is the RMSD in angstrom, or `undef` when there is no
answer to give — fewer than `min_atoms` atoms in common. With more than two it
is a hash reference:

| key | what it holds |
| --- | --- |
| `rmsd` | the matrix, `$r->{rmsd}[$i][$j]`: symmetric, 0 down the diagonal, `undef` for a pair with too few atoms in common |
| `n` | the same shape: how many atoms that pair had in common |
| `n_atoms` | one count per structure: how many atoms the selection left it with |
| `labels` | one name per structure, in the same order — the file name, and `... model N` for a model of an ensemble |
| `fit`, `select`, `match` | the options the answer was computed under |

`detail => 1` gives the same hash for two structures, with `rmsd` and `n` as
plain numbers rather than matrices, and adds the move itself: `rotation`, a
3x3 array of arrays, and `translation`, a vector, such that
`$b = rotation . $a + translation` takes the first structure onto the second.

### Options

| option | default | what it does |
| --- | --- | --- |
| `fit` | 1 | superpose before measuring; 0 measures the two where they lie, which is the question for two structures already in one frame |
| `select` | `'all'` | which atoms take part: `'all'`, `'heavy'` (everything but hydrogen and deuterium), `'backbone'` (N, CA, C, O of an amino acid; P, O5', C5', C4', C3', O3' of a nucleotide), or `'ca'` (CA of an amino acid, P of a nucleotide) |
| `match` | `'key'` | how atoms are paired: `'key'` by chain, residue and atom name, or `'order'` by position in the file |
| `min_atoms` | 3 | fewer atoms in common than this and the answer is `undef`. Three is where a rotation is determined; a pair below it has an arithmetic answer and not a meaningful one |
| `chain_map` | — | hash reference: what a chain of the second and later structures is called in the first |
| `detail` | 0 | return the hash rather than the one number |

`model`, `altloc`, `hydrogens`, `waters`, `hetatm`, `chains` and `format` are
`structure_info()`'s own and mean the same thing here; they apply to the
arguments that are file names. `chains` also applies to a structure already
read, as a filter over the chains it has.

Reading a file without its hydrogens and selecting the heavy atoms of one that
has them are the same answer over the same atoms — `t/rmsd.t` asserts it — so
either will do.

### Against gemmi and Biopython

The superposition is Theobald's quaternion characteristic polynomial (Theobald,
D L (2005) *Acta Cryst* A61:478), as its reference implementation `qcprot.c`
writes it (Liu, Agrafiotis and Theobald (2010) *J Comput Chem* 31:1561) and as
Biopython 1.85 ships it in `Bio/PDB/qcprot.py`.

The deviation itself is not read off the eigenvalue, which is what makes QCP
fast, and that is deliberate. `sqrt(2|E0 - L|/n)` subtracts two numbers that
agree in as many figures as the two structures do, and two structures being
nearly the same is the ordinary case: models 24 and 25 of 1JM4 have identical
coordinates, and gemmi 0.7.5 — which takes that route — answers 8.6e-07 A for
them where this answers 0. Here the rotation is formed and the deviation
measured with it, which costs one more pass over the paired atoms and has no
cancellation in it anywhere.

Against gemmi's `superpose_positions` over every pair of models of the 40 NMR
entries in the first two thousand files of PDBbind v2020 — 5,598 superpositions
— the largest relative difference is 5.65e-12 and the median 1.43e-14. Against
Biopython's `SVDSuperimposer` the two agree to every figure either prints.

Biopython's `QCPSuperimposer` is the exception and does not agree with any of
the three: over the 20 models of 2LL7 it reports 3.5022 A where gemmi,
`SVDSuperimposer` and this module all report 3.6090 A. Its Newton-Raphson
convergence test lost the absolute value `qcprot.c` has around it, so it stops
on the first iteration and reads the RMSD off a barely-improved starting guess.
Measuring with the rotation it returns itself gives 3.60899. `t/rmsd.t` says so
in its header, so that the next person to compare against it knows what they
are looking at.

## aa3to1

    aa3to1('ALA');    # 'A'
    aa3to1('MSE');    # 'M'   selenomethionine is still a methionine
    aa3to1('HOH');    # ''    water is not an amino acid
    aa3to1('NAG');    # ''

The single-letter code of an amino acid, and the empty string for anything
that is not one. Leading and trailing blanks and case do not matter, because
the name usually arrives straight out of columns 18 to 20.

Modified residues map to the residue they were made from — `MSE` to `M`, `SEP`
to `S`, `HYP` to `P`, the D-amino acids to their L partners — because a
structure that soaked in selenomethionine has the same sequence as one that
did not, and a sequence with an `X` every seventh position is no use to
anyone.

## aa1to3

    aa1to3('A');      # 'ALA'
    aa1to3('X');      # 'UNK'
    aa1to3('B');      # 'ASX'   ASP or ASN, as the format spells it
    aa1to3('*');      # ''      not a single-letter code

`aa3to1` backwards: the three-letter name a single-letter code stands for, and
the empty string for anything that is not one of the twenty-six. Blanks and
case do not matter, since the letter usually comes out of a sequence string
rather than out of a file.

Every letter of the alphabet has a name, because the ambiguity codes have one
of their own — `B` is ASX, `Z` is GLX, `J` is XLE, `X` is UNK. Going this way
there is only ever one answer: `aa3to1` maps sixty-odd names onto `C`, and
only CYS comes back.

Amino acids only, as the name says. `aa1to3('A')` is ALA and not adenine, and
`aa1to3('T')` is THR and not thymine — a caller who wants `' DA'` already
knows the chain is DNA, and a function that guessed from a bare letter would be
wrong half the time.

It is in the XS rather than in Perl because it is both faster and smaller
there: the table is 104 bytes of read-only memory in the shared object, shared
between every process that loads the module, against 3,350 bytes of hash per
interpreter, and the lookup is one bounds check and one array index instead of
a hash lookup — about 4.5× the throughput measured a letter at a time.

## res1

    res1('ALA');      # 'A'
    res1(' DA');      # 'A'   deoxyadenosine
    res1('PSU');      # 'U'   pseudouridine
    res1('HOH');      # ''

`aa3to1()` widened to nucleotides, which is what building a sequence wants
when the chain might be DNA or RNA.

## res_type

    res_type('ALA');  # 'amino_acid'
    res_type('DA');   # 'nucleotide'
    res_type('HOH');  # 'water'
    res_type('NAG');  # 'other'

What kind of residue a name is. `other` covers ligands, ions and sugars;
`structure_info()` narrows those to `ligand` or `ion` once it can see how many
atoms the residue has and what they are.

## formats

    my @can = formats(); # ('mmcif', 'pdb')
    my $all = formats(); # every format known, supported or not

## h

Prints a function's documentation to STDOUT. See *Getting help* above.

# Two residues that are not what they look like

Both of these were found by running the module over PDBbind v2020 and asking
where the sequence it read disagreed with SEQRES. Both are in the test suite.

**A free base is not a nucleotide.** `ADE`, `CYT`, `GUA`, `THY` and `URI` mean
one thing in a file written before 2007 — the nucleotides of a nucleic acid
chain — and another in a file written since: a free base sitting in an active
site as a ligand. The sugar tells them apart, since a nucleotide has a `C1'`
and a free base has nothing but the base. Without that check the guanine bound
to 1czc reads as a nucleotide and turns up as a `G` on the end of a
396-residue protein sequence.

**A free amino acid is not part of the chain.** A HETATM residue with an amino
acid's name is a modified residue when it is numbered among the polymer — the
MSE that replaced a methionine belongs in the sequence — and a free amino acid
bound in a site when it is numbered out with the ligands, in which case it
does not. 3lms has a glycine at A501, two hundred residues past the end of a
chain whose SEQRES is 309 long. Those are flagged `free => 1` and typed as
ligands.

Neither is a rule the format states; both are what the format means.

# Files that keep their entry id in columns 73-80

An entry deposited before about 1996 carried its id and a line number in the
last eight columns of every record, and the archive still distributes those
files as they were deposited. Every field a reader takes to the end of the line
is wrong on one of them, and wrong in a way nothing downstream can see: the
SEQRES of a 140-residue chain comes back 162 long with an `X` every thirteenth
place, the compound is the compound with `1GDR   3` after it, `HELIX` reports a
length of `1GDR`, and columns 77-78 make 105 atoms of element `1` — which also
stops `hydrogens => 0` from finding any hydrogens, since it is the element that
says which atoms those are.

So the columns are read as columns. SEQRES takes 20-70 and no more; an element
field that is not letters is not an element and the atom name is used instead;
a charge field that is not a digit and a sign reads as the empty string a blank
one would have given; a `HELIX` length that is not a number reads as empty; and
a text record whose columns 73-80 hold nothing but the entry id and a line
number is cut there — text that is not the entry id is left alone, so a title
that really does run to column 80 is not truncated.

`COMPND` and `SOURCE` predate the `MOL_ID` convention in a file like this and
are free text: `COMPND    GAMMA DELTA RESOLVASE`. There is no chain list in that
form because there was nothing to distinguish, so the entry is the one molecule
and every chain in it gets it, and `$info->{compound}{1}{free_text}` is 1 to say
the record was read that way rather than parsed into tokens.

`t/data/pdb1gdr.ent` is one such file, a 1993 entry, and `t/foreign.t` reads it.

# Where the physical properties come from

None of the arithmetic in `structure_features()` is this module's own. Each
piece is a translation of a published method as somebody else implemented it,
and the tests compare against those implementations rather than against what
this module currently does — `t/features.t` reads what mdtraj and gemmi answered
for every structure in `t/data`, frozen into `t/data/features.txt`, and re-runs
them where they are installed so the frozen answer cannot go stale.

| what | from | as implemented in |
| --- | --- | --- |
| solvent-accessible surface | Shrake, A; Rupley, J A (1973) *J Mol Biol* 79(2):351-71 | mdtraj 1.11's `mdtraj.geometry.shrake_rupley` |
| gyration tensor and shape | | mdtraj's `geometry/shape.py` |
| torsion angles | | `mdtraj.compute_phi`, `compute_psi`, `compute_omega`, `compute_chi1`-`chi5` |
| nucleic acid torsions | IUPAC-IUB Joint Commission on Biochemical Nomenclature (1983) *Eur J Biochem* 131:9-15 | `mdtraj.compute_dihedrals` and gemmi's `calculate_dihedral`, over the four atoms each definition names |
| sugar pucker | Altona, C; Sundaralingam, M (1972) *J Am Chem Soc* 94(23):8205-12, equations 1 and 2; the envelope names as tabulated there and in Saenger, W (1984) *Principles of Nucleic Acid Structure*, ch. 2 | |
| the phosphodiester cutoff | | gemmi's `are_connected()` in `gemmi/polyheur.hpp` |
| base pairs | Watson, J D; Crick, F H C (1953) *Nature* 171(4356):737-8; the pair types as numbered in Saenger, W (1984) *Principles of Nucleic Acid Structure*, ch. 6 | no implementation on hand: measured against the wwPDB's own `_ndb_struct_na_base_pair` annotation, which is 3DNA's, over forty entries |
| base stacking | Condon, D E; Kennedy, S D; Mort, B C; Kierzek, R; Yildirim, I; Turner, D H (2015) *J Chem Theory Comput* 11(6):2729-2742, section 2.4 | the same authors' `PDB_stacker`, and the paper's own Figure 4 worked on 157D |
| residue contacts | | `mdtraj.compute_contacts`, `closest-heavy` |
| backbone hydrogen bonds | Kabsch, W; Sander, C (1983) *Biopolymers* 22(12):2577-637 | `mdtraj.geometry.kabsch_sander` |
| secondary structure | the same paper | `mdtraj.compute_dssp` — exactly; see `structure_dssp` |
| half-sphere exposure | Hamelryck, T (2005) *Proteins* 59(1):38-48 | Biopython's `Bio.PDB.HSExposure.HSExposureCB` |
| the peptide-bond cutoff | | Biopython's `Bio.PDB.Polypeptide.PPBuilder` `radius` |
| disulfides | | mdtraj's `Topology.create_disulfide_bonds` rule |
| van der Waals radii | Bondi, A (1964) *J Phys Chem* 68:441, extended by Mantina, M *et al.* (2009) *J Phys Chem A* 113:5806, with Shannon, R D (1976) *Acta Cryst* A32:751 ionic radii for the ions that are always ionised | mdtraj's `_ATOMIC_RADII` |
| atomic masses | | mdtraj's `mdtraj/core/element.py` |
| pi-stacking geometry | ProLIF's FaceToFace and EdgeToFace | `mdtraj.geometry.pi_stacking` |
| radius of gyration | | `mdtraj.geometry.compute_rg` |
| maximum accessible surface, for `rsa` | Tien, M Z *et al.* (2013) *PLoS ONE* 8(11):e80635, Table 1, the theoretical column | |
| hydropathy | Kyte, J; Doolittle, R F (1982) *J Mol Biol* 157(1):105-132 | Biopython's `Bio.SeqUtils.ProtParamData.kd` and `ProteinAnalysis.gravy()` |
| aromaticity | Lobry, J R; Gautier, C (1994) *Nucleic Acids Res* 22(15):3174-3180 | Biopython's `ProteinAnalysis.aromaticity()` |
| G+C content | | Biopython's `Bio.SeqUtils.gc_fraction()`, with its default `ambiguous => 'remove'` |

mdtraj works in nanometres and float32; this module works in angstrom and NV,
which is what the two file formats are written in and what the rest of the
module already returns. The formulae are the same ones, so the answers agree to
the width of a float32: run in float64, mdtraj's own Shrake-Rupley loop and this
one give the same surface for every atom of every structure in `t/data` to nine
digits, and mdtraj as it ships differs on four atoms of 620, by one sphere point
each — a point sitting within a float32 ulp of a neighbouring atom's surface is
accessible at one width and covered at the other.

The secondary structure is the exception, and computes in float32 and nanometre
as mdtraj does. It is not a number but a letter, and the letter turns on two
comparisons against constants — an energy below -0.5 kcal/mol is a hydrogen
bond, a CA-to-CA separation under 0.9 nm is worth testing at all. Computing
those wider does not make them better; it makes them different, and one bond
either way is worth several residues' letters.

Three of these are deliberately not what the reference does, and each is argued
where it is written down. mdtraj computes a torsion angle, and places a Kabsch–
Sander amide hydrogen, between whichever residues are next to each other in the
file — across a chain break, where the chemistry never joined them; here the two
must be peptide-bonded, or phosphodiester-bonded, first. mdtraj's `Topology.create_disulfide_bonds()`
compares angstrom coordinates against a nanometre cutoff and so finds no
disulfide in any file; the rule it documents is the one implemented here. And
the face-to-face pi-stacking distance, above.

Two more are deliberately not mdtraj's: `rg_mass`, and
`compute_rg(traj, masses=m)` weights the distances by mass but still measures
them from the geometric centroid; `rg_mass` measures from the centre of mass,
which is what the quantity means. `rg` takes mdtraj's default of equal weights,
where the two centres are the same point and the two answers agree exactly.

The secondary structure is not one of the three, and is the reason the hydrogen
bonds are computed twice: `structure_dssp()` wants mdtraj's table, bonds across
chain breaks and all, because that is the table mdtraj's answer is defined on,
and `structure_hbonds()` reports the other one. Both are written up under
`structure_dssp` above.

# What is parsed in C, and why

The C side does one pass over the bytes. It splits ATOM/HETATM records into
their fields, marks where each residue begins and ends, sums what has to be
summed over every atom — the element tally, the bounding box, the B-factors,
each residue's centre — and groups every other record by record name for Perl
to take apart. Residue name lookup, three letters to one letter and the amino
acid/nucleotide/water question, is a switch on three packed bytes, and one
table serves `aa3to1()`, `res1()` and `res_type()` so the three can never
disagree.

When atoms are wanted the parse builds the atom hashes itself, rather than
handing back columns for Perl to rebuild them from; building every atom twice
cost more than everything else in the read put together. When they are not
wanted — `atoms => 0` — it builds none, and the Perl that follows walks
residues rather than atoms.

Everything else is Perl. The header records are irregular, they are a few
dozen lines per file rather than hundreds of thousands, and they are where the
next surprise will turn up; none of that is worth writing in C.

The mmCIF reader is a second pass written to the same division. A PDB file is
fixed columns and an mmCIF file is tag/value pairs and `loop_` tables, so none
of the column arithmetic carries over and the tokenizer — quoting, semicolon
text fields, comments, the two spellings of null — is its own code. What it is
not is a second answer: it fills in the same output, the same column arrays and
residue boundaries and counts, so everything downstream of it, in C and in
Perl, is written once. `_atom_site` goes through that path; every other
category is handed to Perl as tags and loops, which is the same place the line
between the two languages falls for PDB.

On 200 structures from PDBbind v2020, the parse runs at about 2.8 times the
speed of the same parse written in Perl. `structure_info()` as a whole comes
out close to a pure-Perl reader that gathers the same statistics, while also
reading the headers, SEQRES, the gaps, the chain types and the ligands; see
`benchmark.pl`, which measures all of it rather than asserting any of it.

# Author

David E. Condon <dec986@gmail.com>

# COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
