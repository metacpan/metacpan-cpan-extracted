m4_dnl -*- perl -*-
m4_dnl
m4_dnl Run this file through "m4 -P" to create the Perl module "DES_PP.pm"!
m4_dnl 
m4_dnl When implementing cryptographic algorithms you really have the 
m4_dnl choice between readability and poor performance.  One major 
m4_dnl caveat that imposes a considerable performance penalty is the
m4_dnl lack of inline functions (resp. preprocessor macros) in Perl.
m4_dnl
m4_dnl To circumevent these difficulties, earlier versions of this
m4_dnl file contained C preprocessor directives but that approach was
m4_dnl discarded for several reasons: 
m4_dnl 
m4_dnl o The code after the macro expansion is mostly illegible which
m4_dnl   is undesirable when only the expanded code gets installed.
m4_dnl
m4_dnl o Every here and then spurious errors occur because Perl comments
m4_dnl   are mistakenly interpreted as preprocessor directives.
m4_dnl
m4_dnl o There is neither a standard name nor a standard invocation for
m4_dnl   the C preprocessor.  This problem could be partly solved by
m4_dnl   including Config.pm in Makefile.PL and inquiring the invocation 
m4_dnl   syntax from "$Config{cpprun}".  Unfortunately, many people
m4_dnl   have not compiled the Perl interpreter on their own but
m4_dnl   have installed a pre-comupiled binary instead.  Under these
m4_dnl   circumstances the variable "$Config{cpprun}" can only inform
m4_dnl   about the preprocessor invocation on your vendor's build
m4_dnl   machine that was valid at the time that the Perl interpreter
m4_dnl   was compiled.         ' Dear St. Emacs, will you ever learn?
m4_dnl   
m4_dnl Using m4 instead of the C preprocessor looks much more attractive.
m4_dnl None of the above disadvantages apply.  M4 leaves you infinite
m4_dnl control on the output (it is for example not possible to create
m4_dnl a file with a hash bang in the very first line without the help
m4_dnl of extra tools with the preprocessor).  M4 has been designed 
m4_dnl exactly for purposes like this, thus making it relatively 
m4_dnl straightforward to  avoid conflicts between m4 code interpretation 
m4_dnl and Perl code interpretation.  Finally the m4 syntax is pretty much
m4_dnl standardized compared to the numerous pitfalls that C preprocessor
m4_dnl syntax provides (think of string concatenation, spaces between
m4_dnl the hash sign and the directive, ...).  In brief, m4 is better
m4_dnl for preprocessing Perl code just for the same reasons that GNU
m4_dnl autoconf is better than X11 imake. ;-)
m4_dnl
m4_dnl One additional advantage of m4 over the C preprocessor is the
m4_dnl ability to unroll loops (although it turned out that Perl
m4_dnl itself is much smarter about loops than you would think).
m4_dnl
m4_dnl As you might have quessed already, this m4 source file has to
m4_dnl be called with the command line option ``-P'' in order to
m4_dnl to work.
m4_dnl
m4_dnl Enough of m4/cpp advocacy, here we go:
m4_dnl
m4_dnl Change the quoting character to prevent unintended quoting. 
m4_changequote(`[m4[', `]m4]')m4_dnl Make emacs happy '
m4_dnl
# -*- perl -*-
# DES_PP.pm - Pure perl implementation of DES.
#
# The master file for the module is DES_PP.m4 which needs to be run through
# the m4.  Please edit DES_PP.m4 if you need to modify!

package Crypt::DES_PP;

use strict;
use Carp;
use integer;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw (Exporter);
@EXPORT = qw ();
@EXPORT_OK = qw ();
$VERSION = '1.00';

use constant BLKSIZE => 8;

# Stolen from Crypt::DES.
sub usage {
    my ($package, $filename, $line, $subr) = caller (1);
    $Carp::CarpLevel = 2;
    croak "Usage: $subr (@_)";
}

sub blocksize () { BLKSIZE };
sub keysize () { BLKSIZE };

sub expand_key ($);
sub crypt ($$$);

sub new {
    usage ("new Crypt::DES_PP key") 
	unless @_ == 2;
    my ($package, $key) = @_;
    
    bless { ks => Crypt::DES_PP::expand_key ($key) }, $package;
}

sub encrypt {
    usage ("encrypt data[8 bytes]") unless @_ == 2;
    
    my ($self,$data) = @_;
    return Crypt::DES_PP::crypt ($data, $self->{ks}, 1);
}

