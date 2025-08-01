package Bio::MUST::Core::GeneticCode::Factory;
# ABSTRACT: Genetic code factory based on NCBI gc.prt file
$Bio::MUST::Core::GeneticCode::Factory::VERSION = '0.252040';
use Moose;
use namespace::autoclean;

# AUTOGENERATED CODE! DO NOT MODIFY THIS FILE!

use autodie;
use feature qw(say);

use Carp;
use Const::Fast;
use File::Spec;
use List::AllUtils qw(uniq);
use LWP::Simple qw(get);
use Path::Class qw(file);
use Try::Tiny;

use Bio::MUST::Core::Types;
use aliased 'Bio::MUST::Core::GeneticCode';


# public path to NCBI Taxonomy dump directory
has 'tax_dir' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Types::Dir',
    coerce   => 1,
);


# private hash hosting NCBI codes
has '_code_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Bio::MUST::Core::GeneticCode]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_code_for',
    handles  => {
             code_for => 'get',
        list_codes    => 'keys',
    },
);


## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_code_for {
    my $self = shift;

    # split file content into code blocks
    my @codes = $self->_get_gcprt_content =~ m/ \{ ( [^{}]+ ) \} /xmsgc;
    croak "[BMC] Error: cannot parse 'gc.prt' file; aborting!" unless @codes;

# Genetic-code-table ::= {
# ...
#  {
#     name "Mold Mitochondrial; Protozoan Mitochondrial; Coelenterate
#  Mitochondrial; Mycoplasma; Spiroplasma" ,
#   name "SGC3" ,
#   id 4 ,
#   ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
#   sncbieaa "--MM---------------M------------MMMM---------------M------------"
#   -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
#   -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
#   -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
#  },
#  ...
# }
    my %code_for;

    for my $code (@codes) {

        # get all names and id for current code
        my ($id)      = $code =~ m/   id    \s*   (\d+)   /xms;
        my @names     = $code =~ m/ name    \s* \"(.*?)\" /xmsg;
        @names = map {       s{\n}{}xmsgr } @names;     # remove newline chars
        @names = map { split m{;\s*}xms }   @names;     # demultiplex names

        # retrieve the amino acid line
        my ($aa_line) = $code =~ m/ ncbieaa \s* \"(.*?)\" /xms;
        $aa_line =~ s{\*}{x}xmsg;               # make STOPs MUST-compliant

        # retrieve the three codon lines
        my ($b1_line) = $code =~ m/ Base1   \s* ([TACG]+) /xms;
        my ($b2_line) = $code =~ m/ Base2   \s* ([TACG]+) /xms;
        my ($b3_line) = $code =~ m/ Base3   \s* ([TACG]+) /xms;

        # split lines into aas and bases
        my @aas    = split //, $aa_line;
        my @bases1 = split //, $b1_line;
        my @bases2 = split //, $b2_line;
        my @bases3 = split //, $b3_line;

        # build translation table for current code
        my %aa_for = map {
            join( q{}, $bases1[$_], $bases2[$_], $bases3[$_] ) => $aas[$_]
        } 0..$#aas;

        # augment code using ambiguous nucleotides and gap codons
        %aa_for = _augment_code(%aa_for);

        # store translation table under its various id and names
        $code_for{$_} = GeneticCode->new(
            ncbi_id => $id,
            _code   => \%aa_for
        ) for ($id, @names);
    }

    return \%code_for;
}

const my %BASES_FOR => (
    A => q{A},
    C => q{C},
    G => q{G},
    T => q{T},
    U => q{T},
    M => q{[AC]},
    R => q{[AG]},
    W => q{[AT]},
    S => q{[CG]},
    Y => q{[CT]},
    K => q{[GT]},
    V => q{[ACG]},
    H => q{[ACT]},
    D => q{[AGT]},
    B => q{[CGT]},
    N => q{[ACGT]},
    X => q{[ACGT]},
);

sub _augment_code {
    my %aa_for = @_;

    my %amb_aa_for;

    # Note: each cannot be used here because of the nested loops
    my @amb_bases = sort keys %BASES_FOR;
    for my $ab1 (@amb_bases) {
        for my $ab2 (@amb_bases) {

            BASE:
            for my $ab3 (@amb_bases) {

                # build regex for ambiguous codon
                my $codon = join q{},                        $ab1, $ab2, $ab3;
                next BASE if exists $aa_for{$codon};
                my $regex = join q{}, map { $BASES_FOR{$_} } $ab1, $ab2, $ab3;

                # fetch corresponding aas
                my @aas   = uniq map { $aa_for{$_}  }
                                grep { m/$regex/xms } keys %aa_for;

                # add ambiguous codon to code if all aas are the same
                $amb_aa_for{$codon} = shift @aas if @aas == 1;
            }
        }
    }

    # add gap 'codons' to code
    $amb_aa_for{'***'} = q{*};
    $amb_aa_for{'---'} = q{*};
    $amb_aa_for{'   '} = q{ };

    return (%aa_for, %amb_aa_for);
}

