use Config;
$file = @ARGV ? shift : 'examples/elf.pl';
open OUT, ">$file" or die "Can't create $file: $!";
print OUT <<"!GROK!THIS!";
$Config{startperl} -w
!GROK!THIS!
print OUT <<'!NO!SUBS!';
################################################################################
#
# Copyright (c) 2005-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Convert::Binary::C;
use Data::Dumper;
use Getopt::Long;
use strict;

#-------------------------------------------------
# Constants for accessing ELF identification data
#-------------------------------------------------
use constant EI_CLASS => 4;
use constant EI_DATA  => 5;

my %opt;
Getopt::Long::Configure('bundling');
unless (GetOptions(\%opt, qw( list|l info|i debug section|s=s symbols ))) {
  eval q{
    require Pod::Usage;
    Pod::Usage::pod2usage(2);
  };
  print "Cannot show help, please consider installing Pod::Usage.\n";
  exit;
}

unless (@ARGV) {
  print "No input file (try '$0 -h' for usage).\n";
  exit;
}

#---------------------------------------------------
# Compiler Configuration (generated using ccconfig)
#---------------------------------------------------
my %config = (
  Alignment         => 4,
  CharSize          => 1,
  CompoundAlignment => 1,
  IntSize           => 4,
  LongLongSize      => 8,
  LongSize          => 4,
  ShortSize         => 2,
  UnsignedChars     => 0
);

#-----------
# ELF Types
#-----------
my @elftype = qw( ET_NONE ET_REL ET_EXEC ET_DYN ET_CORE );

#-------------------
# ELF Section Types
#-------------------
my @sectype = qw(
  SHT_NULL SHT_PROGBITS SHT_SYMTAB SHT_STRTAB SHT_RELA SHT_HASH
  SHT_DYNAMIC SHT_NOTE SHT_NOBITS SHT_REL SHT_SHLIB SHT_DYNSYM
);

#-------------------
# ELF Segment Types
#-------------------
my @segtype = qw(
  PT_NULL PT_LOAD PT_DYNAMIC PT_INTERP PT_NOTE PT_SHLIB PT_PHDR
);