sub decrypt {
    usage("decrypt data[8 bytes]") unless @_ == 2;
    
    my ($self,$data) = @_;
    return Crypt::DES_PP::crypt ($data, $self->{ks}, 0);
}

use constant ITERATIONS => 16;

# These used to be a single reference to an array of array references.
# Splitting them up into distinct constants slightly improves performance.
use constant des_SPtrans_0 =>
    [ # Nibble 0
      0x00820200, 0x00020000, 0x80800000, 0x80820200,
      0x00800000, 0x80020200, 0x80020000, 0x80800000,
      0x80020200, 0x00820200, 0x00820000, 0x80000200,
      0x80800200, 0x00800000, 0x00000000, 0x80020000,
      0x00020000, 0x80000000, 0x00800200, 0x00020200,
      0x80820200, 0x00820000, 0x80000200, 0x00800200,
      0x80000000, 0x00000200, 0x00020200, 0x80820000,
      0x00000200, 0x80800200, 0x80820000, 0x00000000,
      0x00000000, 0x80820200, 0x00800200, 0x80020000,
      0x00820200, 0x00020000, 0x80000200, 0x00800200,
      0x80820000, 0x00000200, 0x00020200, 0x80800000,
      0x80020200, 0x80000000, 0x80800000, 0x00820000,
      0x80820200, 0x00020200, 0x00820000, 0x80800200,
      0x00800000, 0x80000200, 0x80020000, 0x00000000,
      0x00020000, 0x00800000, 0x80800200, 0x00820200,
      0x80000000, 0x80820000, 0x00000200, 0x80020200,
      ];
use constant des_SPtrans_1 =>
    [ # Nibble 1
      0x10042004, 0x00000000, 0x00042000, 0x10040000,
      0x10000004, 0x00002004, 0x10002000, 0x00042000,
      0x00002000, 0x10040004, 0x00000004, 0x10002000,
      0x00040004, 0x10042000, 0x10040000, 0x00000004,
      0x00040000, 0x10002004, 0x10040004, 0x00002000,
      0x00042004, 0x10000000, 0x00000000, 0x00040004,
      0x10002004, 0x00042004, 0x10042000, 0x10000004,
      0x10000000, 0x00040000, 0x00002004, 0x10042004,
      0x00040004, 0x10042000, 0x10002000, 0x00042004,
      0x10042004, 0x00040004, 0x10000004, 0x00000000,
      0x10000000, 0x00002004, 0x00040000, 0x10040004,
      0x00002000, 0x10000000, 0x00042004, 0x10002004,
      0x10042000, 0x00002000, 0x00000000, 0x10000004,
      0x00000004, 0x10042004, 0x00042000, 0x10040000,
      0x10040004, 0x00040000, 0x00002004, 0x10002000,
      0x10002004, 0x00000004, 0x10040000, 0x00042000,
      ];
use constant des_SPtrans_2 =>
    [ # Nibble 2
      0x41000000, 0x01010040, 0x00000040, 0x41000040,
      0x40010000, 0x01000000, 0x41000040, 0x00010040,
      0x01000040, 0x00010000, 0x01010000, 0x40000000,
      0x41010040, 0x40000040, 0x40000000, 0x41010000,
      0x00000000, 0x40010000, 0x01010040, 0x00000040,
      0x40000040, 0x41010040, 0x00010000, 0x41000000,
      0x41010000, 0x01000040, 0x40010040, 0x01010000,
      0x00010040, 0x00000000, 0x01000000, 0x40010040,
      0x01010040, 0x00000040, 0x40000000, 0x00010000,
      0x40000040, 0x40010000, 0x01010000, 0x41000040,
      0x00000000, 0x01010040, 0x00010040, 0x41010000,
      0x40010000, 0x01000000, 0x41010040, 0x40000000,
      0x40010040, 0x41000000, 0x01000000, 0x41010040,
      0x00010000, 0x01000040, 0x41000040, 0x00010040,
      0x01000040, 0x00000000, 0x41010000, 0x40000040,
      0x41000000, 0x40010040, 0x00000040, 0x01010000,
      ];