## use critic

# old version using a local or remote copy of NCBI gc.prt file
# sub _get_gcprt_content {
#     my $self = shift;
#
#     my $content;
#
#     # if available use local copy in NCBI Taxonomy dump
#     # otherwise try to fetch it from the NCBI FTP server
#     try   { $content = file($self->tax_dir, 'gc.prt')->slurp }
#     catch { $content = get('ftp://ftp.ncbi.nih.gov/entrez/misc/data/gc.prt') };
#
#     croak "Error: cannot read 'gc.prt' file; aborting!"
#         unless $content;
#
#     return $content;
# }

# new version based on templating
sub _get_gcprt_content {
    return <<'EOT';
--**************************************************************************
--  This is the NCBI genetic code table
--  Initial base data set from Andrzej Elzanowski while at PIR International
--  Addition of Eubacterial and Alternative Yeast by J.Ostell at NCBI
--  Base 1-3 of each codon have been added as comments to facilitate
--    readability at the suggestion of Peter Rice, EMBL
--  Later additions by Taxonomy Group staff at NCBI
--
--  Version 4.6
--     Renamed genetic code 24 to Rhabdopleuridae Mitochondrial
--
--  Version 4.5
--     Added Cephalodiscidae mitochondrial genetic code 33
--
--  Version 4.4
--     Added GTG as start codon for genetic code 3
--     Added Balanophoraceae plastid genetic code 32
--
--  Version 4.3
--     Change to CTG -> Leu in genetic codes 27, 28, 29, 30
--
--  Version 4.2
--     Added Karyorelict nuclear genetic code 27
--     Added Condylostoma nuclear genetic code 28
--     Added Mesodinium nuclear genetic code 29
--     Added Peritrich nuclear genetic code 30
--     Added Blastocrithidia nuclear genetic code 31
--
--  Version 4.1
--     Added Pachysolen tannophilus nuclear genetic code 26
--
--  Version 4.0
--     Updated version to reflect numerous undocumented changes:
--     Corrected start codons for genetic code 25
--     Name of new genetic code is Candidate Division SR1 and Gracilibacteria
--     Added candidate division SR1 nuclear genetic code 25
--     Added GTG as start codon for genetic code 24
--     Corrected Pterobranchia Mitochondrial genetic code (24)
--     Added genetic code 24, Pterobranchia Mitochondrial
--     Genetic code 11 is now Bacterial, Archaeal and Plant Plastid
--     Fixed capitalization of mitochondrial in codes 22 and 23
--     Added GTG, ATA, and TTG as alternative start codons to code 13
--
--  Version 3.9
--     Code 14 differs from code 9 only by translating UAA to Tyr rather than
--     STOP.  A recent study (Telford et al, 2000) has found no evidence that
--     the codon UAA codes for Tyr in the flatworms, but other opinions exist.
--     There are very few GenBank records that are translated with code 14,
--     but a test translation shows that retranslating these records with code
--     9 can cause premature terminations.  Therefore, GenBank will maintain
--     code 14 until further information becomes available.
--
--  Version 3.8
--     Added GTG start to Echinoderm mitochondrial code, code 9
--
--  Version 3.7
--     Added code 23 Thraustochytrium mitochondrial code
--        formerly OGMP code 93
--        submitted by Gertraude Berger, Ph.D.
--
--  Version 3.6
--     Added code 22 TAG-Leu, TCA-stop
--        found in mitochondrial DNA of Scenedesmus obliquus
--        submitted by Gertraude Berger, Ph.D.
--        Organelle Genome Megasequencing Program, Univ Montreal
--
--  Version 3.5
--     Added code 21, Trematode Mitochondrial
--       (as deduced from: Garey & Wolstenholme,1989; Ohama et al, 1990)
--     Added code 16, Chlorophycean Mitochondrial
--       (TAG can translated to Leucine instaed to STOP in chlorophyceans
--        and fungi)
--
--  Version 3.4
--     Added CTG,TTG as allowed alternate start codons in Standard code.
--        Prats et al. 1989, Hann et al. 1992
--
--  Version 3.3 - 10/13/95
--     Added alternate intiation codon ATC to code 5
--        based on complete mitochondrial genome of honeybee
--        Crozier and Crozier (1993)
--
--  Version 3.2 - 6/24/95
--  Code       Comments
--   10        Alternative Ciliate Macronuclear renamed to Euplotid Macro...
--   15        Blepharisma Macro.. code added
--    5        Invertebrate Mito.. GTG allowed as alternate initiator
--   11        Eubacterial renamed to Bacterial as most alternate starts
--               have been found in Archea
--
--
--  Version 3.1 - 1995
--  Updated as per Andrzej Elzanowski at NCBI
--     Complete documentation in NCBI toolkit documentation
--  Note: 2 genetic codes have been deleted
--
--   Old id   Use id     - Notes
--
--   id 7      id 4      - Kinetoplast code now merged in code id 4
--   id 8      id 1      - all plant chloroplast differences due to RNA edit
--
--
--*************************************************************************

Genetic-code-table ::= {
 {
  name "Standard" ,
  name "SGC0" ,
  id 1 ,
  ncbieaa  "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "---M------**--*----M---------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Vertebrate Mitochondrial" ,
  name "SGC1" ,
  id 2 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSS**VVVVAAAADDEEGGGG",
  sncbieaa "----------**--------------------MMMM----------**---M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Yeast Mitochondrial" ,
  name "SGC2" ,
  id 3 ,
  ncbieaa  "FFLLSSSSYY**CCWWTTTTPPPPHHQQRRRRIIMMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "----------**----------------------MM---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
    name "Mold Mitochondrial; Protozoan Mitochondrial; Coelenterate
 Mitochondrial; Mycoplasma; Spiroplasma" ,
  name "SGC3" ,
  id 4 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "--MM------**-------M------------MMMM---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Invertebrate Mitochondrial" ,
  name "SGC4" ,
  id 5 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSSSVVVVAAAADDEEGGGG",
  sncbieaa "---M------**--------------------MMMM---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Ciliate Nuclear; Dasycladacean Nuclear; Hexamita Nuclear" ,
  name "SGC5" ,
  id 6 ,
  ncbieaa  "FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "--------------*--------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Echinoderm Mitochondrial; Flatworm Mitochondrial" ,
  name "SGC8" ,
  id 9 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG",
  sncbieaa "----------**-----------------------M---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Euplotid Nuclear" ,
  name "SGC9" ,
  id 10 ,
  ncbieaa  "FFLLSSSSYY**CCCWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "----------**-----------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Bacterial, Archaeal and Plant Plastid" ,
  id 11 ,
  ncbieaa  "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "---M------**--*----M------------MMMM---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Alternative Yeast Nuclear" ,
  id 12 ,
  ncbieaa  "FFLLSSSSYY**CC*WLLLSPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "----------**--*----M---------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Ascidian Mitochondrial" ,
  id 13 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSGGVVVVAAAADDEEGGGG",
  sncbieaa "---M------**----------------------MM---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Alternative Flatworm Mitochondrial" ,
  id 14 ,
  ncbieaa  "FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG",
  sncbieaa "-----------*-----------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Blepharisma Macronuclear" ,
  id 15 ,
  ncbieaa  "FFLLSSSSYY*QCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "----------*---*--------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Chlorophycean Mitochondrial" ,
  id 16 ,
  ncbieaa  "FFLLSSSSYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "----------*---*--------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Trematode Mitochondrial" ,
  id 21 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNNKSSSSVVVVAAAADDEEGGGG",
  sncbieaa "----------**-----------------------M---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Scenedesmus obliquus Mitochondrial" ,
  id 22 ,
  ncbieaa  "FFLLSS*SYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "------*---*---*--------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Thraustochytrium Mitochondrial" ,
  id 23 ,
  ncbieaa  "FF*LSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "--*-------**--*-----------------M--M---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Rhabdopleuridae Mitochondrial" ,
  id 24 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSSKVVVVAAAADDEEGGGG",
  sncbieaa "---M------**-------M---------------M---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Candidate Division SR1 and Gracilibacteria" ,
  id 25 ,
  ncbieaa  "FFLLSSSSYY**CCGWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "---M------**-----------------------M---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Pachysolen tannophilus Nuclear" ,
  id 26 ,
  ncbieaa  "FFLLSSSSYY**CC*WLLLAPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "----------**--*----M---------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Karyorelict Nuclear" ,
  id 27 ,
  ncbieaa  "FFLLSSSSYYQQCCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "--------------*--------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Condylostoma Nuclear" ,
  id 28 ,
  ncbieaa  "FFLLSSSSYYQQCCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "----------**--*--------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Mesodinium Nuclear" ,
  id 29 ,
  ncbieaa  "FFLLSSSSYYYYCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "--------------*--------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Peritrich Nuclear" ,
  id 30 ,
  ncbieaa  "FFLLSSSSYYEECC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "--------------*--------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Blastocrithidia Nuclear" ,
  id 31 ,
  ncbieaa  "FFLLSSSSYYEECCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "----------**-----------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Balanophoraceae Plastid" ,
  id 32 ,
  ncbieaa  "FFLLSSSSYY*WCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "---M------*---*----M------------MMMM---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Cephalodiscidae Mitochondrial" ,
  id 33 ,
  ncbieaa  "FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSSKVVVVAAAADDEEGGGG",
  sncbieaa "---M-------*-------M---------------M---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 }
}

EOT
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::GeneticCode::Factory - Genetic code factory based on NCBI gc.prt file

=head1 VERSION

version 0.252040

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