#-------------------
# ELF Machine Types
#-------------------
my %machine = (
   0 => 'EM_NONE (No machine)',
   1 => 'EM_M32 (AT&T WE 32100)',
   2 => 'EM_SPARC (SUN SPARC)',
   3 => 'EM_386 (Intel 80386)',
   4 => 'EM_68K (Motorola m68k family)',
   5 => 'EM_88K (Motorola m88k family)',
   7 => 'EM_860 (Intel 80860)',
   8 => 'EM_MIPS (MIPS R3000 big-endian)',
   9 => 'EM_S370 (IBM System/370)',
  10 => 'EM_MIPS_RS3_LE (MIPS R3000 little-endian)',
  15 => 'EM_PARISC (HPPA)',
  17 => 'EM_VPP500 (Fujitsu VPP500)',
  18 => 'EM_SPARC32PLUS (Sun\'s "v8plus")',
  19 => 'EM_960 (Intel 80960)',
  20 => 'EM_PPC (PowerPC)',
  21 => 'EM_PPC64 (PowerPC 64-bit)',
  22 => 'EM_S390 (IBM S390)',
  36 => 'EM_V800 (NEC V800 series)',
  37 => 'EM_FR20 (Fujitsu FR20)',
  38 => 'EM_RH32 (TRW RH-32)',
  39 => 'EM_RCE (Motorola RCE)',
  40 => 'EM_ARM (ARM)',
  41 => 'EM_FAKE_ALPHA (Digital Alpha)',
  42 => 'EM_SH (Hitachi SH)',
  43 => 'EM_SPARCV9 (SPARC v9 64-bit)',
  44 => 'EM_TRICORE (Siemens Tricore)',
  45 => 'EM_ARC (Argonaut RISC Core)',
  46 => 'EM_H8_300 (Hitachi H8/300)',
  47 => 'EM_H8_300H (Hitachi H8/300H)',
  48 => 'EM_H8S (Hitachi H8S)',
  49 => 'EM_H8_500 (Hitachi H8/500)',
  50 => 'EM_IA_64 (Intel Merced)',
  51 => 'EM_MIPS_X (Stanford MIPS-X)',
  52 => 'EM_COLDFIRE (Motorola Coldfire)',
  53 => 'EM_68HC12 (Motorola M68HC12)',
  54 => 'EM_MMA (Fujitsu MMA Multimedia Accelerator)',
  55 => 'EM_PCP (Siemens PCP)',
  56 => 'EM_NCPU (Sony nCPU embeeded RISC)',
  57 => 'EM_NDR1 (Denso NDR1 microprocessor)',
  58 => 'EM_STARCORE (Motorola Start*Core processor)',
  59 => 'EM_ME16 (Toyota ME16 processor)',
  60 => 'EM_ST100 (STMicroelectronic ST100 processor)',
  61 => 'EM_TINYJ (Advanced Logic Corp. Tinyj emb.fam)',
  62 => 'EM_X86_64 (AMD x86-64 architecture)',
  63 => 'EM_PDSP (Sony DSP Processor)',
  66 => 'EM_FX66 (Siemens FX66 microcontroller)',
  67 => 'EM_ST9PLUS (STMicroelectronics ST9+ 8/16 mc)',
  68 => 'EM_ST7 (STmicroelectronics ST7 8 bit mc)',
  69 => 'EM_68HC16 (Motorola MC68HC16 microcontroller)',
  70 => 'EM_68HC11 (Motorola MC68HC11 microcontroller)',
  71 => 'EM_68HC08 (Motorola MC68HC08 microcontroller)',
  72 => 'EM_68HC05 (Motorola MC68HC05 microcontroller)',
  73 => 'EM_SVX (Silicon Graphics SVx)',
  74 => 'EM_ST19 (STMicroelectronics ST19 8 bit mc)',
  75 => 'EM_VAX (Digital VAX)',
  76 => 'EM_CRIS (Axis Communications 32-bit embedded processor)',
  77 => 'EM_JAVELIN (Infineon Technologies 32-bit embedded processor)',
  78 => 'EM_FIREPATH (Element 14 64-bit DSP Processor)',
  79 => 'EM_ZSP (LSI Logic 16-bit DSP Processor)',
  80 => 'EM_MMIX (Donald Knuth\'s educational 64-bit processor)',
  81 => 'EM_HUANY (Harvard University machine-independent object files)',
  82 => 'EM_PRISM (SiTera Prism)',
  83 => 'EM_AVR (Atmel AVR 8-bit microcontroller)',
  84 => 'EM_FR30 (Fujitsu FR30)',
  85 => 'EM_D10V (Mitsubishi D10V)',
  86 => 'EM_D30V (Mitsubishi D30V)',
  87 => 'EM_V850 (NEC v850)',
  88 => 'EM_M32R (Mitsubishi M32R)',
  89 => 'EM_MN10300 (Matsushita MN10300)',
  90 => 'EM_MN10200 (Matsushita MN10200)',
  91 => 'EM_PJ (picoJava)',
  92 => 'EM_OPENRISC (OpenRISC 32-bit embedded processor)',
  93 => 'EM_ARC_A5 (ARC Cores Tangent-A5)',
  94 => 'EM_XTENSA (Tensilica Xtensa Architecture)',
);

#-----------------------------
# ELF Symbol Binding and Type
#-----------------------------
my %symbind = (
   0 => 'STB_LOCAL',
   1 => 'STB_GLOBAL',
   2 => 'STB_WEAK',
   3 => 'STB_NUM',
  10 => 'STB_LOOS',
  12 => 'STB_HIOS',
  13 => 'STB_LOPROC',
  15 => 'STB_HIPROC',
);

my %symtype = (
   0 => 'STT_NOTYPE',
   1 => 'STT_OBJECT',
   2 => 'STT_FUNC',
   3 => 'STT_SECTION',
   4 => 'STT_FILE',
   5 => 'STT_COMMON',
   6 => 'STT_TLS',
   7 => 'STT_NUM',
  10 => 'STT_LOOS',
  12 => 'STT_HIOS',
  13 => 'STT_LOPROC',
  15 => 'STT_HIPROC',
);

#--------------------------------------------------------
# Create a C::B::C object to convert ELF data structures
#--------------------------------------------------------
my $ep = Convert::Binary::C->new(%config)->parse(elf_header());

#-------------------------------------------
# Attach hooks to certain interesting types
#-------------------------------------------
my %hook = (
  'Ehdr.e_machine' => \%machine,
  'Ehdr.e_type'    => \@elftype,
  'Shdr.sh_type'   => \@sectype,
  'Phdr.p_type'    => \@segtype,
);