use constant des_SPtrans_3 =>
    [ # Nibble 3 
      0x00100402, 0x04000400, 0x00000002, 0x04100402,
      0x00000000, 0x04100000, 0x04000402, 0x00100002,
      0x04100400, 0x04000002, 0x04000000, 0x00000402,
      0x04000002, 0x00100402, 0x00100000, 0x04000000,
      0x04100002, 0x00100400, 0x00000400, 0x00000002,
      0x00100400, 0x04000402, 0x04100000, 0x00000400,
      0x00000402, 0x00000000, 0x00100002, 0x04100400,
      0x04000400, 0x04100002, 0x04100402, 0x00100000,
      0x04100002, 0x00000402, 0x00100000, 0x04000002,
      0x00100400, 0x04000400, 0x00000002, 0x04100000,
      0x04000402, 0x00000000, 0x00000400, 0x00100002,
      0x00000000, 0x04100002, 0x04100400, 0x00000400,
      0x04000000, 0x04100402, 0x00100402, 0x00100000,
      0x04100402, 0x00000002, 0x04000400, 0x00100402,
      0x00100002, 0x00100400, 0x04100000, 0x04000402,
      0x00000402, 0x04000000, 0x04000002, 0x04100400,
      ];
use constant des_SPtrans_4 =>
    [ # Nibble 4
      0x02000000, 0x00004000, 0x00000100, 0x02004108,
      0x02004008, 0x02000100, 0x00004108, 0x02004000,
      0x00004000, 0x00000008, 0x02000008, 0x00004100,
      0x02000108, 0x02004008, 0x02004100, 0x00000000,
      0x00004100, 0x02000000, 0x00004008, 0x00000108,
      0x02000100, 0x00004108, 0x00000000, 0x02000008,
      0x00000008, 0x02000108, 0x02004108, 0x00004008,
      0x02004000, 0x00000100, 0x00000108, 0x02004100,
      0x02004100, 0x02000108, 0x00004008, 0x02004000,
      0x00004000, 0x00000008, 0x02000008, 0x02000100,
      0x02000000, 0x00004100, 0x02004108, 0x00000000,
      0x00004108, 0x02000000, 0x00000100, 0x00004008,
      0x02000108, 0x00000100, 0x00000000, 0x02004108,
      0x02004008, 0x02004100, 0x00000108, 0x00004000,
      0x00004100, 0x02004008, 0x02000100, 0x00000108,
      0x00000008, 0x00004108, 0x02004000, 0x02000008,
      ];
use constant des_SPtrans_5 =>
    [ # Nibble 5
      0x20000010, 0x00080010, 0x00000000, 0x20080800,
      0x00080010, 0x00000800, 0x20000810, 0x00080000,
      0x00000810, 0x20080810, 0x00080800, 0x20000000,
      0x20000800, 0x20000010, 0x20080000, 0x00080810,
      0x00080000, 0x20000810, 0x20080010, 0x00000000,
      0x00000800, 0x00000010, 0x20080800, 0x20080010,
      0x20080810, 0x20080000, 0x20000000, 0x00000810,
      0x00000010, 0x00080800, 0x00080810, 0x20000800,
      0x00000810, 0x20000000, 0x20000800, 0x00080810,
      0x20080800, 0x00080010, 0x00000000, 0x20000800,
      0x20000000, 0x00000800, 0x20080010, 0x00080000,
      0x00080010, 0x20080810, 0x00080800, 0x00000010,
      0x20080810, 0x00080800, 0x00080000, 0x20000810,
      0x20000010, 0x20080000, 0x00080810, 0x00000000,
      0x00000800, 0x20000010, 0x20000810, 0x20080800,
      0x20080000, 0x00000810, 0x00000010, 0x20080010,
      ];
use constant des_SPtrans_6 =>
    [ # Nibble 6
      0x00001000, 0x00000080, 0x00400080, 0x00400001,
      0x00401081, 0x00001001, 0x00001080, 0x00000000,
      0x00400000, 0x00400081, 0x00000081, 0x00401000,
      0x00000001, 0x00401080, 0x00401000, 0x00000081,
      0x00400081, 0x00001000, 0x00001001, 0x00401081,
      0x00000000, 0x00400080, 0x00400001, 0x00001080,
      0x00401001, 0x00001081, 0x00401080, 0x00000001,
      0x00001081, 0x00401001, 0x00000080, 0x00400000,
      0x00001081, 0x00401000, 0x00401001, 0x00000081,
      0x00001000, 0x00000080, 0x00400000, 0x00401001,
      0x00400081, 0x00001081, 0x00001080, 0x00000000,
      0x00000080, 0x00400001, 0x00000001, 0x00400080,
      0x00000000, 0x00400081, 0x00400080, 0x00001080,
      0x00000081, 0x00001000, 0x00401081, 0x00400000,
      0x00401080, 0x00000001, 0x00001001, 0x00401081,
      0x00400001, 0x00401080, 0x00401000, 0x00001001,
      ];
