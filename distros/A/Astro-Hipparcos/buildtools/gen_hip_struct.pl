use strict;
use warnings;
use File::Spec;

my $header_file = 'HipRecord.h';
open my $header_fh, '>', $header_file or die $!;

my $c_file = 'HipRecord.cc';
open my $c_fh, '>', $c_file or die $!;

my $xsp_file = 'HipRecord.xsp';
open my $xsp_fh, '>', $xsp_file or die $!;

my $pod_dir = File::Spec->catdir('lib', 'Astro', 'Hipparcos');
mkdir($pod_dir);
my $pod_file = File::Spec->catfile('lib', 'Astro', 'Hipparcos', 'Record.pod');
open my $pod_fh, '>', $pod_file or die $!;

my $line = '';
$line = <DATA> while $line !~ /-------/;

my %types = (
  'A' => 'std::string',
  'F' => 'float',
  'D' => 'double',
  'I' => 'int',
  'C' => 'char',
  'S' => 'short int',
);
my %converters = (
  'A' => '$IN',
  'F' => '(float)atof($IN)',
  'D' => '(double)atof($IN)', # check whether we're losing precision here...
  'I' => '(int)atoi($IN)',
  'C' => '(char)atoi($IN)',
  'S' => '(short int)atoi($IN)',
);

my @struct;
my @get_set;
my @get_set_xsp;
my @parser_code;
my @pod;
while (defined($line = <DATA>)) {
  next if $line =~ /^\s*$/;
  chomp $line;

  my $bytes_pos_str = substr($line, 0, 7);
  my ($bytes_start, $bytes_end) = split /-/, $bytes_pos_str;
  $bytes_end-=1;
  $bytes_start-=1;
  $bytes_end = $bytes_start if $bytes_end == 0;

  my $type_str = substr($line, 9, 5);
  $type_str =~ /^\s*([AIF])(\d+(?:\.\d+)?)\s*$/
    or die "Invalid type '$type_str' encountered";
  my ($type, $num) = ($1, $2);
  if ($type eq 'F' and $num > 8) {
    $type = 'D';
  }
  elsif ($type eq 'I') {
    if ($num <= 2) {
      $type = 'C';
    }
    elsif ($num <= 4) {
      $type = 'S',
    }
  }

  my $label_str = substr($line, 21, 11);
  $label_str =~ s/^\s+//;
  $label_str =~ s/\s+$//;
  next if $label_str eq '---';
  $label_str =~ tr/a-zA-z0-9/_/c;

  my $comment = "/* $line */";

  my $c_type = $types{$type};
  $c_type =~ s/\$NUM/$num/g;
  my $struct_line = "    $c_type f$label_str;";
  $struct_line .= ' ' x (25-length($struct_line));
  $struct_line .= $comment."\n";
  push @struct, $struct_line;

  my $getter = "    $c_type get_$label_str() { return f$label_str; }\n";
  my $setter = "    void set_$label_str($c_type newval) { f$label_str = newval; }\n";
  push @get_set, $getter, $setter;
  my $getter_xsp = "    $c_type get_$label_str();\n";
  my $setter_xsp = "    void set_$label_str($c_type newval);\n";
  push @get_set_xsp, $getter_xsp, $setter_xsp;
  my $pod = "=item * get_$label_str() set_$label_str\n\n    $line\n\n";
  push @pod, $pod;

  if ($type eq 'A') {
    my $len = $bytes_end-$bytes_start+1;
    push @parser_code, "  f$label_str = line.substr($bytes_start, $len);\n";
  }
  else {
    my $conv = $converters{$type};
    $conv =~ s/\$IN/&line[$bytes_start]/;
    push @parser_code, <<PARSER;
  f$label_str = $conv;
PARSER
  }
}

my $header_code = <<'HIPCLASS_BEGIN' . join('', @get_set) . <<'HIPCLASS_MID' . join('', @struct) . <<'HIPCLASS_END';
#ifndef _HipRecord_h_
#define _HipRecord_h_

#include <string>

class HipRecord {
  public:
    HipRecord() {}
    bool ParseRecord(const std::string& line);
    std::string get_line() { return fLine; }
    void set_line(const std::string& line) { fLine = line; }
HIPCLASS_BEGIN

  private:
    std::string fLine;
HIPCLASS_MID
}; // end class HipRecord

#endif
HIPCLASS_END

print $header_fh $header_code;

my $xsp_code = <<'HIPCLASS_BEGIN' . join('', @get_set_xsp) . <<'HIPCLASS_END';

%module{Astro::Hipparcos};

%name{Astro::Hipparcos::Record} class HipRecord
{
    %name{new} HipRecord();
    ~HipRecord();
    bool ParseRecord(const std::string& line);
    std::string get_line();
    void set_line(const std::string& line);
HIPCLASS_BEGIN
};
HIPCLASS_END