for my $c (qw( Elf32 Elf64 )) {
  while (my($k,$v) = each %hook) {
    $ep->tag("$c\_$k", Hooks => { unpack => sub {
      my $x = shift; (ref $v eq 'HASH' ? $v->{$x} : $v->[$x]) || "Unknown ($x)"
    }});
  }

  $ep->tag("$c\_Sym.st_info", Hooks => { unpack => sub {
    my $x = shift;
    my $b = $x >> 4;
    my $t = $x & 0xf;
    {
      sti_bind => $symbind{$b} || "Unknown ($b)",
      sti_type => $symtype{$t} || "Unknown ($t)",
    }
  }});
}

#---------------------------------------
# Read the whole ELF file (inefficient)
#---------------------------------------
my $elf = do { local($/, *FH);
               open FH, $ARGV[0] or die "$ARGV[0]: $!\n";
               binmode FH;
               <FH>;
             };

#---------------------------------
# Process ELF identification data
#---------------------------------
my @ident = unpack "C16", substr $elf, 0, 16;

#-----------------------------
# Is this really an ELF file?
#-----------------------------
unless ($ident[0] == 0x7F && pack("C*", @ident[1..3]) eq 'ELF')
  { die "not an ELF file\n" }

#-----------------------------
# Check ELF class (32/64-Bit)
#-----------------------------
if ($ident[EI_CLASS] == 0) { die "invalid ELF class ($ident[EI_CLASS])\n" }
if ($ident[EI_CLASS] > 2) { die "unsupported ELF class ($ident[EI_CLASS])\n" }
my $class = $ident[EI_CLASS] == 1 ? 'Elf32' : 'Elf64';

#-------------------------------------------
# Check Byte Order (BigEndian/LittleEndian)
#-------------------------------------------
if ($ident[EI_DATA] == 0) { die "invalid data encoding ($ident[EI_DATA])\n" }
if ($ident[EI_DATA] > 2) { die "unsupported data encoding ($ident[EI_DATA])\n" }
$ep->ByteOrder($ident[EI_DATA] == 1 ? 'LittleEndian' : 'BigEndian');

sub get
{
  my($type, $off, $len) = @_;
  $ep->unpack("$class\_$type", @_ > 2 ? substr $elf, $off, $len
                                      : substr $elf, $off);
}

#---------------------------------------------------
# Unpack ELF header and section header string table
#---------------------------------------------------
my $header = get('Ehdr', 0);
my $shstrtab = get('Shdr', $header->{e_shoff} +
                           $header->{e_shstrndx}*$header->{e_shentsize});

print Data::Dumper->Dump([$header], ["*$class\_Ehdr"]) if $opt{debug};

#----------------------------
# Get Name from String Table
#----------------------------
sub get_name
{
  my($tab, $off) = @_;
  return unpack "Z*", substr $elf, $tab->{sh_offset} + $off;
}

#--------------------------
# Read all program headers
#--------------------------
for my $ix (0 .. $header->{e_phnum}-1) {
  my $phdr = get('Phdr', $header->{e_phoff} + $ix*$header->{e_phentsize});
  print Data::Dumper->Dump([$phdr], ["*$class\_Phdr"]) if $opt{debug};
}

#--------------------------
# Read all section headers
#--------------------------
my %section;  # for lookup by section name
my @section;  # for lookup by section index

for my $ix (0 .. $header->{e_shnum}-1) {
  my $shdr = get('Shdr', $header->{e_shoff} + $ix*$header->{e_shentsize});
  print Data::Dumper->Dump([$shdr], ["*$class\_Shdr"]) if $opt{debug};
  $section{get_name($shstrtab, $shdr->{sh_name})} = $shdr;
  push @section, $shdr;
}

#-----------------------------------
# Get Section Name by Section Index
#-----------------------------------
sub get_section_name
{
  my $sec = shift;
  if ($sec == 0 || $sec >= 0xff00) {
    my %res = (0 => 'SHN_UNDEF', 0xfff1 => 'SHN_ABS', 0xfff2 => 'SHN_COMMON');
    return $res{$sec} || sprintf "reserved section 0x%04X", $sec;
  }
  return $sec < @section ? get_name($shstrtab, $section[$sec]{sh_name})
                         : "invalid section $sec";
}

#--------------------------
# Print Header Information
#--------------------------
if ($opt{info}) {
  printf "Byte Order: %s\n", $ep->ByteOrder;
  printf "ELF Class : %s\n", $class;
  printf "ELF Type  : %s\n", $header->{e_type};
  printf "Machine   : %s\n", $header->{e_machine};
}