use constant des_SPtrans_7 =>
    [ # Nibble 7
      0x08200020, 0x08208000, 0x00008020, 0x00000000,
      0x08008000, 0x00200020, 0x08200000, 0x08208020,
      0x00000020, 0x08000000, 0x00208000, 0x00008020,
      0x00208020, 0x08008020, 0x08000020, 0x08200000,
      0x00008000, 0x00208020, 0x00200020, 0x08008000,
      0x08208020, 0x08000020, 0x00000000, 0x00208000,
      0x08000000, 0x00200000, 0x08008020, 0x08200020,
      0x00200000, 0x00008000, 0x08208000, 0x00000020,
      0x00200000, 0x00008000, 0x08000020, 0x08208020,
      0x00008020, 0x08000000, 0x00000000, 0x00208000,
      0x08200020, 0x08008020, 0x08008000, 0x00200020,
      0x08208000, 0x00000020, 0x00200020, 0x08008000,
      0x08208020, 0x00200000, 0x08200000, 0x08000020,
      0x00208000, 0x00008020, 0x08008020, 0x08200000,
      0x00000020, 0x08208000, 0x00208020, 0x00000000,
      0x08000000, 0x08200020, 0x00008000, 0x00208020,
      ];

# These have also been split up.
use constant des_skb_0 => 
    [ # For C bits (numbered as per FIPS 46) 1 2 3 4 5 6.
      0x00000000, 0x00000010, 0x20000000, 0x20000010,
      0x00010000, 0x00010010, 0x20010000, 0x20010010,
      0x00000800, 0x00000810, 0x20000800, 0x20000810,
      0x00010800, 0x00010810, 0x20010800, 0x20010810,
      0x00000020, 0x00000030, 0x20000020, 0x20000030,
      0x00010020, 0x00010030, 0x20010020, 0x20010030,
      0x00000820, 0x00000830, 0x20000820, 0x20000830,
      0x00010820, 0x00010830, 0x20010820, 0x20010830,
      0x00080000, 0x00080010, 0x20080000, 0x20080010,
      0x00090000, 0x00090010, 0x20090000, 0x20090010,
      0x00080800, 0x00080810, 0x20080800, 0x20080810,
      0x00090800, 0x00090810, 0x20090800, 0x20090810,
      0x00080020, 0x00080030, 0x20080020, 0x20080030,
      0x00090020, 0x00090030, 0x20090020, 0x20090030,
      0x00080820, 0x00080830, 0x20080820, 0x20080830,
      0x00090820, 0x00090830, 0x20090820, 0x20090830,
      ];
use constant des_skb_1 => 
    [ # For C bits (numbered as per FIPS 46) 7 8 10 11 12 13
      0x00000000, 0x02000000, 0x00002000, 0x02002000,
      0x00200000, 0x02200000, 0x00202000, 0x02202000,
      0x00000004, 0x02000004, 0x00002004, 0x02002004,
      0x00200004, 0x02200004, 0x00202004, 0x02202004,
      0x00000400, 0x02000400, 0x00002400, 0x02002400,
      0x00200400, 0x02200400, 0x00202400, 0x02202400,
      0x00000404, 0x02000404, 0x00002404, 0x02002404,
      0x00200404, 0x02200404, 0x00202404, 0x02202404,
      0x10000000, 0x12000000, 0x10002000, 0x12002000,
      0x10200000, 0x12200000, 0x10202000, 0x12202000,
      0x10000004, 0x12000004, 0x10002004, 0x12002004,
      0x10200004, 0x12200004, 0x10202004, 0x12202004,
      0x10000400, 0x12000400, 0x10002400, 0x12002400,
      0x10200400, 0x12200400, 0x10202400, 0x12202400,
      0x10000404, 0x12000404, 0x10002404, 0x12002404,
      0x10200404, 0x12200404, 0x10202404, 0x12202404,
      ];