print $xsp_fh $xsp_code;

my $c_code = <<"PARSERECORD_BEGIN" . join('', @parser_code) . <<'HIPCLASS_PARSERCODEEND';
#include "$header_file"
#include <iostream>
#include <cstdlib>
#include <cmath>

bool
HipRecord::ParseRecord(const std::string& line) {
  fLine = line;
PARSERECORD_BEGIN
  return true;
}

HIPCLASS_PARSERCODEEND

print $c_fh $c_code;

my $pod_code = <<'POD_BEGIN' . join('', @pod) . <<'POD_END';

=pod

=head1 NAME

Astro::Hipparcos::Record - Represents a single Hipparcos record

=head1 SYNOPSIS

  use Astro::Hipparcos;
  my $catalog = Astro::Hipparcos->new("thefile.dat");
  while (defined(my $record = $catalog->get_record())) {
    print $record->get_HIP(), "\n"; # print record id
  }

=head1 DESCRIPTION

Represents a single Hipparcos record. The code is auto-generated from the C-level structure.
Thus the funny member names.

=head1 METHODS

=head2 new

Returns a new record object.

=head2 ParseRecord

Somewhat internal method that may SEGFAULT if you use it wrong.

Given a string that MUST contain a full line from the record file,
fills the object with data from that line.

=head2 get_line

Returns the full original catalog line.

=head1 GENERATED ACCESSOR METHODS

Each of these methods descriptions have the following format:

    Bytes Format Units   Label     Explanations

=over 2

POD_BEGIN

=back

=head1 SEE ALSO

L<Astro::Hipparcos>

L<http://en.wikipedia.org/wiki/Hipparcos_Catalogue>

At the time of this writing, you could obtain a copy of the Hipparcos catalogue
from L<ftp://adc.gsfc.nasa.gov/pub/adc/archives/catalogs/1/1239/> (hip_main.dat.gz).

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

POD_END

print $pod_fh $pod_code;

__DATA__

  Bytes Format Units   Label     Explanations
--------------------------------------------------------------------------------
      1  A1    ---     Catalog   [H] Catalogue (H=Hipparcos)               (H0)
  9- 14  I6    ---     HIP       Identifier (HIP number)                   (H1)
     16  A1    ---     Proxy     [HT] Proximity flag                       (H2)
 18- 28  A11   ---     RAhms    *Right ascension in h m s, ICRS (Eq=J2000) (H3)
 30- 40  A11   ---     DEdms    *Declination in deg ' ", ICRS (Eq=J2000)   (H4)
 42- 46  F5.2  mag     Vmag      ? Magnitude in Johnson V                  (H5)
     48  I1    ---     VarFlag  *[1,3]? Coarse variability flag            (H6)
     50  A1    ---   r_Vmag     *[GHT] Source of magnitude                 (H7)
 52- 63  F12.8 deg     RAdeg    *? alpha, degrees (ICRS, Eq=J2000)         (H8)
 65- 76  F12.8 deg     DEdeg    *? delta, degrees (ICRS, Eq=J2000)         (H9)
     78  A1    ---     AstroRef *[*+A-Z] Reference flag for astrometry    (H10)
 80- 86  F7.2  mas     Plx       ? Trigonometric parallax                 (H11)
 88- 95  F8.2 mas/yr   pmRA      ? Proper motion mu_alpha.cos(delta), ICRS(H12)
 97-104  F8.2 mas/yr   pmDE      ? Proper motion mu_delta, ICRS           (H13)
106-111  F6.2  mas   e_RAdeg     ? Standard error in RA*cos(DEdeg)        (H14)
113-118  F6.2  mas   e_DEdeg     ? Standard error in DE                   (H15)
120-125  F6.2  mas   e_Plx       ? Standard error in Plx                  (H16)
127-132  F6.2 mas/yr e_pmRA      ? Standard error in pmRA                 (H17)
134-139  F6.2 mas/yr e_pmDE      ? Standard error in pmDE                 (H18)
141-145  F5.2  ---     DE:RA     [-1/1]? Correlation, DE/RA*cos(delta)    (H19)
147-151  F5.2  ---     Plx:RA    [-1/1]? Correlation, Plx/RA*cos(delta)   (H20)
153-157  F5.2  ---     Plx:DE    [-1/1]? Correlation, Plx/DE              (H21)
159-163  F5.2  ---     pmRA:RA   [-1/1]? Correlation, pmRA/RA*cos(delta)  (H22)
165-169  F5.2  ---     pmRA:DE   [-1/1]? Correlation, pmRA/DE             (H23)
171-175  F5.2  ---     pmRA:Plx  [-1/1]? Correlation, pmRA/Plx            (H24)
177-181  F5.2  ---     pmDE:RA   [-1/1]? Correlation, pmDE/RA*cos(delta)  (H25)
183-187  F5.2  ---     pmDE:DE   [-1/1]? Correlation, pmDE/DE             (H26)
189-193  F5.2  ---     pmDE:Plx  [-1/1]? Correlation, pmDE/Plx            (H27)
195-199  F5.2  ---     pmDE:pmRA [-1/1]? Correlation, pmDE/pmRA           (H28)
201-203  I3    %       F1        ? Percentage of rejected data            (H29)
205-209  F5.2  ---     F2       *? Goodness-of-fit parameter              (H30)
211-216  I6    ---     ---       HIP number (repetition)                  (H31)
218-223  F6.3  mag     BTmag     ? Mean BT magnitude                      (H32)
225-229  F5.3  mag   e_BTmag     ? Standard error on BTmag                (H33)
231-236  F6.3  mag     VTmag     ? Mean VT magnitude                      (H34)
238-242  F5.3  mag   e_VTmag     ? Standard error on VTmag                (H35)
    244  A1    ---   m_BTmag    *[A-Z*-] Reference flag for BT and VTmag  (H36)