#------------------------
# Print List Of Sections
#------------------------
if ($opt{list}) {
  printf "%-3s  %-38s  %-13s  %-9s  %-9s\n%s\n",
         'Idx', 'Section', 'Type', 'Offset', 'Size', '-'x80;
  for my $ix (0 .. $#section) {
    my $sh = $section[$ix];
    printf "%3d  %-38s  %-13s  %9d  %9d\n",
            $ix,
                 get_name($shstrtab, $sh->{sh_name}),
                        $sh->{sh_type},
                               $sh->{sh_offset},
                                    $sh->{sh_size};
  }
}

#--------------------
# Print Symbol Table
#--------------------
if ($opt{symbols}) {
  my $symtab = $section{'.symtab'} or die "got no symbol table\n";
  my $strtab = $section{'.strtab'} or die "got no symbol string table\n";

  my @sym = get('Sym', $symtab->{sh_offset}, $symtab->{sh_size});

  printf "%-6s  %-30s  %-9s  %-9s  %-11s  %-11s  %-30s\n%s\n",
         'Index', 'Symbol', 'Value', 'Size', 'Bind', 'Type', 'Section', '-'x120;

  for my $ix (0 .. $#sym) {
    my $s = $sym[$ix];

    print Data::Dumper->Dump([$s], ['*sym']) if $opt{debug};

    printf "%6d  %-30s  %9d  %9d  %-11s  %-11s  %-30s\n",
            $ix,
                 get_name($strtab, $s->{st_name}),
                        $s->{st_value},
                             $s->{st_size},
                                  $s->{st_info}{sti_bind},
                                         $s->{st_info}{sti_type},
                                                get_section_name($s->{st_shndx});
  }
}

#-------------------------
# Write Section to stdout
#-------------------------
if ($opt{section}) {
  my $sec = $opt{section} =~ /^\d+$/ ? $section[$opt{section}]
                                     : $section{$opt{section}};

  die "no such section ($opt{section})\n" unless defined $sec;

  binmode STDOUT;

  print substr $elf, $sec->{sh_offset}, $sec->{sh_size};
}

exit;

###############################################################################
#
# This routine contains the ELF data structures and was generated using:
#
#   perl -MConvert::Binary::C -e'print Convert::Binary::C->new(%{require \
#                 "devel/gcc-config.pl"})->parse_file("elf.h")->sourcify'
#
###############################################################################