use constant des_skb_2 => 
    [ # For C bits (numbered as per FIPS 46) 14 15 16 17 19 20
      0x00000000, 0x00000001, 0x00040000, 0x00040001,
      0x01000000, 0x01000001, 0x01040000, 0x01040001,
      0x00000002, 0x00000003, 0x00040002, 0x00040003,
      0x01000002, 0x01000003, 0x01040002, 0x01040003,
      0x00000200, 0x00000201, 0x00040200, 0x00040201,
      0x01000200, 0x01000201, 0x01040200, 0x01040201,
      0x00000202, 0x00000203, 0x00040202, 0x00040203,
      0x01000202, 0x01000203, 0x01040202, 0x01040203,
      0x08000000, 0x08000001, 0x08040000, 0x08040001,
      0x09000000, 0x09000001, 0x09040000, 0x09040001,
      0x08000002, 0x08000003, 0x08040002, 0x08040003,
      0x09000002, 0x09000003, 0x09040002, 0x09040003,
      0x08000200, 0x08000201, 0x08040200, 0x08040201,
      0x09000200, 0x09000201, 0x09040200, 0x09040201,
      0x08000202, 0x08000203, 0x08040202, 0x08040203,
      0x09000202, 0x09000203, 0x09040202, 0x09040203,
      ];
use constant des_skb_3 => 
    [ # For C bits (numbered as per FIPS 46) 21 23 24 26 27 28
      0x00000000, 0x00100000, 0x00000100, 0x00100100,
      0x00000008, 0x00100008, 0x00000108, 0x00100108,
      0x00001000, 0x00101000, 0x00001100, 0x00101100,
      0x00001008, 0x00101008, 0x00001108, 0x00101108,
      0x04000000, 0x04100000, 0x04000100, 0x04100100,
      0x04000008, 0x04100008, 0x04000108, 0x04100108,
      0x04001000, 0x04101000, 0x04001100, 0x04101100,
      0x04001008, 0x04101008, 0x04001108, 0x04101108,
      0x00020000, 0x00120000, 0x00020100, 0x00120100,
      0x00020008, 0x00120008, 0x00020108, 0x00120108,
      0x00021000, 0x00121000, 0x00021100, 0x00121100,
      0x00021008, 0x00121008, 0x00021108, 0x00121108,
      0x04020000, 0x04120000, 0x04020100, 0x04120100,
      0x04020008, 0x04120008, 0x04020108, 0x04120108,
      0x04021000, 0x04121000, 0x04021100, 0x04121100,
      0x04021008, 0x04121008, 0x04021108, 0x04121108,
      ];
use constant des_skb_4 => 
    [ # For D bits (numbered as per FIPS 46) 1 2 3 4 5 6
      0x00000000, 0x10000000, 0x00010000, 0x10010000,
      0x00000004, 0x10000004, 0x00010004, 0x10010004,
      0x20000000, 0x30000000, 0x20010000, 0x30010000,
      0x20000004, 0x30000004, 0x20010004, 0x30010004,
      0x00100000, 0x10100000, 0x00110000, 0x10110000,
      0x00100004, 0x10100004, 0x00110004, 0x10110004,
      0x20100000, 0x30100000, 0x20110000, 0x30110000,
      0x20100004, 0x30100004, 0x20110004, 0x30110004,
      0x00001000, 0x10001000, 0x00011000, 0x10011000,
      0x00001004, 0x10001004, 0x00011004, 0x10011004,
      0x20001000, 0x30001000, 0x20011000, 0x30011000,
      0x20001004, 0x30001004, 0x20011004, 0x30011004,
      0x00101000, 0x10101000, 0x00111000, 0x10111000,
      0x00101004, 0x10101004, 0x00111004, 0x10111004,
      0x20101000, 0x30101000, 0x20111000, 0x30111000,
      0x20101004, 0x30101004, 0x20111004, 0x30111004,
      ];
use constant des_skb_5 => 
    [ # For D bits (numbered as per FIPS 46) 8 9 11 12 13 14
      0x00000000, 0x08000000, 0x00000008, 0x08000008,
      0x00000400, 0x08000400, 0x00000408, 0x08000408,
      0x00020000, 0x08020000, 0x00020008, 0x08020008,
      0x00020400, 0x08020400, 0x00020408, 0x08020408,
      0x00000001, 0x08000001, 0x00000009, 0x08000009,
      0x00000401, 0x08000401, 0x00000409, 0x08000409,
      0x00020001, 0x08020001, 0x00020009, 0x08020009,
      0x00020401, 0x08020401, 0x00020409, 0x08020409,
      0x02000000, 0x0A000000, 0x02000008, 0x0A000008,
      0x02000400, 0x0A000400, 0x02000408, 0x0A000408,
      0x02020000, 0x0A020000, 0x02020008, 0x0A020008,
      0x02020400, 0x0A020400, 0x02020408, 0x0A020408,
      0x02000001, 0x0A000001, 0x02000009, 0x0A000009,
      0x02000401, 0x0A000401, 0x02000409, 0x0A000409,
      0x02020001, 0x0A020001, 0x02020009, 0x0A020009,
      0x02020401, 0x0A020401, 0x02020409, 0x0A020409,
      ];