246-251  F6.3  mag     B-V       ? Johnson B-V colour                     (H37)
253-257  F5.3  mag   e_B-V       ? Standard error on B-V                  (H38)
    259  A1    ---   r_B-V       [GT] Source of B-V from Ground or Tycho  (H39)
261-264  F4.2  mag     V-I       ? Colour index in Cousins' system        (H40)
266-269  F4.2  mag   e_V-I       ? Standard error on V-I                  (H41)
    271  A1    ---   r_V-I      *[A-T] Source of V-I                      (H42)
    273  A1    ---     CombMag   [*] Flag for combined Vmag, B-V, V-I     (H43)
275-281  F7.4  mag     Hpmag    *? Median magnitude in Hipparcos system   (H44)
283-288  F6.4  mag   e_Hpmag    *? Standard error on Hpmag                (H45)
290-294  F5.3  mag     Hpscat    ? Scatter on Hpmag                       (H46)
296-298  I3    ---   o_Hpmag     ? Number of observations for Hpmag       (H47)
    300  A1    ---   m_Hpmag    *[A-Z*-] Reference flag for Hpmag         (H48)
302-306  F5.2  mag     Hpmax     ? Hpmag at maximum (5th percentile)      (H49)
308-312  F5.2  mag     HPmin     ? Hpmag at minimum (95th percentile)     (H50)
314-320  F7.2  d       Period    ? Variability period (days)              (H51)
    322  A1    ---     HvarType *[CDMPRU]? variability type               (H52)
    324  A1    ---     moreVar  *[12] Additional data about variability   (H53)
    326  A1    ---     morePhoto [ABC] Light curve Annex                  (H54)
328-337  A10   ---     CCDM      CCDM identifier                          (H55)
    339  A1    ---   n_CCDM     *[HIM] Historical status flag             (H56)
341-342  I2    ---     Nsys      ? Number of entries with same CCDM       (H57)
344-345  I2    ---     Ncomp     ? Number of components in this entry     (H58)
    347  A1    ---     MultFlag *[CGOVX] Double/Multiple Systems flag     (H59)
    349  A1    ---     Source   *[PFILS] Astrometric source flag          (H60)
    351  A1    ---     Qual     *[ABCDS] Solution quality                 (H61)
353-354  A2    ---   m_HIP       Component identifiers                    (H62)
356-358  I3    deg     theta     ? Position angle between components      (H63)
360-366  F7.3  arcsec  rho       ? Angular separation between components  (H64)
368-372  F5.3  arcsec  e_rho     ? Standard error on rho                  (H65)
374-378  F5.2  mag     dHp       ? Magnitude difference of components     (H66)
380-383  F4.2  mag   e_dHp       ? Standard error on dHp                  (H67)
    385  A1    ---     Survey    [S] Flag indicating a Survey Star        (H68)
    387  A1    ---     Chart    *[DG] Identification Chart                (H69)
    389  A1    ---     Notes    *[DGPWXYZ] Existence of notes             (H70)
391-396  I6    ---     HD        [1/359083]? HD number <III/135>          (H71)
398-407  A10   ---     BD        Bonner DM <I/119>, <I/122>               (H72)
409-418  A10   ---     CoD       Cordoba Durchmusterung (DM) <I/114>      (H73)
420-429  A10   ---     CPD       Cape Photographic DM <I/108>             (H74)
431-434  F4.2  mag     (V-I)red  V-I used for reductions                  (H75)
436-447  A12   ---     SpType    Spectral type                            (H76)
    449  A1    ---   r_SpType   *[1234GKSX]? Source of spectral type      (H77)