sub elf_header
{
  return <<'ENDC';
/* typedef predeclarations */

typedef signed char int8_t;
typedef short int int16_t;
typedef int int32_t;
typedef long long int int64_t;
typedef unsigned char uint8_t;
typedef unsigned short int uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long int uint64_t;
typedef signed char int_least8_t;
typedef short int int_least16_t;
typedef int int_least32_t;
typedef long long int int_least64_t;
typedef unsigned char uint_least8_t;
typedef unsigned short int uint_least16_t;
typedef unsigned int uint_least32_t;
typedef unsigned long long int uint_least64_t;
typedef signed char int_fast8_t;
typedef int int_fast16_t;
typedef int int_fast32_t;
typedef long long int int_fast64_t;
typedef unsigned char uint_fast8_t;
typedef unsigned int uint_fast16_t;
typedef unsigned int uint_fast32_t;
typedef unsigned long long int uint_fast64_t;
typedef int intptr_t;
typedef unsigned int uintptr_t;
typedef long long int intmax_t;
typedef unsigned long long int uintmax_t;


/* typedefs */

typedef uint16_t Elf32_Half;

typedef uint16_t Elf64_Half;

typedef uint32_t Elf32_Word;

typedef int32_t Elf32_Sword;

typedef uint32_t Elf64_Word;

typedef int32_t Elf64_Sword;

typedef uint64_t Elf32_Xword;

typedef int64_t Elf32_Sxword;

typedef uint64_t Elf64_Xword;

typedef int64_t Elf64_Sxword;

typedef uint32_t Elf32_Addr;

typedef uint64_t Elf64_Addr;

typedef uint32_t Elf32_Off;

typedef uint64_t Elf64_Off;

typedef uint16_t Elf32_Section;

typedef uint16_t Elf64_Section;

typedef Elf32_Half Elf32_Versym;

typedef Elf64_Half Elf64_Versym;

typedef struct
{
	unsigned char e_ident[16];
	Elf32_Half e_type;
	Elf32_Half e_machine;
	Elf32_Word e_version;
	Elf32_Addr e_entry;
	Elf32_Off e_phoff;
	Elf32_Off e_shoff;
	Elf32_Word e_flags;
	Elf32_Half e_ehsize;
	Elf32_Half e_phentsize;
	Elf32_Half e_phnum;
	Elf32_Half e_shentsize;
	Elf32_Half e_shnum;
	Elf32_Half e_shstrndx;
} Elf32_Ehdr;

typedef struct
{
	unsigned char e_ident[16];
	Elf64_Half e_type;
	Elf64_Half e_machine;
	Elf64_Word e_version;
	Elf64_Addr e_entry;
	Elf64_Off e_phoff;
	Elf64_Off e_shoff;
	Elf64_Word e_flags;
	Elf64_Half e_ehsize;
	Elf64_Half e_phentsize;
	Elf64_Half e_phnum;
	Elf64_Half e_shentsize;
	Elf64_Half e_shnum;
	Elf64_Half e_shstrndx;
} Elf64_Ehdr;

typedef struct
{
	Elf32_Word sh_name;
	Elf32_Word sh_type;
	Elf32_Word sh_flags;
	Elf32_Addr sh_addr;
	Elf32_Off sh_offset;
	Elf32_Word sh_size;
	Elf32_Word sh_link;
	Elf32_Word sh_info;
	Elf32_Word sh_addralign;
	Elf32_Word sh_entsize;
} Elf32_Shdr;

typedef struct
{
	Elf64_Word sh_name;
	Elf64_Word sh_type;
	Elf64_Xword sh_flags;
	Elf64_Addr sh_addr;
	Elf64_Off sh_offset;
	Elf64_Xword sh_size;
	Elf64_Word sh_link;
	Elf64_Word sh_info;
	Elf64_Xword sh_addralign;
	Elf64_Xword sh_entsize;
} Elf64_Shdr;

typedef struct
{
	Elf32_Word st_name;
	Elf32_Addr st_value;
	Elf32_Word st_size;
	unsigned char st_info;
	unsigned char st_other;
	Elf32_Section st_shndx;
} Elf32_Sym;

typedef struct
{
	Elf64_Word st_name;
	unsigned char st_info;
	unsigned char st_other;
	Elf64_Section st_shndx;
	Elf64_Addr st_value;
	Elf64_Xword st_size;
} Elf64_Sym;

typedef struct
{
	Elf32_Half si_boundto;
	Elf32_Half si_flags;
} Elf32_Syminfo;

typedef struct
{
	Elf64_Half si_boundto;
	Elf64_Half si_flags;
} Elf64_Syminfo;

typedef struct
{
	Elf32_Addr r_offset;
	Elf32_Word r_info;
} Elf32_Rel;

typedef struct
{
	Elf64_Addr r_offset;
	Elf64_Xword r_info;
} Elf64_Rel;

typedef struct
{
	Elf32_Addr r_offset;
	Elf32_Word r_info;
	Elf32_Sword r_addend;
} Elf32_Rela;

typedef struct
{
	Elf64_Addr r_offset;
	Elf64_Xword r_info;
	Elf64_Sxword r_addend;
} Elf64_Rela;

typedef struct
{
	Elf32_Word p_type;
	Elf32_Off p_offset;
	Elf32_Addr p_vaddr;
	Elf32_Addr p_paddr;
	Elf32_Word p_filesz;
	Elf32_Word p_memsz;
	Elf32_Word p_flags;
	Elf32_Word p_align;
} Elf32_Phdr;

typedef struct
{
	Elf64_Word p_type;
	Elf64_Word p_flags;
	Elf64_Off p_offset;
	Elf64_Addr p_vaddr;
	Elf64_Addr p_paddr;
	Elf64_Xword p_filesz;
	Elf64_Xword p_memsz;
	Elf64_Xword p_align;
} Elf64_Phdr;

typedef struct
{
	Elf32_Sword d_tag;
	union
	{
		Elf32_Word d_val;
		Elf32_Addr d_ptr;
	} d_un;
} Elf32_Dyn;

typedef struct
{
	Elf64_Sxword d_tag;
	union
	{
		Elf64_Xword d_val;
		Elf64_Addr d_ptr;
	} d_un;
} Elf64_Dyn;

typedef struct
{
	Elf32_Half vd_version;
	Elf32_Half vd_flags;
	Elf32_Half vd_ndx;
	Elf32_Half vd_cnt;
	Elf32_Word vd_hash;
	Elf32_Word vd_aux;
	Elf32_Word vd_next;
} Elf32_Verdef;

typedef struct
{
	Elf64_Half vd_version;
	Elf64_Half vd_flags;
	Elf64_Half vd_ndx;
	Elf64_Half vd_cnt;
	Elf64_Word vd_hash;
	Elf64_Word vd_aux;
	Elf64_Word vd_next;
} Elf64_Verdef;

typedef struct
{
	Elf32_Word vda_name;
	Elf32_Word vda_next;
} Elf32_Verdaux;

typedef struct
{
	Elf64_Word vda_name;
	Elf64_Word vda_next;
} Elf64_Verdaux;

typedef struct
{
	Elf32_Half vn_version;
	Elf32_Half vn_cnt;
	Elf32_Word vn_file;
	Elf32_Word vn_aux;
	Elf32_Word vn_next;
} Elf32_Verneed;

typedef struct
{
	Elf64_Half vn_version;
	Elf64_Half vn_cnt;
	Elf64_Word vn_file;
	Elf64_Word vn_aux;
	Elf64_Word vn_next;
} Elf64_Verneed;

typedef struct
{
	Elf32_Word vna_hash;
	Elf32_Half vna_flags;
	Elf32_Half vna_other;
	Elf32_Word vna_name;
	Elf32_Word vna_next;
} Elf32_Vernaux;

typedef struct
{
	Elf64_Word vna_hash;
	Elf64_Half vna_flags;
	Elf64_Half vna_other;
	Elf64_Word vna_name;
	Elf64_Word vna_next;
} Elf64_Vernaux;

typedef struct
{
	int a_type;
	union
	{
		long int a_val;
		void *a_ptr;
		void *a_fcn;
	} a_un;
} Elf32_auxv_t;

typedef struct
{
	long int a_type;
	union
	{
		long int a_val;
		void *a_ptr;
		void *a_fcn;
	} a_un;
} Elf64_auxv_t;

typedef struct
{
	Elf32_Word n_namesz;
	Elf32_Word n_descsz;
	Elf32_Word n_type;
} Elf32_Nhdr;

typedef struct
{
	Elf64_Word n_namesz;
	Elf64_Word n_descsz;
	Elf64_Word n_type;
} Elf64_Nhdr;

typedef struct
{
	Elf32_Xword m_value;
	Elf32_Word m_info;
	Elf32_Word m_poffset;
	Elf32_Half m_repeat;
	Elf32_Half m_stride;
} Elf32_Move;

typedef struct
{
	Elf64_Xword m_value;
	Elf64_Xword m_info;
	Elf64_Xword m_poffset;
	Elf64_Half m_repeat;
	Elf64_Half m_stride;
} Elf64_Move;

typedef union
{
	struct
	{
		Elf32_Word gt_current_g_value;
		Elf32_Word gt_unused;
	} gt_header;
	struct
	{
		Elf32_Word gt_g_value;
		Elf32_Word gt_bytes;
	} gt_entry;
} Elf32_gptab;

typedef struct
{
	Elf32_Word ri_gprmask;
	Elf32_Word ri_cprmask[4];
	Elf32_Sword ri_gp_value;
} Elf32_RegInfo;

typedef struct
{
	unsigned char kind;
	unsigned char size;
	Elf32_Section section;
	Elf32_Word info;
} Elf_Options;

typedef struct
{
	Elf32_Word hwp_flags1;
	Elf32_Word hwp_flags2;
} Elf_Options_Hw;

typedef struct
{
	Elf32_Word l_name;
	Elf32_Word l_time_stamp;
	Elf32_Word l_checksum;
	Elf32_Word l_version;
	Elf32_Word l_flags;
} Elf32_Lib;

typedef struct
{
	Elf64_Word l_name;
	Elf64_Word l_time_stamp;
	Elf64_Word l_checksum;
	Elf64_Word l_version;
	Elf64_Word l_flags;
} Elf64_Lib;

typedef Elf32_Addr Elf32_Conflict;
ENDC
}

__END__

=head1 NAME

elf.pl - Read ELF Files

=head1 SYNOPSIS

elf.pl {I<options>} elf-file

I<options>:

  -i  --info           print information
  -l  --list           print section list
      --symbols        print symbol table
  -s  --section NAME   write section to stdout
      --debug          enable debug output

example:

  elf.pl -il C.o

=cut
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";