use constant des_skb_6 => 
    [ # For D bits (numbered as per FIPS 46) 16 17 18 19 20 21
      0x00000000, 0x00000100, 0x00080000, 0x00080100,
      0x01000000, 0x01000100, 0x01080000, 0x01080100,
      0x00000010, 0x00000110, 0x00080010, 0x00080110,
      0x01000010, 0x01000110, 0x01080010, 0x01080110,
      0x00200000, 0x00200100, 0x00280000, 0x00280100,
      0x01200000, 0x01200100, 0x01280000, 0x01280100,
      0x00200010, 0x00200110, 0x00280010, 0x00280110,
      0x01200010, 0x01200110, 0x01280010, 0x01280110,
      0x00000200, 0x00000300, 0x00080200, 0x00080300,
      0x01000200, 0x01000300, 0x01080200, 0x01080300,
      0x00000210, 0x00000310, 0x00080210, 0x00080310,
      0x01000210, 0x01000310, 0x01080210, 0x01080310,
      0x00200200, 0x00200300, 0x00280200, 0x00280300,
      0x01200200, 0x01200300, 0x01280200, 0x01280300,
      0x00200210, 0x00200310, 0x00280210, 0x00280310,
      0x01200210, 0x01200310, 0x01280210, 0x01280310,
      ];
use constant des_skb_7 => 
    [ # For D bits (numbered as per FIPS 46) 22 23 24 25 27 28
      0x00000000, 0x04000000, 0x00040000, 0x04040000,
      0x00000002, 0x04000002, 0x00040002, 0x04040002,
      0x00002000, 0x04002000, 0x00042000, 0x04042000,
      0x00002002, 0x04002002, 0x00042002, 0x04042002,
      0x00000020, 0x04000020, 0x00040020, 0x04040020,
      0x00000022, 0x04000022, 0x00040022, 0x04040022,
      0x00002020, 0x04002020, 0x00042020, 0x04042020,
      0x00002022, 0x04002022, 0x00042022, 0x04042022,
      0x00000800, 0x04000800, 0x00040800, 0x04040800,
      0x00000802, 0x04000802, 0x00040802, 0x04040802,
      0x00002800, 0x04002800, 0x00042800, 0x04042800,
      0x00002802, 0x04002802, 0x00042802, 0x04042802,
      0x00000820, 0x04000820, 0x00040820, 0x04040820,
      0x00000822, 0x04000822, 0x00040822, 0x04040822,
      0x00002820, 0x04002820, 0x00042820, 0x04042820,
      0x00002822, 0x04002822, 0x00042822, 0x04042822,
      ];

m4_dnl For enhanced readability all macro definitions are "unsafe",
m4_dnl i. e. you may have to put parentheses or (m4!) quotes around the 
m4_dnl arguments in order to make the macro expand correctly.  For 
m4_dnl example calling the following macro like "rs(x, y - 1)" would
m4_dnl be incorrect.  You either have to say "rs(x, [m4[ y - 1 ]m4])",
m4_dnl or "rs(x, (y - 1))". 
m4_dnl
m4_dnl Umh, this macro is not needed any longer.  I keep it here
m4_dnl anyway because it may be useful in other modules.
m4_dnl m4_define(rs, (($1 >> $2) &  RIGHT_SHIFT_MASK->[$2]))
m4_dnl # Right-shifting in Perl with use integer is a little tricky.  In the
m4_dnl # absence of unsigned data types, the sign is always preserved which
m4_dnl # is undesirable in cryptographic applications.
m4_dnl #use constant RIGHT_SHIFT_MASK =>
m4_dnl #    [
m4_dnl #     0xffffffff, 0x7fffffff, 0x3fffffff, 0x1fffffff,
m4_dnl #     0x0fffffff, 0x07ffffff, 0x03ffffff, 0x01ffffff,
m4_dnl #     0x00ffffff, 0x007fffff, 0x003fffff, 0x001fffff,
m4_dnl #     0x000fffff, 0x0007ffff, 0x0003ffff, 0x0001ffff,
m4_dnl #     0x0000ffff, 0x00007fff, 0x00003fff, 0x00001fff,
m4_dnl #     0x00000fff, 0x000007ff, 0x000003ff, 0x000001ff,
m4_dnl #     0x000000ff, 0x0000007f, 0x0000003f, 0x0000001f,
m4_dnl #     0x0000000f, 0x00000007, 0x00000003, 0x00000001,
m4_dnl #     ];
m4_dnl
m4_define(PERM_OP1,
    $3 = (($1 >> 1) ^ $2) & 0x55555555;
    $2 ^= $3;
    $1 ^= $3 << 1)
m4_define(PERM_OP2,
    $3 = (($1 >> 2) ^ $2) & 0x33333333;
    $2 ^= $3;
    $1 ^= $3 << 2)
m4_define(PERM_OP4,
    $3 = (($1 >> 4) ^ $2) & 0x0f0f0f0f;
    $2 ^= $3;
    $1 ^= $3 << 4)
m4_define(PERM_OP8,
    $3 = (($1 >> 8) ^ $2) & 0x00ff00ff;
    $2 ^= $3;
    $1 ^= $3 << 8)
m4_define(PERM_OP16,
    $3 = (($1 >> 16) ^ $2) & 0x0000ffff;
    $2 ^= $3;
    $1 ^= $3 << 16)
m4_define(HPERM_OP,
    $2 = (($1 << 18) ^ $1) & 0xcccc0000;
    $1 = $1 ^ $2 ^ (($2 >> 18) & 0x00003fff))

sub expand_key ($) {
    my ($c, $d) = unpack "VV", shift;

    usage ("at least 8 byte key") unless defined $d;
    my @k = ();
    
    my ($t, $s);
    PERM_OP4($d, $c,  $t);
    HPERM_OP($c, $t);
    HPERM_OP($d, $t);
    PERM_OP1($d, $c,  $t);
    PERM_OP8($c, $d,  $t);
    PERM_OP1($d, $c,  $t);
    $d =     ((($d & 0x000000ff) << 16) |  ($d & 0x0000ff00)     |
	      (($d >> 16) & 0x000000ff) | (($c >> 4) & 0x0f000000));
    $c &= 0x0fffffff;
    
    use constant shifts2 => [0, 0, 1, 1, 1, 1, 1, 1, 
			     0, 1, 1, 1, 1, 1, 1, 0];
    
    # Do not try to unroll any of the loops (not this one and not the
    # one in crypt().  It will make things slower (about 30 %!).
    foreach my $i (0 .. ITERATIONS - 1) {
	# No need to mask out the sign here because only the
	# lower 28 bits are used.
	if (shifts2->[$i]) { 
	    $c = (($c >> 2) | ($c << 26)); 
	    $d = (($d >> 2) | ($d << 26));
	} else {
	    $c= (($c >> 1) | ($c << 27)); 
	    $d= (($d >> 1) | ($d << 27));
	}
	$c &= 0x0fffffff;
	$d &= 0x0fffffff;
	
	$s = (des_skb_0->[($c) & 0x3f] |
	      des_skb_1->[(($c >>  6) & 0x03) | 
			  (($c >>  7) & 0x3c)] |
	      des_skb_2->[(($c >> 13) & 0x0f) | 
			  (($c >> 14) & 0x30)] |
	      des_skb_3->[(($c >> 20) & 0x01) | 
			  (($c >> 21) & 0x06) |
			  (($c >> 22) & 0x38)]); 
	$t = (des_skb_4->[($d) & 0x3f] |
	      des_skb_5->[(($d >>  7) & 0x03) | 
			  (($d >>  8) & 0x3c)] |
	      des_skb_6->[ ($d >> 15) & 0x3f] |
	      des_skb_7->[(($d >> 21) & 0x0f) | 
			  (($d >> 22) & 0x30)]);
	
	$k[$i << 1] = (($t << 16) | ($s & 0x0000ffff)) & 0xffffffff;
	$s = ((($s >> 16) & 0x0000ffff) | ($t & 0xffff0000));
	
	$s = ($s << 4) | (($s >> 28) & 0x0fffffff);
	$k[($i << 1) + 1] = $s & 0xffffffff;
    }
    pack ("V*", @k);
}

m4_define(D_ENCRYPT,
            $u  = ($2 ^ $s[$3    ]);
	    $t =   $2 ^ $s[$3 + 1];
	    $t = (($t >> 4) & 0x0fffffff) | ($t << 28);
	    $1 ^= des_SPtrans_1->[($t      ) & 0x3f]|
	          des_SPtrans_3->[($t >>  8) & 0x3f]|
	          des_SPtrans_5->[($t >> 16) & 0x3f]|
	          des_SPtrans_7->[($t >> 24) & 0x3f]|
	          des_SPtrans_0->[($u      ) & 0x3f]|
	          des_SPtrans_2->[($u >>  8) & 0x3f]|
	          des_SPtrans_4->[($u >> 16) & 0x3f]|
	          des_SPtrans_6->[($u >> 24) & 0x3f])
sub crypt ($$$) {
    my ($input, $ks, $encrypt) = @_;
    my $output;
    
    my ($t, $u);
    
    my ($l, $r) = unpack "VV", $input;
    usage ("at least 8 byte key") unless defined $r;
    
    PERM_OP4($r, $l, $t);
    PERM_OP16($l, $r, $t);
    PERM_OP2($r, $l, $t);
    PERM_OP8($l, $r, $t);
    PERM_OP1($r, $l, $t);
    
    $t = ($r << 1) | (($r >> 31) & 0x1);
    $r = ($l << 1) | (($l >> 31) & 0x1);
    $l = $t;
    
    # Clear the top bits on machines with 8byte longs.
    $l &= 0xffffffff;
    $r &= 0xffffffff;
    
    my @s = unpack ("V32", $ks);
    my $i;
    
    if ($encrypt) {
	for ($i = 0; $i < 32; $i += 4) {
	    D_ENCRYPT($l, $r, ($i + 0));
	    D_ENCRYPT($r, $l, ($i + 2));
	}
    } else {
	for ($i = 30; $i > 0; $i -= 4) {
	    D_ENCRYPT($l, $r, ($i - 0));
	    D_ENCRYPT($r, $l, ($i - 2));
	}		
    }
    
    $l = (($l >> 1) & 0x7fffffff) | ($l << 31);
    $r = (($r >> 1) & 0x7fffffff) | ($r << 31);
    # Clear the top bits on machines with 8byte longs.
    $l &= 0xffffffff;
    $r &= 0xffffffff;
    
    # Swap $l and $r.
    # We will not do the swap so just remember they are
    # Reversed for the rest of the subroutine
    # Luckily FP fixes this problem :-)
    
    PERM_OP1($r, $l, $t);
    PERM_OP8($l, $r, $t);
    PERM_OP2($r, $l, $t);
    PERM_OP16($l, $r, $t);
    PERM_OP4($r, $l, $t);
    
    pack "VV", $l, $r;
}

1;

__END__

=head1 NAME

Crypt::DES_PP - Perl extension for DES encryption

=head1 SYNOPSIS

use Crypt::DES_PP;

    $des = Crypt::DES_PP->new ($key);
    $cipher = $des->encrypt ($plain);
    $plain = $des->decrypt ($cipher);
    $blocksize = $des->blocksize;
    $keysize = $des->keysize;

=head1 DESCRIPTION

The Data Encryption Standard (DES), also known as Data Encryption 
Algorithm  (DEA) is a semi-strong encryption and decryption algorithm.  

The module is 100 % compatible to Crypt::DES but is implemented 
entirely in Perl.  That means that you do not need a C compiler to 
build and install this extension.  

The module implements the Crypt::CBC interface.  You are encouraged
to read the documentation for Crypt::CBC if you intend to use this
module for Cipher Block Chaining.

The minimum (and maximum) key size is 8 bytes.  Shorter keys will
cause an exception, longer keys will get silently truncated.  Data
is encrypted and decrypted in blocks of 8 bytes.

The module implements the Ultra-Fast-Crypt (UFC) algorithm as found
for example in the GNU libc.  On the Perl side a lot has been done
in order to make the module as fast as possible (function inlining,
use integer, ...).

Note: For performance issues the source code for the module is
first preprocessed by m4.  That means that you need an m4 macro
processor in order to hack on the sources.  This is of no concern
for you if you only want to use the module, the preprocessed output
is always included in the distribution.

=head1 BUGS

Nothing known.  The module has not been tested on 64 bit architectures.

=head1 AUTHOR

This implementation was written by Guido Flohr (guido@imperia.net).
It is available under the terms of the Lesser GNU General Public
License (LGPL) version 2 or - at your choice - any later version,
see the file ``COPYING.LIB''.

The original C implementation of the Ultra-Fast-Crypt algorithm
was written by Michael Glad (glad@daimi.aau.dk) and has been donated to 
the Free Software Foundation, Inc.  It is covered by the GNU library 
license version 2, see the file ``COPYING.LIB''.

=head1 SEE ALSO

Crypt::CBC(3), Crypt::DES(3), perl(1), m4(1).

=cut

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
tab-width: 4
End:                                                                            
