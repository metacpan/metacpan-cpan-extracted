package Astro::Bibcode;

=head1 NAME

Astro::Bibcode - Parse standardised astronomical journal bibcode

=head1 SYNOPSIS

  use Astro::Bibcode;
  $bib = new Astro::Bibcode( '2002MNRAS.336...14J' );

  print $bib->journal(),"\n";
  print $bib->volume(),"\n";
  print $bib->year(),"\n";

=head1 DESCRIPTION

This module parses a standardised astronomical journal bibcode (see
references at end of this documentation) and allows the individual
parts to be extracted.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

use vars qw/ $VERSION /;
$VERSION = sprintf("%d.%03d", q$Revision: 0.3 $ =~ /(\d+)\.(\d+)/);

# Some lookup tables

# Standard Classification codes
my %CLASS = (
	     B => 'textbook',
	     C => 'catalog',
	     M => 'digited version',
	     P => 'preprint',
	     R => 'report or conference proceedings',
	     T => 'thesis',
	     U => 'unpublished',
	    );

# Note that ADS seems to use the following classifications:
#  conf   Conference
#  book   Book
#  work   Workshop
#  symp   Symposium
#  rept   Reports
#  meet   Meeting
my %CLASS_ADS = (
		 proc => 'conference proceeding', # Alias for "conf"
		 book => 'book',
		 work => 'workshop',
		 conf => 'conference proceeding',
		 symp => 'symposium',
		 rept => 'report',
		 meet => 'meeting',
		);

# These are populated dynamically as required

# Normal standardised Journal lookup
my %JOURNALS;

# ADS conference proceedings lookup
my %CONF_ADS;


=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new C<Astro::Bibcode> object. This constructor
can be called in a number of ways.

If a single argument is provided it is assumed to be a bibcode.
This code will be parsed, if the parse fails the object will not
be created.

  $bib = new Astro::Bibcode( '1995MNRAS.276.1024J' );

THE REST OF THIS SECTION IS PROPOSED INTERFACE AND IS NOT IMPLEMENTED

If it is called without arguments an empty object will be
created. Further calls to the C<bibcode> method or the individual
components will be required to configure the object.

  $bib = new Astro::Bibcode;


If a series of hash arguments are provided, the object will
be configured by calling the individual accessors in turn.

  $bib = new Astro::Bibcode( journalcode => 'ApJ',
                             year => 2002,
                           );

NOTE THAT BIBCODE CREATION IS NOT YET IMPLEMENTED

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # Create object
  my $bib = bless {
		   BIBCODE => undef,
		   YEAR => undef,
		   JOURNALCODE => undef,
		   CLASSFLAG => undef,
		   VOLUME => undef,
		   MISC => undef,
		   PAGE => undef,
		   INITIAL => undef,
		   CONFCODE => undef,
                  }, $class;

  if (@_) {
    # if we have one code it's a bibcode
    if (scalar(@_) == 1) {
      my $retval = $bib->bibcode( $_[0] );

      # if bibcode method returned undef (error in parse)
      # set the object to undef to indicate error
      $bib = undef unless defined $retval;
    } else {
      my %args = @_;

      # loop over known important methods
      for my $k (qw| year journalcode classflag volume page initial misc |) {
	$bib->$k($args{$k}) if exists $args{$k};
      }

    }

  }

  return $bib;
}

=back

=head2 Accessor Methods

=over 4

=item B<bibcode>

Returns the bibcode associated with this object. It will be generated
from the other object attributes if undefined (which it will be after
something in the object has changed).

  $bib->bibcode( '1998adass...7..216J' );
  $code = $bib->bibcode;

Can return undef if the bibcode did not pass verification (see
C<verify_bibcode>).

=cut

sub bibcode {
  my $self = shift;
  if (@_) {
    my $code = shift;
    # Verify and store
    my %parts = $self->verify_bibcode( $code );

    # if we did not get any result; store undef and return
    if (!keys %parts) {
      $self->{BIBCODE} = undef;
      return;
    }

    # We did get some data. Configure the rest of the object
    # to match. Note that we do not go through the accessors
    # since they may well be configured to clear the bibcode
    # if they are modified and we would end up with recursion
    $self->{YEAR} = $parts{year};
    $self->{VOLUME} = $parts{volume};
    $self->{JOURNALCODE} = $parts{journalcode};
    $self->{CLASSFLAG} = $parts{classflag};
    $self->{MISC} = $parts{misc};
    $self->{PAGE} = $parts{page};
    $self->{INITIAL} = $parts{initial};

    $self->{BIBCODE} = $self->verify_bibcode( $code );

    return $self->{BIBCODE};
  } else {
    # if no bibcode is defined, attempt to generate one from the object
    if (! defined $self->{BIBCODE} ) {
      $self->_construct_bibcode();
    }
  }
  return $self->{BIBCODE};
}

=item B<year>

Year of publication.

 $year = $bib->year;

=cut

sub year {
  my $self = shift;
  return $self->{YEAR};
}

=item B<journalcode>

The Journal code associated with this bib code.

For the current list of journal codes see:

  http://simbad.u-strasbg.fr/simjnl.pl

See the C<journal> method in order to translate this code to a full
journal name.

  $jcode = $bib->journalcode;

=cut

sub journalcode {
  my $self = shift;
  return $self->{JOURNALCODE};
}


=item B<classflag>

Classification flag of this bib code.
Current allowed values are:

     B textbook
     C catalog
     M digited version
     P preprint
     R report or conference proceedings
     T thesis
     U unpublished

and also from ADS:

     book => 'book'
     work => 'workshop'
     conf => 'conference proceeding'
     symp => 'symposium'
     rept => 'report'
     meet => 'meeting'

Note that a null string is used to indicate a periodical.

 $code = $bib->classflag;

See the C<class> method for the translation.

=cut

sub classflag {
  my $self = shift;
  return $self->{CLASSFLAG};
}

=item B<volume>

Volume number.

=cut

sub volume {
  my $self = shift;
  return $self->{VOLUME};
}

=item B<misc>

Value of the miscellaneous field "M" used to remove ambiguity.

=cut

sub misc {
  my $self = shift;
  return $self->{MISC};
}

=item B<page>

Page number.

=cut

sub page {
  my $self = shift;
  return $self->{PAGE};
}

=item B<initial>

Either the first initial of the first author's last name,
or ":" for no author. Also can be "%" to indicate that some
of the other fields may be invalid.

=cut

sub initial {
  my $self = shift;
  return $self->{INITIAL};
}

=back

=head2 General Methods

=over 4

=item B<journal>

Retrieve the full journal name.

 $journal = $bib->journal;

Returns the code if the code can not be translated.

Does try to recognize ADS conference codes.

=cut

sub journal {
  my $self = shift;
  my $jcode = $self->journalcode; # Journal lookup
  my $confcode = $self->confcode; # Conference lookup

  # first time through, populate the journal lookup
  $self->_populate_journals() unless keys %JOURNALS;

  # Is it in the journal list?
  if (exists $JOURNALS{$jcode}) {
    # Straight journal lookup
    return $JOURNALS{$jcode};
  } elsif (defined $confcode) {
    # It is a conference
    return $CONF_ADS{$confcode};
  } else {
    # do not know
    return $jcode;
  }
}

=item B<class>

Retrieve the full name associated with the classification flag.

 $class = $bib->class;

Returns undef if no name can be translated.

=cut

sub class {
  my $self = shift;
  my $flag = $self->classflag;

  # in some cases a "periodical" style bibcode can actually be associated
  # with a conference. Check this by looking to see if confcode is true
  my $confcode = $self->confcode;

  # if confcode is defined but flag is not, we are really a recurring "conf"
  return "recurring conference" if defined $confcode && !$flag;

  # Sometimes a blank classflag simply means that ADS is lying...
  # rather than it being a "periodical"
  if (!length($flag)) {
    my $journal = $self->journal;
    if ($journal =~ /thesi/i) {
      # it is really a thesis
      return "thesis";
    } else {
      # no hint - use periodical
      return "periodical";
    }
  }

  if (exists $CLASS{$flag}) {
    return $CLASS{$flag};
  } elsif (exists $CLASS_ADS{$flag}) {
    return $CLASS_ADS{$flag};
  }
  return undef;
}

=item B<confcode>

Returns the ADS conference code associated with this bibcode.
Returns undef if this bibcode is not associated with a conference.

  $confcode = $bib->confcode;

In some cases (eg 2000immm.proc...77G), a "proc" classification
is used when the ADS standard seems to imply "conf" instead.
This is taken into account when returning the confcode.

=cut

sub confcode {
  my $self = shift;
  my $bibcode = $self->bibcode(); # For ADS conference proceedings translation

  # Force read of DATA segment
  $self->_populate_journals unless keys %CONF_ADS;

  my $confcode;
  if (exists $CONF_ADS{substr($bibcode,0,13)}) {
    # Now try an exact ADS match with the first 13 characters
    # This gives us the journal code
    $confcode = substr($bibcode,0,13);

  } elsif (exists $CONF_ADS{substr($bibcode,4,9)}) {
    # try ADS conference lookup without the year prefix
    $confcode = substr($bibcode,4,9);

  } elsif ($bibcode =~ /proc/) {
    # if we have a .proc see whether .conf matches anywhere
    my $c = $bibcode;
    $c =~ s/proc/conf/;
    if (exists $CONF_ADS{substr($c,0,13)}) {
      $confcode = substr($c,0,13);
    }
  }

  return $confcode;
}

=item B<summary>

Return a multi-line summary string describing the bibcode status.

 $text = $bib->summary;

=cut

sub summary {
  my $self = shift;
  my $str = '';

  my @keys = qw/ class journal year volume page /;

  # Find the max length of the key
  my $max = 0;
  for (@keys) {
    $max = length($_) if length($_) > $max;
  }

  for my $m (@keys) {
    my $data = $self->$m();
    $str .= sprintf("%-".$max."s : %s\n", ucfirst($m), $data);
  }
  return $str;
}

=item B<verify_bibcode>

Given a bibcode, return false if the bibcode does not seem to be 
valid (e.g. it is the wrong lenght, first 4 characters are not digits),
returns the bibcode in scalar context.

  $ok = $bib->verify_bibcode( '1999adass...8...11E' );

In list context returns a hash consisting of the constituent (untranslated)
parts of the bib code.

  %parts = $bib->verify_bibcode( '1998SPIE.3357..548J' );

Since ADS is prone to replacing & with &amp; in Journal codes due to
HTML transport, this routine will reverse this.

Note that in some special cases a bibcode can be specified such 
that it is known not to match all the rules (last character is a '%').
In such cases only the length of the bicode is checked.

=cut

sub verify_bibcode {
  my $self = shift;
  my $bibcode = shift;
  return unless defined $bibcode;

  # Fix HTML-ification
  $bibcode =~ s/&amp;/&/;

  # Check length
  return unless length($bibcode) == 19;

  # Rather than one enormous pattern match, split the string
  # into fixed length chunks
  my $yyyy = substr($bibcode,0,4);
  my $jjjjj= substr($bibcode,4,5);
  my $vvvv = substr($bibcode,9,4);
  my $m    = substr($bibcode,13,1);
  my $pppp = substr($bibcode,14,4);
  my $a    = substr($bibcode,18,1);

  # Verify each component and store in hash
  my %parts;

  # Note that ADS conference proceeding extensions are still valid bibcodes
  $parts{year} = $self->_verify_year( $yyyy );
  $parts{journalcode} = $self->_verify_journalcode( $jjjjj );

  my ($class, $vol) = $self->_verify_volume( $vvvv );
  $parts{volume} = $vol;
  $parts{classflag} = $class;

  $parts{misc} = $self->_verify_misc( $m );
  $parts{page} = $self->_verify_page( $pppp );
  $parts{initial} = $self->_verify_initial( $a );


  # Ordinarily we would return if any of the values in the hash
  # are undef. There is a special case if $a is "%" since this
  # indicates that some of them may not match. In this case
  # we do what we can.

  if ($a ne "%") {
    for my $v (values %parts) {
      return unless defined $v;
    }
  }

  # Return the answer
  if (!wantarray) {
    return $bibcode;
  } else {
    return %parts;
  }
}

=back

=begin PRIVATE__METHODS

Internal routines which may change and should not be used in external
classes.

These are methods, although there is no expectation that subclasses
will be required.

=over 4

=item B<_construct_bibcode>

=cut

sub _construct_bibcode {
  my $self = shift;

  Carp::confess "Bibcode construction is not yet implemented. It may be hard.";

}

=item B<_verify_year>

Check the year looks okay, return false if it does not, the year
if it looks okay.

=cut

sub _verify_year {
  my $self = shift;
  my $year = shift;
  return (($year =~ /^\d{4}$/) ? $year : () );
}

=item B<_verify_journalcode>

Check that the journal code looks okay. Returns the code if okay,
false otherwise.

Does not check to see if the journal code can be translated.

Trailing dots are removed from the input string.

=cut

sub _verify_journalcode {
  my $self = shift;
  my $jcode = shift;

  # Clean the string
  $jcode = _clean_string($jcode, 'L');

  # Just make sure we have A-Z and &
  return ( ( $jcode =~ /^[A-Za-z&]+$/) ? $jcode : () );
}

=item B<_verify_volume>

Check that the volume and class are okay.

In scalar context returns the verified string (with leading
dots removed).

  ($class, $volume) = $bib->_verify_volume( $v );
  $v = $bib->_verify_volume($v);

In list context returns two values. First is the classification
flag (blank string for a periodical), second is the volume number
(leasing zeroes removed).

Note that since ADS does not seem to use the classification
code as presented in the reference documentation, this is a bit
of a hack (eg a Thesis would be expected to have class = T but
instead simply uses PhDT in the journal name and not the university).

This means that a blank volume and class are okay and the
class needs to be hacked in higher up.

=cut

sub _verify_volume {
  my $self = shift;
  my $vol = shift;

  # Second character is important so we need to get that before
  # cleaning
  my $second = substr($vol,1,1);


  # Clean the string
  $vol = _clean_string( $vol, 'R' );

  # empty is okay [need to guess later on]
  return (wantarray ? ('', '') : $vol) unless $vol;

  # Get standard classification codes
  my $classes = join( "", keys %CLASS);

  # Get adass codes and form a pattern match string
  my $adsmatch = join("|",keys %CLASS_ADS);

  # Either we are all numbers
  if ($vol =~ /^\d+$/) {
    # periodical. Test calling context
    return (wantarray ? ('',$vol) : $vol );
  } elsif ($vol =~ /([$classes])(\d\d)$/) {
    # We are a classification other than a published journal
    # with multi-volume
    my $c = $1;
    my $num = $2;
    # strip leading zero
    $num =~ s/^0+//g;

    # return the result (checking for context)
    return (wantarray ? ($c, $num) : $vol);

  } elsif ($second =~ /^([$classes])$/) {
    my $class = $1;
    return (wantarray ? ($class, '') : $vol );
  } elsif ($vol =~ /^($adsmatch)$/) {
    return (wantarray ? ($1, '') : $vol);
  }
  # bad code
  return;
}

=item B<_verify_misc>

Verify the misc field which is used to break ambiguity.

 L     letter section in periodical
 p     pink MNRAS pages
 a-z   issue number in same volume
 A-K   issue designations within same volume
 Q-Z   articles on same page
 A-Z   For theses, first initial of author
 E     "ephemeral". These are temporary bibcodes
       submitted prior to publication [ADS-specific]

Fundamentally, any letter matches or a ".".

To be truly accurate the verification requires the 
journal name and classification flag.

=cut

sub _verify_misc {
  my $self = shift;
  my $m = shift;

  # a . is fine
  return "" if $m eq ".";

  # Now pattern match
  return ( ($m =~ /^[A-Za-z]$/) ? $m : ());
}


=item B<_verify_page>

Verifies the page number. Returns the page number with leading "."
removed. Returns false on error.

=cut

sub _verify_page {
  my $self = shift;
  my $page = shift;
  $page = _clean_string( $page, 'R');
  return (($page =~ /^\d+$/) ? $page : () );
}

=item B<_verify_initial>

Check that the initial is valid. In addition to letters,
':' indicates that there is no author, '%' indicates that
the code may be dodgy.

=cut

sub _verify_initial {
  my $self = shift;
  my $i = shift;
  return ( ($i =~ /^[A-Za-z:%]$/) ? $i : () );
}

=item B<_populate_journals>

Populate the internal journal code to journal name lookup table.

Also populates the ADS conference proceedings table.

=cut

sub _populate_journals {
  my $self = shift;

  # Buffer for concatenating journals that go over a single line
  my $jbuff = '';

  # Current journal code in "scope"
  my $current;

  # Read from data handle
  while (my $line = <DATA>) {
    next if $line =~ /^\#/;

    # This means we are at the end of the journals
    last if $line =~ /^=cut/;

    # Code is first 7 characters
    my $code = substr($line,0,7);
    $code =~ s/\s+$//;

    # Get the translation. Remove newline. remove trailing and leading space
    my $fullname = substr($line,7);
    chomp($fullname);
    $fullname =~ s/^\s+//;
    $fullname =~ s/\s+$//;

    # Do we have a code? If yes, clear previous buffer
    if (length($code)) {
      # Update the new current value
      my $old = $current;
      $current = $code;

      # if we have a previous entry, store it and reset the buffers
      $JOURNALS{$old} = $jbuff if ($old && $jbuff);
      $jbuff = '';

    }

    # Append to buffer, making sure we have a space if concatenating
    $jbuff .= " " if $jbuff;
    $jbuff .= $fullname;

  }

  # Leftover
  $JOURNALS{$current} = $jbuff if ($current && $jbuff);

  # Now try to populate the ADS lookup (if we have it in DATA
  # ADS bibcode is first 13 characters
  while (my $line = <DATA>) {
    next if $line =~ /^\#/;
    next if length($line) < 14;
    my $bcode = substr($line,0,13);
    my $conf  = substr($line,14);
    chomp($conf);
    $conf =~ s/^\s+//;
    $CONF_ADS{$bcode} = $conf;
  }

  return;
}

=back

=end PRIVATE__METHODS

=cut

# Really really private helper subs

# This subroutine cleans the supplied bibcode substring
# Remove "spaces" from the string (ie ".")

# Arg 1: The substring
# Arg 2: Justification for the string "L" or "R"

sub _clean_string {
  my $str = shift;
  my $j = uc(shift);

  if ($j eq 'L') {
    $str =~ s/\.+$//g;
  } elsif ($j eq 'R') {
    $str =~ s/^\.+//g;
  } else {
    croak "Internal error: Justification string was '$j' not L or R";
  }
  return $str;
}



=head1 REFERENCES

Details on the bibcode standard can be obtained from

 http://cdsweb.u-strasbg.fr/simbad/refcode.html

A complete description of the reference coding has been published as a
chapter of the book "Information & On-Line Data in Astronomy", 1995,
D. Egret and M. A. Albrecht (Eds), Kluwer Acad. Publ.

ADS seems to use non-standard bibcodes for meetings and conferences:

  http://adsabs.harvard.edu/abs_doc/conferences.html

ADS Journal codes are here:

  http://adsabs.harvard.edu/abs_doc/all_journals.html

but are not currently used.

=head1 NOTES

Currently the lookup tables for the journal translation and ADS conference
proceedings are embedded in the module. There is no facility for triggering
a remote update from the referenced web sites or for easily updating a
configuration file as new codes are issued. This will probably change in
future releases.

=head1 AUTHOR

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2004 Tim Jenness and the Particle Physics and
Astronomy Research Council.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=head1 SEE ALSO

L<Astro::ADS>

=cut

1;

# Note that some entries have been added that were not found on
# the CDS list but were found in some papers on ADS
#
#   OLEB
#
__DATA__
OLEB    Origins of Life and Evolution of the Biosphere
A&A     Astronomy and Astrophysics
AAA     Astronomy and Astrophysics Abstracts, Heidelberg
AAfz    Astrometriya i Astrofizika. Respublikanskij Mezhvedomstvennyj Sbornik
AAHam   Astronomische Abhandlungen der Hamburger Sternwarte
AAONw   Anglo-Australian Observatory Epping - Newsletter
AAOPr   Anglo-Australian Observatory Epping - Preprint
A&ARv   Astronomy and Astrophysics Review
AAS     American Astronomical Society meeting
A&AS    Astronomy and Astrophysics, Supplement Series
AASFA   Academia Scientiarun Fennica, Annales, Series A VI-Physica
AASPP   Astron. Astrophys. Serie, Ed. Pachart Publishing House Tucson
A&ASS   Astronomy and Astrophysics, Special Supplement Series
A&AT    Astronomical and Astrophysical Transactions (russe ?)
AbaOB   Abastumanskaya Astrofizicheskaya Observatoriya, Gora Kanobili, Byulleten
AbhKP   Stern-Katalog fur die Zone von -6 bis -10 Sudlicher Deklination fur das
        Aequinoktium 1890, erste und zweite Abteilung. Abh. Konigl. Preuss.
        Akad. Wissenschaften Jahre 1906,92, Berlin,1907
AcA     Acta Astronomica
AcApS   Acta Astrophysica Sinica (continued by ChJAA from 2001)
AcAS    Acta Astronomica Supplementa
AcASn   Acta Astronomica Sinica
AcC     Acta Cosmologica
ACiCh   Astronomical Circular
ACMan   Astronomical Contributions from the University of Manchester
AcMPh   Acta Universitatis Caroliae. Mathematica et Physica
AcPhA   Acta Physica Austriaca
AdA&A   Advances in Astronomy and Astrophysics
ADS     New general catalogue of double stars whitin 120 of the north pole.
        Carnegie Inst. Washington D.C. Publ. 417,1932
ADUrb   University of Illinois. Astronomy Department, Urbana Illinois
AExpr   Astronomy Express
AFGL    The AFGL four-color infrared sky survey. AFGL-TR-0208 Environemental
        Research papers,576,1976
AFOEV   Bulletin de l'Association Francaise d'Observateurs d'Etoiles Variables
Afz     Astrofizika
A&G     Astronomy and Geophysics (continuation from QJRAS from no 38 - 1997)
AGAb    Astronomische Gesellschaft, Abstract Series
AGDN    Atlas of galactic dark nebulae. Byull. Abastumansk. Astrofiz. Obs. (in
        Russian)
AGK2    Zweiter Katalog der Astronomische Gesellschaft. Hamburger Sternwarte
        Bergedorf,Bonn,1958
AGK3    AGK3 Catalogue 
AISAO   Astrofizicheskie Issledovaniya. Izvestiya Spetsial'noj Astrofizicheskoj
        Observatorii (continuation from 1993: BSAO)
AISof   Astrofizicheskie Issledovaniya - Sofia
AJ      The Astronomical Journal
AJa     Astronomischer Jahresbericht
AM      Catalogue of Southern Peculiar Galaxies, Cambridge Univ. Press
AN      Astronomische Nachrichten
AnAp    Annales d'Astrophysique
AnBes   Annales de l'Observatoire de Besancon
AnBos   Annals of the Bosscha Observatory Lembang (Java) Indonesia
AnCap   Annals of the Cape Observatory
AnDea   Annals of the Dearborn Observatory of Northwestern University
ANErg   Ergaenzungshefte zu den Astronomischen Nachrichten
AnHar   Annals of Harvard College Observatory
AnLei   Annalen van de Sterrewacht te Leiden
AnLun   Annals of the Observatory of Lund
ANote   Astronomical Notes - University of Gothenburg, Sweden, Section of
        Astronomy
AnPar   Annales de l'Observatoire de Paris
ANS     Astronomische Nachrichten Supplement
AnTok   Annals of the Tokyo Astronomical Observatory, Second Series
AnTou   Annales de l'Observatoire Astronomique et Meteorologique
AnWie   Annalen der Universitaets-Sternwarte Wien
ANZi    Beobachtungs-Zirkular der Astronomischen Nachrichten
Ap      Astrophysics
APh     Astroparticle Physics
ApJ     The Astrophysical Journal
ApJS    The Astrophysical Journal, Supplement Series
ApL     Astrophysical Letters (continued by Astrophysical Letters &
        Communications from vol. 26)
ApL&C   Astrophysical Letters & Communications (following from ApL, till vol.
        26)
ApNr    Astrophysica Norvegica. (Oslo) (continuation of "University Observatory,
        Oslo, publication")
Ap&SS   Astrophysics and Space Science
ApSSS   Astrophysics and Space Science Supplement
APZG    Accurate positions of Zwicky galaxies. 1988
A&R     Astronomie und Raumfahrt
ArA     Arkiv foer Astronomi
ARA&A   Annual Review of Astronomy and Astrophysics
ARBei   Astrophysics Reports - Publications of the Beijing Astronomical
        Observatory (see PBeiO)
ARep    Astronomy Reports (English translation of "Astronomicheskij Zhurnal",
        continuation of "Soviet Astronomy" from vol.37)
ARKod   Annual Report of the Kodaikanal Observatory
ArMAF   Arkiv for Matematik, Astronomi och Fysik utgifvet af K. Svenska
        Vetenskaps-Akademien
ArmOL   Armagh Observatory - Leaflet
ArS     Archives des Sciences
asp     Astronomy of star positions
ASPC    ASP Conference Series
ASSF    Acta Societatis Scientarum Fennicae (Finland)
ASSFA   Acta Societatis Scientarum Fennicae (Finland), Nov. Ser. A
ASSU    Annual Scientific Supplement to Urania
Ast     Astronomy
AstAp   Astronomy and Astro-Physics
Aster   Aster
AstL    Astronomy Letters (English translation of "Pis'ma v Astronomicheskij
        Zhurnal", continuation of "Soviet Astronomy Letters")
Astrf   L'Astrofilo Bolletino Trimestral del Gruppo Astrofili Villaggio Sereno,
        Brescia
ASV     Atlas stellarum variabilium.
ATel    The Astronomer's Telegram
ATi     Astronomisk Tidsskrift
AtlSV   Specola Astronomica Vaticana - Atlas Stellarum Variabilium
AtlVS   Atlas Poiskovykh Kart Peremennykh Zvezd
ATsir   Astronomicheskij Tsirkulyar, Izdavaemyi Byuro Astronomicheskikh
        Soobshchenij Akademii Nauk SSSR
AtSV    Charts for Southern Variables
AUBas   Kataloge Photographischer und Photoelektrischer Helligkeiten von 25
        Galaktischen Sternhaufen im RGU und im UcBV-System. Ed.: W. Becker, S.
        N. Svolopoulos, C. Fang. Publ.: Separate Print Astron. Inst. Univ.
        Basel, 89pp., 1976.
AuJPA   Australian Journal of Physics, Astrophysical Supplement
AuJPh   Australian Journal of Physics
AuJSA   Australian Journal of Science Res. serie A 5
AVSOA   American Association of Variable Stars Observers - Abstracts
AVSOM   American Association of Variable Stars Observers, Monographs
AVSOQ   American Association of Variable Stars Observers - Quarterly Reports
AVSOR   American Association of Variable Stars Observers - Reports
AVSVB   Associazione Veneta Osservatori di Stelle Variabili - Bulletin
AZh     Astronomicheskij Zhurnal (translation in Astronomy Reports)
BAAA    Boletin de la Asociacion Argentina de Astronomia, La Plata, Argentina
BAAS    Bulletin of the American Astronomical Society
BAICz   Bulletin of the Astronomical Institutes of Czechoslovakia
BaltA   Baltic Astronomy
BamKV   Bamberg Kleine Veroeffentlichungen der Remeis-Sternwarte
BamVe   Bamberg Veroeffentlichungen der Remeis-Sternwarte
BAN     Bulletin of the Astronomical Institutes of the Netherlands
BANS    Bulletin of the Astronomical Institutes of the Netherlands, Supplement
        Series
BAOM    Boletin Astronomico del Observatorio de Madrid
BAORB   Bulletin Astronomique. Observatoire Royal de Belgique(Astronomisch
        Bulletin. Koninklijke Sterrenwacht van Belgie)
BAPS    Bulletin de l'Academie Polonaise des Sciences. Serie des Sciences
        mathematiques, astronomiques et physiques, Warsaw
Bar1K   Barcelone (INCA)
BARB    Bulletin de l'Academie Royale de Belgique (Classe des Sciences)
Barn    A photographic Atlas of selected regions of the Milky Way. Carnegie
        Inst. Washington D.C. Publ.,1927
BASI    Bulletin of the Astronomical Society of India
BAth    National Observatory of Athens, Greece - Bulletin of the Astronomical
        Institute
BAVSM   Berliner Arbeitsgemeinschaft fuer Veraenderliche Sterne - Mitteilungen
BAVSO   Bulletin of the American Association of Variable Stars Observers
BAVSR   BAV Rundbrief - Mitteilungsblatt der Berliner Arbeits-gemeinschaft fuer
        Veraenderliche Sterne
BBSAG   Bulletin der Bedeckungsveraenderlichen-Beobachter der Schweizerischen
        Astronomischen Gesellschaft
BCFHT   Bulletin d'information du telescope Canada-France-Hawaii
BCNRS   Bulletin Signaletique - Centre National de la Recherche Scientifique
BCrAO   Bull. Crimean Astrophys. Obs. (English translation of "IzKry")
BD      Bonner Durchmusterung des Nordlichen Himmels. Eds Marcus and Weber's
        Verlag, Bonn,1,1903
BDS     Burnham Double Star, Carnegie Institution of Washington Publication,
        Publ No.5, 2 volumes (1906)
BDus    Byulleten' Instituta Astrofiziki, Dushanbe - Akademiya Nauk Tadzhikskoj
        SSR
BeiRe   Reprints, Beijing Astronomical Observatory, Academia Sinica
Bes1K   Observatoire de Besancon (INCA)
BHarO   Bulletin of the Harvard College Observatory
BICDS   Bulletin d'Information du Centre de Donnees Stellaires
BID1    #Bidon1
BIMAF   Boletin del Instituto de Matematica, Astronomica y Fisica - Universidad
        Nacional de Cordoba, Argentina
BITA    Byulleten' Instituta Teoreticheskoj Astronomii (Leningrad)
BITon   Boletin del Instituto de Tonantzintla
BKoAS   Bulletin of Korean Astronomical Society
BKobO   Bulletin of the Kobe Marine Observatory, Kobe, Japan
BMai    Bulletin de la Station Astrophotographique de Mainterne
bmtm    Blazar Monitoring towards the Third Millennium, Proceedings of the OJ-94
        Annual Meeting 1999, held in Torino, Italy, May 19-21, 1999, Eds.: C.M.
        Raiteri, M. Villata, and L.O. Takalo, Osservatorio Astronomico di
        Torino, Pino Torinese, Italy.
BOBeo   Bulletin de l'Observatoire Astronomique de Belgrade (ISSN: 0354-2955)
        (continued by Serbian Astronomical Journal, since No 158 Jan 1998)
BOOde   Odesskij Gosudarstvennyi Universitet im. I. I. Mechnikova - Byulletin'
        Astronomicheskoj Observatorii
BOPul   Bulletin (Izvestiya) de l'Observatoire Central a Poulkovo
BOTor   Biuletyn Obserwatoium Astronomicznego Uniwersytetu M. Kopernika w
        Toruniu
BOTT    Boletin de los Observatorios Tonantzintla y Tacubaya
BPM     Bruce proper motion survey. The general catalogue (vol 1,2). The
        Observatory, Univ. Minnesota, Minneapolis,1963
BPMS    Bruce proper motion survey. The general catalogue. Vol. I, II. By W.J.
        Lyuten. University of Minnesota,  Minneapolis, 1963.
Brun    Atlas des 139 "Selected Areas" du Mt Wilson, Obs. Lyon, St Genis-Laval
BS      The Bright Star Catalogue
BSAO    Bulletin of the Special Astrophysical Observatory, Russia (continuation
        of AISAO from 1993)
BSD     Bergedorfer Spectral-Durchmusterung der 115 noerdlichen Kapteynschen
        Eichfelder. By A Schwassmann and P.J. van Rhijn. Publ.: Hamburger
        Sternwarte in Bergedorf, 1935-1953.  vol. 1 : 1935 vol. 2 : 1938 vol. 3
        : 1947 vol. 4 : 1951 vol. 5 : 1953 Zweiter Katalog der Astronomische
        Gesellschaft. Ed.: R. Schorr and A. Koschoutter. Publ.: Hamburger
        Sternwarte Bergedorf, Bonn, 1958.
BSRSL   Bulletin de la Societe Royale des Sciences de Liege
BStaO   Byulleten' Stalinabadskoj Astronomicheskoj Observatorii - Akademiya Nauk
        Tadzhikskoj SSR -
BSVIt   Bolletino della Societa dei Variabilisti Italiani
BYam    Bulletin of the Yamagata University, Yamagata, Japan
ByuPr   Byurakanskaya Astrofizicheskaya Observatoriya - Preprint
ByuRe   Byurakan Astrophysical Observatory, Armenia, USSR, Reprints
C4CP    The 4CP survey. Ph. D. Dissertation Univ. Cambridge UK,1966 (XXEH)
CAFOE   Circulaire de l'Association Francaise d'Observateurs d'Etoiles Variables
CamRe   Cambridge Observatories - Reprints
CapMi   Royal Observatory Cape Mimeogram
CarOB   Carter Observatory, Wellington, New Zealand - Astronomical Bulletins
CarRe   Carter Observatory, Wellington, New Zealand - Reprints
CasRe   Case Western Reserve University, Warner and Swasey Observatory,
        Cleveland , Ohio - Reprints
CBVMS   Catalogue of BV magnitudes and spectral classes for 6000 stars.
CCDA    CCD Astronomy (Sky Publishing Corp., Cambridge, Mass.)
CCNRS   Colloque International CNRS - Review Paper
CDT     Connaissance des Temps
C&E     Ciel et Espace
CED27   Observatoire de la Cote d'Azur, Departement: Augustin FRESNEL URA 1361,
        2eme Edition
CF      Catalogue of 20554 faint stars in the Cape astrographic zone -40 to -52
        for the equinox of 1900.0, Royal Obs. Cape of Good Hope. London (on
        magnetic tape),1939
CfAPr   Center for Astrophysics, Cambridge, Mass. - Preprint Series
CFHTQ   CFHT - Blue grens quasar candidates (Modified version of tables 2 and 3
        of Crampton, et al., 1992, AJ, 104, 1706)
CfMil   Conferenze dell'Osservatorio Astronomico di Milano-Merate
CGCG    Catalogue of Galaxies and of Clusters of Galaxies. By F. Zwicky et al.
        Publ.: California Institute of Technology, vol. 1 -1961 , vol.2 -1963,
        vol.3 -1966, vol 4 -1968, vol. 5 -1965, vol.6 -1968.
CGMW    Catalog of galaxies behind the milky way (magnetic tape).
CGPG    Published by F. Zwicky, Guemligen (BE), Switzerland.
ChA&A   Chinese Astronomy and Astrophysics
ChJAA   Chinese Journal of Astronomy and Astrophysics (continuation of AcApS
        from 2001)
CiBAA   Circular of the British Astronomical Association
CiSSV   Circolare Interna della Sezione Stelle Variabili dell'Unione Astrofili
        Italiani
CiUO    Circular of the Union Observatory, Johannesburg (continued by ROCi,
        vol.7 (1962))
CIWP    Carnegie Institution of Washington Publication
clts    Colloquium on late-type stars. Conf. Proc. Trieste, 13-17 June 1966. Ed.
        M. Hack, 1967
CMC     Carlsberg Meridian Catalogs Number 1-11 (1999). Copenhagen University
        Observatory, Royal Greenwich Observatory and Real Instituto y
        observatorio de la Armada en San Fernando.
cmrs    Proceedings of the AAS-NASA Symposium on the Magnetic and Other Peculiar
        and Metallic A-line stars, held at Greenbelt, MD, 8-10 November 1965.
        Ed. R.C. Cameron. Publ. Mono Book Corp., Baltimore, 1967
CoAnk   Communications of the Department of Astronomy of Ankara University
CoArm   Contributions from the Armagh Observatory
CoAsi   Contributi dell'Osservatorio Astrofisico dell'Universita di Padova in
        Asiago
CoAth   Contributions from the Research and Computing Center Academy of Sciences
        of Athens - Series I (Astronomy)
CoBos   Contributions from the Bosscha Observatory
CoBrn   Contributions of the Public Observatory and Planetarium in Brno
CoCam   Contributions from the Cambridge Observatories (England)
CoCDS   Contributions from the Centre de Donnees de Strasbourg (CDS)
        (vizier.u-strasbg.fr/CoCDS)
CoCoi   Comunicacoes do Observatonio Astronomico da Universidade de Coimbra
CoDAO   Contributions from the Dominion Astrophysical Observatory Victoria
CoDDO   Communications from the David Dunlap Observatory, Richmond Hill,
        Ontario, Canada -  University of Toronto
CoDun   Contributions from the Dunsink Observatory, Dublin, Ireland
Coel    Coelum - Periodico Bimestrale per la Divulgazione dell'Astronomia
CoFra   Consiglio Nazionale delle Ricerche (Italia). Laboratorio di Astrofisica,
        Frascati (Roma), Contributi
CoIAB   Contributions de l'Institut d'Astrophysique de Paris. Serie B.
CoIAP   Contributions de l'Institut d'Astrophysique de Paris. Serie A.
CoIoa   Contributions from the Laboratory of Astronomy - University of Ioannina,
        Greece
CoKit   Contributions from the Kitt Peak National Observatory
CoKon   Communications from the Konkoly Observatory of the Hungarian Academy of
        Sciences, Budapest, Hungary (continuation of MiBud since 1981)
CoKwa   Contributions from the Kwasan and Hida Observatories, University of
        Kyoto
CoKyo   Contributions from the Institute of Astrophysics and Kwasan Observatory,
        Kyoto, Japan -  University of Kyoto
CoLic   Contributions from the Lick Observatory
CoLon   Communications from the University of London Observatory. Mill Hill
        Park, London . (Irregularly).
CoLou   Contributions of the Louisiana State University Observatory, Baton
        Rouge, Louisiana
CoLPL   Communications of the Lunar and Planetary Laboratory(Tucson)
ComAp   Comments on Astrophysics
CoMcD   Contributions from the McDonald Observatory - The University of Texas,
        Fort Davis, Texas
CoMil   Contributi dell'Osservatorio Astronomico di Milano-Merate. Nuova Series
CoMtW   Contributions from the Mount Wilson Observatory
CoNMx   Contributions of the Observatory of New Mexico State University, Las
        Cruces, New Mexico
CoORB   Communications de l'Observatoire Royal de Belgique
CoOxf   Communications from the University Observatory, Oxford
Cop1K   Copenhagen (INCA)
CoPer   Ohio State and Wesleyan Universities - Contributions from the Perkins
        Observatory, Delaware, Ohio
CopRe   Copenhagen University Observatory, Reprints
CoRad   Communications from the Radcliffe Observatory, Pretoria, South Africa
CoRHO   Contributions - University of Florida, Rosemary Hill Observatory,
        Department of Physics and Astronomy, Gainesville, Florida
CoROE   Communications from the Royal Observatory, Edinburgh
CorTi   Tirada Aparte - Universidad Nacional de Cordoba, Argentina -
        Observatorio Astronomico
CoRut   Contributions from the Rutherford Observatory of Columbia University,
        New York
CoSka   Contributions of the Astronomical Observatory Skalnate Pleso
CoStA   Communications from the University Observatory, ST Andrews, Scotland
CoSte   Contributions - University of Arizona, Steward Observatory, Tucson,
        Arizona
CoThe   Contributions from the Astronomical Department of the University of
        Thessaloniki
CoTok   Contributions from the Department of Astronomy -  University of Tokyo
CoTol   Contributions from the Cerro Tololo Inter-American Observatory
CoTor   Contributi dell'Osservatorio Astronomico di Torino, Pino Torinese
CoUCL   Contributions - Universite Catholique de Louvain
CoVVO   Contributions from the Van Vleck Observatory
CoWat   Contributions of the University of Waterloo Observatory, Waterloo,
        Ontario, Canada
CoWro   Contributions from the Wroclaw Astronomical Observatory
CR      C.R. Acad. Sci. (serie non specifiee)
CR2     Comptes Rendus Hebdomadaires des Seances de l'Academie des Sciences.
        Serie II
CR4     Comptes Rendus Hebdomadaires des Seances de l'Academie des Sciences.
        Serie IV
CRA     Comptes Rendus Hebdomadaires des Seances de l'Academie des Sciences.
        Serie A.
CraR    Polskie Towarzyslwo Milosnikow Astronomii (Polskie Amateur Astronomical
        Society), Krakow - The Astronomical Reports
CraRe   Cracow Observatory - Reprints
CRB     Comptes Rendus Hebdomadaires des Seances de l'Academie des Sciences.
        Serie B.
CRJS    Comptes-Rendus sur les Journees de Strasbourg, 3eme Reunion
CSCA    Catalogue of star clusters and associations + supplements [OCL]. Akad.
        Kiado, Budapest, Hungary, 3086 p., 2nd edition,1970
CSCAS   Catalogue of stars clusters and associations. Suppl. 1 to the 2nd
        edition [OCL]. Akad. Kiado, Budapest, Hungary,1981
CSRV    Catalog of Stellar Radial Velocities. Ed.: D.S. Evans. Publ.: published
        on microfiche by "Centre de donnees Stellaires", Strasbourg, 1979. ( See
        also IAU Symp. No 30, 57) cf 79.32041 (IAU Symp. No 30, 57). Il s'agit
        d'un article, pas du catalogue.
CSV     Catalogue of suspected variable stars.
C&T     Ciel et Terre
CVSS1   1st Supplement to the 3rd edition of the General Catalogue of variable
        stars. USSR Acad. Sciences,1973
CZC     R. Obs., Cape of Good Hope, London,71,418,1923
DCFRS   Dearborn Catalogue of faint red stars - Annals of the Dearborn
        Observatory of Northwestern University, Vol 5 fasc. 1A (1943), fasc. 1B
        (1944), fasc. 1C (1947)
DDA     AAS/Division of Dynamical Astronomy meeting
DDORe   David Dunlap Observatory, Richmond Hill - Reprints
DeaCo   Lindheimer Astronomical Research Center - Dearborn Observatory,
        Evanston, Illinois - Contributions
DGS75   La dynamique des galaxies spirales. Colloque international C.N.R.S.
        241,pp
DoArm   Doklady - Akademia Nauk Armanskoj SSR
DOCi    Documentation des Observateurs - Circulaire
DOIAP   Documentation des Observateurs. Institut d'Astrophysique de Paris
DoSSR   Doklady - Akademia Nauk SSSR
DPS     AAS/Division for Planetary Science meeting
DudOR   Dudley Observatory, Albany, New York - Reports
DudRe   Dudley Observatory, Albany, New York - Reprints
DunOP   Dunsink Observatory, Dublin, Ireland - Publications
DunRe   Dunsink Observatory, Dublin, Ireland - Reprints
DyeRe   Reprint Series - Vanderbilt University. The Arthur J. Dyer Observatory,
        Nashville, Tennessee
EASPS   EAS Publications Series
EBCi    Eclipsing Binaries Circulars - Polska Akademia Nauk, Krakow
EcGou   Comptes Rendus de l'Ecole de Goutelas
EgUBV   Catalogue of Eggen's UBV data, unpublished
EJPh    European Journal of Physics
EL      Europhysics Letters, European Physical Society
EM&P    Earth, Moon, and Planets
Endvr   Endeavour New Series
epu     Evolutionary Phenomena in the Universe. In honour of the 80th birthday
        of Livio Gratton, Rome 24-26 October 1990. Ed. P. Gioannone, F.
        Melchiori, F. Occhionero. Publ. Soc. Ital. Fisica, Bologna, 1991
ESA7    Proceedings of the 7th ESA Symposium on European Rocket & Balloon
        Programmes and related research. Loen, Norway 5-11 may 1985 ESA SP-229
ESO     The ESO/Uppsala Survey of the ESO(B) Atlas (1982) Ed. Lauberts A. Pub.
        ESO
ESO83   Primordial Helium. Proc. of an ESO workshop held in Garching,
        F.R.Germany, 2-3 Feb. 1983. Eds P.A. Shaver, D. Kunth, K. Kjar.
ESOAR   European Southern Observatory - Annual Reports
ESOB    European Southern Observatory - Bulletin
ESOLV   The Surface Photometry Catalogue of the ESO-Uppsala Galaxies. Ed.
        Lauberts A. and Valentijn E. A. Pub. ESOi (1989)
ESOPN   Strasbourg-ESO Catalogue of Galactic Planetary Nebulae (ISBN
        3-923524-41-2)
ESOSP   European Southern Observatory - Scientific Preprints
ESOSR   European Southern Observatory - Scientific Report
ExA     Experimental Astronomy
EXOSA   EXOSAT Express. ESA, EXPSAT Observatory
FA90    Proceedings of a Workshop held in Beijing, 30 Oct-6 Nov. 1992, Ed. Li
        Qibin, Publ. World Scientific: "Frontiers of Astronomy in 1990s" ISBN
        981-02-1514-2
FCPh    Fundamentals of Cosmic Physics
F&CRe   Reprints - University of Pennsylvania, Flower and Cook Observatory,
        Philadelphia, Pennsylvania
FoPh    Foundations of Physics
GC      General Catalogue of 33342 Stars for the Epoch 1950. Ed.:B. Boss. Dudley
        Observatory, Albany, New York. Publ.: Carnegie Institution of
        Washington, Washington D.C., Publ. No 468, vol. 1-5, 1937.
GCCat   Carnegie Inst. Washington D.C. Publ.,1933
GCCat   Carnegie Inst. Washington D.C. Publ.,1937
GCCCS   A general catalog of cool galactic carbon stars, second edition. Publ.
        Warner & Swasey Obs. 3, %2%  = 0,1989
GCN     Gamma-ray Burst Coordinates Networks, Circular Service
        (vizier.u-strasbg.fr/local/cgi-bin/GCN)
GCRV    Carnegie Inst. Washington D.C. Publ. 601
GCTP    General Catalogue of Trigonometric Stellar Parallaxes
GCVS1   Catalogue of suspected variable stars. Moscow, Acad. of Sciences USSR
        Shternberg,1951
GCVS2   General Catalogue of Variable Stars,1958
GCVS3   General Catalogue of Variable Stars. Ed.: B.V. Kukarkin et al. Sternberg
        State Astronomical Institut. Publ.: Astronomical Council of the Academy
        of Sciences in the USSR, Moscow, 1948 (1st ed.), 1958 (2nd ed.),
        1969-1971 (3rd ed.).  First Supplement to the third edition of the
        General Catalogue of Variables Stars. Ed.: B.V. Kukarkin et al.. Publ.
        Astronomical Council of the Academy of Sciences in the URSS, Moscow,
        1973.
GCVS4   Combined General Catalogue of Variable Stars (1998), 4.1 Ed (II/214A).
        Kholopov P.N. et al.
Gemin   Gemini. Newsletter of the Royal Greenwich Observatory
Gen1K   Observatoire de Geneve (INCA)
GeoOM   Georgetown Observatory Monograph
GeoRe   Georgetown Observatory - Reprints
GEOSC   GEOS Circular on Eclipsing Binaries - Group: Etude et Observation
        Stellaire, Paris
GEOSN   GEOS Note Circulaire - Group: Etude et Observation Stellaire, Paris
GICi    Gruppo Italiano RV Tauri - Circolare (Massa)
GLORe   Goethe Link Observatory of Indiana University, Bloomington, Indiana -
        Reprints
Gmb     New reduction of Groombridge's catalogue of circumpolar stars.
        Proceeding of the Royal Soc. Edinburgh,1905
GriO    Griffith Observer
GRO1B   First BATSE Catalog.
GRO2B   Second BATSE Catalog.
GroR    Kapteyn Astronomical Laboratory, Groningen, Nederlandse Vereniging voor
        Weer - en Sterrenkunde - Reports
GSC1    The HST Guide Star Catalog Version 1.1 (I/220)
GUL     Geschichte und Lichtwechsel der Veraenderlichen Sterne (Potsdam)
HalAR   Hale Observatories, Pasadena, California - Annual Report of the Director
HalRe   Hale Observatories, Pasadena, California - Reprints
HamS    Hamburger Sternwarte - Sonderdrucke
HarAC   Harvard College Observatory. Announcement Card
HarCi   Harvard College Observatory Circular
HarRe   Harvard College Observatory - Reprints
HarZi   Harthaer Beobachtungs-Zirkular
HawRe   Reprints - University of Hawaii, Institute for Astronomy
HD      The Henry Draper Catalogue. Ed.: A.J. Cannon and E.C. Pickering. Annals
        of the Astronomical Observatory of Harvard College, vol. 91-99.
        Corrected version available on magnetic tape and microfiches at the
        Centre de Donnes Stellaire de Strasbourg.
HEAO2   Einstein Observatory Unscreened IPC Data Archive, Ed. J. McDowell, D.
        Plummer, A. Prestwich, K., Manning, D. Van Stone, M. Garcia, SAO HEAD
        CD-ROM Series I, Nos 18-36
HelOB   Helwan Institute of Astronomy and Geophysics (Helwan Observatory) -
        Bulletins
HelR    Observatory and Astrophysics Laboratory, University of Helsinki, Report
HelRe   Astronomical Observatory, Helsinki, Finland - Reprints
HemD    Hemel en Dampkring
HIP     The Hipparcos and Tycho Catalogues, ESA SP-1200 (I/239)
H&RHI   A general catalog of HI observations of galaxies, 1989, New York:
        Springer-Verlag
HvaOB   Hvar Observatory Bulletin - Zagreb
IAFET   Instituto de Astronomia y Fisica del Espacio, Buenos Aires, Argentina -
        Tirada Aparte
IAL1K   Institut d'Astronomie de Lausanne (INCA)
IAUC    International Astronomical Union, Circular
IAUCL   International Astronomical Union, Commission 27 on Variable Stars -
        Circular Letter
IAUCo   IAU Colloquia
IAUDS   Information Circular of IAU Commission 26 (Double Stars)
IAUEB   International Astronomical Union, Commission 42, - Bibliography and
        Program Notes on Eclipsing Binaries
IAUIB   International Astronomical Union, Information Bulletin
IAUS    IAU Symposia
IAUT    Transactions of the International Astronomical Union
IBSH    Information Bulletin for the Southern Hemisphere
IBVS    Information Bulletin on Variable Stars
Icar    Icarus
IDS     Index Catalogue of Visual Double Stars. Publ. Lick Obs. 21,part 1,1963
IERSA   International Earth Rotation Service - Annual Report (Obs. Paris)
IIApN   Indian Institute of Astrophysics,  Newsletter
INGN    The Isaac Newton Group of Telescopes Newsletter
IRA     Infrared Astronomy (NB: pas trouve dans la litterature)
IrAJ    Irish Astronomical Journal
IRAS    IRAS Catalogue and Atlases. Vol. I. Explanatory Supplement
IRASF   IRAS Faint Source Catalogue, version 2.0
IRASG   Cataloged Galaxies and Quasars observed in the IRAS Survey. Version 2.
        JPL D-1932
IRASP   IRAS Point Source Catalog - Version 2.0, NASA RP-1190 (1988), Vol. 2, 3,
        4, 5, 6
IRC     Two micron sky survey : A preliminary Catalogue. Calif. Inst.
        Technology, NASA,1969
ISKZ    Issledovaniya Solntsa i Krasnykh Zvezd.(Investigations of the Sun and
        Red Stars)
IUE80   IUE82   IUE84   IUE88   IUE2n   IUE3r   SBS80   Photometric and
        spectroscopic binary systems. Proc. the NATO Advanced Study Inst. held
        at Maratea, Italy, June 1-14, 1980. Ed.Carling E.B., Kopal Z. Series C,
        Vol 69,pp
IUEEN   IUE ESA Newsletter
IUEML   The IUE Merged Log -- not yet the Final Archive, years 1978-1994
IUENN   IUE NASA Newsletter
IzAlm   Izvestiya Astrofizicheskogo Instituta, Alma-Ata - Akademiya Nauk
        Kazakhskoj SSR, Alma-Ata
IzAne   Izvestiya na Fizicheskiya Institut s Aneb
IzArm   Izvestiya Akademiya Nauk Armyan. SSR
IzAsh   Izvestiya Akademii Nauk Turkmenskoj SSR, Ashkhabad
IzKaz   Izvestiya Astronomicheskoj Engel'gardt obskoj Observatorii, Kazan
IzKie   Izvestiya Glavnoj Astronomicheskoj Observatorii - Kiev, Akademiya Nauk
        Ukrainskoj SSR
IzKry   Izvestiya Ordena Trudovogo Krasnogo Znameni Krymskoj Astrofizicheskoj
        Observatorii (translated in BCrAO)
IzmP    Ege University, Izmir - Publications of the Department of Astronomy
IzOde   Odesskij Gosudarstvennyi Universitet im. I. I. Mechnikova - Izvestiya
        Astronomicheskoj Observatorii
IzPul   Izvestiya Glavnoj Astronomicheskoj Observatorii v Pulkove
JAD     The Journal of Astronomical Data
JAF     Journal des Astronomes Francais
JApA    Journal of Astrophysics and Astronomy
JASAC   Japan Astronomical Study Association - Circulars
JASEg   Journal of the Astronomical Society of Egypt
JASV    Journal of the Astronomical Society of Victoria, Melbourne
JAVSO   Journal of the American Association of Variable Stars Observers
JBAA    Journal of the British Astronomical Association
JBAn    Astronomical Contributions from the University of Manchester - Jodrell
        Bank Annals
JBIS    Journal of the British Interplanetary Society
JBRe    Astronomical Contributions from the University of Manchester - Jodrell
        Bank Reprints
JHA     Journal for the History of Astronomy
JKoAS   Journal of Korean Astronomical Society
JO      Journal des Observateurs
JOp     Journal d'Optique
JQSRT   Journal of Quantitative Spectroscopy and Radiative Transfer
JRASC   Journal of the Royal Astronomical Society of Canada
JRASN   Southern Stars - The Journal of the Royal Astronomical Society of New
        Zealand
JWasA   Journal of the Washington Academy of Sciences
KazOB   Astronomicheskoj Observatorii im V.P. Engel'gardta, Kazan - Byulleten'
KFNT    Kinematika Fizika Nebesnykh Tel. (Kiev)
KiePr   Kievskij Ordena Lenina Gosudarstvennyj Universitet im. T.G. Shevchenko -
        Astronomicheskaya Observatoriya - Preprint
KodOB   Kodaikanal Observatory Bulletins, Serie A
KodRe   Kodaikanal Observatory - Reprints
KoIs    Kosmiceskie Issledovania (Cosmic research), ISSN 0023-4206
Kozmo   Kozmos - Popular Astronomical Journal of the Slavak Central Observatory
        in Hurbanovo
KSVH    Kungl. Svenska Vetenskapsakademiens Handlingar
KVeBB   Kleine Veroeffentlichungen der Universitaetssternwarte zu Berlin-
        Babelsberg
Lalan   A catalogue of those stars in the 'Histoire Celeste Francaise' of J. de
        Lalande for which tables of reduction to the epoch 1800 have been
        published by Prof. Schumacher.  British Ass. Adv. Sci., London,1,1847.
LASP    Leaflet of the Astronomical Society of the Pacific
LAstr   L'Astronomie
LB      A search for faint blue stars [LB]. The Observatory, Univ. Minnesota,
        Minneapolis
LCVS    Lightcurve N.W.A.V.S.O. (North Western Association of Variable Star
        Observers)
LEDA    Lyon-Meudon extragalactic Database
Lei1K   Leiden (INCA)
LFT     Luyten's Five Tenths. Lund Press, Minneapolis, Minnesota,1955
LHS     A catalogue of stars with proper motion > 0''.5 annually. Univ.
        Minnesota,1976
LicOB   Lick Observatory Bulletin
Lie57   Communications Presentees au Huitieme Colloque International
        d'Astrophysique Tenu a Liege les 8,9 et 10 Juillet 1957,
        Cointe-Sclessin, Belgique
Lie81   Proceedings of the 23rd Liege International Astrophysical Colloquium.
        June 23-26, 1981. "Chemically peculiar stars of the upper main
        sequence", Ed. ???
Lie83   Proceedings of the 24th Liege International Astrophysical Colloquium.
        June 21-24, 1983. "Quasars and gravitational lenses"
Lie93   Proceedings of the 31st Liege International Astrophysical Colloquium.
        June 21-25, 1993. "Gravitational lenses in the universe". Ed. Surdej J.,
        Fraipont-Caro D., Gosset E., Refsdal S., Remy M.
LLS     Low Luminosity Stars- Kumar Ed. Gordon., Breach, 1969,139,1969
LLS69   Proceeding of the symposium on Low Luminosity Stars, ed. Kumar, Publ.
        Gordon and Breach, 1969
LNP     Lecture Notes in Physics
LNP87   Proc. fifth Cambridge Workshop on cool stars, stellar systems, and the
        Sun held in Boulder, Colorado, july 7-11, 1987. Eds Linsky J.L., Stencel
        R.E. Lecture notes in physics
LNP96   "Supersoft X-ray Sources", Proceedings of the International Workshop
        held in Garching, Germany, 28 Feb to 1 March 1996, Ed. Jochen Greiner,
        Springer (ISBN 3-540-61390-0)
LowOB   Lowell Observatory Bulletin
LowPM   Lowell Proper Motion Survey. The G numbered stars.
LPlaC   Observatorio Astronomico de la Universidad Nacional de la Plata - Serie
        Circular
LPlaS   Observatorio Astronomico, La Plata - Separata Astronomica
LS      Luminous Stars in the Nothern Milky Way. Ed.: Hamburger Sternwarte,
        Warner and Swasey Observatory. Publ.: Hamburg-Bergedorf, 1959-1965.
        Part I. 1959  (59.20802) Part II. 1960 (60.20801) Part III.
        1964(64.30012) Part IV. 1963 (63.30012) Part V. 1965  (65.30012) Part
        VI. 1965 (65.30011)
LTT     Luyten's Two Tenths. A catalogue of 9867 stars in the southern
        hemisphere with proper motion >0''.2 annually. Lund Press, Minneapolis,
        Minnesota,1957.
LTTN    Lund Press, Minneapolis, Minnesota,1961
LTTS1   First supplement to the LTT catalogue. The Observatory, Univ. Minnesota,
        Minneapolis,1962
Lub75   Proceedings of the Southwest Regional Conference for Astronomy and
        Astrophysics (Lubbock, Texas, July 12, 1975)
LuyWD   White Dwarfs. Univ. Minnesota, Minneapolis,1970
LvoTs   L'vovskij Ordena Lenina Gosudarstvennyj Universitet im. Ivana Franko -
        Tsirkulyar
LyoRe   Observatoire de Lyon -Reprints
MAUTx   University of Texas - Monographs in Astronomy
MCG     Morphological catalogue of galaxies. Part 1: 1962, Part 2: 1964, Part 3:
        1963, Part 4: 1968, Part 5: 1974. Vorontsov-Vel'Yaminov B.A., Arkhipova
        V.P. Moscow State University.
MeAar   Meddelelser fra Ole Romer Observatoriet, Aarhus
MeeRe   Reprints - University of Rochester, C.E. Kenneth Mees Observatory,
        Rochester, New York
MeGen   Mededelingen - Universiteit te Gent, Sterrenkundig Instituut
MeLeu   Mededelingen van het Astronomisch Instituut van de Katholieke
        Universiteit, Leuven
MeLu1   Meddelanden fran Lunds Astronomiska Observatorium, Serie I
MeLu2   Meddelanden fran Lunds Astronomiska Observatorium, Serie II
Mercu   Mercury
MerRe   Instituto Venezolano de Astronomia, Merida, Venezuela
Meteo   De Meteoor
Meu1K   Observatoire de Meudon (INCA)
MeUpp   Meddelanden fran Astronomiska Observatorium Uppsala
MiARB   Astronomisches Rechen-Institut Heidelberg, Mitteilungen Serie B
MiARI   Astronomisches Rechen-Institut Heidelberg, Mitteilungen Serie A
MiBas   Mitteilungen der Astronomisch-Meteorologischen Anstalt der Universitaet
        Basel. Astronomische Reihe
MiBon   Mitteilungen der Astronomischen Institute der Universitaet Bonn
MiBud   Mitteilungen der Sternwarte der Ungarischen Akademie der Wissenschaften,
        Budapest (Budapest - Szabadsaghegy)(continued by CoKon after 1980)
MicRe   Reprints from the Observatory of the University of Michigan, Ann Arbor
MiGra   Mitteilungen der Universitaets-Sternwarte Graz
MiHam   Mitteilungen der Hamburger Sternwarte in Bergedorf
MiHar   Mitteilungen der Bruno-H.-Buergel-Sternwarte, Hartha, DDR
MiHei   Mitteilungen der Landessternwarte Heidelberg-Koenigstuhl
MiInn   Mitteilungen der Sternwarte Innsbruck
MiJen   Mitteilungen der Universitaets-Sternwarte zu Jena
MiMue   Mitteilungen des Astronomischen Instituts des Universitaet Munster
MiMun   Mitteilungen der Sternwarte Munchen
MiPot   Mitteilungen des Astrophysikalischen Observatoriums, Potsdam
MiSon   Mitteilungen der Sternwarte zu Sonneberg
MitAG   Mitteilungen der Astronomischen Gesellschaft, Hamburg
MiTau   Zentralinstitut fuer Astrophysik - Mitteilungen des Karl-Schwarzschild-
        Observatoriums Tautenburg
MiTue   Mitteilungen des Astronomischen Instituts der Universitaet Tuebingen
MitVS   Zentralinstitut fuer Astrophysik, Sternwarte Sonneberg - Mitteilungen
        ueber Veraenderliche Sterne
MiVSS   Zentralinstitut fuer Astrophysik, Sternwarte Sonneberg - Mitteilungen
        ueber Veraenderliche Sterne, Supplement Series
MiWie   Mitteilungen der Universitaets-Sternwarte Wien
MKAtl   An Atlas of stellar Spectra with an Outline of Spectral Classification.
        Ed.: W.W. Morgan, P.C. Keenan and E. Kellman. Publ.: Astrophysics
        Monographs, University Chicago Press, 1943.
MLS69   Mass Loss from Stars, ed. M. Hack
MmARB   Academie Royale de Belgique. Classe des Sciences - Memoires, Collection
        in 8
MmASI   Memoirs of the Astronomical Society of India
MmBAA   Memoirs of the British Astronomical Association
MmKyo   Memoirs College of Sciences, University of Kyoto, Serie A
MmMtS   Memoirs of the Mount Stromlo Observatory
MmRAS   Memoirs of the Royal Astronomical Society
MmSAI   Memorie della Societa Astronomica Italiana
MNRAS   Monthly Notices of the Royal Astronomical Society
MNSSA   Monthly Notes of the Astronomical Society of Southern Africa
MonAP   Communications du Departement d'Astrophysique de la Faculte des Sciences
        de Mons - Mons Astrophysical Papers
MPER    MPI fuer Extraterrestrische Physik Report
Msngr   Messenger - El Mensajero
MSRSL   Memoires de la Societe Royale des Sciences de Liege
MSS     Michigan Catalogue of Two-Dimensional Spectral Types for the HD Stars.
        Ed.: N. Houk. Publ.: Department of Astronomy University of Michigan, Ann
        Arbor , Michigan, 1978.
MSS1    Michigan Spectral Survey, Ann Arbor, Vol. 1
MSS2    Michigan Spectral Survey, Ann Arbor, Vol. 2
MSS3    Michigan Spectral Survey, Ann Arbor, Vol. 3
MSS4    Michigan Spectral Survey, Ann Arbor, Vol. 4 Univ. Michigan
MtSOM   Mount Stromlo Observatory Mimeogram
MtSRe   Mount Stromlo Observatory, Canberra - Reprints
MtWAR   Mount Wilson and Palomar Observatories, Pasadena, California Annual
        Report of the Director
MtWRe   Mount Wilson and Palomar Observatory - Reprints
N30     Catalog of 5268 Standard Stars for the Equinox and Epoch 1950.0 Based on
        the Normal Star System N30. Ed.: H. R. Morgan. Yale University
        Observatory and U.S.Naval Observatory. Publ.: The Nautical Almanac
        Office, U.S.Naval Observatory, 1950.
NAICR   National Astronomy and Ionospheric Center Report.
NaiRe   Reprints - Utta Pradesh  State Observatory, Naini Tal, India
NapCo   Osservatorio Astronomico di Capodimonte-Napoli - Contributi Astronomici
NASAC   National Aeronautics and Space Administration, Conference Publication
NASAL   National Aeronautics and Space Administration, Lyndon B. Johnson Space
        Center, Houston, Texas - Circular Letter
NASAR   National Aeronautics and Space Administration, Reference Publication
NASAS   National Aeronautics and Space Administration, Special Publication
NATi    Nordisk Astronomisk Tidsskrift
Natur   Nature (London)
NAZ     Nachrichtenblatt der Astronomischen Zentralstelle, Heidelberg
NBSSP   National Bureau of Standards Special Publication
NBSTN   National Bureau of Standards Technical Note
NCimB   Nuovo Cimento B (Catalog also in Lab. Naz. Radioastron. Inst. Fis.
        Bologna, 33 pp.)
NEDR    NED Team Report.
NewA    New Astronomy (Elsevier Science)
NewAR   New Astronomy Reviews (Elsevier Science), continuation from VA, (n. 4,
        dec. 31th 1997)
NewSc   New Scientist
NIA86   New insights in astrophysics. Proc. International Symp. co-sponsored by
        NASA, ESA and SERC, held at Univ. Coll. London, 14-16 July 1986. ESA
        SP-263
Nic1K   Observatoire de Nice (INCA)
NInfo   Nauchnye Informatsii
NizRe   Nizamiah Observatory, Hyderabad - Reprints
NLTT    University Minnesota- USA -,1986
NoDef   Not Defined
NPhS    Nature, Physical Science
NRAOR   National Radio Astronomy Observatory - Reprints
NSC3    Nearby Stars, Preliminary 3rd Version, Astron. Rechen-Institut,
        Heideleberg (1991) V/70A
NSSDC   IRAS 1.2 Jy IRAS redshift survey (Catalog 7185 in VizieR).
NVS     Nachrichtenblatt der Vereinigung der Sternfreunde e.V.
NVVSR   Nederlandse Vereiniging voor Weer - en Sterrenkunde, Werkgroep
        veranderlijke Sterren - Reports
OBN1K   Observatoire de Besancon - CNES (INCA)
Obs     The Observatory
OklRe   Reprints - University of Oklahoma Observatory
ONRAS   Occasional Notes of the Royal Astronomical Society
OOVRO   Observations Owens Valley Radio Obs.
Orion   Orion - Mitteilungen der Schweizerischen Astronomischen Gesellschaft
ORROE   Occasional Reports of the Royal Observatory, Edinburgh
OslR    Institute of Theoretical Astrophysics, Blindern, Oslo, Norway - Reports
OVS     Observation of Variable Stars
PA      Popular Astronomy. Northfield, Minn., U.S.A.
PAAS    Publications of the American Astronomical Society
PAB     National Research Council of Canada. Publication of the Astrophysical
        Branch, Ottawa
PABei   Progress in Astronomy (Publ. Beijing)
PACap   Publication of the Departement of Astr. University of Capetown
PadCR   Osservatorio Astronomico di Padova - Comunicazioni e Rassegne
PAICz   Publications of the Astronomical Institute of the Czechoslovak Academy
        of Sciences
PAllO   Publications of the Allegheny Observatory of the University of
        Pittsburgh
PASA    Publications - the Astronomical Society of Australia (continuation of
        PASAu)
PASAu   Proceedings of the Astronomical Society of Australia (continued by PASA)
PASJ    Publications of the Astronomical Society of Japan
PASK    Publ. Ac. Sc. Kasakstan, Sect. Astrobotanics
PASP    Publications of the Astronomical Society of the Pacific
PASPS   Publications of the Astronomical Society of the Pacific, Supplement
PAth    Publications of the Laboratory of Astronomy, Univervity of Athens,
        Greece, Series II
PATi    Popular Astronomisk Tidsskrift
PAUTx   University of Texas - Publications in Astronomy
PAZh    Pis'ma v Astronomicheskij Zhurnal
PBeiO   Publications of the Beijing Astronomical Observatory (later
        "Astrophysics Reports")
PBosO   Publications of the Bosscha Observatory, Lembang, Indonesia
PBrn    Astronomical Institute of the University  Brno - Publications
PCat    Osservatorio Astrofisico di Catania, Pubblicazioni, Nuova Serie
PCinO   Publications of the Cincinnati Observatory
PCMP3   Proc. 3rd Chinese Acad. Sci. and Max-Planck Soc. Workshop. Huangshan
        19-23 Oct. 1990, Ed. Li Qibin, World Scientific Publ. "High Energy
        Astrophysics: Compact Stars and Active Galaxies" ISBN 981-02-0697-6
PCopO   Publikationer og mindre Meddelelser fra Kobenhavns Observatorium
PDAA    Publications of the Department of Astronomy, Austin, Texas -  University
        of Texas
PDAO    Publications of the Dominion Astrophysical Observatory, Victoria, Canada
PDAUC   Publications Departamento de Astronomia, Universidad de Chile
PDDO    Publications of the David Dunlap Observatory
PDO     Publications of the Dominion Observatory, Ottawa, Ontario, Canada
PF&CO   Publications of the University of Pennsylvania, Astronomical Series,
        Flower and Cook Astronomical Observatory
PGenA   Publications de l'Observatoire de Geneve, Serie A
PGenB   Publications de l'Observatoire de Geneve, Serie B
PGLO    Publications of the Goethe Link Observatory of Indiana University,
        Bloomington, Indiana
PGooO   Publications of the Goodsell Observatory of Carlton College, Northfield,
        Minnesota
PGro    Publications of the Kapteyn Astronomical Laboratory at Groningen
PhDT    Thesis - PhDThesis
Phoen   Phoenix, Mitteilungsblatt fuer Veraenderlichenbeobachter
PhR     Physics Reports
PhRvA   Physical Review A
PhRvB   Physical Review B
PhRvC   Physical Review C
PhRvD   Physical Review D
PhRvL   Physical Review Letters
PhST    Physica Scripta, volume T (supplement for colloquia)
PhT     Physics Today
PhyS    Physica Scripta
PIAG    Publications de l'Institut d'Astronomie et de Geophysique, Louvain
PIstO   Publications of the Istanbul University Observatory
PJA     Proceeding of the Japan Academy
PK      Catalogue of galactic planetary nebulae. Academia Publishing  House of
        the Czech. Acad. Sci., Prague
PKoAS   Publication of Korean Astronomical Society
PKS     Parkes Catalog, 1990
PLicO   Publications of the Lick Observatory
PLPla   Publications del Observatorio Astronomico de la Universidad Nacional de
        la Plata, Serie Astronomica
PMad    Publicacion - Universidad Complutense - Facultad de Ciencias Madrid,
        Seminario de Astronomia y Geodesia -
PMcCO   Publications of the Leander Mc Cormik Observatory of the University of
        Virginia, Charlottesville
PMMin   Proper Motion Survey with the 48-inch Telescope, $ fasc. 1-57,$ 1963-81,
        University of Minnesota, Minneapolis
PMtv    Facultad de Humanidades y Ciencias Universidad de la Republica,
        Departamento de Astronomia, Montevideo - Publicacions
PN70    Planetary Nebulae Reidel D. Publ. Comp. Dordrecht
PN86    Planetary and Proto-Planetary Nebulae: From IRAS to ISO. Proc. Frascati
        Workshop, Vulcano Island, Sep. 8-12, 1986 Ed. A. Preite-Martinez.
PNAOJ   Publications of the National Astronomical Observatory of Japan
PNAS    Proceedings of the National Academy of Sciences of the United States of
        America
PoA     Postepy Astronomii, Krakow
POAN    Departamento de Astronomia, Universidad de Chile, Observatorio
        Astronomico Nacional, Cerro Calan Publicaciones
POBeo   Publications de l'Observatoire Astronomique de Beograd (ISSN 0373-3742)
POBol   Pubblicazioni dell'Osservatorio Astronomico Universitario  di Bologna
POBor   Publications de l'Observatoire de l'Universite de Bordeaux
POClu   Publicatiile Observatorului Astronomical Universitatii din Cluj
POHel   Publications of the Astronomical Observatory, Helsinki, Finnland
POHP    Publication de l'Observatoire de Haute-Provence
POLyo   Publication de l'Observatoire de Lyon
POMic   Publications of the Observatory of the University of Michigan, Ann
        Arbor, Mich
POMil   Pubblicazioni dell'Osservatorio Astronomico di Milano-Merate (Nuova
        Serie)
POMin   Publications of the Astronomical Observatory. University of Minnesota
POPad   Pubblicazioni dell'Osservatorio Astronomico di Padova
POPal   Pubblicazioni dell'Osservatorio Astronomico di Palermo
POPar   Publication de l'Observatoire de Paris - Notes et Informations
POPot   Publikationen des Astrophysikalischen Observatoriums zu Potsdam
POStr   Publication de l'Observatoire de Strasbourg
POTor   Pubblicazioni Varie Fuori Serie dell'Osservatorio Astronomico di Torino,
        Pino Torinese
POTou   Publications de l'Observatoire de Toulouse
POVRO   Publication of the Owens Valley Radio Observatory
POxf    Publications - University of Oxford, Department of Astrophysics
PPMtO   Publications of the Purple Mountain Observatory
Pram    Pramana
PraP    Astronomical Institute of the Charles University - Publications
Priv    Private Communication
PrKFi   Problemy Kosmicheskoi Fiziki
PROE    Publications of the Royal Observatory, Edinburgh(suspended from vol 19
        No 3 (2000) on)
PrPNP   Progress in Particle and Nuclear Physics
PSAIL   Pubblicazioni della Stazione Astronomica Internazionale di Latitudine
        Carloforte-Cagliari
PSCDS   Publication Speciale du Centre de Donnees Stellaires
PSci    Pour la science
P&SS    Planetary and Space Science
PTarO   Publikatsii Tartuskoj Astrofizicheskoj Observatorii im. V. Struve -
        Akademiya Nauk Estonskoj SSR
PTRSL   Philosophical Transactions of the Royal Society of London, Series A:
        Mathematical and Physical Sciences
PUSNO   Publications of the United States Naval Observatory, Second Series
PVSS    Royal Astronomical Society of New Zealand - Publications of Variable
        Star Section
PWasO   Publications of the Washburn Observatory of the University of Wisconsin,
        Madison, Wisconsin
PW&SO   Publications of the Warner and Swasey Observatory
PYerO   Publications of the Yerkes Observatory
PYunO   Publications of the Yunnan Observatory (China)
PZ      Peremennye Zvezdy (variable stars)
PZP     Peremennye Zvezdy, Prilozhenie(Variable Stars, Supplement)
QJRAS   Quarterly Journal of the Royal Astronomical Society (continue with A&G
        from no 38 - 1997)
QSO     A new optical catalog of QSO (magnetic version of 1989ApJS...69....1H)
RA      Specola Astronomica Vaticana - Richerche Astronomiche
RadRe   Radcliffe Observatory, Pretoria, South Africa - Reprints
RAS     Revised Shapley-Ames Catalog
RC2     Second reference catalogue of bright galaxies, 1976.
RC3     Third reference catalogue of bright galaxies, 1991, New York :
        Springer-Verlag
RC3v9   Third reference catalogue of bright galaxies, version 9, 1991, New York
        : Springer-Verlag.
Rech    La Recherche
ReToh   Sci. Reports Tohoku Univ. Ser. I
RGOB    Royal Greenwich Observatory, Bulletins (Serie E)
RioB    Observatorio Nacional Publicacoes do Servico Astronomico, Rio de Janeiro
Rise    Rise hvezd - Popularne vedecky astronomicky casopis, Praha
RMxAA   Revista Mexicana de Astronomia y Astrofisica
RMxAC   Revista Mexicana de Astronomia y Astrofisica Serie de Conferencias
RNAO    Resultados del Observatorio Nacional Argentino
RoAJ    Romanian Astronomical Journal
ROAn    Royal Observatory Annals
ROCi    Republic Observatory Johannesburg Circulars (continuation of CiUO till
        vol.7 (1962))
Roczn   Rocznik Astronomiczny Observatorjum Krakowskiego, Krakow
ROLun   Reports from the Observatory of Lund
RomCo   Osservatorio Astronomico di Roma su Monte Mario - Contributi Scientifici
RosOB   Observatorio Astronomico Municipal de Rosario, Argentia - Boletin
RPPh    Reports on Progress in Physics
RvA     Revista Astronomica - Organo de la Asociacion Argengina Amigos de la
        Astronomia, Buenos Aires
RVG     Radial Velocity of Galaxies, 1983
RvMad   Revista Real Acad. Ciencias Exact., Fis., Nat. Madrid
RvMP    Reviews of Modern Physics
RvMPS   Reviews of Modern Physics, Special Issue
RvPD    Revue du Palais de la Decouverte
RZh     Referationyj Zhurnal
SAAOC   South African Astronomical Observatory, Circulars (vol. 1 includes
        issues 1 to 5, following by vol. 6)
SAJ     Serbian Astronomical Journal (ISSN: 1450-698X) (continuation of BOBeo -
        Bull. Obs. Astron. Beograd, from Jan 1998 No 158)
SAnAp   Supplements aux Annales d'Astrophysique
SanS    Separata - Universidad de Chile, Departamento de Astronomia, Santiago
SAO     Smithsonian Astrophysical Observatory Star Catalog, Ed. Smithsonian
        Institution, Washington DC,1966
SAOCo   Smithsonian Astrophysical Observatory, Cambridge, Massachusetts -
        Smithsonian Contributions to Astrophysics
SAOP    Smithsonian Astrophysical Observatory Publications.
SAOSR   Smithsonian Institution. Astrophysical Observatory. Research in Space
        Science. SAO Special Report
SASn    Studia Astronomica Sinica
SCA     Studii si Cercetari de Astronomie, Bucuresti
Sci     Science
SciAm   Scientific American
SciN    Science News (Washington D.C.)
SDM     Spektral-Durchmusterung von Milchstrassenfeldern. Teil 1 
SenAR   Sendai Astronomiaj Raportoj
sf99    Proceedings of Star Formation 1999, held in Nagoya. Ed. T. Nakamoto
        (NRO)
SFSN    Scripta Fac. Sci. Nat. Ujep Brunensis Physica
SGC     Southern galaxy catalog. 1985, Austin: University of Texas Press
SNSNR   Proceeding of Beijing Workshop 1991Jun.29/Jul.03, Ed. Li Qibin, Ma Er
        and Li Zongwei. Int. Academic Publ.: "Supernovae and Their Remnants"
        ISBN 7-80003-180-2/P-13
SoByu   Soobshcheniya Byurakanskoj Observatorii - Akademiya Nauk Armyanskoj SSR,
        Erevan
SoKie   Sonderdrucke der Sternwarte Kiel
SoMue   Sonderdrucke - Universitaet Muenster, Astronomisches Institut
SoPh    Solar Physics
SoSAO   Soobshcheniya Spetsial'noj Astrofizicheskoj Observatorii
SoShe   Soobshchenie Shemakhinskoj Astrofizicheskoj Observatorii - Akademiya
        Nauk Azerbajdzhanskoj SSR
SoSht   Soobshcheniya Gosudarstvennogo Astronomicheskogo Instituta im. P.K.
        Shternberga
SpA     Durchmusterung of selected areas of the special plan. Vol. I and Vol. II
SPD     AAS/Solar Physic Division meeting
SPhD    Soviet Physics Doklady
SprRe   Sproul Observatory - Swarthmore, Pennsylvania - Reprints
SRToh   Sci. Rep. Tohoku Univ., Eighth Ser.
SSC     IRAS Serendipitous Survey Catalog. Tucson, Univ. of Arizona - 10
        Microfiches +Explanatory Supplement on paper.
SSRv    Space Science Reviews
SSS     Stars and stellar systems.
SSSC    IRAS Catalogs and Atlases. The Small Scale Structure Catalog. NASA
        RP-1190. Vol. 7
SSTor   Studia Societatis Scientiarum Torunensis, Sectio F (Astronomia)
S&T     Sky and Telescope
StARe   Reprints - University Observatory, St. Andrews, Scotland
Sterb   Der Sternenbote - Monatsschrift fuer Oesterreichs Amateur-astronomen
SteRe   Reprints - University of Arizona, Steward Observatory, Tucson, Arizona
Stern   Die Sterne
Sterz   Sternzeit - Mitteilungen der Astrnomischen Vereinigungen Aachen, Bad
        Kissingen usw
StoAn   Stockholms Observatoriums Annaler
StoMe   Stockholms Observatoriums - Meddelande
StoOR   Stockholms Observatoriums - Reports
SUVSR   Scandinavian Union of Amateur Astronomers, Variable Star Section -
        Reports
SvA     Soviet Astronomy (English translation of "Astronomicheskij Zhurnal",
        continued by "Astronomy Report")
SvAL    Soviet Astronomy Letters (English translation of "Pis'ma v
        Astronomicheskij Zhurnal", continued by "Astronomy Letters")
SvPhA   Soviet Physics-Astronomy
S&W     Sterne und Weltraum
SydOP   Sydney Observatory, Papers
Tac1K   Tache 1000 (INCA)
TamCo   Astronomical Contributions from the University of South Florida at Tampa
TApA    Top. Astrophys. Astron. Space Sci.
TAPS    Transactions of the American Philosophical Society
TarOT   Tartu Astrofuusika Observatoorium Teated
TarPr   Tartuskoj Astrofizicheskoj Observatorii, Preprint - Akademiya Nauk
        Estonskoj SSR
TD1     Catalogue of Stellar Ultraviolet Fluxes. A Compilation of Absolute
        Stellar Fluxes Measured by the Sky Survey Telescope (S2/68) aboard the
        ESRO Satellite TD-1. Ed.: G. I. Thompson, K. Nandy, C. Jamar, A.
        Monfils,  L. Houziaux, D. J. Carnochan, R. Wilson. Publ.: The Science
        Research Council, 23+449pp., 1978.
TerCo   Osservatorio Astronomico di Collurania, Teramo - Contributi
TerMm   Osservatorio Astronomico di Collurania, Teramo - Memorie ed Osservazioni
TerNC   Osservatorio Astronomico di Collurania, Teramo - Note e Comunicazioni
Thesi   Thesis
TITas   Tsirkulyar Astronomicheskogo Instituta. Akademiya Nauk Uzbekskoj SSR.
        Izdatel'stovo Fan, Tashkent (USSR) - (Irregularly - continuation of
        TsTas from 1967).
TMSS    Two-Micron Sky Survey - A Preliminary Catalog. By G. Neugebauer and R.B.
        Leighton . NASA SP-3047 . Ed. NASA Washington D.C. , 1969.
TokAB   Tokyo Astronomical Bulletin, Second Series
TokRe   Tokyo Astronomical Observatory - Reprints
TOYal   Transactions of the Astronomical Observatory of Yale University
TrAlm   Trudy Astrofizicheskogo Instituta , Alma-Ata - Akademiya Nauk Kazakhskoj
        SSR, Alma-Ata
TrDus   Trudy Instituta Astrofiziki, Dushanbe - Akademiya Nauk Tadzhikskoj SSR
TreP    Osservatorio Privato Specola "Ariel" Treviso Italia - Pubblicazione
TriP    Osservatorio Astronomico di Trieste - Pubblicazioni
TrKaz   Trudy Kazanskoj Gorodkoj Astronomicheskoj Observatorii
TrLen   Trudy Astronomicheskoj Observatorii. Leningrad
TrPul   Trudy Glavnoj Astronomicheskoj Observatorii v Pulkovo, Serie II
TrRig   Trudy Astrofizicheskoj Laboratorii, Riga -  Akademiya Nauk Latvijskoj
        SSR
TrSht   Trudy Gosudarstvennogo Astronomicheskogo Instituta im P.K.Shternberga
TrSta   Trudy Instituta Astrofiziki, Stalinabad - Akademiya Nauk Tadzhikskoj SSR
TrTas   Trudy Tashkentskoj Astronomicheskoj Observatorii -  Akademiya Nauk
        Uzbekskoj SSR
TsPul   Tsirkulyary Glavnoj Astronomicheskoj Observatorii i Pulkove
TsShe   Tsirkulyar Shemakhinskoj Astrofizicheskoj Observatorii - Akademiya Nauk
        Azerbajdzhanskoj SSR
TSSLW   Travaux de la Societe des Sciences et des Letters de Wroclaw
TsSta   Tsirkulyar Stalinabadskoj Astronomicheskoj Observatorii - Tadzhikskij
        Filial Akademii Nauk SSR
TsTas   Tsirkulyar Tashkentskoj Astronomicheskoj Observatorii -  Akademiya Nauk
        Uzbekskoj SSR (continued by TITas after 1966)
TxSym   Texas Symp. on Relativistic Astrophysics
UCLAP   Astronomical Papers - University of California, Los Angeles
UGC     Nova Acta Regiae Societatis Scientarum Upsaliensis, Ser. V:A, vol. 1 (=
        Uppsala Astronomiska Observatoriums Annaler, vol. 6). Ed.: P. Nilson.
        Publ.: Uppsala, 1973.
ULIA4   Universite de Liege, Institut d'Astrophysique, Liege - Collection in 4
ULIA8   Universite de Liege, Institut d'Astrophysique, Liege - Collection in 8
UMt1K   Universite de Montpellier (INCA)
Unpub   Unpublished (XXEU)
UppAn   Uppsala Astronomiska Observatoriums Annaler
UppOR   Uppsala Astronomical Observatory - Reports
Urani   Urania
USNO1   The PMM USNO-A1.0 Catalog.
USNO2   The PMM USNO-A2.0 Catalog.
USNOC   Circulars - U.S. Naval Observatory, Washington D.C.
USNOR   Reprint - U.S. Naval Observatory, Washington D.C.
UtrOv   Utrechtse Sterrekundige Overdrukken
VA      Vistas in Astronomy
VAG     Vierteljahresschrift der Astronomischen Gesellschaft
VatAR   Specola Astronomica Vaticana - Annual Reports
VatCo   Specola Astronomica Vaticana - Comunicazione
VatMA   Specola Astronomica Vaticana - Miscellanea Astronomica
VatOP   Vatican Observatory Publications
VeARI   Veroeffentlichungen des Astronomishen Rechen-Instituts Heidelberg
VeBB    Veroeffentlichungen der Universitaetssternwarte zu Berlin-Babelsberg
VeBoc   Veroeffentlichungen des Astronomischen Instituts der Ruhr-Universitaet,
        Bochum
VeBon   Veroeffentlichungen der Universitaets-Sternwarte zu Bonn (Astronomischen
        Institute)
VeFra   Veroeffentlichungen des Astronomischen Instituts des Universitaet
        Frankfurt (Main)
VeGoe   Veroeffentlichungen der Universitaets-Sternwarte zu Goettingen
VeHei   Veroeffentlichungen des Badischen Landessternwarte zu Heidelberg
        (Koenigstuhl)
VeMun   Veroeffentlichungen der Sternwarte Muenchen
VeSon   Veroeffentlichungen der Sternwarte in Sonneberg
VeUSB   Veroeffentlichungen der Universitaets-Sternwarte zu Bonn
VeWFS   Veroeffentlichung der Wilhelm Foerster Sterwarte
VilCo   Villanova University - Observatory Contributions
VilOB   Vilnius Astronomijos Observatorijos Biuletenis
VKha    Vestnik Khar'kovskogo Universiteta
VKie    Vestnik Kievskogo Universiteta, Seriya Astronomii
Vsin    3 references : P.L. BERNACCA, M. PERINOTTO, Cont.Padova No 239, 1970
        P.L. BERNACCA, M. PERINOTTO, Cont.Padova No 250, 1971
        P.L. BERNACCA, Cont.Padova No 294, 1973
VSOLB   Variable Star Observers League in Japan - Bulletin
VSSCi   Royal Astronomical Society of New Zealand, Variable Star Section -
        Circulars
VSSRe   Royal Astronomical Society of New Zealand, Variable Star Section -
        Reprints
VSSSC   Royal Astronomical Society of New Zealand, Variable Star Section -
        Special Circulars
VV      Atlas and catalog of interacting galaxies. Moscow State University.
VVORe   Reprints - Van Vleck Observatory, Middletown, Connecticut
WarRe   Polish Academy of Sciences, Warsaw University, Observatory and
        Astronomical Institute - Reprints
WasOA   University of Wisconsin-Madison, Washburn Observatory, Madison,
        Wisconsin - Astrophysics
WroRe   Wroclaw Astronomical Observatory - Reprints
XXAJ    Etude de l'amas de Praesepe basee sur les magnitudes photographiques et
        les longueurs d'onde effectives de 1821 etoiles. Duculot J. 1933
XXBG    The determination of the spectrophotometric temperature and the Balmer
        serie decrement of AG Pegasi. Bol. Estrel. Var. 12,372,1952
XXCF    Colors and luminosities of stars near the Sun. Sternberg Astron. Inst.
        Moscow 29,3,1958
XXCH    Bol. Estrel. Var. 12,398,1959
XXCI    The variations of brightness of chi Ophiuchi. Bol. Estrel. Var.
        12,432,1959
XXCJ     Catalogue of galaxies and of clusters of galaxies. Vol I [Z].
        California Inst. Techn. Pasadena, 320pp,1960
XXCK    Bol. Estrel. Var.12,391,1960
XXCL    Spectral classification of Southern fundamental stars. INEXISTANT-Mount
        Stromlo Obs. Mimeo. 2,1961
XXCM    General Catalogue of Variable Stars, 1961
XXCN    R. Obs. Cape Mim. 12,1961
XXCO    IAU Transactions, 11A, 251-254,1961
XXCQ    Publ. U.S. Naval Obs. 17,347,1961
XXCR    Publ. U.S. Naval Obs. 20,$part 6$1961
XXCS    Publ. U.S. Naval Obs. 20,$part 7$1961
XXCT    Publ. U.S. Naval Obs. 20,$part 3$1961
XXCU    Publ. U.S. Naval Obs. 24,$part 1$1961
XXCV    Astron. Acad. Sc. U.R.S.S. 1,1961
XXCW    Astron.council Acad. of Sc.of U.R.S.S. 2,1961
XXCX    Astron. Acad. Sc. U.R.S.S. 2,1961
XXCY    Bol. Estrel. Var. 13,434,1961
XXDC    Mitt. Staatl. Astr. Sternberg, 118,3-35,1962
XXDW    California Inst. Techn. Pasadena, 8 + 371 pp,1963
XXDY    Yale Univ. Obs.,1964
XXDZ    in cat. of Galactic P.N.,1964
XXEA    Moscow, USSR, 288 pp,1964
XXEB    Astron. Abh. Prof. C. Hoffmeister zum 70 Geburtst. gew. 42-52,1965
XXEC    Landolt-Borstein tables 566,1965
XXED    Ann. Obs. Bordeaux,18,103,1965
XXEJ    Univ. Microfilm Inc. Ann Arbor Michigan,1966
XXEM    Reidel Plubl.Cie.Dord-Holland,6,226,1966
XXEO    Mono Book Corporation Baltimore,1967
XXER    Univ. Munster,1967
XXES    Symp. Inst. Astrophys. Univ. Liege 558,68,1968
XXET    Nebula., Interstellar Matter, 7,483,1968
XXEV    IAU Coll. Budapest,1968
XXFA    Obs. Owens Vall. Rad. Obs. 12,1-11,1969
XXFB    Low Luminosity Stars- Kumar Ed. Gordon., Breach, 1969,139,1969
XXFF    Sci. Reports Tohoku Univ. Ser. I. 53,10-20,1970
XXFG    Trieste Oss. Astr. 1970,317pp,1970
XXFH    Izv. Krym. Astrofiz. Obs. 41-42,264,1970
XXFI    Separate print Univ. Minnesota, Minn. pp.48,1970
XXFM    Symp. on Solar Physics, Atomic Spectra, Gaseous Nebulae,190,1971
XXFN    Symp. on Solar Physics, Atomic Spectra, Gaseous Nebulae,151,1971
XXFO    Symp. on Solar Physics, Atomic Spectra, Gaseous Nebulae,161,1971
XXFP    Symp. on Solar Physics, Atomic Spectra, Gaseous Nebulae,169,1971
XXFQ    Symp. on Solar Physics, Atomic Spectra, Gaseous Nebulae,182,1971
XXFR    Lowell Proper Motion Survey. The G numbered stars. Lowell Obs., 1971
XXFT    Pontif. Acad. Scient. Citta del Vaticano Scripta Varia. . Ed. by
        O'Connell D.J.K. Study week on 'Nuclei of galaxies', Citta del Vaticano
        1970 april 13-18 Vol 35,351-378,1971
XXFU    Catalogue of nebulae in Crux, Centaurus, Circinus and Norma. Published
        by Steward Observatory, Tucson, Arizona,1972
XXFV    Ph. D. Thesis, Univ. Toronto, Canada,1972
XXFY    ESRO,1974
XXFZ    Preprint,1974
XXGA    New York,1974
XXGB    Moscow State University,1974
XXGC    Problems in stellar atmospheres and envelopes, 57-100,1975
XXGF    University of Michigan Catalogue Vol 1,1975
XXGH    Separate print, Astron. Inst. Univ. Basel,1976
XXGJ    Publ. U.S. Naval Obs. 24,$part 3$1976
XXGK    IAU Coll. 40, held at the Paris-Meudon Observatory, France, September
        6-8, 1976. 1-39.15,1977
XXGL    IAU Coll. 40, held at the Paris-Meudon Observatory, France, September
        6-8, 1976. 1-47.13,1977
XXGM    Univ. Minnesota, Minneapolis,1977
XXGN    Air Force Geophysics Lab. AFGL-TR-77-0160,1977
XXGO    Protostars & Planets, 648,1978
XXGP    Protostars & Planets, 625,1978
XXGQ    Sci. Research Council,1978
XXGR    Publ. Obs. Univ. Chili III, 169-170,1978
XXGS    Publ. Obs. Univ. Chili III, 171-174,1978
XXGT    The Univ. of Texas Publ. in Astron. %14% 1978
XXGW    User's Manual,1980
XXGX    A publier,1980
XXGY    These 4eme partie,413,1980
XXHA    Second European IUE Conference. Proceedings of an International
        Conference held at Tubingen, Germany, 26-28 March 1980 Ed. B.Battrick,
        J.Mort,ESA SP-157$xxvii-xxxi$1980
XXHB    Second European IUE Conference. Proceedings of an International
        Conference held at Tubingen, Germany, 26-28 March 1980 Ed. B.Battrick,
        J.Mort,ESA SP-157$xxxiii-xxxviii$1980
XXHC    Second European IUE Conference. Proceedings of an International
        Conference held at Tubingen, Germany, 26-28 March 1980 Ed. B.Battrick,
        J.Mort,ESA SP-157$xxxix-xl$1980
XXHD    Second European IUE Conference. Proceedings of an International
        Conference held at Tubingen, Germany, 26-28 March 1980 Ed. B.Battrick,
        J.Mort,ESA SP-157$xli$1980
XXHE    Second European IUE Conference. Proceedings of an International
        Conference held at Tubingen, Germany, 26-28 March 1980 Ed. B.Battrick,
        J.Mort,ESA SP-157$xliii-xlviii$1980
XXHF    Second European IUE Conference. Proceedings of an International
        Conference held at Tubingen, Germany, 26-28 March 1980 Ed. B.Battrick,
        J.Mort,ESA SP-157$il-lvii$1980
XXHG    Second European IUE Conference. Proceedings of an International
        Conference held at Tubingen, Germany, 26-28 March 1980 Ed. B.Battrick,
        J.Mort,ESA SP-157$lix-lxv$1980
XXHH    Second European IUE Conference. Proceedings of an International
        Conference held at Tubingen, Germany, 26-28 March 1980 Ed. B.Battrick,
        J.Mort,ESA SP-157$lxvii-lxx$1980
XXHI    Second European IUE Conference. Proceedings of an International
        Conference held at Tubingen, Germany, 26-28 March 1980 Ed. B.Battrick,
        J.Mort,ESA SP-157$lxxi-lxxx$1980
XXHJ    Second European IUE Conference. Proceedings of an International
        Conference held at Tubingen, Germany, 26-28 march 1980 Ed. B.Battrick,
        J.Mort,ESA SP-157,pp 515,1980
XXHK    Proc. North American Workshop on Symbiotic stars,15,1981
XXHL    Procee. North American Work. Symb. Stars,1981
XXHO    Landolt-Bornstein-G. VI Vol.2 A&A Subv. B-ST. & ST. CL. 364-372,1982
XXHP    Dep. Astron. Kyoto Univ.,1982
XXHR    Inf. Sci. Moscow, 50,3-9,1982
XXHT    Astron. Astrophys. 124,C1-C2,1983
XXHU    These Univ. Paul Sabatier Toulouse,1983
XXHW    Errors detected in catalogues,1983
XXHX    Errors detected in catalogues,1983
XXHY    ,1984
XXHZ    ,1984
XXIB    Spektroskopische Beobachtungen von PV Cephei, der zentra,1985
XXID    Thesis University of Illinois at Urbana-Champaign,1-154, August 14,1985
XXIE    Publicacoes do Observatorio Nacional No 10,1985
XXIG    in preparation,1986
XXII    ARI-Heidelberg- RFA -,1986
XXIK    Tache 1000,1986
XXIL    Carlsberg Automatic Meridian Circle - Cat. no 1 - 1985,1986
XXIM    Liege - Geneve,1986
XXIO    Private Communication. voir 89.1350,1987
XXIP    Private Communication. voir 88.1056,1987
XXIQ    Departement of Astronomy University of Washington,1987
XXIR    Carlsberg Automatic Meridian Circle,1987
XXIT    Proceedings of the 132nd symposium of the IAU held in Paris, France june
        29 - july 3 1987 Eds G. Cayrel de Strobel, M. Spite. The impact of very
        high S/N spectroscopy on stellar physics, xvii-xxiii,1988
XXIU    ARI-Heidelberg- RFA -,1988
XXIV    Geneve,1988
XXIW    USSR Acad. Sciences,1988
XXIX    USSR Acad. Sciences,1988
XXIZ    Observatoire de Geneve et de Besancon,1989
XXJA    ,1989
XXJB    ,1989
YamCi   Yamamoto Circular
yCat    Catalogues in Machine-Readable Form in the nomenclature shared by Data
        Centers
ZA      Zeitschrift fuer Astrophysik
ZCAT    Center for Astrophysic Redshift catalog, june 1990
ZD      Zvaigznota Debess - Latujas PSR Zinatnu Akademijas Radio-astrofizikas
        Observatorijas Populaerzinatnisks Gadalaiken Izdevums Izdevniecila
        "Zinatne", Riga
Zenit   Zenit
ZGTR    Unpublished Report to Office of Naval Research. Zwicky F., Gates H.S.
        and Taylor D. "Photometry of galaxies."
zzzzz   This ending name just to be sure everything works...
=cut    # The following entries are ADS special conference codes
1977lupl.symp    10th ISAS Lunar and Planetary Symposium
1978lupl.symp    11th ISAS Lunar and Planetary Symposium
1979lupl.symp    12th ISAS Lunar and Planetary Symposium
1980lupl.symp    13th ISAS Lunar and Planetary Symposium
1987txra.symp    13th Texas Symposium on Relativistic Astrophysics
    icr....14    14th International Cosmic Ray Conference
1981lupl.symp    14th ISAS Lunar and Planetary Symposium
    icr....15    15th International Cosmic Ray Conference
1982lupl.symp    15th ISAS Lunar and Planetary Symposium
    icr....16    16th International Cosmic Ray Conference
    icr....17    17th International Cosmic Ray Conference
    icr....18    18th International Cosmic Ray Conference
1965soec.conf    1965 Solar Eclipse Symposium
1977duma.work    1976 DUMAND Summer Workshop
1980duma.work    1979 DUMAND Summer Workshops at Khabarovsk and Lake Baikal
1985eepa.rept    1982-1984 Eclipse of Epsilon Aurigae
1992smmel        The 1984 - 1987 Solar Maximum Mission Event List
    icr....19    19th International Cosmic Ray Conference
2003cnam.conf    1er Congreso Nacional de Astrof\x{00ED}sica Molecular: Una visi\x{00F3}n general del potencial de los grupos de qu\x{00ED}mica espa\x{00F1}oles anters los nuevos desaf\x{00ED}os de la Astrof\x{00ED}sica
2003trso.conf    2001: A Relativistic Spacetime Odyssey
2001socm.symp    2001: a Symplectic Odyssey
2001syod.conf    2001: a Symplectic Odyssey
2001aprs.conf    2001 Asia-Pacific Radio Science Conference AP-RASC '01
1998stel.conf    20th Stellar Conference of the Czech and Slovak Astronomical Institutes
    icr....21    21st International Cosmic Ray Conference
    icr....22    22nd International Cosmic Ray Conference
1991ceme.symp    24th Symposium on Celestial Mechanics,
1998ICRC....8    25th International Cosmic Ray Conference, Volume 8
1998fuph.conf    25th International Winter Meeting on Fundamental Physics.  Selected Topics on High Energy and Astropartical Physics.
1992ceme.symp    25th Symposium on Celestial Mechanics,
1994pas..conf    26th Meeting of the Polish Astronomical Society
1994ceme.symp    26th Symposium on Celestial Mechanics,
1996vsr..conf    27th Conference on Variable Star Research
1995ceme.symp    27th Symposium on Celestial Mechanics,
1997vsr..conf    28th Conference on Variable Star Research
1996ceme.symp    28th Symposium on Celestial Mechanics,
1998vsr..conf    29th Conference on Variable Star Research
1997ceme.symp    29th Symposium on Celestial Mechanics,
1994evji.conf    2nd EVN/JIVE Symposium
1996hell.conf    2nd Hellenic astronomical conference
1999svms.work    2nd Millimeter-VLBI Science Workshop
1990grra.conf    3rd Canadian Conference on General Relativity and Relativistic Astrophysics
1990asos.conf    3rd International Collogium of the Royal Netherlands Academy of Arts and Sciences
1998fyc..conf    40 Years of COSPAR
1992grra.conf    4th Canadian Conference on General Relativity and Relativistic Astrophysics
1981goje.symp    5th G\x{00F6}ttingen-Jerusalem Symposium on Astrophysics
    icr.....5    5th International Cosmic Ray Conference
1986mnap.conf    '86 Massive Neutrinos in Astrophysics and in Particle Physics
1988eiut.conf    '88 Electroweak Interactions and Unified Theories
1989eiut.conf    '89 Electroweak Interactions and Unified Theories
2002aprm.conf    8th Asian-Pacific Regional Meeting, Volume II
1991eiut.conf    '91 Electroweak Interactions and Unified Theories
1991hehi.conf    '91 High Energy Hadronic Interactions
1992eiut.conf    '92 Electroweak Interactions and Unified Theories
1993eiut.conf    '93 Electroweak Interactions and Unified Theories
1994eiut.conf    '94 Electroweak Interactions and Unified Theories
1995eiut.conf    '95 Electroweak Interactions Unified Theories
1995qheh.conf    '95 QCD and High Energy Hadronic Interactions
    asdy.conf    AAS/AIAA Astrodynamics Conference
1999asmm.conf    The Abdus Salam Memorial Meeting
1951asa1.conf    Abhandlungen Aus Der Sowjetischen Astronomie, Folge I
1951asa2.conf    Abhandlungen Aus Der Sowjetischen Astronomie, Folge II
1953asa3.conf    Abhandlungen Aus Der Sowjetischen Astronomie, Folge III
1988asgc.conf    The Abundance Spread within Globular Clusters: Spectroscopy of Individual Stars JCM 5 and CM 37/3
1982ans..conf    Accreting Neutron Stars
1993adcs.book    Accretion Disks in Compact Stellar Systems
1998apas.conf    Accretion Processes in Astrophysical Systems: Some Like it Hot!
1986apa..proc    Accretion Processes in Astrophysics
1983adsx.conf    Accretion-Driven Stellar X-ray Sources
1990apcb.conf    Accretion-Powered Compact Binaries
1984aims.rept    Achievements of the International Magnetospheric Study (IMS)
1968agwa.conf    Acoustic-Gravity Waves in the Atmosphere
1982ang..proc    Active Nuclei of Galaxies
1984apoa.conf    Active Phenomena in the Outer Atmosphere of the Sun and Stars
1998axrs.symp    The Active X-ray Sky: Results from BeppoSAX and RXTE
1996adop.conf    Adaptive Optics
2001sac..conf    Advanced Lectures on the Starburst-AGN
1997atma.conf    Advanced techniques and methods for astronomical image handling
1993atpi.work    Advanced Technologies for Planetary Instruments
1995aap..conf    Advances in Astrofundamental Physics
1997adp..conf    Advances in Dusty Plasmas
    amva.conf    Advances in Molecular Vibrations and Collision Dynamics, A Research Annual
2003and..book    Advances in Nonlinear Dynamics
1985ands.conf    Advances in Nonlinear Dynamics and Stochastic Processes
1986ana..work    Advances in Nuclear Astrophysics
1983app..conf    Advances in Photoelectric Photometry, Vol. 1.
1984app..conf    Advances in Photoelectric Photometry, Vol. 2.
1980apg..book    Advances in Planetary Geology
1998asct.conf    Advances in Solar Connection with Transient Interplanetary Phenomena
1994asp..conf    Advances in solar physics
1991assm.conf    Advances in Solar System Magnetohydrodynamics
1978nisa.symp    Advances in Space Exploration
1997ase..work    Advances in Stellar Evolution
1990atp..conf    Advances in Theoretical Physics
1982auva.nasa    Advances in Ultraviolet Astronomy
1963auar.conf    Advances in Upper Atmosphere Research
1960avst.conf    Advances in Vacuum Science and Technology
1959aeco.conf    A\x{00E9}ronomie Communications
2001adrt.conf    Aerodynamic Drag Reduction Technologies. Proceedings of the CEAS/DragNet European Drag Reduction
2003attp.conf    Aerodynamics, Thermophysics, Thermal Protection
1976amgd.book    Aeromechanics and Gas Dynamics
1987spmp.conf    Aerospace Century XXI: Space missions and Policy
1974aero.rept    Aerospace Corp. Interim Report, El Segundo, CA. Lab. Operations.
1998aums.conf    The Age of the Universe, Dark Matter, and Structure Formation
    aiaa.meet    AIAA, Aerospace Sciences Meeting
1983AIPC..101    AIP Conf. Proc. 101: Positron-Electron Pairs in Astrophysics
1985AIPC..126    AIP Conf. Proc. 126: Solar Neutrinos and Neutrino Astronomy
1986AIPC..144    AIP Conf. Proc. 144: Magnetospheric Phenomena in Astrophysics
1987AIPC..155    AIP Conf. Proc. 155: The Galactic Center
1988AIPC..169    AIP Conf. Proc. 169: Modern Physics in America
1988AIPC..170    AIP Conf. Proc. 170: Nuclear Spectroscopy of Astrophysical Sources
1988AIPC..174    AIP Conf. Proc. 174: Radio Wave Scattering in the Interstellar Medium
1989AIPC..183    AIP Conf. Proc. 183: Cosmic Abundances of Matter
1989AIPC..186    AIP Conf. Proc. 186: High-Energy Radiation Background in Space
1989AIPC..197    AIP Conf. Proc. 197: Drops and Bubbles
1990AIPC..197    AIP Conf. Proc. 197: Drops and Bubbles
1989AIPC..198    AIP Conf. Proc. 198: Astrophysics in Antarctica
1990AIPC..202    AIP Conf. Proc. 202: Physics and Astrophysics from a Lunar Base
1990AIPC..203    AIP Conf. Proc. 203: Particle Astrophysics - The NASA Cosmic Ray Program for the 1990s and Beyond
1990AIPC..205    AIP Conf. Proc. 205: The Physics of Electronic and Atomic Collisions
1990AIPC..207    AIP Conf. Proc. 207: Astrophysics from the Moon
1990AIPC..211    AIP Conf. Proc. 211: High-Energy Astrophysics in the 21st Century
1974AIPC...22    AIP Conf. Proc. 22: Neutrinos - 1974
1991AIPC..220    AIP Conf. Proc. 220: High Energy Gamma Ray Astronomy
1991AIPC..222    AIP Conf. Proc. 222: After the first three minutes
1991AIPC..232    AIP Conf. Proc. 232: Gamma-Ray Line Astrophysics
1992AIPC..264    AIP Conf. Proc. 264: Particle Acceleration in Cosmic Plasmas
1992AIPC..267    AIP Conf. Proc. 267: Electromechanical Coupling of the Solar Atmosphere
1993AIPC..278    AIP Conf. Proc. 278: Back to the Galaxy
1994AIPC..294    AIP Conf. Proc. 294: High-Energy Solar Phenomena - a New Era of Spacecraft Measurements
1993AIPC..295    AIP Conf. Proc. 295: The Physics of Electronic and Atomic Collisions
1994AIPC..307    AIP Conf. Proc. 307: Gamma-Ray Bursts
1994AIPC..308    AIP Conf. Proc. 308: The Evolution of X-ray Binariese
1994AIPC..310    AIP Conf. Proc. 310: Analysis of Interplanetary Dust Particles
1994AIPC..312    AIP Conf. Proc. 312: Molecules and Grains in Space
1994AIPC..313    AIP Conf. Proc. 313: The Soft X-ray Cosmos
1994AIPC..317    AIP Conf. Proc. 317: Fifth Mexican School of Particles and Fields
1995AIPC..323    AIP Conf. Proc. 323: Atomic Physics 14
1995AIPC..327    AIP Conf. Proc. 327: Nuclei in the Cosmos III
1995AIPC..336    AIP Conf. Proc. 336: Dark Matter
1988AIPC..336    AIP Conf. Proc. 336: Dark Matter, 23rd Rencontre de Moriond
1995AIPC..338    AIP Conf. Proc. 338: Intersections between Particle and Nuclear Physics
1995AIPC..341    AIP Conf. Proc. 341: Volatiles in the Earth and Solar System
1995AIPC..360    AIP Conf. Proc. 360: The Physics of Electronic and Atomic Collisions
1996AIPC..366    AIP Conf. Proc. 366: High Velocity Neutron Stars
1996AIPC..379    AIP Conf. Proc. 379: Physical origin of homochirality in life
1997AIPC..385    AIP Conf. Proc. 385: Robotic Exploration Close to the Sun: Scientific Basis
1997AIPC..387    AIP Conf. Proc. 387: Space Technology and Applications
1978AIPC...39    AIP Conf. Proc. 39: Physics Careers, Employment, and Education
1997AIPC..410    AIP Conf. Proc. 410: Proceedings of the Fourth Compton Symposium
1997AIPC..414    AIP Conf. Proc. 414: Two-Dimensional Turbulence in Plasmas and Fluids
1998AIPC..415    AIP Conf. Proc. 415: Beyond the Standard Model.  From Theory to Experiment
1998AIPC..420    AIP Conf. Proc. 420: Space Technology and Applications
1998AIPC..423    AIP Conf. Proc. 423: Fundamental Particles and Interactions, Frontiers in Contemporary Physics
1998AIPC..424    AIP Conf. Proc. 424: Twenty Beautiful Years of Bottom Physics
1998AIPC..430    AIP Conf. Proc. 430: The Eleventh International Conference on Fourier Transform Spectroscopy
1998AIPC..433    AIP Conf. Proc. 433: Workshop on Observing Giant Cosmic Ray Air Showers From >10(20) eV Particles From Space
1998AIPC..434    AIP Conf. Proc. 434: Atomic and Molecular Data and their Applications
1998AIPC..444    AIP Conf. Proc. 444: Particle Physics and Cosmology, First Tropical Workshop
1998AIPC..445    AIP Conf. Proc. 445: Particles and Fields, Sixth Mexican Workshop
1998AIPC..446    AIP Conf. Proc. 446: Physics of Dusty Plasmas, Seventh Workshop
1998AIPC..448    AIP Conf. Proc. 448: Workshop on Space Charge Physics in High Intensity Hadron Rings
1998AIPC..453    AIP Conf. Proc. 453: Particles, Fields, and Gravitation
1998AIPC..456    AIP Conf. Proc. 456: Laser Interferometer Space Antenna, Second International LISA Symposium on the Detection and Observation of Gravitational Waves in Space
1999AIPC..458    AIP Conf. Proc: 458: Space Technology and Applications, International Forum -- 1999
1999AIPC..467    AIP Conf. Proc. 467: Spectral Line Shapes
1999AIPC..470    AIP Conf. Proc. 470: After the Dark Ages: When Galaxies were Young (the Universe at 2 < Z < 5)
1999AIPC..481    AIP Conf. Proc. 471: Solar Wind Nine
1999AIPC..476    AIP Conf. Proc. 476: 3K cosmology
1999AIPC..478    AIP Conf. Proc. 478: COSMO-98
1999AIPC..484    AIP Conf. Proc. 484: Trends in Theoretical Physics II
1999AIPC..488    AIP Conf. Proc. 488: High Energy Physics at the Millennium: MRST '99,
1979AIPC...49    AIP Conf. Proc. 49: Cosmic Rays and Particle Physics
1999AIPC..493    AIP Conf. Proc. 493: General Relativity and Relativistic Astrophysics
2000AIPC..504    AIP Conf. Proc. 504: Space Technology and Applications International Forum
2000AIPC..516    AIP Conf. Proc. 516: 26th International Cosmic Ray Conference, ICRC XXVI
2000AIPC..526    AIP Conf. Proc. 526: Gamma-ray Bursts, 5th Huntsville Symposium
2000AIPC..528    AIP Conf. Proc. 528: Acceleration and Transport of Energetic Particles Observed in the Heliosphere
2000AIPC..531    AIP Conf. Proc. 531: Particles and Fields
2000AIPC..537    AIP Conf. Proc. 537: Waves in Dusty, Solar, and Space Plasmas
2000AIPC..540    AIP Conf. Proc. 540: Particle Physics and Cosmology
2001AIPC..541    AIP Conf. Proc. 541: Theoretical High Energy Physics
2000AIPC..541    AIP Conf. Proc. 541: Theoretical High Energy Physics, MRST 2000
2000AIPC..543    AIP Conf. Proc. 543: Atomic and Molecular Data and their Applications, ICAMDATA
2001AIPC..555    AIP Conf. Proc. 555: Cosmology and Particle Physics
2001AIPC..556    AIP Conf. Proc. 556: Explosive Phenomena in Astrophysical Compact Objects
1979AIPC...56    AIP Conf. Proc. 56: Particle Acceleration Mechanisms in Astrophysics
2001AIPC..561    AIP Conf. Proc. 561: Symposium on Nuclear Physics IV
2001AIPC..562    AIP Conf. Proc. 562: Particles and Fields
2001AIPC..565    AIP Conf. Proc. 565: Young Supernova Remnants
2001AIPC..566    AIP Conf. Proc. 566: Observing Ultrahigh Energy Cosmic Rays from Space and Earth
2001AIPC..568    AIP Conf. Proc. 568: Bayesian Inference and Maximum Entropy Methods in Science and Engineering
2001AIPC..570    AIP Conf. Proc. 570: SPIN 2000
2001AIPC..575    AIP Conf. Proc. 575: Astrophysical Sources for Ground-Based Gravitational Wave Detectors
2001AIPC..579    AIP Conf. Proc. 579: Radio Detection of High Energy Particles
2001AIPC..586    AIP Conf. Proc. 586: 20th Texas Symposium on relativistic astrophysics
2001AIPC..587    AIP Conf. Proc. 587: Gamma 2001: Gamma-Ray Astrophysics
2001AIPC..598    AIP Conf. Proc. 598: Joint SOHO/ACE workshop "Solar and Galactic Composition"
2001AIPC..599    AIP Conf. Proc. 599: X-ray Astronomy: Stellar Endpoints, AGN, and the Diffuse X-ray Background
2001AIPC..600    AIP Conf. Proc. 600: Cyclotrons and Their Applications 2001
2001AIPC..601    AIP Conf. Proc. 601: Theoretical High Energy Physics: MRST 2001
2001AIPC..602    AIP Conf. Proc. 602: QCD @ Work, International Workshop on Quantum Chromodynamics
2001AIPC..603    AIP Conf. Proc. 603: Mesons and Light Nuclei
2002AIPC..604    AIP Conf. Proc. 604: Correlations, Polarization, and Ionization in Atomic Systems
2002AIPC..605    AIP Conf. Proc. 605: Low Temperature Detectors
2002AIPC..606    AIP Conf. Proc. 606: Non-Neutral Plasma Physics IV
2002AIPC..607    AIP Conf. Proc. 607: String Theory
2002AIPC..608    AIP Conf. Proc. 608: Space Technology and Applications International Forum
2002AIPC..609    AIP Conf. Proc. 609: Astrophysical Polarized Backgrounds
2002AIPC..610    AIP Conf. Proc. 610: Nuclear Physics in the 21st Century
2002AIPC..611    AIP Conf. Proc. 611: Superstrong Fields in Plasmas
2002AIPC..612    AIP Conf. Proc. 612: Stress-Induced Phenomena in Metallization
2002AIPC..613    AIP Conf. Proc. 613: Advances in Cryogenic Engineering CEC
2002AIPC..614    AIP Conf. Proc. 614: Advances in Cryogenic Engineering ICMC
2002AIPC..615    AIP Conf. Proc. 615: Quantitative Nondestructive Evaluation
2002AIPC..616    AIP Conf. Proc. 616: Experimental Cosmology at Millimetre Wavelengths
2002AIPC..617    AIP Conf. Proc. 617: Bayesian Inference and Maximum Entropy Methods in Science and Engineering
2002AIPC..618    AIP Conf. Proc. 618: Heavy Flavor Physics
2002AIPC..619    AIP Conf. Proc. 619: Hadron Spectroscopy
2002AIPC..620    AIP Conf. Proc. 620: Shock Compression of Condensed Matter
2002AIPC..621    AIP Conf. Proc. 621: Ocean Acoustic Interference Phenomena and Signal Processing
2002AIPC..622    AIP Conf. Proc. 622: Experimental Chaos
2002AIPC..623    AIP Conf. Proc. 623: Particles and Fields
2002AIPC..624    AIP Conf. Proc. 624: Cosmology and Elementary Particle Physics
2002AIPC..626    AIP Conf. Proc. 626: Fundamental Physics of Ferroelectrics 2002
2002AIPC..627    AIP Conf. Proc. 627: Computing Anticipatory Systems: CASYS 2001
2002AIPC..628    AIP Conf. Proc. 628: Women in Physics
1980AIPC...63    AIP Conf. Proc. 63: Supernovae Spectra
2002AIPC..631    AIP Conf. Proc. 631: New States of Matter in Hadronic Interactions
2002AIPC..632    AIP Conf. Proc. 632: Unattended Radiation Sensor Systems for Remote Applications
2002AIPC..633    AIP Conf. Proc. 633: Structural and Electronic Properties of Molecular Nanostructures
2002AIPC..635    AIP Conf. Proc. 635: Atomic Processes in Plasmas
2002AIPC..636    AIP Conf. Proc. 636: Atomic and Molecular Data and Their Applications
2002AIPC..637    AIP Conf. Proc. 637: Classical Nova Explosions
2002AIPC..638    AIP Conf. Proc. 638: Mapping the Triangle
2002AIPC..639    AIP Conf. Proc. 639: Production and Neutralization of Negative Ions and Beams
2002AIPC..641    AIP Conf. Proc. 641: X-ray Lasers 2002
2002AIPC..642    AIP Conf. Proc. 642: High Intensity and High Brightness Hadron Beams
2002AIPC..643    AIP Conf. Proc. 643: Quantum Limits to the Second Law
2002AIPC..644    AIP Conf. Proc. 644: Exotic Clustering
2002AIPC..645    AIP Conf. Proc. 645: Spectral Line Shapes
2002AIPC..646    AIP Conf. Proc. 646: Theoretical Physics: MRST 2002
2002AIPC..647    AIP Conf. Proc. 647: Advanced Accelerator Concepts: Tenth Workshop
2002AIPC..648    AIP Conf. Proc. 648: Beam Instrumentation Workshop 2002
2002AIPC..649    AIP Conf. Proc. 649: Dust Crystal in the Electrode Sheath of a Gaseous Discharge
2002AIPC..650    AIP Conf. Proc. 650: Beams 2002
2002AIPC..651    AIP Conf. Proc. 651: Dense Z-Pinches
2003AIPC..652    AIP Conf. Proc. 652: X-Ray and Inner-Shell Processes
2003AIPC..653    AIP Conf. Proc. 653: Thermophotovoltaic Generation of Electricity
2003AIPC..654    AIP Conf. Proc. 654: Space Technology and Applications International Forum - STAIF 2003
2003AIPC..655    AIP Conf. Proc. 655: Particle Physics and Cosmology
2003AIPC..656    AIP Conf. Proc. 656: Frontiers of Nuclear Structure
2003AIPC..657    AIP Conf. Proc. 657: Review of Progress in Quantitative Nondestructive Evaluation
2003AIPC..658    AIP Conf. Proc. 658: Modern Challenges in Statistical Mechanics: Patterns, Noise, and the Interplay of Nonlinearity and Complexity
2003AIPC..659    AIP Conf. Proc. 659: Bayesian Inference and Maximum Entropy Methods in Science and Engineering
2003AIPC..660    AIP Conf. Proc. 660: Hadron Physics: Effective Theories of Low Energy QCD
2003AIPC..661    AIP Conf. Proc. 661: Modeling of Complex Systems
2003AIPC..662    AIP Conf. Proc. 662: Gamma-Ray Burst and Afterglow Astronomy 2001: A Workshop Celebrating the First Year of the HETE Mission
2003AIPC..663    AIP Conf. Proc. 663: Rarefied Gas Dynamics
2003AIPC..664    AIP Conf. Proc. 664: Beamed Energy Propulsion
2003AIPC..665    AIP Conf. Proc. 665: Unsolved Problems of Noise and Fluctuations: UPoN 2002
2003AIPC..666    AIP Conf. Proc. 666: The Emergence of Cosmic Structure
2003AIPC..667    AIP Conf. Proc. 667: Increasing the AGS Polarization
2003AIPC..668    AIP Conf. Proc. 668: Cosmology and Gravitation
2003AIPC..669    AIP Conf. Proc. 669: Plasma Physics
2003AIPC..670    AIP Conf. Proc. 670: Particles and Fields
2003AIPC..671    AIP Conf. Proc. 671: Hydrogen in Materials and Vacuum Systems
2003AIPC..672    AIP Conf. Proc. 672: Short Distance Behavior of Fundamental Interactions
2003AIPC..673    AIP Conf. Proc. 673: Plutonium Futures - The Science
2003AIPC..674    AIP Conf. Proc. 674: Instrumentation in Elementary Particle Physics
2003AIPC..675    AIP Conf. Proc. 675: SPIN 2002
2003AIPC..676    AIP Conf. Proc. 676: Experimental Chaos
2003AIPC..677    AIP Conf. Proc. 677: Fundamental Physics of Ferroelectrics 2003
2003AIPC..678    AIP Conf. Proc. 678: Lectures on the Physics of Highly Correlated Electron Systems VII
2003AIPC..679    AIP Conf. Proc. 679: Solar Wind Ten
2003AIPC..680    AIP Conf. Proc. 680: Application of Accelerators in Research and Industry
2003AIPC..681    AIP Conf. Proc. 681: Proton-Emitting Nuclei: Second International Symposium; PROCON 2003
2003AIPC..682    AIP Conf. Proc. 682: Medical Physics
2003AIPC..683    AIP Conf. Proc. 683: Characterization and Metrology for ULSI Technology
2003AIPC..684    AIP Conf. Proc. 684: Temperature: Its Measurement and Control in Science and Industry
2003AIPC..685    AIP Conf. Proc. 685: Molecular Nanostructures
2003AIPC..686    AIP Conf. Proc. 686: The Astrophysics of Gravitational Wave Sources
2003AIPC..687    AIP Conf. Proc. 687: High Energy Physics
2003AIPC..688    AIP Conf. Proc. 688: Scalar Mesons: An Interesting Puzzle for QCD
2003AIPC..689    AIP Conf. Proc. 689: Neutrinos, Flavor Physics, and Precision Cosmology
2003AIPC..690    AIP Conf. Proc. 690: The Monte Carlo Method in the Physical Sciences
1982AIPC...77    AIP Conf. Proc. 77: Gamma Ray Transients and Related Astrophysical Phenomena
1982AIPC...82    AIP Conf. Proc. 82: Interpretation of Climate and Photochemical Models, Ozone and Temperature
1982AIPC...83    AIP Conf. Proc. 83: The Galactic Center
1983AIPC...98    AIP Conf. Proc. 98: Particles and Fields 1982
1983AIPC...99    AIP Conf. Proc. 99: Neutrino Mass and Gauge Structure of Weak Interactions (Telemark, 1982)
    aifo.rept    Air Force Interim Report
1984abas.symp    Airborne Astronomy Symposium
1955aiau.conf    The Airglow and the Aurorae
    alab.rept    Alabama Univ., Huntsville Report
1995albu.meet    The Albuquerque Meeting, Vol. 2.
1997asxo.proc    All-Sky X-Ray Observations in the Next Decade
    aans.meet    American Astronautical Society Meeting
    aans.symp    American Astronautical Society Symposium
1999aasf.book    The American Astronomical Society's first century
    acs..meet    American Chemical Society Meeting
    aiaa.conf    American Institute of Aeronautics and Astronautics Conference
    AIPC.        American Institute of Physics Conference Series
1974amst.iafc    Amsterdam International Astronautical Federation Congress
1976anah.iafc    Anaheim International Astronautical Federation Congress
1974aem..book    Analyse Extraterrestrischen Materials
1994aelp.conf    The Analysis of Emission Lines
1995aelm.conf    The Analysis of Emission Lines
1989arcn.work    Analysis of Returned Comet Nucleus Samples
1997arcn.rept    Analysis of Returned Comet Nucleus Samples
1970acs..book    Analytical Chemistry in Space
1999aacd.book    Ancient Astronomy and Celestial Divination
1980asfr.symp    The Ancient Sun: Fossil Record in the Earth, Moon and Meteorites
1997anmi.conf    Anni Mirabiles
1990angg.nasa    Annihilation in Gases and Galaxies
1984aem..book    Anorthosites of the Earth and the Moon
1984anme....9    Antarctic Meteorites IX
1981anme....6    Antarctic Meteorites VI
1982anme....7    Antarctic Meteorites VII
1983anme....8    Antarctic Meteorites VIII
1985anme...10    Antarctic Meteorites X
1986anme...11    Antarctic Meteorites XI
1987anme...12    Antarctic Meteorites XII
1988anme...13    Antarctic Meteorites XIII
1989anme...14    Antarctic Meteorites XIV
1994anme...19    Antarctic Meteorites XIX
1990anme...15    Antarctic Meteorites XV
1991anme...16    Antarctic Meteorites XVI
1992anme...17    Antarctic Meteorites XVII
1993anme...18    Antarctic Meteorites XVII
1995anme...20    Antarctic Meteorites XX
1996anme...21    Antarctic Meteorites XXI
1997anme...22    Antarctic Meteorites XXII
1998anme...23    Antarctic Meteorites XXIII
1999anme...24    Antarctic Meteorites XXIV
2000anme...25    Antarctic Meteorites XXV
2001anme...26    Antarctic Meteorites XXVI
2002anme...27    Antarctic Meteorites XXVII
1993amc..conf    Antarctic Meteorology and Climatology: Studies Based on Automatic Weather Stations
1985ap...conf    Antennas and Propagation (ICAP 85)
1983appw.conf    Antiproton Proton Physics and the W Discovery
1999ahp..conf    APCTP Workshop on Astro-Hadron Physics.  Properties of Hadrons in Matter
1976apso.nasa    Apollo-Soyuz Test Project
1980apba.conf    Application de la Photom\x{00E9}trie Bidimensionelle \x{00E0} l'Astronomie
1974amg..conf    Applications of Marine Geodesy
1982aacp....1    Applied Atomic Collision Physics
1987apge.conf    Applied Geodesy
    arcl.rept    Applied Research Corp. Annual Report
1992anr..conf    Approaches to Numerical Relativity
1978apsi.conf    Ap-Stars in the Infrared
1981araa.conf    Archaeoastronomy in the Americas
1982arnw.conf    Archaeoastronomy in the New World
1982aow..conf    Archaeoastronomy in the Old World
    asu..rept    Arizona State University Technical Report
    uat..rept    Arizona Univ., Tucson Report
1997asca.conf    The Art and Science of CCD Astronomy
1994aira.symp    Artificial Intelligence, Robotics, and Automation for Space Symposium
1990aita.proc    Artificial Intelligence Techniques for Astronomy
1988posh.conf    ASP Conf. Ser.   1: Progress and Opportunities in Southern Hemisphere Optical Astronomy.  The CTIO 25th Anniversary Symposium
1988osq..conf    ASP Conf. Ser.   2: Optical Surveys for Quasars
1988fopa.proc    ASP Conf. Ser.   3: Fiber Optics in Astronomy
1988egds.symp    ASP Conf. Ser.   4: The Extragalactic Distance Scale
1988cgls.meet    ASP Conf. Ser.   5: The Minnesota lectures on Clusters of Galaxies and Large-Scale Structure
1989sira.conf    ASP Conf. Ser.   6: Synthesis Imaging in Radio Astronomy
1990phls.work    ASP Conf. Ser.   7: Properties of Hot Luminous Stars
1990ccda.proc    ASP Conf. Ser.   8: CCDs in astronomy
1990csss....6    ASP Conf. Ser.   9: Cool Stars, Stellar Systems, and the Sun
1990eug..symp    ASP Conf. Ser.  10: Evolution of the Universe of Galaxies
1990cbsp.proc    ASP Conf. Ser.  11: Confrontation Between Stellar Pulsation and Evolution
1990eism.conf    ASP Conf. Ser.  12: The Evolution of the Interstellar Medium
1991fesc.book    ASP Conf. Ser.  13: The Formation and Evolution of Star Clusters
1990awia.conf    ASP Conf. Ser.  14: Astrophysics with Infrared Arrays
1991lssp.conf    ASP Conf. Ser.  15: Large-scale Structures and Peculiar Motions in the Universe
1991aimn.conf    ASP Conf. Ser.  16: Atoms, Ions and Molecules: New Results in Spectral Line Astrophysics
1991lpri.conf    ASP Conf. Ser.  17: IAU Colloq. 112: Light Pollution, Radio Interference, and Space Debris
1991osgl.work    ASP Conf. Ser.  18: The Interpretation of Modern Synthesis Observations of Spiral Galaxies
1991ritt.proc    ASP Conf. Ser.  19: IAU Colloq. 131: Radio Interferometry. Theory, Techniques, and Applications
1991fse..conf    ASP Conf. Ser.  20: Frontiers of Stellar Evolution
1991sdq..proc    ASP Conf. Ser.  21: The Space Distribution of Quasars
1992nvos.work    ASP Conf. Ser.  22: Nonisotropic and Variable Outflows from Stars
1992acor.conf    ASP Conf. Ser.  23: Astronomical CCD Observing and Reduction Techniques
1992clss.conf    ASP Conf. Ser.  24: Cosmology and Large-Scale Structure in the Universe
1996clss.conf    ASP Conf. Ser.  24: Cosmology and Large-scale Structure in the Universe
1992adass...1    ASP Conf. Ser.  25: Astronomical Data Analysis Software and Systems I
1992csss....7    ASP Conf. Ser.  26: Cool Stars, Stellar Systems, and the Sun
1992socy.work    ASP Conf. Ser.  27: The Solar Cycle
1992atpi.conf    ASP Conf. Ser.  28: Automated Telescopes for Photometry and Imaging
1992cvs..work    ASP Conf. Ser.  29: Cataclysmic Variable Stars
1992vsg..conf    ASP Conf. Ser.  30: Variable Stars and Galaxies, in honor of M. W. Feast on his retirement
1992rbag.work    ASP Conf. Ser.  31: Relationships Between Active Galactic Nuclei and Starburst Galaxies
1992cadm.conf    ASP Conf. Ser.  32: IAU Colloq. 135: Complementary Approaches to Double and Multiple Star Research
1992raa..proc    ASP Conf. Ser.  33: Research Amateur Astronomy
1992robt.proc    ASP Conf. Ser.  34: Robotic Telescopes in the 1990s
1993msli.conf    ASP Conf. Ser.  35: Massive Stars:  Their Lives in the Interstellar Medium
1993pap..conf    ASP Conf. Ser.  36: Planets Around Pulsars
1993fopa.proc    ASP Conf. Ser.  37: Fiber Optics in Astronomy II
1993nfbs.proc    ASP Conf. Ser.  38: New Frontiers in Binary Star Research
1993sdmw.conf    ASP Conf. Ser.  39: The Minnesota Lectures on the Structure and Dynamics of the Milky Way
1993ist..proc    ASP Conf. Ser.  40: IAU Colloq. 137: Inside the Stars
1993ais..conf    ASP Conf. Ser.  41: Astronomical Infrared Spectroscopy: Future Observational Directions
1993gong.conf    ASP Conf. Ser.  42: GONG 1992. Seismic Investigation of the Sun and Stars
1993sspp.conf    ASP Conf. Ser.  43: Sky Surveys. Protostars to Protogalaxies
1993pvnp.conf    ASP Conf. Ser.  44: IAU Colloq. 138: Peculiar versus Normal Phenomena in A-type and Related Stars
1993lhls.work    ASP Conf. Ser.  45: Luminous High-Latitude Stars
1993mvfs.conf    ASP Conf. Ser.  46: IAU Colloq. 141: The Magnetic and Velocity Fields of Solar Active Regions
1993seti.conf    ASP Conf. Ser.  47: Third Decennial US-USSR Conference on SETI
1993gcgc.work    ASP Conf. Ser.  48: The Globular Cluster-Galaxy Connection
1993getm.conf    ASP Conf. Ser.  49: Galaxy Evolution. The Milky Way Perspective
1993sdgc.proc    ASP Conf. Ser.  50: Structure and Dynamics of Globular Clusters
1993obco.symp    ASP Conf. Ser.  51: Observational Cosmology
1993adass...2    ASP Conf. Ser.  52: Astronomical Data Analysis Software and Systems II
1993blst.conf    ASP Conf. Ser.  53: Blue Stragglers
1994pag..conf    ASP Conf. Ser.  54: The Physics of Active Galaxies
1994oaem.conf    ASP Conf. Ser.  55: Optical Astronomy from the Earth and Moon
1994ibs..conf    ASP Conf. Ser.  56: Interacting Binary Stars
1994scsa.conf    ASP Conf. Ser.  57: Stellar and Circumstellar Astrophysics, a 70th birthday celebration for K. H. Bohm and E. Bohm-Vitense
1994icdi.conf    ASP Conf. Ser.  58: The First Symposium on the Infrared Cirrus and Diffuse Interstellar Clouds
1994amsw.conf    ASP Conf. Ser.  59: IAU Colloq. 140: Astronomy with Millimeter and Submillimeter Wave Interferometry
1994mpyp.conf    ASP Conf. Ser.  60: The MK Process at 50 Years:  A Powerful Tool for Astrophysical Insight
1994adass...3    ASP Conf. Ser.  61: Astronomical Data Analysis Software and Systems III
1994nesh.conf    ASP Conf. Ser.  62: The Nature and Evolutionary Status of Herbig Ae/Be Stars
1994sfyh.conf    ASP Conf. Ser.  63: 75 Years of Hirayama Asteroid Families:  The Role of Collisions in the Solar System History
1994csss....8    ASP Conf. Ser.  64: Cool Stars, Stellar Systems, and the Sun
1994cclm.conf    ASP Conf. Ser.  65: Clouds, Cores, and Low Mass Stars
1994pgsd.conf    ASP Conf. Ser.  66: Physics of the Gaseous and Stellar Disks of the Galaxy
1994ulss.conf    ASP Conf. Ser.  67: Unveiling Large-Scale Structures Behind the Milky Way
1994sare.conf    ASP Conf. Ser.  68: Solar Active Region Evolution: Comparing Models with Observations
1994rmbl.conf    ASP Conf. Ser.  69: Reverberation Mapping of the Broad-Line Region in Active Galactic Nuclei
1995grga.conf    ASP Conf. Ser.  70: Groups of Galaxies
1995tosm.conf    ASP Conf. Ser.  71: IAU Colloq. 149: Tridimensional Optical Spectroscopic Methods in Astrophysics
1995mpds.conf    ASP Conf. Ser.  72: Millisecond Pulsars.  A Decade of Surprise
1995fgts.symp    ASP Conf. Ser.  73: From Gas to Stars to Dust
1995psel.conf    ASP Conf. Ser.  74: Progress in the Search for Extraterrestrial Life.
1995mfsr.conf    ASP Conf. Ser.  75: Multi-Feed Systems for Radio Telescopes
1995gong.conf    ASP Conf. Ser.  76: GONG 1994. Helio- and Astro-Seismology from the Earth and Space
1995adass...4    ASP Conf. Ser.  77: Astronomical Data Analysis Software and Systems IV
1995aapn.conf    ASP Conf. Ser.  78: Astrophysical Applications of Powerful New Databases
1995rtcc.conf    ASP Conf. Ser.  79: Robotic Telescopes.  Current Capabilities, Present Developments, and Future Prospects for Automated Astronomy
1995pimi.conf    ASP Conf. Ser.  80: The Physics of the Interstellar Medium and Intergalactic Medium
1995lahr.conf    ASP Conf. Ser.  81: Laboratory and Astronomical High Resolution Spectra
1995vlbi.conf    ASP Conf. Ser.  82: Very Long Baseline Interferometry and the VLBA
1995aasp.conf    ASP Conf. Ser.  83: IAU Colloq. 155: Astrophysical Applications of Stellar Pulsation
1995fust.conf    ASP Conf. Ser.  84: IAU Colloq. 148: The Future Utilisation of Schmidt Telescopes
1995mcv..conf    ASP Conf. Ser.  85: Magnetic Cataclysmic Variables
1995fveg.conf    ASP Conf. Ser.  86: Fresh Views of Elliptical Galaxies
1996nomn.conf    ASP Conf. Ser.  87: New Observing Modes for the Next Century
1996clfu.conf    ASP Conf. Ser.  88: Clusters, Lensing, and the Future of the Universe
1996aecd.conf    ASP Conf. Ser.  89: Astronomy Education: Current Developments, Future Coordination
1996oedb.conf    ASP Conf. Ser.  90: The Origins, Evolution, and Destinies of Binary Stars in Clusters
1996baga.conf    ASP Conf. Ser.  91: IAU Colloq. 157: Barred Galaxies
1996fogh.conf    ASP Conf. Ser.  92: Formation of the Galactic Halo...Inside and Out
1996ress.conf    ASP Conf. Ser.  93: Radio Emission from the Stars and the Sun
1996mmmu.conf    ASP Conf. Ser.  94: Mapping, Measuring, and Modelling the Universe
1996sdit.conf    ASP Conf. Ser.  95: Solar Drivers of the Interplanetary and Terrestrial Disturbances
1996hds..conf    ASP Conf. Ser.  96: Hydrogen Deficient Stars
1996pim..conf    ASP Conf. Ser.  97: Polarimetry of the Interstellar Medium
1996fstg.conf    ASP Conf. Ser.  98: From Stars to Galaxies: the Impact of Stellar Physics on Galaxy Evolution
1996coab.proc    ASP Conf. Ser.  99: Cosmic Abundances
1996etrg.conf    ASP Conf. Ser. 100: Energy Transport in Radio Galaxies and Quasars
1996adass...5    ASP Conf. Ser. 101: Astronomical Data Analysis Software and Systems V
1996tgc..conf    ASP Conf. Ser. 102: The Galactic Center
1996tpol.conf    ASP Conf. Ser. 103: The Physics of Liners in View of Recent Observations
1996pcdi.conf    ASP Conf. Ser. 104: IAU Colloq. 150: Physics, Chemistry, and Dynamics of Interplanetary Dust
1996ppp..conf    ASP Conf. Ser. 105: IAU Colloq. 160: Pulsars: Problems and Progress
1996eghi.proc    ASP Conf. Ser. 106: The Minnesota Lectures on Extragalactic Neutral Hydrogen
1996ciss.conf    ASP Conf. Ser. 107: Completing the Inventory of the Solar System
1996mass.conf    ASP Conf. Ser. 108: M.A.S.S., Model Atmospheres and Spectrum Synthesis
1996csss....9    ASP Conf. Ser. 109: Cool Stars, Stellar Systems, and the Sun
1996bcv..conf    ASP Conf. Ser. 110: Blazar Continuum Variability
1997mrsa.conf    ASP Conf. Ser. 111: Magnetic Reconnection in the Solar Atmosphere
1996gach.conf    ASP Conf. Ser. 112: The History of the Milky Way and Its Satellite System
1997elag.conf    ASP Conf. Ser. 113: IAU Colloq. 159: Emission Lines in Active Galaxies: New Methods and Techniques
1997ygqa.conf    ASP Conf. Ser. 114: Young Galaxies and QSO Absorption-Line Systems
1997gccf.conf    ASP Conf. Ser. 115: Galactic Cluster Cooling Flows
1997neg..conf    ASP Conf. Ser. 116: The Nature of Elliptical Galaxies; 2nd Stromlo Symposium
1997dvmg.proc    ASP Conf. Ser. 117: Dark and Visible Matter in Galaxies and Cosmological Implications
1997fasp.conf    ASP Conf. Ser. 118: 1st Advances in Solar Physics Euroconference.  Advances in Physics of Sunspots
1997pbss.conf    ASP Conf. Ser. 119: Planets Beyond the Solar System and the Next Generation of Space Missions
1997lbv..conf    ASP Conf. Ser. 120: Luminous Blue Variables: Massive Stars in Transition
1997apro.conf    ASP Conf. Ser. 121: IAU Colloq. 163: Accretion Phenomena and Related Outflows
1997fstp.conf    ASP Conf. Ser. 122: From Stardust to Planetesimals
1997taca.conf    ASP Conf. Ser. 123: Computational Astrophysics; 12th Kingston Meeting on Theoretical Astrophysics
1997diri.conf    ASP Conf. Ser. 124: Diffuse Infrared Radiation and the IRTS
1997adass...6    ASP Conf. Ser. 125: Astronomical Data Analysis Software and Systems VI
1997fqfc.conf    ASP Conf. Ser. 126: From Quantum Fluctuations to Cosmological Structures
1997pmga.conf    ASP Conf. Ser. 127: Proper Motions and Galactic Astronomy
1997meag.conf    ASP Conf. Ser. 128: Mass Ejection from Active Galactic Nuclei
1997ggs..conf    ASP Conf. Ser. 129: George Gamow Symposium
1997rdbs.conf    ASP Conf. Ser. 130: The Third Pacific Rim Conference on Recent Development on Binary Star Research
1998phls.conf    ASP Conf. Ser. 131: Properties of Hot Luminous Stars
1998sfis.conf    ASP Conf. Ser. 132: Star Formation with the Infrared Space Observatory
1998swng.conf    ASP Conf. Ser. 133: Science With The NGST
1998bdep.conf    ASP Conf. Ser. 134: Brown Dwarfs and Extrasolar Planets
1998hcsp.conf    ASP Conf. Ser. 135: A Half Century of Stellar Pulsation Interpretation
1998gaha.conf    ASP Conf. Ser. 136: Galactic Halos
1998wsow.conf    ASP Conf. Ser. 137: Wild Stars in the Old West
1998stas.conf    ASP Conf. Ser. 138: 1997 Pacific Rim Conference on Stellar Astrophysics
1998paw..conf    ASP Conf. Ser. 139: Preserving The Astronomical Windows
1998ssp..conf    ASP Conf. Ser. 140: Synoptic Solar Physics
1998afa..conf    ASP Conf. Ser. 141: Astrophysics From Antarctica
1998simf.conf    ASP Conf. Ser. 142: The Stellar Initial Mass Function (38th Herstmonceux Conference)
1998sigh.conf    ASP Conf. Ser. 143: The Scientific Impact of the Goddard High Resolution Spectrograph
1998rege.conf    ASP Conf. Ser. 144: IAU Colloq. 164: Radio Emission from Galactic and Extragalactic Compact Sources
1998adass...7    ASP Conf. Ser. 145: Astronomical Data Analysis Software and Systems VII
1998yugf.conf    ASP Conf. Ser. 146: The Young Universe: Galaxy Formation and Evolution at Intermediate and High Redshift
1998apdt.conf    ASP Conf. Ser. 147: Abundance Profiles: Diagnostic Tools for Galaxy History
1998orig.conf    ASP Conf. Ser. 148: Origins
1998ssfe.conf    ASP Conf. Ser. 149: Solar System Formation and Evolution
1998npsp.conf    ASP Conf. Ser. 150: IAU Colloq. 167: New Perspectives on Solar Prominences
1998cmbl.conf    ASP Conf. Ser. 151: Cosmic Microwave Background and Large Scale Structure of the Universe
1998fopa.proc    ASP Conf. Ser. 152: Fiber Optics in Astronomy III
1998lisa.conf    ASP Conf. Ser. 153: Library and Information Services in Astronomy III
1998csss...10    ASP Conf. Ser. 154: Cool Stars, Stellar Systems, and the Sun
1998sasp.conf    ASP Conf. Ser. 155: Three-Dimensional Structure of Solar Active Regions
1999hrrl.conf    ASP Conf. Ser. 156: Highly Redshifted Radio Lines
1999mcv..work    ASP Conf. Ser. 157: Annapolis Workshop on Magnetic Cataclysmic Variables
1999ssa..conf    ASP Conf. Ser. 158: Solar and Stellar Activity:  Similarities and Differences
1999bllp.conf    ASP Conf. Ser. 159: BL Lac Phenomenon
1999asdi.conf    ASP Conf. Ser. 160: Astrophysical Discs - an EC Summer School
1999hepa.conf    ASP Conf. Ser. 161: High Energy Processes in Accreting Black Holes
1999quco.conf    ASP Conf. Ser. 162: Quasars and Cosmology
1999sfet.conf    ASP Conf. Ser. 163: Star Formation in Early Type Galaxies
1999uosa.conf    ASP Conf. Ser. 164: Ultraviolet-Optical Space Astronomy Beyond HST
1999gaha.conf    ASP Conf. Ser. 165: The Third Stromlo Symposium: The Galactic Halo
1999hvc..work    ASP Conf. Ser. 166: Stromlo Workshop on High-Velocity Clouds
1999hcds.conf    ASP Conf. Ser. 167: Harmonizing Cosmic Distance Scales in a Post-HIPPARCOS Era
1999npim.conf    ASP Conf. Ser. 168: New Perspectives on the Interstellar Medium
1999ewwd.conf    ASP Conf. Ser. 169: 11th European Workshop on White Dwarfs
1999lsbu.conf    ASP Conf. Ser. 170: The Low Surface Brightness Universe
1999lcrr.conf    ASP Conf. Ser. 171: LiBeB Cosmic Rays, and Related X- and Gamma-Rays
1999adass...8    ASP Conf. Ser. 172: Astronomical Data Analysis Software and Systems VIII
1999sstt.conf    ASP Conf. Ser. 173: Stellar Structure:  Theory and Test of Connective Energy Transport
1999cpw..conf    ASP Conf. Ser. 174: Catching the Perfect Wave:  Adaptive Optics and Interferometry for the 21st Century
1999skqb.conf    ASP Conf. Ser. 175: Structure and Kinematics of Quasar Broad Line Regions
1999obco.conf    ASP Conf. Ser. 176: Observational Cosmology: The Development of Galaxy Systems
1999aisp.conf    ASP Conf. Ser. 177: Astrophysics with Infrared Surveys: A Prelude to SIRTF
1999sdnc.conf    ASP Conf. Ser. 178: Stellar Dynamos: Nonlinearity and Chaotic Flows
1999ecm..conf    ASP Conf. Ser. 179: Eta Carinae at The Millennium
1999sira.conf    ASP Conf. Ser. 180: Synthesis Imaging in Radio Astronomy II
1999mifo.conf    ASP Conf. Ser. 181: Microwave Foregrounds
1999gady.conf    ASP Conf. Ser. 182: Galaxy Dynamics - A Rutgers Symposium
1999hrsp.conf    ASP Conf. Ser. 183: High Resolution Solar Physics: Theory, Observations, and Techniques
1999tasp.conf    ASP Conf. Ser. 184: Third Advances in Solar Physics Euroconference: Magnetic Fields and Oscillations
1999psrv.conf    ASP Conf. Ser. 185: IAU Colloq. 170: Precise Stellar Radial Velocities
1999cpg..conf    ASP Conf. Ser. 186: The Central Parsecs of the Galaxy
1999egct.conf    ASP Conf. Ser. 187: The Evolution of Galaxies on Cosmological Timescales
1999oisc.conf    ASP Conf. Ser. 188: Optical and Infrared Spectroscopy of Circumstellar Matter
1999pcp..conf    ASP Conf. Ser. 189: Precision CCD Photometry
1999grb..conf    ASP Conf. Ser. 190: Gamma-Ray Bursts: The First Three Minutes
1999prdh.conf    ASP Conf. Ser. 191: Photometric Redshifts and the Detection of High Redshift Galaxies
1999sdsg.conf    ASP Conf. Ser. 192: Spectrophotometric Dating of Stars and Galaxies
1999hrug.conf    ASP Conf. Ser. 193: The Hy-Redshift Universe: Galaxy Formation and Evolution at High Redshift
1999wfoi.conf    ASP Conf. Ser. 194: Working on the Fringe: Optical and IR Interferometry from Ground and Space
2000iutd.conf    ASP Conf. Ser. 195: Imaging the Universe in Three Dimensions
2000tesa.conf    ASP Conf. Ser. 196: Thermal Emission Spectroscopy and Analysis of Dust, Disks, and Regoliths
2000dgeu.conf    ASP Conf. Ser. 197: Dynamics of Galaxies: from the Early Universe to the Present
2000scac.conf    ASP Conf. Ser. 198: Stellar Clusters and Associations: Convection, Rotation, and Dynamos
2000apn..conf    ASP Conf. Ser. 199: Asymmetrical Planetary Nebulae II: From Origins to Microstructures
2000chr..conf    ASP Conf. Ser. 200: Clustering at High Redshift
2000cofl.work    ASP Conf. Ser. 201: Cosmic Flows Workshop
2000puas.conf    ASP Conf. Ser. 202: IAU Colloq. 177: Pulsar Astronomy - 2000 and Beyond
2000ilss.conf    ASP Conf. Ser. 203: IAU Colloq. 176: The Impact of Large-Scale Surveys on Pulsating Star Research
2000tiaf.conf    ASP Conf. Ser. 204: Thermal and Ionization Aspects of Flows from Hot Stars
2000ltse.conf    ASP Conf. Ser. 205: Last Total Solar Eclipse of the Millennium
2000hesp.conf    ASP Conf. Ser. 206: High Energy Solar Physics Workshop - Anticipating Hess!
2000ngst.conf    ASP Conf. Ser. 207: Next Generation Space Telescope Science and Technology
2000pmhs.conf    ASP Conf. Ser. 208: IAU Colloq. 178: Polar Motion: Historical and Scientific Problems
2000sgg..conf    ASP Conf. Ser. 209: IAU Colloq. 174: Small Galaxy Groups
2000dsrs.conf    ASP Conf. Ser. 210: Delta Scuti and Related Stars
2000msc..conf    ASP Conf. Ser. 211: Massive Stellar Clusters
2000fgpc.conf    ASP Conf. Ser. 212: From Giant Planets to Cool Stars
2000bioa.conf    ASP Conf. Ser. 213: Bioastronomy 99
2000bpet.conf    ASP Conf. Ser. 214: IAU Colloq. 175: The Be Phenomenon in Early-Type Stars
2000cegf.conf    ASP Conf. Ser. 215: Cosmic Evolution and Galaxy Formation: Structure, Interactions, and Feedback
2000adass...9    ASP Conf. Ser. 216: Astronomical Data Analysis Software and Systems IX
2000irsm.conf    ASP Conf. Ser. 217: Imaging at Radio through Submillimeter Wavelengths
2000mhu..conf    ASP Conf. Ser. 218: Mapping the Hidden Universe: The Universe behind the Mily Way - The Universe in HI
2000dpp..conf    ASP Conf. Ser. 219: Disks, Planetesimals, and Planets
2000appa.conf    ASP Conf. Ser. 220: Amateur - Professional Partnerships in Astronomy
2000sgdg.conf    ASP Conf. Ser. 221: Stars, Gas and Dust in Galaxies: Exploring the Links
2001pgf..conf    ASP Conf. Ser. 222: The Physics of Galaxy Formation
2001csss...11    ASP Conf. Ser. 223: 11th Cambridge Workshop on Cool Stars, Stellar Systems and the Sun
2001ppag.conf    ASP Conf. Ser. 224: Probing the Physics of Active Galactic Nuclei
2001vof..conf    ASP Conf. Ser. 225: Virtual Observatories of the Future
2001ewwd.work    ASP Conf. Ser. 226: 12th European Workshop on White Dwarfs
2001bdp..conf    ASP Conf. Ser. 227: Blazar Demographics and Physics
2001dscm.conf    ASP Conf. Ser. 228: Dynamics of Star Clusters and the Milky Way
2001ebms.conf    ASP Conf. Ser. 229: Evolution of Binary and Multiple Star Systems
2001gddg.conf    ASP Conf. Ser. 230: Galaxy Disks and Disk Galaxies
2001gssi.conf    ASP Conf. Ser. 231: Tetons 4: Galactic Structure, Stars and the Interstellar Medium
2001newf.conf    ASP Conf. Ser. 232: The New Era of Wide Field Astronomy
2001pcyg.conf    ASP Conf. Ser. 233: P Cygni 2000: 400 Years of Progress
2001xras.conf    ASP Conf. Ser. 234: X-ray Astronomy 2000
2001salm.conf    ASP Conf. Ser. 235: Science with the Atacama Large Millimeter Array
2001aspt.conf    ASP Conf. Ser. 236: Advanced Solar Polarimetry -- Theory, Observation, and Instrumentation
2001glrp.conf    ASP Conf. Ser. 237: Gravitational Lensing: Recent Progress and Future Go
2001adass..10    ASP Conf. Ser. 238: Astronomical Data Analysis Software and Systems X
2001mlap.conf    ASP Conf. Ser. 239: Microlensing 2000: A New Era of Microlensing Astrophysics
2001gge..conf    ASP Conf. Ser. 240: Gas and Galaxy Evolution
2001cru..conf    ASP Conf. Ser. 241: The 7th Taipei Astrophysics Workshop on Cosmic Rays in the Universe
2001ecom.conf    ASP Conf. Ser. 242: Eta Carinae and Other Mysterious Stars: The Hidden Opportunities of Emission Spectroscopy
2001fdtl.conf    ASP Conf. Ser. 243: From Darkness to Light: Origin and Evolution of Young Stellar Clusters
2001ysne.conf    ASP Conf. Ser. 244: Young Stars Near Earth: Progress and Prospects
2001aats.conf    ASP Conf. Ser. 245: Astrophysical Ages and Times Scales
2001stag.conf    ASP Conf. Ser. 246: IAU Colloq. 183: Small Telescope Astronomy on Global Scales
2001scpp.conf    ASP Conf. Ser. 247: Spectroscopic Challenges of Photoionized Plasmas
2001mfah.conf    ASP Conf. Ser. 248: Magnetic Fields Across the Hertzsprung-Russell Diagram
2001cksa.conf    ASP Conf. Ser. 249: The Central Kiloparsec of Starbursts and AGN: The La Palma Connection
2001pfrg.conf    ASP Conf. Ser. 250: Particles and Fields in Radio Galaxies Conference
2001ncxa.conf    ASP Conf. Ser. 251: New Century of X-ray Astronomy
2001hdmc.conf    ASP Conf. Ser. 252: Historical Development of Modern Cosmology
2002ceii.conf    ASP Conf. Ser. 253: Chemical Enrichment of Intracluster and Intergalactic Medium
2002eglr.conf    ASP Conf. Ser. 254: Extragalactic Gas at Low Redshift
2002moag.conf    ASP Conf. Ser. 255: Mass Outflow in Active Galactic Nuclei: New Perspectives
2002oapb.conf    ASP Conf. Ser. 256: Observational Aspects of Pulsating B- and A Stars
2002hzcm.conf    ASP Conf. Ser. 257: AMiBA 2001: High-Z Clusters, Missing Baryons, and CMB Polarization
2002iuag.conf    ASP Conf. Ser. 258: Issues in Unification of Active Galactic Nuclei
2002rnpp.conf    ASP Conf. Ser. 259: IAU Colloq. 185: Radial and Nonradial Pulsationsn as Probes of Stellar Physics
2002iwms.conf    ASP Conf. Ser. 260: Interacting Winds from Massive Stars
2002pcvr.conf    ASP Conf. Ser. 261: The Physics of Cataclysmic Variables and Related Objects
2002heus.conf    ASP Conf. Ser. 262: The High Energy Universe at Sharp Focus: Chandra Science
2002scmc.conf    ASP Conf. Ser. 263: Stellar Collisions, Mergers and their Consequences
2002ccea.conf    ASP Conf. Ser. 264: Continuing the Challenge of EUV Astronomy: Current Analysis and Prospects for the Future
2002ocuw.conf    ASP Conf. Ser. 265: Omega Centauri, A Unique Window into Astrophysics
2002asev.conf    ASP Conf. Ser. 266: Astronomical Site Evaluation in the Visible and Radio Range
2002host.work    ASP Conf. Ser. 267: Hot Star Workshop III: The Earliest Phases of Massive Star Birth
2002hsw..work    ASP Conf. Ser. 267: Hot Star Workshop III: The Earliest Phases of Massive Star Birth
2002tceg.conf    ASP Conf. Ser. 268: Tracing Cosmic Evolution with Galaxy Clusters
2002esip.conf    ASP Conf. Ser. 269: The Evolving Sun and its Influence on Planetary Environments
2002aia..conf    ASP Conf. Ser. 270: Astronomical Instrumentation and Astrophysics
2002nssr.conf    ASP Conf. Ser. 271: Neutron Stars in Supernova Remnants
2002fsse.conf    ASP Conf. Ser. 272: The Future of Solar System Exploration (2003-2013) -- First Decadal Study contributions
2002dshg.conf    ASP Conf. Ser. 273: The Dynamics, Structure & History of Galaxies: A Workshop in Honour of Professor Ken Freeman
2002ohds.conf    ASP Conf. Ser. 274: Observed HR Diagrams and Stellar Evolution
2002dgkd.conf    ASP Conf. Ser. 275: Disks of Galaxies: Kinematics, Dynamics and Peturbations
2002stdd.conf    ASP Conf. Ser. 276: Seeing Through the Dust: The Detection of HI and the Exploration of the ISM in Galaxies
2002sccx.conf    ASP Conf. Ser. 277: Stellar Coronae in the Chandra and XMM-NEWTON Era
2002sdra.conf    ASP Conf. Ser. 278: Single-Dish Radio Astronomy: Techniques and Applications
2002esce.conf    ASP Conf. Ser. 279: Exotic Stars as Challenges to Evolution
2002ngwf.conf    ASP Conf. Ser. 280: Next Generation Wide-Field Multi-Object Spectroscopy
2002adass..11    ASP Conf. Ser. 281: Astronomical Data Analysis Software and Systems XI
2002gtd..conf    ASP Conf. Ser. 282: Galaxies: the Third Dimension
2002nec..conf    ASP Conf. Ser. 283: A New Era in Cosmology
2002agns.conf    ASP Conf. Ser. 284: AGN Surveys
2002msfo.conf    ASP Conf. Ser. 285: Modes of Star Formation and the Origin of Field Populations
2003ctmf.conf    ASP Conf. Ser. 286: Current Theoretical Models and Future High Resolution Solar Observations: Preparing for ATST
2003gsfa.conf    ASP Conf. Ser. 287: Galactic Star Formation Across the Stellar Mass Spectrum
2003sam..conf    ASP Conf. Ser. 288: Stellar Atmosphere Modeling
2003aprm.conf    ASP Conf. Ser. 289: The Proceedings of the IAU 8th Asian-Pacific Regional Meeting, Volume I
2003agnc.conf    ASP Conf. Ser. 290: Active Galactic Nuclei: From Central Engine to Host Galaxy
2003hslf.conf    ASP Conf. Ser. 291: Hubble's Science Legacy: Future Optical/Ultraviolet Astronomy from Space
2003ipc..conf    ASP Conf. Ser. 292: Interplay of Periodic, Cyclic and Stochastic Variability in Selected Areas of the H-R Diagram
2003tdse.conf    ASP Conf. Ser. 293: 3D Stellar Evolution
2003sfre.conf    ASP Conf. Ser. 294: Scientific Frontiers in Research on Extrasolar Planets
2003adass..12    ASP Conf. Ser. 295: Astronomical Data Analysis Software and Systems XII
2003nhgc.conf    ASP Conf. Ser. 296: New Horizons in Globular Cluster Astronomy
2003sftt.conf    ASP Conf. Ser. 297: Star Formation Through Time
2003gsst.conf    ASP Conf. Ser. 298: GAIA Spectroscopy: Science and Technology
2003heba.conf    ASP Conf. Ser. 299: High Energy Blazar Astronomy
2003raf..conf    ASP Conf. Ser. 300: Radio Astronomy at the Fringe
2003rapu.conf    ASP Conf. Ser. 302: Radio Pulsars
2004apnw.conf    ASP Conf. Ser. 313: Asymmetrical Planetary Nebulae III: Winds, Structure and the Thunderbird
2004adass..13    ASP Conf. Ser. 314: Astronomical Data Analysis Software and Systems (ADASS) XIII
1986acim.book    Aspects of the Complex Investigation of the Moon
1986awph.conf    Aspen Winter Physics Conference
1965sosp.conf    ASSL Vol. 1: The Solar Spectrum
1968phma.conf    ASSL Vol. 10: Physics of the Magnetosphere
1983kdsm.work    ASSL Vol. 100: Kinematics, Dynamics and Structure of the Milky Way
1983cvro.proc    ASSL Vol. 101: IAU Colloq. 72: Cataclysmic Variables and Related Objects
1983ards.proc    ASSL Vol. 102: IAU Colloq. 71: Activity in Red-Dwarf Stars
1983ajet.proc    ASSL Vol. 103: Astrophysical Jets
1983stp..conf    ASSL Vol. 104: Solar-Terrestrial Physics: Principles and Theoretical Foundations
1983ssg..work    ASSL Vol. 105: Surveys of the Southern Galaxy
1983dtes.coll    ASSL Vol. 106: IAU Colloq. 74: Dynamical Trapping and Evolution in the Solar System
1984geis.proc    ASSL Vol. 108: Galactic and Extragalactic Infrared Spectroscopy
1984stnu.conf    ASSL Vol. 109: Stellar Nucleosynthesis
1984astt.coll    ASSL Vol. 110: IAU Colloq. 78: Astronomy with Schmidt-Type Telescopes
1984cgg..conf    ASSL Vol. 111: Clusters and Groups of Galaxies
1985cvlm.proc    ASSL Vol. 113: Cataclysmic Variables and Low-Mass X-ray Binaries
1985cseh.proc    ASSL Vol. 114: Cool Stars with Excesses of Heavy Elements
1985dcto.proc    ASSL Vol. 115: IAU Colloq. 83: Dynamics of Comets: Their Origin and Evolution
1985rst..conf    ASSL Vol. 116: Radio Stars
1985mlrg.proc    ASSL Vol. 117: Mass Loss from Red Giants
1985ehcr.conf    ASSL Vol. 118: Early History of Cosmic Ray Studies
1985piid.proc    ASSL Vol. 119: IAU Colloq. 85: Properties and Interactions of Interplanetary Dust
1969mere.conf    ASSL Vol. 12: Meteorite Research
1985bems.symp    ASSL Vol. 120: Birth and Evolution of Massive Stars and Stellar Groups
1986seag.proc    ASSL Vol. 121: Structure and Evolution of Active Galactic Nuclei
1986seg..work    ASSL Vol. 122: Spectral Evolution of Galaxies
1986shtd.symp    ASSL Vol. 123: The Sun and the Heliosphere in Three Dimensions
1986lodm.conf    ASSL Vol. 124: Light on Dark Matter
1986umss.proc    ASSL Vol. 125: IAU Colloq. 90: Upper Main Sequence Stars with Anomalous Abundances
1986swmc.conf    ASSL Vol. 126: Solar Wind Magnetosphere Coupling
1986sdcm.work    ASSL Vol. 127: Space Dynamics and Celestial Mechanics
1986hdsr.proc    ASSL Vol. 128: IAU Colloq. 87: Hydrogen Deficient Stars and Related Objects
1987euwi.book    ASSL Vol. 129: Exploring the Universe with the IUE Satellite
1969mlfs.conf    ASSL Vol. 13: Mass Loss from Stars
1987lsse.proc    ASSL Vol. 132: Late Stages of Stellar Evolution
1987ip...symp    ASSL Vol. 134: Interstellar Processes
1987pppn.work    ASSL Vol. 135: Planetary and Proto-Planetary Nebulae: From IRAS to ISO
1987ilet.work    ASSL Vol. 136: Instabilities in Luminous Early Type Stars
1987isav.symp    ASSL Vol. 137: The Internal Solar Angular Velocity
1988pffl.proc    ASSL Vol. 138: IAU Colloq. 94: Physics of Formation of FE II Lines Outside LTE
1969lwii.conf    ASSL Vol. 14: Low-Frequency Waves and Irregularities in the Ionosphere
1988fbp..coll    ASSL Vol. 140: IAU Colloq. 96: The Few Body Problem
1988uglr.work    ASSL Vol. 141: Towards Understanding Galaxies at Large Redshift
1988mosg.proc    ASSL Vol. 142: Mass Outflows from Stars and Galactic Nuclei
1988acse.book    ASSL Vol. 143: Activity in Cool Star Envelopes
1988bns..proc    ASSL Vol. 144: IAU Colloq. 99: Bioastronomy - The Next Steps
1988syph.book    ASSL Vol. 145: IAU Colloq. 103: The Symbiotic Phenomenon
1988rcia.conf    ASSL Vol. 146: Rate Coefficients in Astrochemistry
1988msas.conf    ASSL Vol. 147: Millimetre and Submillimetre Astronomy
1988pmls.conf    ASSL Vol. 148: Pulsation and Mass Loss in Stars
1988ecda.book    ASSL Vol. 149: Experiments on Cosmic Dust Analogues
1969spen.conf    ASSL Vol. 15: Space Engineering
1989dsqs.work    ASSL Vol. 150: Dynamics and Structure of Quiescent Solar Prominences
1988lssm.conf    ASSL Vol. 151: Large Scale Structure and Motions in the Universe
1989rfr..conf    ASSL Vol. 154: Reference Frames
1989acfp.proc    ASSL Vol. 155: Astronomy, Cosmology and Fundamental Physics
1989admf.proc    ASSL Vol. 156: Accretion Disks and Magnetic Fields in Astrophysics
1989plbv.coll    ASSL Vol. 157: IAU Colloq. 113: Physics of Luminous Blue Variables
1990suas.conf    ASSL Vol. 158: Submillimetre Astronomy
1990insu.conf    ASSL Vol. 159: IAU Colloq. 121: Inside the Sun
1969mls..conf    ASSL Vol. 16: Manned Laboratories in Space
1990wiga.conf    ASSL Vol. 160: Windows on Galaxies
1990ismg.conf    ASSL Vol. 161: The Interstellar Medium in Galaxies
1990ppfs.work    ASSL Vol. 162: Physical Processes in Fragmentation and Star Formation
1990rrly.conf    ASSL Vol. 163: IAU Colloq. 125: Radio Recombination Lines: 25 Years of Investigation
1990cmwb.book    ASSL Vol. 164: The Cosmic Microwave Backround: 25 Years Later
1990dou..conf    ASSL Vol. 165: Dusty Objects in the Universe
1990oeob.coll    ASSL Vol. 166: IAU Colloq. 123: Observatories in Earth Orbit and Beyond
1991cphe.conf    ASSL Vol. 167: IAU Colloq. 116: Comets in the post-Halley era
1991pnee.proc    ASSL Vol. 169: Primordial Nucleosynthesis and Evolution of Early Universe
1970pfm..conf    ASSL Vol. 17: Particles and Field in the Magnetosphere
1991oeid.coll    ASSL Vol. 173: IAU Colloq. 126: Origin and Evolution of Interplanetary Dust
1992doss.conf    ASSL Vol. 174: Digitised Pptical Sky Surveys
1992ribs.conf    ASSL Vol. 177: The Realm of Interacting Binary Stars
1992mpcg.work    ASSL Vol. 178: Morphological and Physical Classification of Galaxies
1992cbdm.book    ASSL Vol. 180: The center, bulge, and disk of the Milky Way
1993iirc.book    ASSL Vol. 182: Intelligent Information Retrieval: The Case of Astronomy and Related Space Sciences
1993pssc.symp    ASSL Vol. 183: Physics of Solar and Stellar Coronae
1993sjbo.conf    ASSL Vol. 186: Stellar Jets and Bipolar Outflows
1994fsgb.book    ASSL Vol. 187: Frontiers of Space and Ground-Based Astronomy
1993eeg..conf    ASSL Vol. 188: The Environment and Evolution of Galaxies
1970iso..conf    ASSL Vol. 19: Satellite Observations
1994iaan.conf    ASSL Vol. 190: Astronomy with Arrays, The Next Generation
1965istr.conf    ASSL Vol. 2: Introduction to Solar Terrestrial Relations
1970edfr.conf    ASSL Vol. 20: Earthquake Displacement Field and the Rotation of the Earth
1995dib..book    ASSL Vol. 202: The Diffuse Interstellar Bands
1995ioda.book    ASSL Vol. 203: Information & On-Line Data in Astronomy
1995cava.conf    ASSL Vol. 205: Cataclysmic Variables
1996cghr.conf    ASSL Vol. 206: Cold Gas at High Redshift
1996woca.conf    ASSL Vol. 207: The Westerbork Observatory, Continuing Adventure in
1996cvro.coll    ASSL Vol. 208: IAU Colloq. 158: Cataclysmic Variables and Related Objects
1996nepn.conf    ASSL Vol. 209: New Extragalactic Perspectives in the New South Africa
1997ilsn.proc    ASSL Vol. 210: The Impact of Large Scale Near-IR Sky Surveys
1997grco.conf    ASSL Vol. 211: Gravitation and Cosmology
1997wfs..conf    ASSL Vol. 212: Wide-field spectroscopy
1997whdw.work    ASSL Vol. 214: White dwarfs
1997isia.conf    ASSL Vol. 215: Infrared Space Interferometry : Astrophysics & the Study of Earth-Like Planets
1997ats..proc    ASSL Vol. 218: Astronomical Time Series
1971seg..conf    ASSL Vol. 22: Structure and Evolution of the Galaxy
1997tgms.conf    ASSL Vol. 220: The Three Galileos the Man, the Spacecraft the Telescope
1998ream.conf    ASSL Vol: 222: Remembering Edith Alice Mueller
1997vdsf.conf    ASSL Vol. 223: Visual Double Stars : Formation, Dynamics and Evolutionary Tracks
1997eppa.conf    ASSL Vol. 224: Electronic Publishing for Physics and Astronomy
1997scor.proc    ASSL Vol. 225: SCORe'96 : Solar Convection and Oscillations and their Relationship
1998ocnr.conf    ASSL Vol. 226: Observational Cosmology with the New Radio Surveys
1998ssi..conf    ASSL Vol. 227: Solar System Ices
1998oda..conf    ASSL Vol. 228: Optical Detectors for Astronomy
1998opaf.conf    ASSL Vol. 229: Observational Plasma Astrophysics : Five Years of YOHKOH and Beyond
1971macl.conf    ASSL Vol. 23: The Magellanic Clouds
1998inis.conf    ASSL Vol. 230: The Impact of Near-Infrared Sky Surveys on Galactic and Extragalactic Astronomy
1998evun.work    ASSL Vol. 231: The Evolving Universe
1998best.work    ASSL Vol. 233: B[e] stars
1999oebh.conf    ASSL Vol. 234: Observational Evidence for the Black Holes in the Universe
1998lasr.conf    ASSL Vol: 236: Laboratory astrophysics and space research
1999phcc.conf    ASSL Vol. 237: Post-Hipparcos cosmic candles
1998subs.conf    ASSL Vol. 238: Substorms-4
1999msa..proc    ASSL Vol. 239: Motions in the Solar Atmosphere
1971raat.conf    ASSL Vol. 24: The Radiating Atmosphere
1999numa.conf    ASSL Vol. 240: Numerical Astrophysics
1999mwam.conf    ASSL Vol. 241: Millimeter-Wave Astronomy: Molecular Chemistry & Physics in Space.
1999sopo.conf    ASSL Vol. 243: Polarization
1971mmre.conf    ASSL Vol. 25: Mesospheric Models and Related Experiments
2001ibsp.conf    ASSL Vol. 264: The Influence of Binaries on Stellar Population Studies
2001nugh.conf    ASSL Vol. 267: The Nature of Unidentified Galactic High-Energy Gamma-Ray Sources
1971psc..conf    ASSL Vol. 27: Physics of the Solar Corona
2002mpgc.book    ASSL Vol. 272: Merging Processes in Galaxy Clusters
2002nqsa.conf    ASSL Vol. 274: New Quests in Stellar Astrophysics: the Link Between Stars and Cosmology
2002mtoc.conf    ASSL Vol. 276: Modern Theoretical and Observational Cosmology
2003igcd.conf    ASSL Vol. 281: The IGM/Galaxy Connection. The Distribution of Baryons at z=0
2003mlps.work    ASSL Vol. 283: Mass-Losing Pulsating Stars and their Circumstellar Matter
2003lpgv.conf    ASSL Vol. 284: Light Pollution: The Global View
1972sun..conf    ASSL Vol. 29: The Sun.  Part 1 of Solar-Terrestrial Physics/1970
2003asco.conf    ASSL Vol. 290: Astronomy Communication
2003sath.conf    ASSL Vol. 298: Stellar Astrophysics - A Tribute to Helmut A. Abt
1965pss..conf    ASSL Vol. 3: Plasma Space Science
1972idts.conf    ASSL Vol. 30: Infrared Detection Techniques for Space Research
1971gnbp.coll    ASSL Vol. 31: IAU Colloq. 10: Gravitational N-Body Problem
1972emp..conf    ASSL Vol. 32: Earth's Magnetospheric Processes
1973pcua.conf    ASSL Vol. 35: Physics and Chemistry of Upper Atmospheres
1973vsgc.coll    ASSL Vol. 36: IAU Colloq. 21: Variable Stars in Globular Clusters and in Related Systems
1973ppis.conf    ASSL Vol. 37: Photon and Particle Interactions with Surfaces in Space
1973rac..conf    ASSL Vol. 38: Relativity, Astrophysics and Cosmology
1973rada.conf    ASSL Vol. 39: Recent Advances in Dynamical Astronomy
1973cosm.conf    ASSL Vol. 40: Cosmochemistry
1974cimo.symp    ASSL Vol. 42: Correlated Interplanetary and Magnetospheric Observations
1974xras.conf    ASSL Vol. 43: X-ray Astronomy
1974maph.conf    ASSL Vol. 44: Magnetospheric Physics
1974ssr..conf    ASSL Vol. 45: Supernovae and Supernova Remnants
1975nsbh.proc    ASSL Vol. 48: Neutron Stars, Black Holes and Binary X-ray Sources
1966rtem.conf    ASSL Vol. 5: Radiation Trapped in the Earth's Magnetic Field
1975aep..conf    ASSL Vol. 51: Atmospheres of Earth and the Planets
1975msej.symp    ASSL Vol. 52: The Magnetospheres of the Earth and Jupiter
1975ipta.proc    ASSL Vol. 54: Image Processing Techniques in Astronomy
1975ssas.conf    ASSL Vol. 55: Solid State Astrophysics
1975sspi.conf    ASSL Vol. 57: The Scientific Satellite Programme during the International Magnetospheric Study
1976mpf..conf    ASSL Vol. 58: Magnetospheric Particles and Fields
1976snra.book    ASSL Vol. 59: Spallation Nuclear Reactions and their Applications
1976mpvs.coll    ASSL Vol. 60: IAU Colloq. 29: Multiple Periodic Variable Stars
1976aps..conf    ASSL Vol. 61: Atmospheric Physics from Spacelab
1977sall.conf    ASSL Vol. 62: Scientific Applications of Lunar Laser Ranging
1977isa..symp    ASSL Vol. 63: Infrared and submillimeter astronomy
1977cced.coll    ASSL Vol. 64: IAU Colloq. 35: Compilation, Critical Evaluation, and Distribution of Stellar Data
1977nrst.conf    ASSL Vol. 65: Novae and Related Stars
1977supe.conf    ASSL Vol. 66: Supernovae
1977cia..proc    ASSL Vol. 67: CNO Isotopes in Astrophysics
1977igss.conf    ASSL Vol. 69: Illustrated Glossary for Solar and Solar-Terrestrial Physics
1977tism.conf    ASSL Vol. 70: Topics in Interstellar Matter
1977stip.conf    ASSL Vol. 71: Study of Travelling Interplanetary Phenomena
1978dpst.proc    ASSL Vol. 72: IAU Colloq. 41: Dynamics of Planets and Satellites and Theories of their Motion
1979wisp.proc    ASSL Vol. 74: Wave Instabilities in Space Plasmas
1979sss..meet    ASSL Vol. 75: Stars and star systems
1979ifcf.coll    ASSL Vol. 76: IAU Colloq. 49: Image Formation from Coherence Functions in Astronomy
1979dma..conf    ASSL Vol. 78: Dynamics of the Magnetosphere
1967memo.conf    ASSL Vol. 8: Measure of the Moon
1980rrl..conf    ASSL Vol. 80: Radio Recombination Lines
1980as...book    ASSL Vol. 81: Astrophysics from Spacelab
1980sslu.meet    ASSL Vol. 83: Strategies for the Search for Life in the Universe
1981rbls.conf    ASSL Vol. 84: Relation Between Laboratory and Space Plasmas
1981rced.conf    ASSL Vol. 86: Reference Coordinate Systems for Earth Dynamics
1981xaes.proc    ASSL Vol. 87: X-ray Astronomy with the Einstein Satellite
1981pprg.work    ASSL Vol. 88: Physical Processes in Red Giants
1981emls.proc    ASSL Vol. 89: IAU Colloq. 59: Effects of Mass Loss on Stellar Evolution
1981iuzk.book    ASSL Vol. 91: Investigating the Universe
1982ialo.coll    ASSL Vol. 92: IAU Colloq. 67: Instrumentation for Astronomy with Large Optical Telescopes
1982rrsf.symp    ASSL Vol. 93: Regions of Recent Star Formation
1982hper.coll    ASSL Vol. 94: IAU Colloq. 63: High-Precision Earth Rotation and Earth-Moon Dynamics: Lunar Distances and Related Observations
1982nss..coll    ASSL Vol. 95: IAU Colloq. 70: The Nature of Symbiotic Stars
1982spsy.conf    ASSL Vol. 96: Sun and Planetary System
1982adra.proc    ASSL Vol. 97: IAU Colloq. 64: Automated Data Retrieval in Astronomy
1982bmst.proc    ASSL Vol. 98: IAU Colloq. 69: Binary and Multiple Stars as Tracers of Stellar Evolution
1982pric.conf    ASSL Vol. 99: Progress in Cosmology
1979aste.book    Asteroids
1978astd.nasa    Asteroids: An Exploration Assessment
1984acm..proc    Asteroids, Comets, Meteors
1992acm..proc    Asteroids, Comets, Meteors 1991
1986acm..proc    Asteroids, Comets, Meteors II
1990acm..proc    Asteroids, Comets, Meteors III
1989aste.conf    Asteroids II
2002aste.conf    Asteroids III
1991atq..conf    Asteroids to Quasars. A Symposium Honouring William Liller
2003aahd.conf    Asteroseismology Across the HR Diagram
1996asbi.work    Astrobiology Workshop: Leadership in Astrobiology
2000IAUS..197    Astrochemistry: From Molecular Clouds to Planetary
    ads..conf    Astrodynamics Specialist Conference
1974acda.conf    Astrometric Conference in connection with the Dedication of the 41-inch Astrometric Reflector of the Observatory of Torino
1981asin.book    Astrometric investigations
1974amap.nasa    Astrometrics and Astrophysics
1973aars.conf    Astrometry and Astrophysics, No. 9 Research of the Sun and Stars
1989aic..conf    Astrometry: Into the 21st Century
    asi..nasa    Astron. Soc. Inform.
1975asex.conf    Astronomia Extragalactica
1998aei..conf    Astronomical Education with the Internet
1983asmm.work    Astronomical Measuring Machines Workshop
1984amd..conf    Astronomical Microdensitometry Conference
1956aors.conf    Astronomical Optics and Related Subjects
1978bs...symp    Astronomical Papers Dedicated to Bengt Stromgren
1954asph.conf    Astronomical Photoelectric Conference
    asph.conf    Astronomical Photography
    ASPC.        Astronomical Society of the Pacific Conference Series
1979aust.conf    Astronomical USes of the Space Telescope
    AGAb.        Astronomische Gesellschaft Abstract Series
    AGM..        Astronomische Gesellschaft Meeting Abstracts
2000aasm.work    Astronomy and Astrophysics at Sub Millimeter Wavelengths
1982asas.conf    Astronomy and Astrophysics for the 1980's
1991aap..rept    Astronomy and Astrophysics Panel Reports
2001aard.conf    Astronomy and Astrophysics: Recent Developments
2003acfp.conf    Astronomy, Cosmology and Fundamental Physics
1972afsp.conf    Astronomy from a Space Platform
1988alds.proc    Astronomy from Large Databases
1992ald2.proc    Astronomy from Large Databases II
1984afmm.conf    Astronomy from Measuring Machines
1983ssst.book    Astronomy from Space: Sputnik to Space Telescope
2003ala..conf    Astronomy in Latin America
1979asan.book    Astronomy of the Ancients
1994awca.conf    Astronomy with the CFHT Adaptive Optics Bonnette
1999aaop.conf    Astronomy with adaptive optics : present results and future programs
1999asra.conf    Astronomy with Radioactivities
1991asph.conf    Astroparticle Physics
1996app..conf    Astro-Particle Physics
1988astr.conf    Astrophotography
1991aame.conf    Astrophysical Aspects of the Most Energetic Cosmic Rays
1982ac...proc    Astrophysical Cosmology Proceedings
1992NYASA.675    Astrophysical Disks
1997ails.conf    Astrophysical Implications of the Laboratory Study of Presolar Materials
1998ajop.conf    Astrophysical Jets: Open Problems
1994spmt.nasa    Astrophysical Science with a Spaceborne Photometric Telescope
2001ashe.conf    Astrophysical Sources of High Energy Particles and Radiation
2002apsp.conf    Astrophysical Spectropolarimetry
2000NYASA.898    Astrophysical Turbulence and Convection
1963ambp.book    Astrophysics and the Many-Body Problem
1998asal.conf    Astrophysics and Algorithms
1982acp..book    Astrophysics and Cosmic Physics
1980aepc.conf    Astrophysics and Elementary Particles, Common Problems
1974asgr.proc    Astrophysics and Gravitation
    ASSL.        Astrophysics and Space Science Library
1984atca.conf    Astrophysics and Twentieth-Century Astronomy to 1950
1985aagq.conf    Astrophysics of Active Galaxies and Quasi-Stellar Objects
1986abd..proc    Astrophysics of Brown Dwarfs
2003asdu.conf    Astrophysics of Dust
1992atc..book    Astrophysics on the Threshold of the 21st Century
1990arpf.symp    Astrophysics: Recent Progress and Future Possibilities
1999anot.conf    Astrophysics with the NOT
1995AnIPS..11    Asymmetrical Planetary Nebulae
1983arp..book    Asymptotic Realms of Physics
1977asst.conf    Asymptotic Structure of Space-Time
2001aax..proc    Atelier d'astronomie X
1969arsm.conf    Atlas of the Reverse Side of the Moon, Part II.
1974atti.conf    The Atmosphere of Titan
1975atve.conf    The Atmosphere of Venus
2002assc.book    Atmospheres in the Solar System: Comparative Aeronomy
1949aep..conf    The Atmospheres of the Earth and Planets
1975atep.proc    Atmospheres of Earth and the Planets
1979ajs..book    Atmospheres of Jupiter and Saturn
1985atst.rept    The Atmospheres of Saturn and Titan
1968avm..book    The Atmospheres of Venus and Mars
1982aafo.conf    Atmospheric Aerosols: Their Formation, Optical Properties, and Effects
    aeri.rept    Atmospheric and Environmental Research, Inc. Report
1982atch.conf    Atmospheric Chemistry
1959accs.conf    Atmospheric Chemistry of Chlorine and Sulfur Compounds
1969atem.conf    Atmospheric Emissions
1981visi.rept    Atmospheric Infrared Radiance Variability
1970atop.book    Atmospheric Optics
1972atop.conf    Atmospheric optics, Volume 2
1960atoz.conf    Atmospheric Ozone
1977atoz.conf    Atmospheric Ozone
1980aovh.conf    Atmospheric Ozone and its Variation and Human Influences
1985atoz.proc    Atmospheric ozone; Proceedings of the Quadrennial
1972atra.conf    Atmospheric Radiation
    atra.conf    Atmospheric Radiation Conference
1985asom.conf    Atmospheric Studies by Optical Methods
1982atc..conf    Atmospheric Trace Constituents
1993atm..work    Atmospheric Transport on Mars
1987atra.conf    Atmospheric Turbulence Relative to Aviation, Missile, and Space Programs
1991amp..conf    Atomic and Molecular Physics
1985aere.conf    Atomic Excitation and Recombination in External Fields
1968atin.conf    Atomic Interactions Part A
1967atma.conf    Atomic Masses
1969atph.conf    Atomic Physics
1987atph.conf    Atomic Physics 10 (ICAP-X)
1971atph.conf    Atomic Physics 2
1973atph.conf    Atomic Physics 3
1975atph.conf    Atomic Physics 4
1977atph.conf    Atomic Physics 5
1978atph.conf    Atomic Physics 6
1983atph.conf    Atomic Physics 8
1981apns.conf    Atomic Physics at the National Synchrotron Light Source
1999aphi.conf    Atomic Physics with Heavy Ions
1978astm.conf    Atomic Scattering Theory: Mathematical and Computational Aspects
1988asce.conf    Atomic Spectra and Collisions in External Fields
1998amse.conf    Atoms and Molecules in Strong External Fields.
1983aia..conf    Atoms in Astrophysics
1964susp.conf    Atti del Convegno Sulle Macchie Solari
1997como.conf    Atti Del SVI Congresso Nazionale Di Storia Della Fisica E Dell'Astornomia
1993agns.book    The Attraction of Gravitation: New Studies in the History of General Relativity
1967auai.conf    Aurora and Airglow
1968auai.conf    Aurorae and Airglow
1965apet.conf    Auroral Phenomena: Experiments and Theory
1993apd..book    Auroral Plasma Dynamics, Geophysical Monograph 80
1979aupr.conf    Auroral Processes
1971auro.rept    Auroras, A Collection of Articles
2002adaa.conf    Automated Data Analysis in Astronomy
1999aca..conf    Automatic Control in Aerospace 1998
1986apt..conf    Automatic Photoelectric Telescopes
1982bsel.nasa    B Stars With and Without Emission Lines
2001bmya.conf    Balkan Meeting of Young Astronomers
1985bsfg.book    Balloon Studies of Fluxes of Gamma Rays and Charged Particles in the Equatorial Region
1994bang.conf    BANG: The Evolving Cosmos.  Nobel Conference XXVII.
1988bang.iafc    Bangalore International Astronautical Federation Congress
1971brab.rept    Barium Release at Altitudes Between 200 and 1000 Kilometers
1993bvapcrept    Basaltic Volcanism and Ancient Planetary Crusts
1974zlms.nasa    Basic Models for Interpretation of Zodiacal Light Measures and Light Scattering by Dust Particles of Different Shapes
1993bgrb.work    BATSE Gamma Ray Burst Workshop
1976bss..proc    Be and Shell Stars
1976bfs1.conf    Beam-Foil Spectroscopy, Atomic Structure and Lifetimes, Volume 1
1976bfs2.conf    Beam-Foil Spectroscopy, Collisional and Radiative Processes, Volume 2
1991bja..book    Beams and Jets in Astrophysics
1988bqc..book    Between Quantum and Cosmos
1980baey.rept    Beyond the Atmosphere: Early Years of Space Science
1997bsm..conf    Beyond the Standard Model V.
1983bsm..conf    Beyond the Standard Model, Volume 2
2001bcao.conf    Beyond Conventional Adaptive Optics
1986bsse.book    Beyond Spaceship Earth: Environmental Ethics and the Solar System
1989bbag.conf    Big Bang, Active Galactic Nuclei and Supernovae
1984bbgl.symp    Big-Bang Cosmology Symposium in honour of G. Lemaitre
1984bims.symp    Binary and Multiple Systems
1993beps.proc    Biological Effects and Physics of Solar and Galactic Cosmic Radiation
1985biof.conf    Birth and the Infancy of Stars
1990beeu.symp    The Birth and Early Evolution of Our Universe
2001beu..conf    Birth and Evolution of the Universe
1984bens.work    Birth and Evolution of Neutron Stars: Issues Raised by Millisecond Pulsars
1982botu.conf    The Birth of the Universe
1998blho.conf    The Black Hole: 25 years after.
2002bhap.conf    Black Hole Astrophysics 2002
1986bhmp.book    Black Holes: The Membrane Paradigm
1998bhrs.conf    Black Holes and Relativistic Stars
1999bhgr.conf    Black Holes, Gravitational Radiation, and the Universe: Essays in Honor of C.V. Vishveshwara
2001bhbg.conf    Black Holes in Binaries and Galactic Nuclei
1993bhmw.conf    Black Holes, Membranes, Wormholes and Superstrings
1982blho.book    Black Holes: Selected Reprints
2003bhto.conf    Black Holes: Theory and Observation
2002babs.conf    Blazar Astrophysics with BeppoSAX and Other Observatories
1999bmtm.proc    Blazar Monitoring towards the Third Millennium
2001bbbb.conf    The Bridge Between the Big Bang and Biology: Stars, Planetary Systems, Atmospheres, Volcanoes: Their Link to Life
1987brig.iafc    Brighton International Astronautical Federation Congress
2000bbxs.conf    Broad Band X-ray Spectra of Cosmic Sources
1983buda.iafc    Budapest International Astronautical Federation Congress
1994bbc..conf    Building Blocks of Creation, From Microfermis to Megaparsecs
2000bgfp.conf    Building Galaxies; from the Primordial Universe to the Present
    burg.conf    Burghausen 4th International Conference on Solar Wind
1995cuhe.conf    Calibrating and Understanding HST and ESO Instruments
1994chst.conf    Calibrating Hubble Space Telescope
1988csa..proc    Calibration of Stellar ages
    cait.rept    California Institute of Technology Report
    cit..rept    California Instute of Technology Technical Report
    ucb..rept    California Univ., Berkeley Report
    ucla.rept    California Univ., Los Angeles Report
    ucsd.rept    California Univ., San Diego Report
1966lupl.conf    Caltech-JPL Lunar and Planetary Conference
1997ciha.book    The Cambridge Illustrated History of Astronomy
    CLNP.        Cambridge Lecture Notes in Physics
    CMP..        Cambridge Monographs in Physics
    CMAMC        Cambridge Monographs on Atomic Molecular and Chemical Physics
    CMMP.        Cambridge Monographs on Mathematical Physics
1993casi.proc    Canadian Space Agency, CASI Conference on Astronautics
1990cgse.nasa    Carbon in the Galaxy: Studies from Earth and Space
1967cltp.book    Carg\x{00E8}se Lectures in Theoretical Physics, Application of Mathematics to Problems in Theoretical Physics
    CLP..        Cargese Lectures in Physics
1973clp..book    Cargese Lectures in Physics, Volume 6
1997csu..book    Carl Sagan's Universe
1984cmar.conf    The Case for Mars
1993AnIPS..10    Cataclysmic Variables and Related Physics
1980cam..proc    Catalog of Antarctic Meteorites
1989ceas.proc    Catastrophes and Evolution: Astronomical Foundations
1998clmp.conf    Causality and Locality in Modern Physics
1965ccc..conf    Causes of Climatic Change
1990ccd2.proc    CCDs in Astronomy. II. New Methods and Applications of CCD Technology
2002ceme.conf    Celestial Mechanics, Dedicated to Donald Saari for his 60th Birthday
1948cent.symp    Centennial Symposia
1975cemo.nasa    Cepheid Modeling
1990cdta.book    Cerenkov Detectors and their Application in Science and Technology
1971cesra...1    CESRA-1, Committee of European Solar Radio Astronomers
1971cesra...2    CESRA-2, Committee of European Solar Radio Astronomers
1972cesra...3    CESRA-3, Committee of European Solar Radio Astronomers
1974cesra...4    CESRA-4, Committee of European Solar Radio Astronomers
1975cesra...5    CESRA-5, Committee of European Solar Radio Astronomers
1978cesra...7    CESRA-7, Committee of European Solar Radio Astronomers
2001chfe.symp    Chandra Fellows Symposium 2001
1995cdhs.conf    Chaos and diffusion in Hamiltonian systems
    coas.conf    Chaos in Astrophysics
1987cpa..work    Chaotic Phenomena in Astrophysics
1979chtv.conf    Characterization of High Temperature Vapors and Gases
    ceol.symp    Chemical Evolution and the Origin and Evolution of Life
1999cezh.conf    Chemical Evolution from Zero to High Redshift
1976cegp.book    Chemical Evolution of the Giant Planets
1987cega.proc    Chemical Evolution of Galaxies with Active Star Formation
1994cpms.conf    Chemically Peculiar and Magnetic Stars
1981cpsu.conf    Chemically Peculiar Stars of the Upper Main Sequence
1998cpmg.conf    Chemistry and Physics of Molecules and Grains in Space.  Faraday Discussions No. 109
1986cptp.conf    Chemistry and Physics of Terrestrial Planets
1992csim.conf    Chemistry and Spectroscopy of Interstellar Molecules
2002cdsf.conf    Chemistry as a Diagnostic of Star Formation
    ChiLP        Chicago Lectures in Physics
1987cnf..book    Choas, Noise and Fractals
1994cpd..conf    Chondrules and the Protoplanetary Disk
1983chto.conf    Chondrules and their Origins
1969cctr.conf    Chromosphere-Corona Transition Region
1985cdm..proc    Chromospheric Diagnostics and Modelling
1994chdy.conf    Chromospheric Dynamics
1980csc..conf    Circuits, Systems, and Computers Conference
1994cddp.conf    Circumstellar Dust Disks and Planet Formation
1996chz..conf    Circumstellar Habitable Zones
1994cmls.conf    Circumstellar Media in Late Stages of Stellar Evolution
1999cqnl.conf    Classical and Quantum Nonlocality
1982cira.conf    Classics in Radio Astronomy
1982cra..book    Classics in Radio Astronomy
1991cms..meet    Clay Minerals Society Meeting
2000caa1.book    Clifford Algebras and their Applications in Mathematical Physics, Volume 1: Algebra and Physics
2000caa2.book    Clifford Algebras and their Applications in Mathematical Physics, Volume 2: Clifford Analysis
1992ccep.conf    Climate Change and Energy Policy
1985cia..conf    Climate Impact Assessment
1990cisv.nasa    Climate Impact of Solar Variability
1953ccec.book    Climatic Change: Evidence, Causes, and Effects
1972ciap.conf    Climatic Impact Assessment Program
1978clus.nasa    A Close-up of the Sun
1983clun.proc    Clustering in the Universe
1995clun.conf    Clustering in the Universe
1983citu.conf    Clustering in the Universe P.15, 1983
1991csg..conf    Clusters and Superclusters of Galaxies
1992cscg.conf    Clusters and Superclusters of Galaxies
1990clga.conf    Clusters of Galaxies
1994clga.conf    Clusters of Galaxies
2001cghr.conf    Clusters of Galaxies and the High Redshift Universe Observed in X-rays
1989clga.meet    Clusters of Galaxies Meeting
2004cgpc.symp    Clusters of Galaxies: Probes of Cosmological Structure and Galaxy Evolution
1994caty.conf    CMB Anisotropies Two Years after COBE: Observations, Theory and the Future
2004cbhg.symp    Coevolution of Black Holes and Galaxies
1986ccf..conf    Coherence, Cooperation and Fluctuations
1994coun.conf    The Cold Universe
1960dyme.book    A Collection of Articles on Dynamic Meteorology
2001cpss.conf    Collisional Processes in the Solar System
1984chcl.conf    Collisions and Half-Collisions with Lasers
2000ccr..conf    Colloquium on Cosmic Rotation
1971css..conf    Colloquium on Supergiant Stars
    cub..rept    Colorado Univ. Boulder Technical Report
    colo.rept    Colorado University Report
1981cpg..conf    Colors and Populations of Galaxies
    cuny.rept    Columbia Univ. Annual Report
1998coen.book    Comet Encounters
1991chas.book    The Comet Halley archive: Summary volume
1990ch1..book    Comet Halley: Investigations, Results, Interpretations. Vol. 1: Organization, Plasma, Gas
1990ch2..book    Comet Halley: Investigations, Results, Interpretations. Vol. 2: Dust, Nucleus, Evolution
1981chpp.rept    The Comet Halley Probe.  Plasma Environment
1988cspp.book    Cometary and Solar Plasma Physics
1984coam.nasa    Cometary Astrometry
1983coex....1    Cometary Exploration
1979comi.work    Cometary Missions Workshop
1987cra..proc    Cometary Radio Astronomy
1981col..proc    Comets and the Origin of Life
2003come.conf    Comets II
1972csdm.conf    Comets: Scientific Data and Missions
1973cwei.book    Communication With Extraterrestrial Intelligence
1973cono.book    Comology Now
1994cers.conf    Compact Extragalactic Radio Sources
1979cgxs.work    Compact Galactic X-Ray Sources
1990cssg.conf    Compact Steep-Spectrum & GHZ-peaked Spectrum Radio Sources
1982chcn.conf    Comparative HI Content of Normal Galaxies
1978copl.conf    Comparative Planetology
1986csms.coll    Comparative Study of Magnetospheric Systems
    ccic.conf    Compilation of Contributions to the 15th International Cosmic Ray Conference
1992como.work    The Compton Observatory Science Workshop
1990canp.conf    Computational Atomic and Nuclear Physics
    cfd..symp    Computational Fluid Dynamics Symposium
    csc..rept    Computer Sciences Corp. Final Report
1981lajo.conf    Conf. held in La Jolla, Calif.
2000emr..conf    Conference Earth-Moon Relationships
1973denv.conf    Conference held at Denver, 17-30 Aug. 1973
1990hotx.conf    Conference held in Houston, TX
2001gdwm.conf    Conference on the Geophysical Detection of Subsurface Water on Mars
1998herb.conf    Conference on the High Energy Radiation Backgroun in Space
1997herb.conf    Conference on the High Energy Radiation Background in Space
1971cltd.conf    Conference on Large Telescope Design
1975aso..conf    Conference on Scientific Research by Artificial Satellites Observations
1999ccmn.conf    Confluence of Cosmology, Massive Neutrinos, Elementary Particles, and Gravitation
1990cbto.conf    Confrontation between Theories and Observations in Cosmology: Present Status and Future Programmes
2000cucg.conf    Constructing the Universe with Clusters of Galaxies
1969cp1..conf    Contemporary Physics, Volume 1
1969cp2..conf    Contemporary Physics, Volume 2
1974sgra.rept    Context and Status of Gamma Ray Astronomy
1986ceagnwork    Continuum Emission in Active Galactic Nuclei
1976conm....1    Contributions of the Observatory of New Mexico State University
1984xras.rept    Contributions of the X-Ray Astronomy Group
1993csgg.conf    Contributions of Space Geodesy to Geodynamics: Earth Dynamics
1981cicc.conf    Contributions to the International Cosmic Ray Conference
1988copa.conf    Coordination of Observational Projects in Astronomy
1975coch.book    The Copernican Achievement
    cuni.rept    Cornell Univ. Final Report
1986copp.nasa    Coronal and Prominence Plasmas
1974cd...symp    Coronal Disturbances
1990coax.conf    Cosmic Axions
1964NYASA.119    Cosmic Dust
1978codu.book    Cosmic Dust
2001coev.conf    Cosmic evolution
1986cpcp.book    Cosmic Pathways: Contemporary Perpectives in Physics and Astrophysics
1989cp...book    Cosmic Perspectives
2001coqu.conf    Cosmic Questions
1985crhe.work    Cosmic Ray and High Energy Gamma Ray Experiments for the Space Station Era
    crnm.conf    Cosmic Ray NM-64 Neutron Monitor Data
1975crs..book    Cosmic Ray Studies
1975cora.nasa    Cosmic Rays
1983crgp.nasa    Cosmic Rays.  Results of Researches on the International Geophysics Project
1992crat.conf    Cosmic Rays Above 10^19 eV
1979crhe.book    Cosmic Rays and High-Energy Nuclear Interactions
1976crsn.book    Cosmic Rays in the Stratosphere and in Near Space (Russian)
1978crsn.book    Cosmic Rays in the Stratosphere and in Near Space (Translation)
1982cris.book    Cosmic Rays in Interplanetary Space and the Earth's Ionosphere
1988cscs.conf    Cosmic strings. The current status
1993cvf..conf    Cosmic Velocity Fields
1985cgd..conf    Cosmical Gas Dynamics
1993cmcp.conf    Cosmical Magnetism
1996co94.conf    Cosmion-94.  Proceedings of the First International Conference on Cosmoparticle Physics dedicated to the 80th Anniversary of YA. B. Zeldovich and to the 5th Memorial of A. D. Sakharov
1981coge.conf    Cosmo- and Geochemistry
1998cosm.work    COSMO-97, First International Workshop on Particle Physics and the Early Universe
2000ppeu.conf    COSMO-99, International Workshop on Particle Physics and the Early Universe
2004cmpe.conf    Cosmochemistry. The melting pot of the elements
1983col..conf    Cosmochemistry and the Origin of Life
1986conu.work    Cosmogenic Nuclides
1986copr.conf    Cosmogonical Processes
1996cceu.conf    Cosmological Constant and the Evolution of the Universe
1986coco.conf    Cosmological Constants
1994cdm..conf    Cosmological Dark Matter
1996cpu..book    Cosmology: the Physics of the Universe
1982caeh.book    Cosmology and Astrophysics: Essays in honor of Thomas Gold
1989cep..conf    Cosmology and Elementary Particles
1992cep..conf    Cosmology and Elementary Particles
1996cogr.conf    Cosmology and Gravitation II.  VII Brazilian School of Cosmology and Gravitation II
1987cpp..conf    Cosmology and Particle Physics
1988cpp..conf    Cosmology and Particle Physics
1981cp...proc    Cosmology and Particles
1986cafp.proc    Cosmology, Astronomy and Fundamental Physics
1972cfom.book    Cosmology, Fusion and Other Matters
1977cht..conf    Cosmology, History, and Theology
1984ceu..book    Cosmology of the Early Universe
1986coec.conf    Cosmos: An Educational Challenge
    cosp.meet    COSPAR, Plenary Meeting
1977cpmaa        COSPAR Plenary Meeting and Associated Activities
2000cpv..work    CP Violation
1985cnrs.work    The Crab Nebula and Related Supernova Remnants
1977ctep.conf    Cretaceous-Tertiary Extinctions and Possible Terrestrial and Extraterrestrial Causes
1997cdc..conf    Critical Dialogues in Cosmology
1972cpmp.conf    Critical Problems of Magnetospheric Physics
1995cscs.conf    Cross-Scale Coupling in Space Plasmas, Geophysical Monograph 93
2001canp.book    Current aspects of neutrino physics
1974ccrm.book    Current Concepts Regarding the Moon
2002chee.conf    Current high-energy emission around black holes
1988cihp.conf    Current Issues in Hadron Physics
1980cppt.conf    Current Problems in Particle Theory
1981cppt.conf    Current Problems in Particle Theory. 5: Unified Field Theories and Beyond
1981cppt.conf    Current Problems in Particle Theory. 5: Unified Field Theories and Beyond
1980spui.rept    Current Problems in Stellar Pulsation Instabilities
1993ctap.conf    Current Topics in Astrofundamental Physics
2001ctap.conf    Current Topics in Astrofundamental Physics: the Cosmic Microwave Background
1984ctsc.conf    Current Topics in Chinese Science
1998ctmc.conf    Current Topics in Mathematical Cosmology
1993cac..book    Currents in Astrophysics and Cosmology
1998cvsw.conf    Cyclical Variability in Stellar Winds
1996cyga.book    Cygnus A -- Studay of a Radio Galaxy
1988dama.meet    Dark Matter, 8th Moriond Astrophysics Meeting
1989dmsu.conf    Dark Matter and the Structure of the Universe
1987dmu..conf    Dark Matter in the Universe
1990dmiu.conf    Dark Matter in the Universe
1997dmud.conf    Dark matter in the Universe and its Direct Detection.
2001dmap.conf    Dark Matter in Astro- and Particle Physics
1999dmap.conf    Dark matter in Astrophysics and Particle Physics
1995dmcc.conf    Dark Matter in Cosmology, Clocks and Tests of Fundamental Laws
1996dmcq.conf    Dark Matter in Cosmology Quantam Measurements Experimental Gravitation
1971dngp.conf    Dark nebulae, Globules and Protostars
1996dsu..conf    The Dark Side of the Universe; Experimental Efforts and Theoretical Framework
2003dume.symp    The Dark Universe: Matter, Energy and Gravity
    dchn.rept    Dartmouth College, Report
1985daa..conf    Data Analysis in Astronomy
1989daa..conf    Data Analysis in Astronomy
1986daa..conf    Data Analysis in Astronomy II
1997daia.conf    Data Analysis in Astronomy IV
1992daan.work    Data Analysis Workshop
1991deas.rept    Data Evaluation, Analysis, and Scientific Study
1992dvim.conf    Data Validation of Ionospheric Models and Maps (VIM)
1993dgs..work    Databases for Galactic Structure
2003dhst.symp    A Decade of Hubble Space Telescope Science
1988uvai....1    A Decade of UV Astronomy with the IUE Satellite, Volume 1
1988uvai....2    A Decade of UV Astronomy with the IUE Satellite, Volume 2
1994depv.conf    Deep Earth and Planetary Volatiles
2001defi.conf    Deep Fields
2001dmsi.conf    Deep Millimeter Surveys: Implications for Galaxy Formation and Evolution
    dsn..nasa    Deep Space Network
    udnw.rept    Delaware Univ., Newark Report
1993dunw.rept    Delaware University Semiannual Report
1991dgw..conf    The Detection of Gravitational Waves
1991dgpf.conf    Determination of the Geoid: Present and Future
1996dgps.conf    The Determination of Geophysical Parameters from Space
    dglr.meet    Deutsche Gesellschaft fuer Luft- und Raumfahrt
1992dhrl.nasa    Development of a High Resolution Liquid Xenon Imaging Telescope for Medium Energy Gamma Ray Astrophysics
1999dad..conf    Development of Astronomical Databases
2000dmep.conf    Developments in Mathematical and Experimental Physics, Volume A: Cosmology and Gravitation
2002dmep.conf    Developments in Mathematical and Experimental Physics, Volume A: Cosmology and Gravitation
1989dots.work    Developments in Observations and Theory for Solar Cycle 22
1995deps.rept    Diffuse Emission and Pathological Seyfert Spectra
1994dib..nasa    The Diffuse Interstellar Bands
1999dtrp.conf    Diffuse Thermal and Relativistic Plasma in Galaxy Clusters
1991dir..conf    Digital Image Restoration
1993dgr1.conf    Directions in General Relativity: Papers in Honor of Charles Misner, Volume 1
1993dgr2.conf    Directions in General Relativity: Papers in Honor of Dieter Brill, Volume 2
1999dicb.conf    Disk Instabilities in Close Binary Systems
    drte.conf    Dissociative Recombination: Theory, Experiment and Applications
1972dmim.conf    The Distribution and Motion of Interstellar Matter in Galaxies
1992daec.conf    Distribution of Matter in the Universe
1990sdsr.rept    A Documentation on Space Research in North-Rhineland-Westphalia in the Period 1985-1990
1992daoa.conf    Doscientos A\x{00F1}os del Observatorio Astron\x{00F3}mico de Madrid
1987dla..conf    Double Layers in Astrophysics
1997ldpf.book    Double Layers: Potential Formation and Related Nonlinear Phenomena in Plasmas
1990dres.iafc    Dresden International Astronautical Federation Congress
1978dubr.iafc    Dubrovnik International Astronautical Federation Congress
1975mpth.proc    Dudley Observatory Report
1979duma....1    DUMAND Summer Workshop
1979uina....1    DUMAND Summer Workshop, Volume 1
1979uina....2    DUMAND Summer Workshop, Volume 2
1981duma.conf    DUMAND-80
1993dca..book    Dust and Chemistry in Astronomy
1988duun.conf    Dust in the Universe
2002dpis.book    Dust Plasma Interaction in Space
1975duun.book    The Dusty Universe
1994dwga.work    Dwarf Galaxies
2001dge..conf    Dwarf galaxies and their environment
1998dcar.conf    Dymanics of Comets and Asteroids and their Role in
1982decs.book    The Dynamic Evolution of Cosmic Systems
1990dysu.conf    The Dynamic Sun
2003dysu.book    Dynamic Sun
2001dysu.conf    The Dynamic Sun, Proceedings of the Summerschool and Workshop held at the Solar Observatory
1985dyas.conf    Dynamical Astronomy
1997dbps.conf    The Dynamical Behaviour of our Planetary System
2002dfsb.conf    Dynamical Friction Strikes Back
1986dsnr.work    Dynamical Spacetimes and Numerical Relativity
1994dana.conf    Dynamics and Astrometry of Natural and Artificial Celestial Bodies
1990dig..book    Dynamics and Interactions of Galaxies
1977dpas.book    Dynamics and Physics of Astrophysical Systems
1987dssp.conf    Dynamics and Structure of Solar Prominences
1976dges.book    Dynamics of the Galaxy and Extragalactic Systems
1984dma..conf    Dynamics of the Middle Atmosphere
1989dad..conf    Dynamics of Astrophysical Discs
1982dcsa.book    The Dynamics of Current Sheets and the Physics of Solar Activity
1989ddse.work    Dynamics of Dense Stellar Systems
1991dodg.conf    Dynamics of Disc Galaxies
1987degp.book    Dynamics of Elementary Gas-phase Reactions
1966dfp..conf    Dynamics of Fluids and Plasmas
1981dgs..book    Dynamics of Gravitating Systems
1986dmp..book    Dynamics of Molecular Photofragmentation
2002dnac.conf    Dynamics of Natural and Artificial Celestial Bodies
1975dgs..conf    La Dynamique des galaxies spirales
1985eeia.work    The Early Earth:  The Interval from Accretion to the Older Archean
1997LPICo.916    Early Mars: Geologic and Hydrologic Evolution, Physical and Chemical Environments, and the Implications for Life
1993emhw.work    Early Mars: How Warm and How Wet?
1991eoud.conf    The Early Observable Universe from Diffuse Backgrounds
1980essp.conf    Early Solar System Processes and the Present Solar System
1996eaun.book    The Early Universe
1988eur..book    The Early Universe: Reprints
1997euvl.conf    The Early Universe with the VLT.
1984eyra.book    The Early Years of Radio Astronomy - Reflections Fifty Years after Jansky's Discovery
1997eaun.book    The Earth and the Universe
1954eap..book    The Earth as a Planet
1968eaun.book    The Earth in the Universe
1967easp.book    The Earth in Space
1982eras.nasa    Earth Radiation Science Seminars
1985ertr.conf    Earth Rotation and the Terrestrial Reference Frame
1961eato.book    The Earth Today
1973egfs.conf    The Earth's Gravitational Field and Secular Variations in Position
1975eiss.conf    Effect of the Ionosphere on Space Systems and Communications
1980eora.work    Effects in Optical and Radio Astronomy
1972eaag.conf    Effects of Atmospheric Acousitic Gravity Waves on Electromagnetic
1977esae.rept    Effects of Solar Activity on the Earth's Atmosphere and Biosphere
1984evml.conf    Effects of Variable Mass Loss on the Local Stellar Environment
1977NYASA.302    Eight Texas Symposium on Relativistic Astrophysics
1983ICRC.        Eighteenth International Cosmic Ray Conference
1998tsra.conf    Eighteenth Texas Symposium on Relativistic Astrophysics
1963ICRC.        Eighth International Cosmic Ray Conference
1997stt..conf    Eighth International Symposium on Space Terahertz Technology
1992slew.rept    Einstein All-Sky Slew Survey
2002esr..book    Einstein Studies in Russia
1982eamb.conf    Ejection and Accretion of Matter in Binary Systems
    eds..conf    Elastic and Diffractive Scattering
1992ecim.nasa    Electrical and Chemical Interactions at Mars
1970eem..conf    Electrmagnetic Exploration of the Moon
1974eaa..conf    Electrography and Astronomical Applications
1989epps.book    Electromagnetic and Plasma Processes from the Sun to the earth's Core
1989ecpc.conf    Electromagnetic Coupling in the Polar Clefts and Caps
1967emrs.conf    Electromagnetic Radiation in Space
1976epia.conf    Electron and Photon Interactions with Atoms
1994ecmc.conf    Electron Collisions with Molecules, Clusters, and Surfaces
1967edtm.conf    Electron Density and Temperature Measurements in the Ionosphere
1964eddi.conf    Electron Density Distribution in Ionosphere and Exosphere
1962edpi.conf    Electron Density Profiles in the Ionosphere and Exosphere
1966edpi.conf    Electron Density Profiles in Ionosphere and Exosphere
1983eaem.conf    Electron-Atom and Electron-Molecule Collisions
1978easy.conf    Electronics and Aerospace Systems Conference
1979empm.conf    Electron-Molecule and Photon-Molecule Collisions
1979ems..book    Electron-Molecule Scattering
1988emsp.conf    Electron-Molecule Scattering and Photoionization
2000ewp..conf    Electroweak Physics
1988eaa..conf    Elemental Abundance Analyses
1963eppf.book    Elementary Particle Physics and Field Theory 1
1970epcr.conf    Elementary Particles and Cosmic Rays
1992eatc.conf    Elements and the Cosmos
1979eisu.conf    The Elements and their Isotopes in the Universe
2001eag..conf    Eleventh Annual V. M. Goldschmidt Conference
1970ICRC.        Eleventh International Conference on Cosmic Rays
1972emun.book    The Emerging Universe
1948esns.conf    The Emission Spectra of the Night Sky and Aurorae
1993eme..work    Emulsion Chamber Experiments at Mt. Chacaltaya and Pamirs
1990egre.symp    The Energetic Gamma-Ray Experiment Telescope (EGRET) Science Symposium
1986epos.conf    Energetic Phenomena on the Sun
1976ep...conf    Energy and Physics
    eas..conf    Engineering and Science
    ecos.proc    Engineering, Construction, and Operations in Space
1992eocm.rept    Environment Observation and Climate Modelling Through International Space Projects
1991ese..book    Environmental and Space Electromagnetics
2000eeve.book    Environmental Effects on Volcanic Eruptions: From Deep Oceans to Deep Space
1991emma.proc    The Environmental Model of Mars
    erp..rept    Environmental Research Papers Air Force Cambridge Research Labs
1974esr..nasa    Equipment for Space Research
1990ebua.conf    Errors, Bias and Uncertainties in Astronomy
1976epsr.conf    ESA SP-115: European Programmes on Sounding-Rocket and Balloon Research in the Auroral Zone
1993cmps.book    ESA SP-1159: Cluster: Mission, Payload and Supporting Activities
1995bsi..book    ESA SP-1162: Biorack on Spacelab IML-1
1997hspm.conf    ESA SP-1177: Huygens: Science, Payload and Mission
1997asdm.book    ESA SP-1191: Anthrorack on the Spacelab D2 Mission
1997sgbc.conf    ESA SP-1198: Satellite-Ground Based Coordination Sourcebook
1997lsep.book    ESA SP-1206: Life Sciences Experiments Performed on Sounding Rockets (1985-1994): TEXUS 11-32, MASER 3-6 MAXUS 1
1977ragr.conf    ESA SP-124: Recent Advances in Gamma-Ray Astronomy
2002ses..book    ESA SP-1261: Switzerland, Europe and Space: Adventure and Imperative
1977pas..conf    ESA SP-132: Physics and Astrophysics from Spacelab
1978esrb.conf    ESA SP-135: European Sounding Rocket, Balloon and Related Research, with Emphasis on Experiments at High Latitudes
1979scad.conf    ESA SP-146: SPACECAD '79, Computer-aided design of electronics for space applications
1979mbl..rept    ESA SP-148: Magnetospheric Boundary Layers
1979chmh.work    ESA SP-153: Comet Halley Micrometeoroid Hazard Workshop
1980iue..conf    ESA SP-157: Ultraviolet observations of Quasars
1981ojig.conf    ESA SP-162: Optical Jets in Galaxies
1981sse..conf    ESA SP-164: Solar System and its Exploration
1981chdg.conf    ESA SP-174: The Comet Halley. Dust and Gas Environment
1982iue..conf    ESA SP-176: Third European IUE Conference
1982sahs.rept    ESA SP-177: The Scientific Aspects of the Hipparcos Space Astrometry Mission
1982uvsc.conf    ESA SP-182: Ultraviolet Stellar Classification
1983erbp.conf    ESA SP-183: European Rocket and Balloon Programmes and Related Research
1982plma.rept    ESA SP-185: The Planet Mars
1982siso.conf    ESA SP-189: Scientific Importance of Submillimetre Observations
1982geis.rept    ESA SP-192: Galactic and Extragalactic Infrared Spectroscopy
1983sma..conf    ESA SP-201: Statistical Methods in Astronomy
1984plap.conf    ESA SP-207: Plasma Astrophysics
1984qvos.rept    ESA SP-213: QUASAT:  A VLBI Observatory in Space
1984iue..conf    ESA SP-218: Fourth European IUE Conference
1985koas.coll    ESA SP-226: Kilometric Optical Arrays in Space
1985erbp.symp    ESA SP-229: European Rocket & Balloon Programmes and Related Research
1985fmsh.work    ESA SP-235: Future Missions in Solar, Heliospheric & Space Plasma Physics
1985rrcv.work    ESA SP-236: Recent Results on Cataclysmic Variables. The Importance of IUE and Exosat Results on Cataclysmic Variables and Low-Mass X-Ray Binaries
1985cxrs.work    ESA SP-239: Cosmic X-Ray Spectroscopy Mission
1986cnsr.proc    ESA SP-249: Comet Nucleus Sample Return Mission
1986ehc1.conf    ESA SP-250: ESLAB Symposium on the Exploration of Halley's Comet. Volume 1: Plasma and Gas
1986ehc2.conf    ESA SP-250: ESLAB Symposium on the Exploration of Halley's Comet. Volume 2: Dust and Nucleus
1986ehc3.conf    ESA SP-250: ESLAB Symposium on the Exploration of Halley's Comet. Volume 3: Posters
1986plas.work    ESA SP-251: Plasma Astrophysics
1987erbp.symp    ESA SP-270: European Rocket & Balloon Programmes and Related Research
1987ois..work    ESA SP-273: Optical Interferometry in Space
1987sspp.symp    ESA SP-275: Small Scale Plasma Processes in the Solar Chromosphere/Corona, Interplanetary Medium and Planetary Magnetospheres
1987dsc..proc    ESA SP-278: Diversity and Similarity of Comets
1989rsp..conf    ESA SP-285: Reconnection in Space Plasma
1993rsp..conf    ESA SP-285: Reconnection in Space Plasma
1988ssls.rept    ESA SP-286: Seismology of the Sun and Sun-Like Stars
1989erbp.symp    ESA SP-291: European Rocket & Balloon Programmes and Related Research
1989esp..conf    ESA SP-294: European Space Power Conference
1989ttxa.symp    ESA SP-296: Two Topics in X-Ray Astronomy, Volume 1: X Ray Binaries.  Volume 2: AGN and the X Ray Background
1989ioot.conf    ESA SP-297: Second European In-Orbit Operations Technology Symposium
1989pmcm.rept    ESA SP-302: Physics and Mechanics of Cometary Materials
1990etsp.conf    ESA SP-304: Environmental Testing for Space Programmes Test: Facilities and Methods
1992tita.symp    ESA SP-338: Symposium on Titan
1992ssts.rept    ESA SP-346: Study of the Solar-Terrestrial System
1992cscl.work    ESA SP-348: Coronal Streamers, Coronal Loops, and Coronal and Solar Wind Composition
1992tsbi.rept    ESA SP-354: Targets for Space-Based Interferometry
1992pdsi.symp    ESA SP-356: Photon Detectors for Space Instrumentation
1994asd..conf    ESA SP-364: Euro-Latin American Space Days
1994tetr.work    ESA SP-365: Technology Transfer Workshop
1995asv..conf    ESA SP-367: Aerothermodynamics for space vehicles
1995esp..conf    ESA SP-369: European Space Power
1995erbp.book    ESA SP-370: European rocket and balloon programmes and related research
1995clus.work    ESA SP-371: Proceedings of the Cluster Workshops, Data Analysis Tools and Physical Measurements and Mission-Oriented Theory
1995icsc.conf    ESA SP-372: International Cooperation in Satellite Communications
1994sdps.conf    ESA SP-373: SOHO 3: Solar Dynamic Phenomena and Solar Wind Consequences
1995esmt.conf    ESA SP-374: European Space Mechanisms and Tribology Symposium
1995heli.conf    ESA SP-376: Helioseismology
1996pass.conf    ESA SP-377: Product Assurance Symposium and Software Product Assurance Workshop
1995iprs.book    ESA SP-378: Intellectual Property Rights and Space Activities
1995fpas.conf    ESA SP-379: Future Possibilities for bstrometry in Space
1997sgnc.conf    ESA SP-381: Spacecraft Guidance, Navigation and Control Systems
1997trun.conf    ESA SP-382: The Transparent Universe
1995acsa.conf    ESA SP-384: Approaches in Communicating Space Applications to Society
1996ssmm.conf    ESA SP-386: Spacecraft Structures, Materials and Mechanical Engineering
1996rspe.conf    ESA SP-391: Remote Sensing of the Polar Environments
1996emsb.conf    ESA SP-392: Environment Modeling for Space-Based Applications
1997spde.conf    ESA SP-393: Second European Conference on Space Debris
1996ecdl.conf    ESA SP-396: EUROMIR 95 Crew Debriefing and Lessons Learnt
1997esp..conf    ESA SP-398: European Spacecraft Propulsion Conference
1997secs.symp    ESA SP-400: Sixth European Symposium on Space Environmental Control Systems
1997fisu.conf    ESA SP-401: The Far Infrared and Submillimetre Universe.
1997hipp.conf    ESA SP-402: Hipparcos - Venice '97
1997cswn.conf    ESA SP-404: Fifth SOHO Workshop:  The Corona and Solar Wind Near Minimum Activity
1997uael.conf    ESA SP-405: The Use and Applications of ERS in Latin America
1997esi..conf    ESA SP-406: ERS SAR Interferometry
1997ipt..conf    ESA SP-407: Image Processing Techniques, First Latino-American Seminar on Radar Remote Sensing
1998elas.conf    ESA SP-412: Third Euro-Latin American Space Conference
1998uabi.conf    ESA SP-413: Ultraviolet Astrophysics Beyond the IUE Final Archive
1997sse..symp    ESA SP-414: Third ERS Symposium on Space at the service of our Environment
1997cpsh.conf    ESA SP-415: Correlated Phenomena at the Sun, in the Heliosphere and in Geospace
1998espc.conf    ESA SP-416: Proceedings of the Fifth European Space Power Conference (ESPC)
1998cesh.conf    ESA SP-417: Crossroads for European Solar and Heliospheric Physics.  Recent Achievements and Future Mission Possibilities
1998soho.conf    ESA SP-418: Structure and Dynamics of the Interior of the Sun and Sun-like Stars
1997fiso.work    ESA SP-419: The first ISO workshop on Analytical Spectroscopy
1997fps..conf    ESA SP-420: Fundamental Physics in Space
1998sjcp.conf    ESA SP-421: Solar Jets and Coronal Plumes
1998rsme.conf    ESA SP-423: Remote Sensing Methodology for Earth Observation and Planetary Exploration
1998esar.conf    ESA SP-424: Emerging Scatterometer Applications - From Research to Operations
2000sgnc.conf    ESA SP-425: Spacecraft Guidance, Navigation and Control Systems
1999asv..conf    ESA SP-426: Aerothermodynamics for space vehicles
1999usis.conf    ESA SP-427: The Universe as Seen by ISO
1999ssmm.conf    ESA SP-428: Spacecraft Structures, Materials and Mechanical Testing
1998ngst.conf    ESA SP-429: The Next Generation Space Telescope: Science Drivers and Technological Challenges
1999cosp.conf    ESA SP-430: Cooperation in Space
1998sslt.conf    ESA SP-431: Space Science and the Long-Term Future of Space in Europe
1998aics.conf    ESA SP-432: Conference on Academic and Industrial Cooperation in Space Research
1999uiss.conf    ESA SP-433: Utilisation of the International Space station 2
1998ipt..conf    ESA SP-434: Image Processing Techniques
1999ipo..work    ESA SP-435: Workshop on ISO Polarisation Observations
1999hesa.conf    ESA SP-436: The history of the European Space Agency
1999erbp.conf    ESA SP-437: European Rocket and Balloon Programs and Related Research
1999smt..conf    ESA SP-438: Space Mechanisms and Tribology
2000escc.conf    ESA SP-439: European Space Components Conference : ESCCON 2000
1999aira.conf    ESA SP-440: Artificial Intelligence, Robotics and Automation in Space
1998rbgp.conf    ESA SP-441: Retrieval of Bio- and Geo-Physical Parameters from SAR Data for Land Applications
1999iosl.conf    ESA SP-442: International Organizations and Space Law : Their Role and Contributions
2000sust.conf    ESA SP-443: Fifth International Conference on Substorms
2000anpr.conf    ESA SP-444: AP 2000 - Antennas and Propagation
2000sfsl.conf    ESA SP-445: Star Formation from the Small to the Large Scale
1999soho....8    ESA SP-446: 8th SOHO Workshop: Plasma Dynamics and Diagnostics in the Solar Transition Region and Corona
1999dsa..conf    ESA SP-447: Data Systems in Aerospace
1999mfsp.conf    ESA SP-448: Magnetic Fields and Solar Processes
2000mmpm.conf    ESA SP-449: Cluster-II Workshop Multiscale / Multipoint Plasma Measurements
2000ceos.conf    ESA SP-450: SAR workshop : CEOS Committee on Earth Observation Satellites
2000dais.conf    ESA SP-451: Darwin and Astronomy : the Infrared Space Interferometer
2000fmr..work    ESA SP-452: First MSG RAO Workshop
2001mrap.conf    ESA SP-454: Microgravity Research and Aplications in Physical Sciences and Biotechnology
2000ibps.conf    ESA SP-455: ISO Beyond Point Sources: Studies of Extended Infrared Emission
2000ibp..conf    ESA SP-456: ISO Beyond the Peaks: The 2nd ISO Workshop on Analytical Spectroscopy
2000dsa..conf    ESA SP-457: Data Systems in Aerospace
2000geom.conf    ESA SP-458: Proceedings of the International Symposium GEOMARK 2000
2001egru.conf    ESA SP-459: Exploring the Gamma-Ray Universe
2001phso.conf    ESA SP-460: The Promise of the Herschel Space Observatory
2001lden.conf    ESA SP-461: Looking Down to Earth in the New Millennium
2000eum..conf    ESA SP-462: Exploration and Utilisation of the Moon
2000sctc.proc    ESA SP-463: The Solar Cycle and Terrestrial Climate, Solar and Space weather
2001soho...10    ESA SP-464: SOHO 10/GONG 2000 Workshop: Helio- and Asteroseismology at the Dawn of the Millennium
2001sppr.conf    ESA SP-465: Spacecraft Propulsion
2001etsp.conf    ESA SP-467: Fourth International Symposium Environmental Testing for Space Programmes
2001ssmm.conf    ESA SP-468: Spacecraft Structures, Materials and Mechanical Testing
2001fpsr.conf    ESA SP-469: Fundamental Physics in Space and Related Topics
2001aics.conf    ESA SP-470: Academic and Industrial Cooperation in Space Research
2001erbp.conf    ESA SP-471: European Rocket and Balloon Programmes and Related Research
2001pesp.conf    ESA SP-472: L'Essor des Recherches Spatiales en France: Premi\x{00E8}re rencontre de l'I. F. H. E.
2001spde.conf    ESA SP-473: Space Debris
2002spec.work    ESA SP-474: Spectra Workshop
2002rbgp.conf    ESA SP-475: Retrieval of Bio- and Geo-Physical Parameters from SAR Data for Land Applications
2001sct..conf    ESA SP-476: Spacecraft Charging Technology
2002scsw.conf    ESA SP-477: Solspa 2001, Proceedings of the Second Solar Cycle and Space Weather Euroconference
2000aesi.conf    ESA SP-478: Fringe '99 - Advancing ERS SSAR Interferometry from Applications Towards Operations
2000atsr.work    ESA SP-479: Applications of the ERS Along-Track Scanning Radiometer
2001smt..conf    ESA SP-480: 9th European Space Mechanisms and Tribology Symposium
2003clim.conf    ESA SP-481: The Calibration Legacy of the ISO Mission
2002isop.conf    ESA SP-482: Photometric Mapping with ISOPHOT using the "P32" Astronomical Observation Template
2001dsa..conf    ESA SP-483: Data Systems in Aerospace
2001gpsp.conf    ESA SP-484: Green Propellents for Space Propulsion
2002sshp.conf    ESA SP-485: Stellar Structure and Habitable Planet Finding
2002sfs..conf    ESA SP-486: Joint ESA-NASA Space-Flight Safety ConferenceESA SP-486: Joint ESA-NASA Space-Flight Safety Conference
2002asv..conf    ESA SP-487: Fourth Symposium on Aerothermodynamics for Space Vehicles
2000ire..work    ESA SP-489: INDREX (Indonesian Radar Experiment) Final Results Workshop
2002tesp.conf    ESA SP-491: Teach Space 2001: International Space Station Education Conference
2001sspm.conf    ESA SP-492: Sheffield Space Plasma Meeting: Multipoint Measurements versus Theory
2001sefs.work    ESA SP-493: Solar encounter. Proceedings of the First Solar Orbiter Workshop
2001mete.conf    ESA SP-495: Meteoroids 2001 Conference
2001eab..conf    ESA SP-496: Exo-/Astro-Biology
2001phst.conf    ESA SP-497: Physics on Stage
2002mird.conf    ESA SP-498: MIR Deorbiting
2001dase.work    ESA SP-499: The Digital Airborne Spectrometer Experiment (DAISEX)
2002acm..conf    ESA SP-500: Asteroids, Comets, and Meteors: ACM 2002
2002lsle.conf    ESA SP-501: Life in Space for Life on Earth
2002sppo.conf    ESA SP-502: Space Power
2002solm.conf    ESA SP-505: SOLMAG 2002. Proceedings of the Magnetic Coupling of the Solar Atmosphere Euroconference
2002svco.conf    ESA SP-506: Solar Variability: From Core to Outer Frontiers
2002soho...11    ESA SP-508: From Solar Min to Max: Half a Solar Cycle with SOHO
2002dsa..conf    ESA SP-509: Data Systems in Aerospace
2002eida.conf    ESA SP-511: Exploiting the ISO Data Archive. Infrared Astronomy in the Internet Age
2003eida.conf    ESA SP-511: Exploiting the ISO Data Archive. Infrared Astronomy in the Internet Age
2002elpm.conf    ESA SP-514: Earth-like Planets and Moons
2003soho...12    ESA SP-517: GONG+ 2002. Local and Global Helioseismology: the Present and Future
2002eab..conf    ESA SP-518: Exo-Astrobiology
2003smt..conf    ESA SP-524: European Space Mechanisms and Tribology Symposium
2003erbp.conf    ESA SP-530: European Rocket and Balloon Programmes and Related Research
2003rhtg.work    ESA SP-533: Radiation of High Temperature Gases in Atmospheric Entry
2003iscs.symp    ESA SP-535: Solar Variability as an Input to the Earth's Environment
2003toed.conf    ESA SP-539: Earths: DARWIN/TPF and the Search for Extrasolar Terrestrial Planets
2003mse..symp    ESA SP-540: Materials in a Space Environment
2003lcpm.conf    ESA SP-542: Low-Cost Planetary Missions
2004ppae.work    ESA SP-544: Planetary Probe Atmospheric Entry and Descent Trajectory Analysis and Science
2004soho...13    ESA SP-547: SOHO 13 Waves, Oscillations and Small-Scale Transients Events in the Solar Atmosphere:  Joint View from SOHO and TRACE
    ESASP        ESA Special Publication
1980dwga.work    ESA Workshop on Dwarf Galaxies
    esla.symp    ESLAB Symposium
1990daan.work    ESO Conf. Proc. 34: 2nd ESO/ST-ECF Data Analysis Workshop
1991daan.work    ESO Conf. Proc. 38: 3rd ESO/ST-ECF Data Analysis Workshop
1993daan.work    ESO Conf. Proc. 41: 5th ESO/ST-ECF Data Analysis Workshop Garching
1982esoi.work    ESO Infrared Workshop
1985vcg..work    ESO Workshop on the Virgo Cluster
1987sn...work    ESO Workshop on SN 1987 A
1983vlt..work    ESO's Very Large Telescope
1989eeda.conf    ESO/ST-ECF Data Analysis Workshop
1982ena..conf    Essays in Nuclear Astrophysics
1987ess..nasa    Essays in Space Science
1985gasr.book    Essays presented to W.B. Bonnor on his 65th birthday
1985ashc.rept    The European Astrometry Satellite HIPPARCOS: Scientific Aspects of the Input Catalog Preparation
1981ecap.conf    European Conference on Atomic Physics
1987eram....1    European Regional Astronomy Meeting of the IAU, Volume 1
1987eram....2    European Regional Astronomy Meeting of the IAU, Volume 2
1987eram....3    European Regional Astronomy Meeting of the IAU, Volume 3
1987eram....4    European Regional Astronomy Meeting of the IAU, Volume 4
1987eram....5    European Regional Astronomy Meeting of the IAU, Volume 5
    erbp.symp    European Rocket and Balloon Programs and Related Research
    eurb.rept    European Rocket Ballong Programmes
1980urbp.symp    European Rocket Balloon Program
1979esa..conf    European Satellite Astrometry
1975esm..meet    European Solar Meeting
    esrb.rept    European Sounding Rocket, Balloon and Related Research with Emphasis on Experiments at High Latitudes
    ESOC.        European Southern Observatory Astrophysics Symposia
    eso..rept    European Southern Observatory Report
1974eslt.rept    European Southern Observatory Research Programmes for the New Large Telescopes
1988evga.conf    European VLBI for Geodesy and Astrometry
2000evn..conf    EVN Symposium 2000, Proceedings of the 5th european VLBI Network Symposium
1982eitu.conf    Evolution in the Universe
1990iuea.rept    Evolution in Astrophysics: IUE Astronomy in the Era of New Space Missions
1993eep..book    Evolution of the Earth and Planets
    evci.conf    The Evolution of the Galaxies and its Cosmological Implications
1992ema..work    Evolution of the Martian Atmosphere
2000emw..conf    The Evolution of the Milky Way: Stars versus Clusters
1987esbs.conf    The Evolution of the Small Bodies of the Solar System
1976evss.nasa    Evolution of the Solar System
1997evun.work    The Evolution of the Universe: report of the Dahlem Workshop on the Evolution of the Universe
1977egsp.conf    Evolution of Galaxies and Stellar Populations
1993egte.conf    Evolution of Galaxies and their Environment
1989eidr.proc    Evolution of Interstellar Dust and Related Topics
1992eoim.conf    Evolution of Interstellar Matter and Dynamics of Galaxies
1999elss.conf    Evolution of Large Scale Structure : From Recombination to Garching
1998elss.conf    Evolution of Large-Scale Structure: From Recombination to Garching
1978epac.conf    Evolution of Planetary Atmospheres and Climatology of the Earth
1979epac.conf    Evolution of Planetary Atmospheres and Climatology of the Earth
1979epac.conf    Evolution of Planetary Atmospheres and Climatology of the Earth
1972teps.proc    The Evolution of Population II Stars
1991epu..conf    Evolutionary Phenomena in the Universe
1989epg..conf    Evolutionary Phenomena in Galaxies
1981ebas.conf    Excitation and Broadening in Atomic Spectra of Astrophysical Interest
1989exmm.nasa    Exobiology and Future Mars Missions
1992esse.nasa    Exobiology in Solar System Exploration
2003enam.conf    Exotic Nuclei and Atomic Masses
1999ewgr.book    The Expanding Worlds of General Relativity
1991eahe.conf    Experimental Apparatus for High Energy Particle Physics and Astrophysics
1994exgr.conf    Experimental Gravitation
1993ehtf.conf    Experimental Heat Transfer, Fluid Mechanics, and Thermodynamics 1993
2000epgw.conf    Experimental Physics of Gravitational Waves
1987eprs.nasa    Experiments in Planetary and Related Sciences and the Space Station
2002esis.book    Exploration of Space: Issues and Status
2003ears.book    Exploring the Atmosphere by Remote Sensing Techniques
2001egru.work    Exploring the Gamma-Ray Universe
1973exnu.conf    Explosive Nucleosynthesis
1997eai..proc    Extragalactic Astronomy in the Infrared
1993ebr..proc    Extragalactic Background Radiation: A Meeting in Honor of Riccardo Giacconi
1997eds..proc    The Extragalactic Distance Scale
1985ees..conf    Extragalactic Energetic Sources
2003egcs.conf    Extragalactic Globular Cluster Systems
1981ehea.conf    Extragalactic High Energy Astrophysics
1981exmo.conf    Extragalactic Molecules
1981egm..work    Extragalactic Molecules Workshop
1992ersf.meet    Extragalactic Radio Sources. From Beams to Jets
1989eag..work    Extranuclear Activity in Galaxies
1968exre.conf    Extraterrestrial Resources
1982ewat.book    Extraterrestrials - Where are they?
1991eua..coll    Extreme Ultraviolet Astronomy
1976fia..book    Far Infrared Astronomy
1993fces.conf    The Feedback of Chemical Evolution on the Stellar Content of Galaxies
1940fes..book    Festschrift f\x{00FC}r Elis Str\x{00F6}mgren
1999fbpp.conf    Few-Body Problems in Physics '98
1982ftep.conf    Field Theory in Elementary Particles
2001mhmd.work    Field Trip and Workshop on the Martian Highlands and Mojave Desert Analogs
1991eisc.work    Fifth EISCAT Scientific Workshop: Programme and Abstracts
1987fdem.conf    Figure and Dynamics of the Earth, Moon and Planets
    raincrept    Final Radiophysics, Inc. Report
1991fnps.conf    Finnish Physical Society Conference Proceedings
1990fnsr.meet    Finnish Space Researchers Meeting
1980csss....1    First Cambridge Workshop on Cool Stars, Stellar Systems, and the Sun
1965cfbs.conf    First Conference on Faint Blue Stars
2001fcm..book    First COROT/MONS/MOST  Ground  Support Workshop
1995gwe..conf    First Edoardo Amaldi Conference on Gravitational Wave Experiments
1996nuig.conf    First Informal Meeting of Nuclear Astrophysics Italian Groups
1998mps..conf    First International Conference on Mars Polar Science and Exploration
2001mers.work    First Landing Site Workshop for the 2003 Mars Exploration Rovers
1993flus.conf    First Light in the Universe. Stars or QSO's?
1967mage.symp    First Marine Geodesy Symposium
1979fppv.book    First Panoramic Photographs of the Venus Surface
1991fyho.conf    The First Year of HST Observations
1997flst.conf    Flamsteed's stars: new perspectives on the life and work of the first Astronomer Royal, 1646-1719.
1979fpp..book    Flare Processes in Plasmas
1988fnsm.work    Flare Research at the Next Solar Maximum
1986fsro.conf    Flare Stars and Related Objects
1974fpsw.conf    Flare-Produced Shock Waves in the Corona and in Interplanetary Space
1985fmcv.conf    Flavour Mixing and CP Violation
    fmet.symp    Flight Mechanics/Estimation Theory Symposium
2001flas.book    Florilegium astronomicum. Festschrift f\x{00FC}r Felix Schmeidler
1998fuhr.book    Flow at Ultra-High Reynolds and Rayleigh Numbers
1974fdg..symp    The Formation and Dynamics of Galaxies
1994feg..conf    The Formation and Evolution of Galaxies
1989feps.meet    The Formation and Evolution of Planetary Systems
1999fgb..conf    The Formation of Galactic Bulges
1982fps..conf    Formation of Planetary Systems
1990fspe.rept    Formation of Stars and Planets, and the Evolution of the Solar System
1999fsu..conf    Formation of Structure in the Universe
1981fseg.conf    Formation, Structure and Evolutino of Galaxies
2001iaop.work    Forum on Innovative Approaches to Outer Planetary Exploration 2001-2020
2001fpld.conf    Forward Physics and Luminosity Determination at LHC
    sbim....1    Foundations of Space Biology and Medicine
1971fosp.conf    Fourier Spectroscopy
1975ICRC.        Fourteenth International Cosmic Ray Conference
1996frph.conf    Fractals in Physics
1987fpsw.conf    From the Planck Scale to the Weak Scale: Toward a Theory of the Universe
1998fsam.conf    From the Sun, Auroras, Magnetic Storms, Solar Flares, Cosmic Rays
1989fdtm.conf    From Data to Model
2000fdtp.conf    From Dust to Terrestrial Planets
1990fgbs.rept    From Ground-Based to Space-Borne Sub-mm Astronomy
2002imgt.book    From Integrable Models to Gauge Theories
1990fmm..conf    From Mantle to Meteorites: A Garland of Perspectives
1992fmtg.conf    From Mars to Greenland : Charting Gravity with Space
1990fmpn.coll    From Miras to Planetary Nebulae: Which Path for Stellar Evolution?
1989fptp.conf    From Particles to Plasmas
1972fpp..conf    From Plasma to Planet
1999fsgu.conf    From Stars to Galaxies to the Universe
1989stq..conf    From Stars to Quasars
1986fsgf.book    From SU(3) to Gravity
1994fsts.conf    From superconductivity to supernovae: The Ginzburg Symposium
2003fthp.conf    From Twilight to Highlight: The Physics of Supernovae
2001foap.symp    Frontier Objects in Astrophysics and Particle Physics
1998ftqp.conf    Frontier Tests of QED and Physics of the Vacuum
2000fdp..conf    Frontiers in Dusty Plasmas
1989fnr..book    Frontiers in Numerical Relativity
1998fqp..conf    Frontiers in Quantum Physics
1984faa..conf    Frontiers of Astronomy and Astrophysics
2001fcgp.work    Frontiers of Cosmology and Gravitation
1984ffp..conf    Frontiers of Fundamental Physics
1990ftph.conf    Frontiers of Physics
2001ftp..conf    Frontiers of Theoretical Physics: A General View of Theoretical Physics at the Crossing of Centuries
1992fxra.conf    Frontiers Science Series
1998bhhe.conf    Frontiers Science Series 23: Black Holes and High Energy Astrophysics
1998psrd.conf    Frontiers Science Series No. 23: Pulsating Stars: Recent Developments in Theory and Observation
1985fic..conf    Fundamental Interactions and Cosmology
2000fps..conf    Fundamental Physics in Space
1995NYASA.755    Fundamental Problems in Quantum Theory
1978fpsm.conf    Fundamental Problems in Statistical Mechanics IV
2000fdso.conf    Further Developments in Scientific Optical Imaging
1988faom.conf    Future Astronomical Observatories on the Moon
1985shpp.rept    Future Missions in Solar, Heliospheric and Space Plasma Physics
2000fufc.conf    The Future of the Universe and the Future of our Civilization.
2003fst1.book    The Future of Small Telescopes In The New Millennium. Volume I - Perceptions, Productivities, and Policies
2003fst2.book    The Future of Small Telescopes In The New Millennium. Volume II - The Telescopes We Use
2003fst3.book    The Future of Small Telescopes In The New Millennium. Volume III - Science in the Shadow of Giants
1984fiue.rept    Future of Ultraviolet Astronomy Based on Six Years of IUE Research
1980fsoo.conf    Future Solar and Optical Observations Needs and Constraints
1978fsoo.conf    Future solar optical observations needs and constraints
    fsa..work    Future Space Activities Workshop
1985gecx.conf    Galactic and Extra-Galactic Compact X-ray Sources
1988gera.book    Galactic and Extragalactic Radio Astronomy
1994gsso.conf    Galactic and Solar System Optical Astrometry
1970gaas.conf    Galactic Astronomy
2003gbh..book    The Galactic Black Hole
1981gaev.conf    Galactic Evolution
1999gfp..work    Galactic Foreground Polarization
2000ghgc.conf    The Galactic Halo : From Globular Cluster to Field Stars
1982gxrs.conf    Galactic X-Ray Sources
1982gxs..conf    Galactic X-ray sources
1986gala.conf    Galaxias
2001gtd..conf    Galaxies: the Third Dimension
1968gaun.book    Galaxies and the Universe
1974gra..conf    Galaxies and Relativistic Astrophysics
2003ghr..conf    Galaxies at High Redshift
1985gqc..book    Galaxies, Quasars and Cosmology
1976RGOB..182    The Galaxy and the Local Group
1986gass.book    The Galaxy and the Solar System
1999gecd.conf    Galaxy Evolution: Connecting the Distant Universe with the Local Fossil Record
2002geto.conf    Galaxy evolution, theory and observations
1997gsr..proc    Galaxy Scaling Relations: Origins, Evolution and Applications
1985gamf.conf    The Galileo Affair: A Meeting of Faith and Science
2001gic..book    Galileo in Context
1966gare.book    Galileo Reappraised
1993grnc.conf    Gamma Ray - Neutrino Cosmology and Planck Scale
1981gra..rept    Gamma Ray Astrophysics
1989gros.work    Gamma Ray Observatory Science Workshop
1978grsa.rept    Gamma Ray Spectroscopy in Astrophysics
1982grap.symp    Gamma-Ray Astronomy in Perspective of Future Space Experiments
1973gra..conf    Gamma-Ray Astrophysics
1992hgrb.symp    Gamma-Ray Bursts
1992grbo.book    Gamma-Ray Bursts - Observations, Analyses and Theories
1998hgrb.symp    Gamma-Ray Bursts, 4th Hunstville Symposium
2001grba.conf    Gamma-ray Bursts in the Afterglow Era
1996grea.conf    Gamma-ray Emitting AGN
1986goco.conf    Ganow Cosmology
2003gafe.conf    The Garrison Festschrift
1984gim..conf    Gas in the Interstellar Medium
1986ghg..conf    Gaseous halos of Galaxies
1986ghog.conf    Gaseous Halos of Galaxies
1976gtmf.conf    Gauge Theories and Modern Field Theory
1988gteu.book    Gauge Theory and the Early Universe
1977grep.conf    General Relativistic Effects in Physics and Astrophysics
1984grg..conf    General Relativity and Gravitation Conference
1980grg2.conf    General Relativity and Gravitation II
    grgp.proc    General Relativity and Gravitational Physics
1977gep..symp    Geodesy and Physics of the Earth
1977gpe..symp    Geodesy and Physics of the Earth
1992gpe..conf    Geodesy and Physics of the Earth: Geodetic Contributions to Geodynamics
1961gsa..symp    Geodesy in the Space Age
1982gari.conf    Geodetic Applications of Radio Interferometry
1979sdp..conf    Geodetic Symposium on Satellite Doppler Positioning
1976gbep.rept    A Geological Basis for the Exploration of the Planets
1971gplp.conf    Geological Problems in Lunar and Planetary Research
1985ga15.conf    Geology of the Apollo 15 Landing Site
1992ga17.conf    Geology of the Apollo 17 Landing Site
1984gtp..rept    Geology of the Terrestial Planets
    gmu..rept    George Mason Univ. Technical Report
    gita.rept    Georgia Institute of Technology Final Report
1989gadv.book    Gerard and Antoinette de Vaucouleurs: A life for Astronomy
2000gtgr.conf    GeV-TeV Gamma Ray Astrophysics Workshop : towards a major atmospheric Cherenkov detector
1980gmcg.work    Giant Molecular Clouds in the Galaxy
1997gpsc.conf    Gigahertz Peaked Spectrum and Compact Steep Spectrum Radio Sources
1969gsse.conf    Giornate di Studio Sull'Elio
1990grg..conf    Global and Regional Geodynamics
1990gceh.book    Global Catastrophes in Earth History
1985gmgm.rept    Global Mega-Geomorphology
1970gwp..book    Global Weather Predication: The Coming Revolution
1980glcl.conf    Globular Clusters
1983ghf..conf    Gluons and Heavy Flavours, Volume 1
1991gwos.work    Graduate Workshop on Star Formation
1984guww.book    Grand Unification With and Without Supersymmetry and Cosmological
2000graa.conf    Gravitation and Astrophysics
2002gchr.conf    Gravitation and Cosmology : from the Hubble Radius to the Planck Scale
1991gamc.conf    Gravitation and Modern Cosmology. The Cosmological Constant Problem
1995grqu.conf    Gravitation and Quantizations, Session LVII of Les Houches
1984grap.conf    Gravitation and Relativistic Astrophysics
1998grtm.conf    Gravitation and Relativity: At the Turn of the Millennium
2001gect.book    Gravitation, Electromagnetism and Cosmology: Toward a New Synthesis,
1988gqfs.conf    Gravitation, Quantum Fields, and Superstrings
1991gaid.conf    Gravitational Astronomy: Instrument Design and Astrophysical Prospects
1986gcr..conf    Gravitational Collapse and Relativity
1996grdy.conf    Gravitational dynamics
1989gfpg.conf    Gravitational Force Perpendicular to the Galactic Plane
1993glu..conf    Gravitational Lenses in the Universe
1989gmca.conf    Gravitational Magneto-Convection and Accretion
1983grr..proc    Gravitational Radiation
1986rac..conf    Gravitational Radiation and Relativity
1980grco.symp    Gravitational Radiation, Collapsed Objects, and Exact Solutions
1979grt..conf    Gravitational radiation theory
1997gwd..conf    Gravitational Wave Detection
2000gwd..conf    Gravitational Wave Detection II
2001gwvs.conf    Gravitational Waves
1974gwr..conf    Gravitational Waves and Radiations
1997gwsd.conf    Gravitational Waves: Sources and Detectors
1995grge.conf    Gravity and Geoid
1990ggg..conf    Gravity, Gradiometry, and Gravimetry
1993graz.iafc    Graz International Astronautical Federation Congress
2000gesb.conf    The Greatest Explosions Since the Big Bang : Supernovae and Gamma-Ray Bursts
    gmd..rept    Greenbelt, Md. Workshop
    gtr..rept    Greenwich Time Report
1986gsih.conf    Ground and Space Investigations of the Halley Comet 1985-1986
1996gbaa.conf    Ground-Based Astronomy in Asia
1988gcc..work    Growth of Continental Crust
1975grhe.conf    Growth Rhythms and the History of the Earth's Rotation
1973gnrp.conf    The Gum Nebula and Related Problems
1974hrgc.rept    H2 Regions and the Galactic Centre
1979haob.rept    Hale Observatories Annual Report
2000hscm.conf    Hamiltonian Systems and Celestial Mechanics (HAMSYS-98)
1994hadg.conf    Handling and Archiving Data from Ground-Based Telescopes
1992hoae.conf    Hands-on Astronomy for Education
    huha.rept    Hawaii Univ., Honolulu Report
    hawi.rept    Hawaii University Technical Report
1994hdtc.conf    Hazards Due to Comets and Asteroids
1985hdce.conf    Heat and Detachment in Crustal Extension on Continents and Planets
1974hta..conf    Heat Transfer in the Atmosphere
1998hume.conf    HEDS-UP Mars Exploration Forum
1974hsde.rept    Helios Satellite Sci. Data Evaluation
1982hac..book    Heteogeneous Atmospheric Chemistry, Geophysical Monograph 26
1987huba.conf    HE-UHE Behaviour of Accreting X-ray Sources
    hea..conf    High Energy Astrophysics
1985hea..book    High Energy Astrophysics
1994heam.book    High Energy Astrophysics
1984heac.conf    High Energy Astrophysics and Cosmology
1993heac.conf    High Energy Astrophysics and Cosmology
1991heac.conf    High Energy Astrophysics: Compact Stars and Active Galaxies
1984hea..meet    High Energy Astrophysics Meeting
1997hecn.conf    High Energy Cosmic Neutrinos: Origin, Production and Detection
2001hegr.proc    High Energy Gamma-Ray Astronomy
1990hehi.conf    High Energy Hadronic Interactions
1992hena.conf    High Energy Neutrino Astrophysics
1973heps.conf    High Energy Phenomena on the Sun
1995hep..conf    High Energy Physics
1986hep..conf    High Energy Physics, 1985, Vol. 2.
1998hepc.conf    High Energy Physics and Cosmology, 1997 Summer School
1999hepc.conf    High Energy Physics and Cosmology, 1998 Summer School
1996hesp.conf    High Energy Solar Physics
1983het..work    High Energy Transients
1984heta.conf    High Energy Transients in Astrophysics
2001heus.conf    High Energy Universe at Sharp Focus: Chandra Science
1987hrpg.work    High Redshift and Primeval Galaxies
1978hrs..conf    High resolution spectrometry
2002hrxs.conf    High Resolution X-ray Spectroscopy with XMM-Newton and Chandra
1989hsrs.conf    High spatial resolution solar observations
1991heaa.conf    High-Energy Astrophysics. American and Soviet Perspectives
1991hiaa.rept    High-Energy Astrophysics. American and Soviet Perspectives
1967henr.book    High-Energy Nuclear Reactions in Astrophysics
1981heps.book    High-Energy Particles in Space - Experimental Methods and Techniques
1997hepc.conf    High-Energy Physics and Cosmology: Celebrating the Impact of 25 Years of Coral Gables Conferences
2000hcmp.conf    Highlights in Condensed Matter Physics
1988hgc..conf    Highlights in Gravitation and Cosmology
1999hxra.conf    Highlights in X-ray Astronomy
1986hmac.book    Highlights of Modern Astrophysics: Concepts and Controversies
2001hsa..conf    Highlights of Spanish astrophysics II
1992hrii.conf    High-Resolution Imaging by Interferometry
1996hsra.proc    High-Sensitivity Radio Astronomy
1989hmps....2    The Hipparcos Mission. Prelaunch Status. Volume 2: The Input Catalog
1989hmps....3    The Hipparcos Mission. Prelaunch Status. Volume 3: The Data Reductions
1965hoga.book    Homage to Galileo
1999fftq.conf    Horizons in World Physics 227: Frontiers of Field Theory, Quantum Gravity and Strings
1985hbuv.proc    Horizontal-Branch and UV-Bright Stars
1994hsgh.conf    Hot Stars in the Galactic Halo
1998hdf..symp    The Hubble Deep Field
1997hsth.conf    The Hubble Space Telescope and the High Redshift Universe
    hsth.        Hubble Space Telescope Handbook
    hstx.rept    Hughes STX, Inc. Technical Report
1965hmmc.book    Humidity and Moisture: Measurement and Control in Science and Industry
1985hasr.book    Hydroaeromechanics and Space Research
1986hmps.conf    Hydrodynamic and Magnetodynamic Problems in the Sun and Stars
1984hms..rept    The Hydromagnetics of the Sun
    hvi..symp    Hypervelocity Impact Symposium
1972pvgc.coll    IAU Colloq. 1: The Problem of the Variation of the Geographical Coordinates in the Southern Hemisphere
1987fuas.conf    IAU Colloq. 100: Fundamentals of Astrometry
1988srim.conf    IAU Colloq. 101: Supernova Remnants and the Interstellar Medium
1988sasf.conf    IAU Colloq. 104: Solar and Stellar Flares
1990teas.conf    IAU Colloq. 105: The Teaching of astronomy
1989eprg.proc    IAU Colloq. 106: Evolution of Peculiar Red Giant Stars
    adse.conf    IAU Colloq. 108: Atmospheric Diagnostics of Stellar Evolution
1989lisa.conf    IAU Colloq. 110: Library and Information Services in Astronomy
1989upsf.conf    IAU Colloq. 111: The Use of pulsating stars in fundamental problems of astronomy
1990hrxr.conf    IAU Colloq. 115: High Resolution X-ray Spectroscopy of Cosmic Plasmas
1971psmp.coll    IAU Colloq. 12: Physical Studies of Minor Planets
1990pcn..conf    IAU Colloq. 122: Physics of Classical Nova
1990pig..coll    IAU Colloq. 124: Paired and Interacting Galaxies
1991resy.coll    IAU Colloq. 127: Reference Systems
1992msem.coll    IAU Colloq. 128: Magnetospheric Structure and Emission Mechanics of Radio Pulsars
1991sepa.conf    IAU Colloq. 129: The 6th Institute d'Astrophysique de Paris (IAP) Meeting: Structure and Emission Properties of Accretion Disks
1973eppm.coll    IAU Colloq. 13: Evolutionary and Physical Properties of Meteoroids
1993icpc.proc    IAU Colloq. 132: Instability, Chaos and Predictability in Celestial Mechanics and Stellar Dynamics
1993spct.conf    IAU Colloq. 136: Stellar Photometry - Current Techniques and Future Developments
1993npsp.conf    IAU Colloq. 139: New Perspectives on Stellar Pulsation and Pulsating Variable Stars
1994svs..coll    IAU Colloq. 143: The Sun as a Variable Star: Solar and Stellar Irradiance Variations
1994scs..conf    IAU Colloq. 144: Solar Coronal Structures
1996ssr..conf    IAU Colloq. 145: Supernovae and Supernova Remnants
1994esa..conf    IAU Colloq. 147: The Equation of State in Astrophysics
1971ndnf.coll    IAU Colloq. 15: New Directions and New Frontiers in Variable Star Research
1996aeu..conf    IAU Colloq. 152: Astrophysics in the Extreme Ultraviolet
1996mpsa.conf    IAU Colloq. 153: Magnetodynamic Phenomena in the Solar Atmosphere - Prototypes of Stellar Magnetic Activity
1996ccsl.proc    IAU Colloq. 156: The Collision of Comet Shoemaker-Levy 9 and Jupiter
1997abos.conf    IAU Colloq. 161: Astronomical and Biochemical Origins and the Search for Life in the Universe
1998ntat.coll    IAU Colloq. 162: New Trends in Astronomy Teaching,
1997dana.coll    IAU Colloq. 165: Dynamics and Astrometry of Natural and Artificial Celestial Bodies
1972ade..coll    IAU Colloq. 17: Age des Etoiles
1998imda.coll    IAU Colloq. 172: Impact of Modern Dynamics in Astronomy
1999esra.conf    IAU Colloq. 173: Evolution and Source Regions of Asteroids and Comets
2000tmcs.conf    IAU Colloq. 180: Towards Models and Constants for Sub-Microarcsecond Astrometry
2002dsso.conf    IAU Colloq. 181: Dust in the Solar System and Other Planetary Systems
2001agns.conf    IAU Colloq. 184: AGN Surveys
1973stch.coll    IAU Colloq. 19: Stellar Chromospheres
1970sfss.coll    IAU Colloq. 2: Spectrum Formation in Stars with Steady-State Extended Atmospheres
1974acmm.book    IAU Colloq. 22: Asteroids, Comets, Meteoric Matter
1974psns.coll    IAU Colloq. 23: Planets, Stars, and Nebulae: Studied with Photopolarimetry
1976scom.nasa    IAU Colloq. 25: The Study of Comets
1975rcse.proc    IAU Colloq. 26: On Reference Coordinate Systems for Earth Dynamics
1977ps...book    IAU Colloq. 28: Planetary Satellites
1976jsia.coll    IAU Colloq. 30: Jupiter: Studies of the Interior, Atmosp here, Magnetosphere and Satellites
1976idzl.coll    IAU Colloq. 31: Interplanetary Dust and Zodiacal Light
1976paps.coll    IAU Colloq. 32: Physics of Ap Stars
1977ebhs.coll    IAU Colloq. 36: The Energy Balance and Hydrodynamics of the Solar Chromosphere and Corona
1977dreu.coll    IAU Colloq. 37: Decalages vers le Rouge et Expansion de L'Univers
1977stco.coll    IAU Colloq. 38: Problems of Stellar Convection
1977cami.coll    IAU Colloq. 39: Comets, Asteroids, Meteorites: Interrelations, Evolution and Origins
1970stro.coll    IAU Colloq. 4: Stellar Rotation
1977aaid.coll    IAU Colloq. 40: Astronomical Applications of Image Detectors with Linear Response
1977ivsw.conf    IAU Colloq. 42: The Interaction of Variable Stars with their Environment
1977uxsa.coll    IAU Colloq. 43: Fifth Conference on UV and X-Ray Spectroscopy of Astrophysical and Laboratory Plasmas
1979phsp.coll    IAU Colloq. 44: Physics of Solar Prominences
1978cdeo.coll    IAU Colloq. 45: Chemical and Dynamical Evolution of our Galaxy
1979ctvs.conf    IAU Colloq. 46: Changing Trends in Variable Star Research
1979RA......9    IAU Colloq. 47: Spectral Classification of the Future
1978moas.coll    IAU Colloq. 48: Modern Astrometry
1979hars.proc    IAU Colloq. 50: High Angular Resolution Stellar Interferometry
1980sttu.coll    IAU Colloq. 51: Stellar Turbulence
1978prpl.conf    IAU Colloq. 52: Protostars and Planets
1979wdvd.coll    IAU Colloq. 53: White Dwarfs and Variable Degenerate Stars
1980srst.coll    IAU Colloq. 54: Scientific Research with the Space Telescope
1981csed.proc    IAU Colloq. 56: Reference Coordinate Systems for Earth Dynamics
1981saju.coll    IAU Colloq. 57: Satellites of Jupiter
1970mlec.coll    IAU Colloq. 6: Mass Loss and Evolution in Close Binaries
1982urop.coll    IAU Colloq. 60: Uranus and the Outer Planets
1982come.coll    IAU Colloq. 61: Comet Discoveries, Statistics, and Observational Selection
1981apgc.conf    IAU Colloq. 68: Astrophysical Parameters for Globular Clusters
1970prmo.coll    IAU Colloq. 7: Proper Motions
1982uxsa.coll    IAU Colloq. 73: Seventh International Colloquium on UV and X-Ray Spectroscopy of Astrophysical and Laboratory Plasmas
1984prin.conf    IAU Colloq. 75: Planetary Rings
1983nssl.conf    IAU Colloq. 76: Nearby Stars and the Stellar Luminosity Function
1986sats.book    IAU Colloq. 77: Some Background about Satellites
1984vlti.conf    IAU Colloq. 79: Very Large Telescopes, their Instrumentation and Programs
1984lim..conf    IAU Colloq. 81: Local Interstellar Medium
1985cto..conf    IAU Colloq. 82: Cepheids: Theory and Observation
1985loze.conf    IAU Colloq. 84: Longitude Zero 1884-1984
1984uxsa.coll    IAU Colloq. 86: Eighth International Colloquium on UV and X-Ray Spectroscopy of Astrophysical and Laboratory Plasmas
1985srv..proc    IAU Colloq. 88: Stellar Radial Velocities
1986rhsc.conf    IAU Colloq. 89: Radiation Hydrodynamics in Stars and Compact Objects
1987hooa.coll    IAU Colloq. 91: History of Oriental Astronomy
1987pbes.coll    IAU Colloq. 92: Physics of Be Stars
1987fbs..conf    IAU Colloq. 95: Second Conference on Faint Blue Stars
1988scaa.conf    IAU Colloq. 98: Stargazers. The Contribution of Amateurs to Astronomy
    IAUCo        IAU Colloquia
    IAUDS        IAU Commission on Double Stars
    IAUIn        IAU Commission on Instruments
1955IAUS....1    IAU Symp.   1: Conference on Co-ordination of galactic research
1951IAUS....1    IAU Symp.   1: Problems of Cosmical Aerodynamics
1955IAUS....2    IAU Symp.   2: Gas Dynamics of Cosmic Clouds
1957IAUS....3    IAU Symp.   3: Non-stable stars
1957IAUS....4    IAU Symp.   4: Radio astronomy
1958IAUS....5    IAU Symp.   5: Comparison of the Large-Scale Structure of the Galactic System with that of Other Stellar Systems
1958IAUS....6    IAU Symp.   6: Electromagnetic Phenomena in Cosmical Physics
1959IAUS....7    IAU Symp.   7: Co-ordination of Galactic Research
1958IAUS....8    IAU Symp.   8: Cosmical Gas Dynamics
1959IAUS....9    IAU Symp.   9: URSI Symp. 1: Paris Symposium on Radio Astronomy
1959IAUS...10    IAU Symp.  10: The Hertzsprung-Russell Diagram
1959IAUS...11    IAU Symp.  11: The Rotation of the Earth and Atomic Time Standards
1960IAUS...12    IAU Symp.  12: Aerodynamic Phenomena in Stellar Atmospheres
1961IAUS...13    IAU Symp.  13: The Future of the International Latitude Service
1962IAUS...14    IAU Symp.  14: The Moon
1962IAUS...15    IAU Symp.  15: Problems of Extra-Galactic Research
1963IAUS...16    IAU Symp.  16: The Solar Corona
1962IAUS...17    IAU Symp.  17: Visual Double Stars
1964IAUS...18    IAU Symp.  18: Theoretical Interpretation of Upper Atmosphere Emission
1964IAUS...19    IAU Symp.  19: Le choix des sites d'observatoires astronomiques (site testing)
1964IAUS...20    IAU Symp.  20: The Galaxy and the Magellanic Clouds
1965IAUS...21    IAU Symp.  21: The system of Astronomical Constants
1965IAUS...22    IAU Symp.  22: Stellar and Solar Magnetic Fields
1965IAUS...23    IAU Symp.  23: Astronomical Observations from Space Vehicles
1966IAUS...24    IAU Symp.  24: Spectral Classification and Multicolour Photometry
1966IAUS...25    IAU Symp.  25: The Theory of Orbits in the Solar System and in Stellar Systems
1966IAUS...26    IAU Symp.  26: Abundance Determinations in Stellar Spectra
1966IAUS...27    IAU Symp.  27: The Construction of Large Telescopes
1967IAUS...28    IAU Symp.  28: Aerodynamic Phenomena in Stellar Atmospheres
1967IAUS...29    IAU Symp.  29: Non-stable Phenomena in Galaxies
1967IAUS...30    IAU Symp.  30: Determination of Radial Velocities and their Applications
1967IAUS...31    IAU Symp.  31: Radio Astronomy and the Galactic System
1968IAUS...32    IAU Symp.  32: Continental Drift, Secular Motion of the Pole, and Rotation of the Earth
1968IAUS...33    IAU Symp.  33: Physics and Dynamics of Meteors
1968IAUS...34    IAU Symp.  34: Planetary Nebulae
1968IAUS...35    IAU Symp.  35: Structure and Development of Solar Active Regions
1970IAUS...36    IAU Symp.  36: Ultraviolet Stellar Spectra and Related Ground-Based Observations
1970IAUS...37    IAU Symp.  37: Non-Solar X- and Gamma-Ray Astronomy
1970IAUS...38    IAU Symp.  38: The Spiral Structure of our Galaxy
1970IAUS...39    IAU Symp.  39: Interstellar Gas Dynamics
1971IAUS...40    IAU Symp.  40: Planetary Atmospheres
1971IAUS...41    IAU Symp.  41: New techniques in Space Astronomy
1971IAUS...42    IAU Symp.  42: White Dwarfs
1971IAUS...43    IAU Symp.  43: Solar Magnetic Fields
1972IAUS...44    IAU Symp.  44: External Galaxies and Quasi-Stellar Objects
1972IAUS...45    IAU Symp.  45: The Motion, Evolution of Orbits, and Origin of Comets
1971IAUS...46    IAU Symp.  46: The Crab Nebula
1972IAUS...47    IAU Symp.  47: The Moon
1972IAUS...48    IAU Symp.  48: Rotation of the Earth
1973IAUS...49    IAU Symp.  49: Wolf-Rayet and High-Temperature Stars
1973IAUS...50    IAU Symp.  50: Spectral Classification and Multicolour Photometry
1973IAUS...51    IAU Symp.  51: Extended Atmospheres and Circumstellar Matter in Spectroscopic Binary Systems
1973IAUS...52    IAU Symp.  52: Interstellar Dust and Related Topics
1974IAUS...53    IAU Symp.  53: Physics of Dense Matter
1973IAUS...54    IAU Symp.  54: Problems of Calibration of Absolute Magnitudes and Temperature of Stars
1973IAUS...55    IAU Symp.  55: X- and Gamma-Ray Astronomy
1974IAUS...56    IAU Symp.  56: Chromospheric Fine Structure
1974IAUS...57    IAU Symp.  57: Coronal Disturbances
1974IAUS...58    IAU Symp.  58: The Formation and Dynamics of Galaxies
1974IAUS...59    IAU Symp.  59: Stellar Instability and Evolution
1974IAUS...60    IAU Symp.  60: Galactic Radio Astronomy
1974IAUS...61    IAU Symp.  61: IAU Symp. 61: New Problems in Astrometry
1974IAUS...62    IAU Symp.  62: Stability of the Solar System and of Small Stellar Systems
1974IAUS...63    IAU Symp.  63: Confrontation of Cosmological Theories with Observational Data
1974IAUS...64    IAU Symp.  64: Gravitational Radiation and Gravitational Collapse
1974IAUS...65    IAU Symp.  65: Exploration of the Planetary System
1974IAUS...66    IAU Symp.  66: Late Stages of Stellar Evolution
1975IAUS...67    IAU Symp.  67: Variable Stars and Stellar Evolution
1975IAUS...68    IAU Symp.  68: Solar Gamma-, X-, and EUV Radiation
1975IAUS...69    IAU Symp.  69: Dynamics of the Solar Systems
1976IAUS...70    IAU Symp.  70: Be and Shell Stars
1976IAUS...71    IAU Symp.  71: Basic Mechanisms of Solar Activity
1976IAUS...72    IAU Symp.  72: Abundance Effects in Classification
1976IAUS...73    IAU Symp.  73: Structure and Evolution of Close Binary Systems
1977IAUS...74    IAU Symp.  74: Radio Astronomy and Cosmology
1977IAUS...75    IAU Symp.  75: Star Formation
1978IAUS...76    IAU Symp.  76: Planetary Nebulae
1978IAUS...77    IAU Symp.  77: Structure and Properties of Nearby Galaxies
1980IAUS...78    IAU Symp.  78: Nutation and the Earth's Rotation
1978IAUS...79    IAU Symp.  79: Large Scale Structures in the Universe
1978IAUS...80    IAU Symp.  80: The HR Diagram - The 100th Anniversary of Henry Norris Russell
1979IAUS...81    IAU Symp.  81: Dynamics of the Solar System
1979IAUS...82    IAU Symp.  82: Time and the Earth's Rotation
1979IAUS...83    IAU Symp.  83: Mass Loss and Evolution of O-Type Stars
1979IAUS...84    IAU Symp.  84: The Large-Scale Characteristics of the Galaxy
1980IAUS...85    IAU Symp.  85: Star Formation
1980IAUS...86    IAU Symp.  86: Radio Physics of the Sun
1980IAUS...87    IAU Symp.  87: Interstellar Molecules
1980IAUS...88    IAU Symp.  88: Close Binary Stars: Observations and Interpretation
1979IAUS...89    IAU Symp.  89: Refractional Influences in Astrometry and Geodesy
1980IAUS...90    IAU Symp.  90: Solid Particles in the Solar System
1980IAUS...91    IAU Symp.  91: Solar and Interplanetary Dynamics
1980IAUS...92    IAU Symp.  92: Objects of High Redshift
1981IAUS...93    IAU Symp.  93: Fundamental Problems in the Theory of Stellar Evolution
1981IAUS...94    IAU Symp.  94: Origin of Cosmic Rays
1981IAUS...95    IAU Symp.  95: Pulsars: 13 Years of Research on Neutron Stars
1981IAUS...96    IAU Symp.  96: Infrared Astronomy
1982IAUS...97    IAU Symp.  97: Extragalactic Radio Sources
1982IAUS...98    IAU Symp.  98: Be Stars
1982IAUS...99    IAU Symp.  99: Wolf-Rayet Stars: Observations, Physics, Evolution
1983IAUS..100    IAU Symp. 100: Internal Kinematics and Dynamics of Galaxies
1983IAUS..101    IAU Symp. 101: Supernova Remnants and their X-ray Emission
1983IAUS..102    IAU Symp. 102: Solar and Stellar Magnetic Fields: Origins and Coronal Effects
1983IAUS..103    IAU Symp. 103: Planetary Nebulae
1983IAUS..104    IAU Symp. 104: Early Evolution of the Universe and its Present Structure
1984IAUS..105    IAU Symp. 105: Observational Tests of the Stellar Evolution Theory
1985IAUS..106    IAU Symp. 106: The Milky Way Galaxy
1985IAUS..107    IAU Symp. 107: Unstable Current Systems and Plasma Instabilities in Astrophysics
1984IAUS..108    IAU Symp. 108: Structure and Evolution of the Magellanic Clouds
1986IAUS..109    IAU Symp. 109: Astrometric Techniques
1984IAUS..110    IAU Symp. 110: VLBI and Compact Radio Sources
1985IAUS..111    IAU Symp. 111: Calibration of Fundamental Stellar Quantities
1985IAUS..112    IAU Symp. 112: The Search for Extraterrestrial Life: Recent Developments
1985IAUS..113    IAU Symp. 113: Dynamics of Star Clusters
1986IAUS..114    IAU Symp. 114: Relativity in Celestial Mechanics and Astrometry.  High Precision Dynamical Theories and Observational Verifications
1987IAUS..115    IAU Symp. 115: Star Forming Regions
1986IAUS..116    IAU Symp. 116: Luminous Stars and Associations in Galaxies
1987IAUS..117    IAU Symp. 117: Dark matter in the universe
1986IAUS..118    IAU Symp. 118: Instrumentation and Research Programmes for Small Telescopes
1986IAUS..119    IAU Symp. 119: Quasars
1987IAUS..120    IAU Symp. 120: Astrochemistry
1987IAUS..121    IAU Symp. 121: Observational Evidence of Activity in Galaxies
1987IAUS..122    IAU Symp. 122: Circumstellar Matter
1988IAUS..123    IAU Symp. 123: Advances in Helio- and Asteroseismology
1987IAUS..124    IAU Symp. 124: Observational Cosmology
1987IAUS..125    IAU Symp. 125: The Origin and Evolution of Neutron Stars
1988IAUS..126    IAU Symp. 126: The Harlow-Shapley Symposium on Globular Cluster Systems in Galaxies
1987IAUS..127    IAU Symp. 127: Structure and Dynamics of Elliptical Galaxies
1988IAUS..128    IAU Symp. 128: The Earth's Rotation and Reference Frames for Geodesy and Geodynamics
1988IAUS..129    IAU Symp. 129: The Impact of VLBI on Astrophysics and Geophysics
1988IAUS..130    IAU Symp. 130: Large Scale Structures of the Universe
1989IAUS..131    IAU Symp. 131: Planetary Nebulae
1988IAUS..132    IAU Symp. 132: The Impact of Very High S/N Spectroscopy on Stellar Physics
1988IAUS..133    IAU Symp. 133: Mapping the Sky: Past Heritage and Future Directions
1989IAUS..134    IAU Symp. 134: Active Galactic Nuclei
1989IAUS..135    IAU Symp. 135: Interstellar Dust
1989IAUS..136    IAU Symp. 136: The Center of the Galaxy
1990IAUS..137    IAU Symp. 137: Flare Stars in Star Clusters, Associations and the Solar Vicinity
1989IAUS..138    IAU Symp. 138: Solar Photosphere: Structure, Convection, and Magnetic Fields
1990IAUS..139    IAU Symp. 139: The Galactic and Extragalactic Background Radiation
1990IAUS..140    IAU Symp. 140: Galactic and Intergalactic Magnetic Fields
1990IAUS..141    IAU Symp. 141: Inertial Coordinate System on the Sky
1990IAUS..142    IAU Symp. 142: Basic Plasma Processes on the Sun
1991IAUS..143    IAU Symp. 143: Wolf-Rayet Stars and Interrelations with Other Massive Stars in Galaxies
1991IAUS..144    IAU Symp. 144: The Interstellar Disk-Halo Connection in Galaxies
1991IAUS..145    IAU Symp. 145: Evolution of Stars: the Photospheric Abundance Connection
1991IAUS..146    IAU Symp. 146: Dynamics of Galaxies and Their Molecular Cloud Distributions
1991IAUS..147    IAU Symp. 147: Fragmentation of Molecular Clouds and Star Formation
1991IAUS..148    IAU Symp. 148: The Magellanic Clouds
1992IAUS..149    IAU Symp. 149: The Stellar Populations of Galaxies
1992IAUS..150    IAU Symp. 150: Astrochemistry of Cosmic Phenomena
1992IAUS..151    IAU Symp. 151: Evolutionary Processes in Interacting Binary Stars
1992IAUS..152    IAU Symp. 152: Chaos, Resonance, and Collective Dynamical Phenomena in the Solar System
1993IAUS..153    IAU Symp. 153: Galactic Bulges
1994IAUS..154    IAU Symp. 154: Infrared Solar Physics
1993IAUS..155    IAU Symp. 155: Planetary Nebulae
1993IAUS..156    IAU Symp. 156: Developments in Astrometry and their Impact on Astrophysics and Geodynamics
1993IAUS..157    IAU Symp. 157: The Cosmic Dynamo
1994IAUS..158    IAU Symp. 158: Very High Angular Resolution Imaging
1994IAUS..159    IAU Symp. 159: Multi-Wavelength Continuum Emission of AGN
1994IAUS..160    IAU Symp. 160: Asteroids, Comets, Meteors 1993
1994IAUS..161    IAU Symp. 161: Astronomy from Wide-Field Imaging
1994IAUS..162    IAU Symp. 162: Pulsation; Rotation; and Mass Loss in Early-Type Stars
1994IAUS..163    IAU Symp. 163: Wolf-Rayet Stars: Binaries; Colliding Winds; Evolution
1995IAUS..164    IAU Symp. 164: Stellar Populations
1996IAUS..165    IAU Symp. 165: Compact Stars in Binaries
1995IAUS..166    IAU Symp. 166: Astronomical and Astrophysical Objectives of Sub-Milliarcsecond Optical Astrometry
1995IAUS..167    IAU Symp. 167: New Developments in Array Technology and Applications
1996IAUS..168    IAU Symp. 168: Examining the Big Bang and Diffuse Background Radiations
1996IAUS..169    IAU Symp. 169: Unsolved Problems of the Milky Way
1996IAUS..170    IAU Symp. 170: CO: Twenty-Five Years of Millimeter-Wave Spectroscopy
1996IAUS..171    IAU Symp. 171: New Light on Galaxy Evolution
1996IAUS..172    IAU Symp. 172: Dynamics, Ephemerides, and Astrometry of the Solar System
1996IAUS..173    IAU Symp. 173: Astrophysical Applications of Gravitational Lensing
1996IAUS..174    IAU Symp. 174: Dynamical Evolution of Star Clusters: Confrontation of Theory and Observations
1996IAUS..175    IAU Symp. 175: Extragalactic Radio Sources
1996IAUS..176    IAU Symp. 176: Stellar Surface Structure
1996IAUS..178    IAU Symp. 178: Molecules in Astrophysics: Probes & Processes
1998IAUS..179    IAU Symp. 179: New Horizons from Multi-Wavelength Sky Surveys
1997IAUS..180    IAU Symp. 180: Planetary Nebulae
1997IAUS..181    IAU Symp. 181: Sounding Solar and Stellar Interiors
1997IAUS..182    IAU Symp. 182: Herbig-Haro Flows and the Birth of Stars
1999IAUS..183    IAU Symp. 183: Cosmological Parameters and the Evolution of the Universe
1998IAUS..184    IAU Symp. 184: The Central Regions of the Galaxy and Galaxies
1998IAUS..185    IAU Symp. 185: New Eyes to See Inside the Sun and Stars
1999IAUS..186    IAU Symp. 186: Galaxy Interactions at Low and High Redshift
1997IAUS..187    IAU Symp. 187: Cosmic Chemical Evolution
1998IAUS..188    IAU Symp. 188: The Hot Universe
1998IAUS..189    IAU Symp. 189: Fundamental Stellar Properties
1999IAUS..190    IAU Symp. 190: New Views of the Magellanic Clouds
1999IAUS..191    IAU Symp. 191: Asymptotic Giant Branch Stars
1999IAUS..193    IAU Symp. 193: Wolf-Rayet Phenomena in Massive Stars and Starburst Galaxies
1999IAUS..194    IAU Symp. 194: Activity in Galaxies and Related Phenomena
2000IAUS..195    IAU Symp. 195: Highly Energetic Physical Processes and Mechanisms for Emission from Astrophysical Plasmas
    IAUS.        IAU Symposium
    ISTP.        ICTP Series in Theoretical Physics
1994isra.conf    Ideas for Space Research After the Year 2000
1997idm..work    Identification of Dark Matter
1999idm..conf    The Identification of Dark Matter
2001idm..conf    Identification of Dark Matter
2003idm..conf    Identification of Dark Matter
1987iopo.book    Identification, Optimization and Protection of Optical Telescope Sites
1987iop..conf    Identitification, Optimization, and Protection of Optical Telescope Sites
1988iaia.conf    Image Analysis in Astronomy
1979ipia.coll    Image Processing in Astronomy
1977iecp.symp    Impact and Explosion Cratering: Planetary and Terrestrial Implications
2003icbg.conf    Impact Cratering: Bridging the Gap Between Modeling and Observations
1990icmc.book    Impact Craters of the Mesozoic-Cenozoic Boundary
1984itp..work    Improvements to Photometry
1974inbe.conf    In the beginning
1998seti.conf    In Search for the Extraterrestrial Life
2000iagt.conf    INES Access Guide No. 2, International Ultraviolet Explorer - IUE Newly Extracted Spectra Normal Galaxies
1985ivnt.book    Infinite Vistas : New Tools for Astronomy
2003iha..book    Information Handling in Astronomy - Historical Vistas
1999iprs.conf    Information Processing for Remote Sensing
1968inas.book    Infrared Astronomy
1993inas.conf    Infrared Astronomy
1985iras.rept    Infrared Astronomy Satellite (IRAS) Catalogs and Atlases
1987iawa.conf    Infrared astronomy with arrays
1976inde.conf    Infrared detectors
1988ioch.rept    Infrared Observations of Comets Halley and Wilson and Properties of the Grains
1978irea.book    Infrared Radiation in the Earth's Atmosphere and in Space
2000iast.conf    Infrared Space Astronomy, Today and Tomorrow
1991isrs.conf    The Infrared Spectral Region of Stars
1989irsa.rept    Infrared Spectroscopy in Astronomy
1989isc..conf    Infrared Systems and Components
1995itsa.conf    Infrared tools for solar astrophysics: What's next?
1995icm..conf    Inhomogeneous Cosmological Models
1973inip.conf    Inner Shell Ionization Phenomena and Future Applications
1986isos.book    Inner Space/Outer Space: The Interface between Cosmology and Particle Physics
1998icmn.conf    Innovative Computational Methods in Nuclear Many-Body Problems, Towards a New Generation of Physics in Finite Quantum Systems (INNOCOM97)
1986inns.iafc    Innsbruck International Astronautical Federation Congress
1989icis.conf    Inside the Sun
1992iesh.conf    Instabilities in Evolved Super- and Hypergiants
    ieee.conf    Institute of Electrical and Electronics Engineers, Inc. Conference
1975iafe.rept    Instituto de Astronomia y Fisica del Espacio
1989imse.book    Instrumentation and Methods for Space Exploration
1966ihep.conf    Instrumentation for High Energy Physics
1961ihep.conf    Instrumentation for High-Energy Physics
1979SPIE..172    Instrumentation in Astronomy III
1997ioai.book    Integrated Optics for Astronomical Interferometry
1988inex.book    Inteligencia Extraterrestre
1985ibs..book    Interacting Binary Stars
1976ip...book    The Intercosmos Program
1987iia..conf    Interferometric Imaging in Astronomy
1982iie..conf    Interferometry, Identification and Excision
    iapp.rept    International Amateur-Professional Photoelectric Photometric Communications
1986iau..meet    International Astronomical Union Meeting
    IAEAP        International Atomic Energy Agency Proceedings Series 3
    ICTP.        International Center for Theoretical Physics
    ictp.rept    International Centre for Theoretical Physics Technical Report
1992venu.coll    International Colloquium on Venus
2000ceme.conf    International Conference on Catastrophic Events and Mass Extinctions: Impacts and Beyond
1969igaw.conf    International Gravity and Acoustic Waves
1996isp..book    International School of Physics Course CXXXII
1992paco.conf    International School on Particles and Cosmology
1994paco.conf    International School on Particles and Cosmology
1980isot.symp    International Symposium on the Observatories in Islam
1999arse.conf    International Symposium on Astrophysics Research and Science Education
1998omeg.conf    International Symposium on Origin of Matter and Evolution of Galaxies 97
    rse.....1    International Symposium on Remote Sensing of Environment
2002vlbi.conf    International VLBI Service for Geodesy and Astrometry
1992iwrn.conf    International Weather Radar Networking
1986anme.work    International Workshop on Antarctic Meteorites
1999irpa.conf    Internet Resources for Professional Astronomy
1974impm.nasa    Interplanetary Medium and Physics of the Magnetosphere
1988ippe.conf    Interplanetary Particle Environment
1996ibms.conf    The Interplay Between Massive Star Formation, the ISM and Galaxy Evolution
1992ibpd.conf    Interrelations Between Physics and Dynamics for Minor Bodies in the Solar System
1986icii.conf    Interrelationships Among Circumstellar, Interstellar and Interplanetary Dust
1982inco.work    Interstellar Comets Workshop
1974icsp.book    Interstellar Communication: Scientific Perspectives
1989idcp.rept    Interstellar Dust: Contributed Papers
1968iih..conf    Interstellar Ionized hydrogen Proceedings of the Symposium on HII
1987imfo.work    Interstellar Magnetic Fields: Observation and Theory
1988inma.conf    Interstellar Matter
1974inme.conf    The Interstellar Medium
1986inpr.conf    Interstellar Processes: Abstracts of Contributed Papers
1999intu.conf    Interstellar Turbulence
1965its..book    Introduction to Space Science
1968itss.book    Introduction to Space Science
1996imie.conf    Inverse Methods.  Interdisciplinary Elements of Methodology, Computation, and Applications.
1965ibml.conf    Investigation of the Bottom 300-Meter Layer of the Atmosphere
1983igrt.book    Investigation of Gamma-Ray Transients by Means of Unmanned Spacecraft
1965iavm.book    Investigations of the Atmospheres of Venus and Mars
1984isap.book    Investigations of Solar Activity and the Prognoz Space System
1963iono.conf    The Ionosphere
1973idir.conf    Ionosphere Disturbances and their Influence on Radio Communications
1962ise..book    Ionospheric  Sporadic E
1972iore.book    Ionospheric Research, No. 18 - Collection of Articles
    iowa.rept    Iowa University Progress Report
1996isbn.conf    Islands in the Sky: Bold New Ideas for Colonizing Space
1993ispu.conf    Isolated Pulsars
1985irss.rept    Isotopic Ratios in the Solar System
1997foap.conf    Ital. Phys. Soc. Conf. Ser. 57: Frontier Objects in Astrophysics and Particle Physics
    IPSC.        Italian Physical Society Conference Proceedings
1980idr..conf    IUE Data Reduction
1981iue..work    IUE Data Reduction Workshop
1965cngg.conf    IV Centenario Della Nascita di Galileo Galilei, 1564-1964
1969csph.conf    IV Consultation on Solar Physics and Hydromagnetics
1966acte.book    %J Atomic
1999hea..work    Japanese-German Workshop on High Energy Astrophysics
1980jfss.conf    Japan-France Seminar on Solar Physics
    jpl..rept    Jet Propulsion Lab. Report
    jhu..rept    Johns Hopkins Univ. Final Report
1992jdrr.conf    Joint Discussion 3: Results from Rosar and GRO and Other Recent High Energy Astrophysics Missions of the Max-Planck-Institut fuer Extraterrestrische Physik
1997jena.conf    Joint European and National Astronomical Meeting
1986joat.conf    Jovian Atmospheres
1980jupi.conf    Jupiter
1972jrb..work    The Jupiter Radiation Belt Workshop
2000kthr.conf    The Kth Reunion
1984lois.conf    Laboratory and Observational Infrared Spectra of Interstellar Dust
1989lsp..conf    Laboratory and Space Plasmas
1990prpa.conf    Laboratory Research for Planetary Atmospheres
1987adlg.conf    L'Activite dans les Galaxies
1982lbg6.conf    Landolt-Bornstein: Group 6: Astronomy
    lbor.book    Landolt-Bornstein: Numerical Data and Functional Relationships in Science and Technology
1984ldrs....3    Large Deployable Reflector Science and Technology Workshop.  Vol. 3
1982lest.rept    Large European Solar Telescope
2003lmim.conf    Large Meteorite Impacts
1992lmip.conf    Large Meteorite Impacts and Planetary Evolution
1999lmip.conf    Large Meteorite Impacts and Planetary Evolution II
1998lsst.conf    Large Scale Structure:  Tracks and Traces
1989lssm.meet    Large Scale Structure and Motions in the Universe
1995lssu.conf    Large Scale Structure in the Universe
1987lssu.proc    Large Scale Structures in the Universe, Switzerland
1988lsso.conf    Large Scale Structures: Observations and Instrumentation
1974lstn.conf    Large Space Telescope - A New Tool for Science
1988lsmu.book    Large-Scale Motions in the Universe: A Vatican study Week
1999lssu.conf    Large-Scale Structure in the Universe
1984lssu.conf    Large-Scale Structure of the Universe
1988lssu.work    Large-Scale Structures in the Universe.  Observational and Analytical Methods
1978lase.work    Laser Workshop, Third International Workshop on Laser Ranging Instrumentation
1970lts..conf    Late-Type Stars
1971lts..conf    Late-Type Stars
1984laus.iafc    Lausanne International Astronautical Federation Congress
    llnl.rept    Lawrence Livermore National Lab. Report
1991ldef.conf    LDEF, 69 Months in Space: First Post-Retrieval Symposium
1964lawi.book    Lectures on Astrophysics and Weak Interactions
1965gere.book    Lectures on General Relativity
1965pft..book    Lectures on Particles and Field Theory
1964lsei.book    Lectures on Strong and Electromagnetic Interactions
1990lepu.conf    LEP and the Universe
1999lbnv.conf    Lepton and Baryon Number Violation in Particle Physics, Astrophysics and Cosmology
1983bist.conf    Les Etoiles Binaires Dans le Diagramme H.R
    LHSS.        Les Houches Summer School Conference
1967mdgs.conf    Les Methodes Dynamiques de Geodesie par Satellites
1967nmds.conf    Les Nouvelles M\x{00E9}thodes de la Dynamique Stellaire
1954pna..conf    Les Processus Nucl\x{00E9}aires dans les Astres
1996lqt..conf    The Lesson of Quantum Theory
2003lisa.conf    Library and Information Services in Astronomy IV (LISA IV)
1981litu.conf    Life in the Universe
1990leep.book    The Life of the Earth - Evolution of the Earth and the Planets
1979lssr.proc    Life Sciences and Space Research
1999lseb.conf    Life Sciences: Exobiology
1980lsis.conf    Light Scattering by Irregularly Shaped Particles
1966lil..conf    LIL Symposium on Research in Geosciences and Astronomy
1972lfpm.conf    Line Formation in the Presence of Magnetic Fields
1975lisb.iafc    Lisbon International Astronautical Federation Congress
1980ipcp.conf    LNP Vol. 112: Imaging Processes and Coherence in Physics
1982utep.conf    LNP Vol. 160: Unified Theories of Elementary Particles, Critical Assessment and Prospects
1982radc.conf    LNP Vol. 162: Relativistic Action at a Distance: Classical and Quantum Aspects
1983spfa.conf    LNP Vol. 184: Stochastic Processes Formalism and Applications
1984csss....3    LNP Vol. 193: Cool Stars, Stellar Systems, and the Sun
1984rdnt.conf    LNP Vol. 199: Recent Developments in Nonequilibrium Thermodynamics
1984abms.conf    LNP Vol. 202: Asymptotic Behavior of Mass and Spacetime Geometry
1984ssnq.conf    LNP Vol. 208: Supersymmetry and Supergravity Nonperturbative QCD
1984ggrp.conf    LNP Vol. 212: Gravitation, Geometry and Relativistic Physics
1985qm84.conf    LNP Vol. 221: Quark Matter '84
1985sndi.work    LNP Vol. 224: Supernovae as Distance Indicators
1985hrsp.proc    LNP Vol. 233: High Resolution in Solar Physics
1985amen.conf    LNP Vol. 236: Advanced Methods in the Evaluation of Nuclear Scattering Data
1985nmc..proc    LNP Vol. 237: Nearby Molecular Clouds
1985gaee.conf    LNP Vol. 239: Geometric Aspects of the Einstein Equations and Integrable Systems
1985mcma.conf    LNP Vol. 240: Monte-Carlo Methods and Applications in Neutronics, Photonics, and Statistical Physics
1986ftqg.conf    LNP Vol. 246: Field Theory, Quantum Gravity and Strings
1986lmo..conf    LNP Vol. 250: Lie Methods in Optics
1986lgmn.conf    LNP Vol. 252: Local and Global Methods of Nonlinear Dynamics
1986csss....4    LNP Vol. 254: Cool Stars, Stellar Systems and the Sun
1986dwpm.conf    LNP Vol. 256: Dynamics of Wave Packets in Molecular and Nuclear Physics
1986paco.conf    LNP Vol. 266: The Physics of Accretion onto Compact Objects
1986ussd.conf    LNP Vol. 267: The Use of Supercomputers in Stellar Dynamics
1987stpu.conf    LNP Vol. 274: Stellar Pulsation
1987pps..conf    LNP Vol. 278: The Physics of Phase Space, Nonlinear Dynamics and Chaos, Geometric Quantization, and Wigner Function
1998nuas.conf    LNP Vol. 287: Proceedings of the 9th workshop on Nuclear Astrophysics
1987csss....5    LNP Vol. 291: Cool Stars, Stellar Systems and the Sun
1987ssp..conf    LNP Vol. 292: Solar and Stellar Physics
1988heia.conf    LNP Vol. 294: High-Energy Ion-Atom Collisions
1988ctc..conf    LNP Vol. 297: Comets to Cosmology
1988adse.book    LNP Vol. 305: Atmospheric Diagnostics of Stellar Evolution
1988ouga.conf    LNP Vol. 306: The Outer Galaxy
1988agn..conf    LNP Vol. 307: Active Galactic Nuclei
1988aan..conf    LNP Vol. 309: Atmospheric Aerosol and Nucleation
1974trph.conf    LNP Vol. 31: Transport Phenomena
1988lssu.work    LNP Vol. 310: Large-scale structures in the universe
1988mcmw.conf    LNP Vol. 315: Molecular Clouds, MilkY-Way and External Galaxies
1988sstb.conf    LNP Vol. 316: Supernova Shells and Their Birth Events
1989reso.conf    LNP Vol. 325: Resonances
1989hser.work    LNP Vol 327: Hot Spots in Extragalactic Radio Sources
1989whdw.coll    LNP Vol. 328: IAU Colloq. 114: White Dwarfs
1989kbsa.book    LNP Vol. 329: Knowledge Based Systems in Astronomy
1989grle.conf    LNP Vol. 330: Gravitational Lenses
1989pcim.symp    LNP Vol. 331: The Physics and Chemistry of Interstellar Molecular Clouds - mm and Sub-mm Observations in Astrophysics
1989moco.proc    LNP Vol. 332: Morphological Cosmology
1989egao.conf    LNP Vol. 333: Evolution of Galaxies: Astronomical Observations
1989blo..conf    LNP Vol. 334: BL Lac Objects
1989ies..conf    LNP Vol. 341: Infrared Extinction and Standardization
1989sdim.conf    LNP Vol. 350: IAU Colloq. 120: Structure and Dynamics of the Interstellar Medium
1990aeas.conf    LNP Vol. 356: Accuracy of Element Abundances from Stellar Atmospheres
1990grle.conf    LNP Vol. 360: Gravitational Lensing
1990lfas.work    LNP Vol. 362: Low Frequency Astrophysics from Space
1990doqp.coll    LNP Vol: 363: IAU Colloq. 117: Dynamics of Quiescent Prominences
1990rmsi.conf    LNP Vol. 366: Rotation and Mixing in Stellar Interiors
1990psss.conf    LNP Vol. 367: Progress of Seismology of the Sun and Stars
1991lsse.conf    LNP Vol. 373: Late Stages of Stellar Evolution.  Computational Methods in Astrophysical Hydrodynamics
1991vag..conf    LNP Vol. 377: Variability of Active Galaxies
1991sacs.coll    LNP Vol. 380: IAU Colloq. 130: The Sun and Cool Stars. Activity, Magnetism, Dynamos
1991ildx.conf    LNP Vol. 385: Iron Line Diagnostics in X-ray Sources
1991fpsa.conf    LNP Vol. 387: Flare Physics in Solar Activity Maximum 22
1991ctsm.conf    LNP Vol. 388: Challenges to Theories of the Structure of Moderate-Mass Stars
1991rhcc.conf    LNP Vol. 391: Relativistic Hadrons in Cosmic Compact Objects
1992sils.conf    LNP Vol. 397: Surface Inhomogeneities on Late-Type Stars
1992esf..coll    LNP Vol. 399: IAU Colloq. 133: Eruptive Solar Flares
1992aets.conf    LNP Vol. 401: The Atmospheres of Early-Type Stars
1992grle.conf    LNP Vol. 406: Gravitational Lenses
1992amds.conf    LNP Vol. 407: Atomic and Molecular Data for Space Astronomy
1992niiu.conf    LNP Vol. 408: New Insights into the Universe
1992rgr..conf    LNP Vol. 410: Relativistic Gravity Research
1993asma.conf    LNP Vol. 412: Astrophysical Masers
1993cag..conf    LNP Vol. 413: Central Activity in Galaxies. From Observational Data to Astrophysical Diagnostics
1993namc.meet    LNP Vol. 416: New Aspects of Magellanic Cloud Research
1993ghea.conf    LNP Vol. 418: Galactic High-Energy Astrophysics. High-Accuracy Timing and Positional Astronomy
1975hrrt.conf    LNP Vol. 42: H II regions and related topics
1993jers.conf    LNP Vol. 421: Jets in Extragalactic Radio Sources
1993rorp.conf    LNP Vol. 423: Rotating Objects and Relativistic Physics
1994mse..conf    LNP Vol. 428: IAU Colloq. 146: Molecules in the Stellar Environment
1994pfcm.conf    LNP Vol. 429: Present and Future of the Cosmic Microwave Background
1975lasp.conf    LNP Vol. 43: Laser Spectroscopy
1994ecsd.conf    LNP Vol. 430: Ergodic Concepts in Stellar Dynamics
1994dpet.conf    LNP Vol. 438: Diffusion Processes: Experiment, Theory, Simulations
1994scmc.conf    LNP Vol. 439: The Structure and Content of Molecular Clouds
1994muec.conf    LNP Vol. 440: Matter Under Extreme Conditions
1995whdw.conf    LNP Vol. 443: White Dwarfs
1995cmer.conf    LNP Vol. 444: Coronal Magnetic Energy Releases
1995flfl.conf    LNP Vol. 454: IAU Colloq. 151: Flares and Flashes
1995bufp.conf    LNP Vol. 455: Birth of the Universe and Fundamental Physics
1995ppa..conf    LNP Vol. 458: Particle Physics and Astrophysics
1995pcim.symp    LNP Vol. 459: The Physics and Chemistry of Interstellar Molecular Clouds
1996gseg.conf    LNP Vol. 460: Global Structure and Evolution in General Relativity
1995ssst.conf    LNP Vol. 462: Small-Scale Structures in Three-Dimensional Hydrodynamic and Magnetohydrodynamic Turbulence
1995gyu..conf    LNP Vol. 463: Galaxies in the Young Universe
1996mful.conf    LNP Vol. 464: Materials and Fluids Under Low Gravity
1996doay.conf    LNP Vol. 465: Disks and Outflows Around Young Stars
1996plas.conf    LNP Vol. 468: Plasma Astrophysics
1996uhlz.conf    LNP Vol. 470: The Universe at High-z, Large-Scale Structure and the Cosmic Microwave Background
1996jsgn.conf    LNP Vol. 471: Jets from Stars and Galactic Nuclei
1996sxrs.conf    LNP Vol. 472: Supersoft X-Ray Sources
1997pbs..conf    LNP Vol. 480: Physics of Biological Systems: From Molecules to Species
1997cnsm.conf    LNP Vol. 482: Contemporary Nuclear Shell Models
1997cprs.conf    LNP Vol. 483: Coronal Physics from Radio and Space Observations
1997adna.conf    LNP Vol. 487: Accretion Disks - New Aspects
1997shpp.conf    LNP Vol. 489: European Meeting on Solar Physics
1997ins..conf    LNP Vol. 495: Integrability of Nonlinear Systems
1997sato.conf    LNP Vol. 497: Stellar Atmospheres: Theory and Observations
1997apmm.conf    LNP Vol. 499: Atomic Physics Methods in Modern Research
1998plnm.conf    LNP Vol. 503: A Perspective Look at Nonlinear Media from Physics to Biology and Social Sciences
1998irca.conf    LNP Vol. 504: Irreversibility and Causality
1998imea.conf    LNP Vol. 505: Impacts on Earth
1998lbb..coll    LNP Vol. 506: IAU Colloq. 166: The Local Bubble and Beyond
1998sspt.conf    LNP Vol. 507: Space Solar Physics: Theoretical and Observational Issues in the Context of the SOHO Mission
1998sqft.conf    LNP Vol. 509: Supersymmetry and Quantum Field Theory
1998cknd.conf    LNP Vol. 511: Chaos, Kinetics and Nonlinear Dynamics in Fluids and Plasmas
1998bhto.conf    LNP Vol. 514: Black Holes: Theory and Observation
1999hdmh.conf    LNP Vol. 516: Hadrons in Dense Matter and Hadrosynthesis
1999qffv.conf    LNP Vol. 517: Quantum Future: From Volta and Como to the Present and Beyond
1999dspg.conf    LNP Vol. 518: Dynamical Systems, Plasmas and Gravitation
1999xrsa.conf    LNP Vol. 520: X-Ray Spectroscopy in Astrophysics
1999sann.conf    LNP Vol. 522: Scientific Applications of Neural Nets
1999vnss.coll    LNP Vol. 523: IAU Colloq. 169: Variable and Non-spherical Stellar Winds in Luminous Hot Stars
1999dmr..conf    LNP Vol. 528: Density-Matrix Renormalization, a New Numerical Method in Physics
1999rgm87conf    LNP Vol. 530: The Radio Galaxy Messier 87
2000lsm..conf    LNP Vol. 534: Light Scattering from Microstructure
2000espp.conf    LNP Vol. 535: Electronic Structure and Physical Properties of Solids. The Use of the LMTO Method
1999nmwt.conf    LNP Vol. 536: Nonlinear MHD Waves and Turbulence
2000mqar.conf    LNP Vol. 537: Mathematical and Quantum Aspects of Relativity and Cosmology
2000dtec.conf    LNP Vol. 538: Decoherence: Theoretical, Experimental, and Conceptual Problems
2000tpfs.conf    LNP Vol. 539: Theoretical Physics Fin de Si\x{00E8}cle
2000efe..conf    LNP Vol. 540: Einstein's Field Equations and Their Physical Implications
2000tqg..conf    LNP Vol. 541: Toward Quantum Gravity
2000nsdt.conf    LNP Vol. 542: Nonlinear Science at the Dawn of the 21st Century
2000gqp..conf    LNP Vol. 543: Geometry and Quantum Physics
2000ldsi.conf    LNP Vol. 544: Low-Dimensional Systems. Interactions and Transport Properties
2000ndht.conf    LNP Vol. 545: New Developments in High Temperature Superconductivity
2000nthp.conf    LNP Vol. 546: New Trends in Hera Physics 1999
2000sdam.conf    LNP Vol. 547: Statistical and Dynamical Aspects of Mesoscopic Systems
2000isdu.conf    LNP Vol. 548: ISO Survey of a Dusty Universe
2000prf..conf    LNP Vol. 549: Physics of Rotating Fluids
2000noar.conf    LNP Vol. 550: Noise, Oscillators and Algebraic Randomness. From Noise in Communication Systems to Number Theory
2000imsa.conf    LNP Vol. 551: Impacts in Mechanical Systems. Analysis and Modelling
2000ntmf.conf    LNP Vol. 552: Numerical Treatment of Multiphase Flows in Porous Media
2000tech.conf    LNP Vol. 553: Transport and Energy Conversion in the Heliosphere
2000spss.conf    LNP Vol. 554: Statistical Physics and Spatial Statistics. The Art of Analyzing and Modeling Spatial Structures and Pattern Formation
2000vsd..conf    LNP Vol. 555: Vortex Structure and DynamicsLNP Vol. 555: Vortex Structure and Dynamics
2000stga.conf    LNP Vol. 556: From the Sun to the Great Attractor
2000sppc.conf    LNP Vol. 557: Stochastic Processes in Physics, Chemistry, and Biology
2000qft..conf    LNP Vol. 558: Quantum Field Theory
2000rqmd.conf    LNP Vol. 559: Relativistic Quantum Measurement and Decoherence
2001nsma.conf    LNP Vol. 560: Nonextensive Statistical Mechanics and Its Application
2001dqo..conf    LNP Vol: 561: Directions in Quantum Optics
2001gcit.conf    LNP Vol. 562: Gyros, Clocks, Interferometers ...: Testing Relativistic Gravity in Space
2001bist.conf    LNP Vol. 563: Binary Stars: Selected Topics on Observations and Physical Processes
2001grga.conf    LNP Vol. 564: Granular Gases
2001msr..conf    LNP Vol. 565: Magnetism and Synchrotron Radiation
2001fmed.conf    LNP Vol. 566: Fluid Mechanics and the Environment: Dynamical Approaches
2001cscs.conf    LNP Vol. 567: Coherent Structures in Complex Systems
2001cdmc.conf    LNP Vol. 568: Continuous and Discontinuous Modelling of Cohesive-Frictional Materials
2001spel.conf    LNP Vol. 569: Spin Electronics
2001happ.conf    LNP Vol. 570: The Hydrogen Atom: Precision Physics of Simple Atomic Systems
2001qvds.conf    LNP Vol. 571: Quantized Vortex Dynamics and Superfluid Turbulence
2001mequ.conf    LNP Vol. 572: Methods of Quantization
2001astr.conf    LNP Vol. 573: Astrotomography, Indirect Imaging Methods in Observational Astronomy
2001chph.conf    LNP Vol. 574: Chance in Physics
2001mcqo.conf    LNP Vol. 575: Modern Challenges in Quantum Optics
2001pauh.conf    LNP Vol. 576: Physics and Astrophysics of Ultra-High-Energy Cosmic Rays
2001sesp.conf    LNP Vol. 577: Solar and extra-solar planetary systems
2001pnsi.conf    LNP Vol. 578: Physics of Neutron Star Interiors
2001ien..conf    LNP Vol. 579: Interacting Electrons in Nanostructures
2001bfgs.conf    LNP Vol. 580: Band-Ferromagnetism. Ground-State and Finite-Temperature Phenomena
2001aacm.conf    LNP Vol. 581: An Advanced Course in Modern Nuclear Physics
2001gfm..conf    LNP Vol. 582: Geomorphological Fluid Mechanics
2002lqm..conf    LNP Vol. 583: Lectures on Quark Matter
2002tnpf.conf    LNP Vol. 584: Thermal Nonequilibrium Phenomena in Fluid Mixtures
2002besp.conf    LNP Vol. 585: Biological Evolution and Statistical Physics
2002sfi..conf    LNP Vol. 586: Sound-Flow Interactions
2002qcdq.conf    LNP Vol. 587: Qubits, Cbits, Decoherence, Quantum Measurement and Environment
2002nsas.conf    LNP Vol. 588: Nanoscale Spectroscopy and Its Applications to Semiconductor Research
2002rfa..conf    LNP Vol. 589: Relativistic Flows in Astrophysics
2002sgs..conf    LNP Vol. 590: Singularities in Gravitational Systems
2002cvpn.conf    LNP Vol. 591: CP Violation in Particle, Nuclear, and Astrophysics
2002cocr.conf    LNP Vol. 592: Cosmological Crossroads
2002nmma.conf    LNP Vol. 593: Nanostructured Magnetic Materials and Their Applications
2002fmcf.conf    LNP Vol. 594: Ferrofluids: Magnetically Controllable Fluids and Their Applications
2002hmf..conf    LNP Vol. 595: High Magnetic Fields
2002ngsm.conf    LNP Vol. 596: Noncommutative Geometry and the Standard Model of Elementary Particle Physics
2002dydi.conf    LNP Vol. 597: Dynamics of Dissipation
2002sgrb.conf    LNP Vol. 598: Supernovae and Gamma-Ray Bursters
2003sgrb.conf    LNP Vol. 598: Supernovae and Gamma-Ray Bursters
2003sssi.conf    LNP Vol. 599: The Sun's Surface and Subsurface: Investigating Shape
2002mcm..conf    LNP Vol. 600: Morphology of Condensed Matter
2002nses.conf    LNP Vol. 601: Neutron Spin Echo Spectroscopy: Basics, Trends and Applications
2002dtsl.conf    LNP Vol. 602: Dynamics and Thermodynamics of Systems with Long-Range Interactions
2002rrcm.conf    LNP Vol. 603: Ruthenate and Rutheno-Cuprate Materials
2002csst.conf    LNP Vol. 604: The Conformal Structure of Space-Time
2002btsm.conf    LNP Vol. 605: Bridging the Time Scales:  Molecular Simulations for the Next Decade
2002pcoc.conf    LNP Vol. 606: Polymer Crystallization: Obervations, Concepts and Interpretations
2003ears.conf    LNP Vol. 607: Exploring the Atmosphere by Remote Sensing Techniques
2002glat.conf    LNP Vol. 608: Gravitational Lensing: An Astrophysical Tool
2003asmi.conf    LNP Vol. 609: Astromineralogy
2003psxr.conf    LNP Vol. 610: Particle Scattering, X-Ray Diffraction, and Microstructure of Solids and Liquids
2002cene.conf    LNP Vol. 611: Coherent Evolution in Noisy Environments
2003ecpa.conf    LNP Vol. 612: Energy Conversion and Particle Acceleration in the Solar Corona
2003opso.conf    LNP Vol. 613: Optical Solitons
2003tmfa.conf    LNP Vol. 614: Turbulence and Magnetic Fields in Astrophysics
2003sps..book    LNP Vol. 615: Space Plasma Simulation
2003ppnm.conf    LNP Vol. 616: Particle Physics in the New Millennium
2003ctra.conf    LNP Vol. 617: Current Trends in Relativistic Astrophysics
2003maqm.conf    LNP Vol. 618: The Mathematical Aspects of Quantum Maps
2003lsp..conf    LNP Vol. 619: Lectures on Solar Physics
2003pdft.conf    LNP Vol. 620: A Primer in Density Functional Theory
2003plrc.conf    LNP Vol. 621: Processes with Long-Range Correlations
2003iqd..conf    LNP Vol. 622: Irreversible Quantum Dynamics
2003ucd..conf    LNP Vol. 623: Understanding Calcium Dynamics
2003ggd..conf    LNP Vol. 624: Granular Gas Dynamics
2003smcn.conf    LNP Vol. 625: Statistical Mechanics of Complex Networks
2003gach.conf    LNP Vol. 626: Galaxies and Chaos
2003ppsa.conf    LNP Vol. 627: Precision Physics of Simple Atomic Systems
2003ifdt.conf    LNP Vol. 628: Interfacial Fluid Dynamics and Transport Processes
2003alrd.conf    LNP Vol. 630: Anderson Localization and Its Ramifications: Disorder, Phase Coherence and Electron Correlations
2003qgte.conf    LNP Vol. 631: Quantum Gravity: From Theory to Experimental Search
2003dimn.conf    LNP Vol. 632: Direct and Inverse Methods in Nonlinear Evolution Equations
2003decs.conf    LNP Vol. 633: Decoherence and Entropy in Complex Systems
2004misi.conf    LNP Vol. 634: Molecules in Interaction with Surfaces and Interfaces
2003sced.conf    LNP Vol. 635: Stellar Candles for the Extragalactic Distance Scale
2003klp..conf    LNP Vol. 636: The Kolmogorov Legacy in Physics
2004rrbp.conf    LNP Vol. 637: Rubber and Rubber Balloons: Paradigms of Thermodynamics
2004ins..conf    LNP Vol. 638: Integrability of Nonlinear Systems
2004dsmc.conf    LNP Vol. 639: Dual Superconductor Models of Color Confinement
2004nmsm.conf    LNP Vol. 640: Novel Methods in Soft Matter Simulations
2004edfn.conf    LNP Vol. 641: Extended Density Functionals in Nuclear Structure Physics
1994lgcg.conf    The Local Group: Comparative and Global Properties
1984lism.rept    Local Interstellar Medium
    lock.rept    Lockheed Missiles and Space Co. Report
    ldef.symp    Long Duration Exposure Facility
1998lrca.conf    Long-Range Correlations in Astrophysical Systems.
1983ltpd.conf    Long-Time Prediction in Dynamics
1976ltpd.proc    Long-time Predictions in Dynamics
1999ldss.work    Looking Deep in the Southern Sky
    lubr.rept    Louisiana State Univ., Baton Rouge Report
1986lect.conf    Low Energy Collision Theory Techniques for Atomic Excititation and Radiative Data
1982lfve.conf    Low Frequency Variability Extragalactic Radio Sources
1989lmsf.conf    Low Mass Star Formation and Pre-main Sequence Objects
1992lmsf.book    Low Mass Star Formation in Southern Molecular Clouds
1987ltdn.conf    Low Temperature Detectors for Neutrinos and Dark Matter
1988ltdn.conf    Low temperature detectors for Neutrinos and Dark Matter II
1990ltdn.conf    Low Temperature Detectors for Neutrinos and Dark Matter III
1992ltdn.conf    Low Temperature Detectors for Neutrinos and Dark Matter IV
1986lasf.symp    The Lower Atmosphere of Solar Flares; Proceedings of the Solar Maximum Mission Symposium
1969lls..symp    Low-Luminosity Stars
1997mtsr.work    LPI Technical Report No. 97-01: Mars 2005 Sample Return Workshop
1992lpem.rept    Lunar and Planetary Exploration Mission
    lpi..rept    Lunar and Planetary Inst. Technical Report
    LPI..        Lunar and Planetary Institute Conference Abstracts
    LPITR        Lunar and Planetary Institute Technical Report
    LPSC.        Lunar and Planetary Science Conference
1989lbag.rept    Lunar Base Agriculture: Soils for Plant Growth
1985lbsa.conf    Lunar Bases and Space Activities of the 21st Century
1992lbsa.conf    Lunar Bases and Space Activities of the 21st Century II
1988lhfp.rept    Lunar Helium-3 and Fusion Power
1979lhls.book    Lunar Highland Soil
1980luhc.conf    Lunar Highlands Crust
1992lmt..symp    Lunar Materials Technology
1992loui.rept    A Lunar Optical-Ultraviolet-Infrared Synthesis Array (LOUISA)
1975lspa.book    Lunar science: A post-Apollo view
1974lssf.book    Lunar Soil from the Sea of Fertility
1980lsmc.book    Lunar Soil from Mare Crisium
1997lbal.conf    A Lunar-Based Analytical Laboratory
1992lbca.book    A Lunar-Based Chemical Analysis Laboratory
1995mpfn.conf    Mach's Principle: From Newton's Bucket to Quantum Gravity
1965macl.conf    Magellanic Clouds
1998mcod.conf    The Magellanic Clouds and Other Dwarf Galaxies
1972mwm..book    Magic Without Magic: John Archibald Wheeler
1967mrs..conf    Magnetic and Related Stars
1983mvs..conf    Magnetic and Variable Stars
    mfeo.conf    Magnetic Fields and Extragalactic Objects
1991mfeo.conf    Magnetic Fields and Extragalactic Objects
1986mrt..conf    Magnetic Reconnection and Turbulence
1988mast.conf    Magnetic Stars
1997mast.book    Magnetic Storms, Geophysical Monograph Series, Vol. 98
2004mim..proc    The Magnetized Interstellar Medium
1959mcf..book    The Magnetodynamics of Conducting Fluids
1980mhda.conf    Magnetohydrodynamic Aspects / Corona
1963mhd..conf    Magnetohydrodynamics
1976mgpa.proc    Magnetospheric Particles and Fields
1974mgph.proc    Magnetospheric Physics
1987magp.book    Magnetotail Physics
    kiev.rept    Main Astronomical Observatory Kiev, Ukraine Report
1989mala.iafc    Malaga International Astronautical Federation Congress
1975maco.book    Man and Cosmos: Nine Guggenheim Lectures on the Solar System
1986mmm..work    Manned Mars Mission
1978mit..conf    Man's Impact on the Troposphere: Lectures in Tropospheric Chemistry
1999mfs..conf    The many faces of the sun: a summary of the results from NASA's Solar Maximum Mission.
1963mbp..conf    The Many-Body Problem
1966mbt..book    Many-Body Theory
1978mmm..book    Mapping of the Moon and Mars
1982mgm..conf    Marcel Grossmann Meeting: General Relativity
1978mcvl.conf    Mare Crisium: The view from Luna 24
1991mvbp.work    Mare Volcanism and Basalt Petrogenesis: Astoundi ng Fundamental Concepts
1979mars.conf    Mars
1992mars.book    Mars
    mevt.rept    Mars: Evolution of Volcanism, Tectonics, and Volatiles
1990mgnm.proc    Mars Global Network Mission Workshop
1992mppf.proc    Mars: Past, Present, and Future
1993mppf.proc    Mars: Past, Present, and Future. Results from the MSATT Program
1994mpls.work    Mars Pathfinder Landing Site Workshop
1995mpls.work    Mars Pathfinder Landing Site Workshop II: Characteristics
1978mrat.meet    The Mars Reference Atmosphere
1988msrs.work    Mars Sample Return Science
1997mto..work    Mars Telescopic Observations Workshop II
1979msfc.symp    Marshall Space Flight Center HEAO Science Symposium
1998mmws.work    Martian Meteorites: Where do we Stand and Where are we Going?  Abstracts from a workshop
1992msat.work    Martian Surface and Atmosphere Through Time
    mmc..rept    Martin Marietta Corp. Report
    umd..rept    Maryland Univ. College Park Report
1986mmmo.conf    Masers, Molecules, and Mass Outflows in Star Formation Regions
1982mlao.conf    Mass Loss from Astronomical Objects
1993mlab.conf    Mass Loss on the AGB and Beyond
1968mmsf.conf    Mass Motions in Solar Flares and Related Phenomena
1988tmot.work    Mass of the Galaxy
2003mglh.conf    The Mass of Galaxies at Low and High Redshift
    mit..rept    Massachusetts Inst. of Tech. Report
    umassrept    Massachusetts Univ. Report
1986mnia.conf    Massive Neutrinos in Astrophysics
1984mnap.conf    Massive Neutrinos in Astrophysics and in Particle Physics
1994mtia.conf    Mass-Transfer Induced Activity in Galaxies
    MMPhy        Masters of Modern Physics
1987mcu..conf    Material Content of the Universe
1986mntp.conf    Mathematical and Numerical Techniques in Physical Geodesy
    MAGeo        Mathematical Approaces to Geophysics Series
2000mmp..conf    Mathematical Methods in Physics
1999mrqm.conf    Mathematical Results in Quantum Mechanics
2002madm.conf    Matter, Antimatter and Dark Matter
1991max..conf    Max '91/SMM Solar Flares: Observations and Theory
1998mebm.conf    Maximum Entropy and Bayesian Methods
1985svmf.nasa    Measurements of Solar Vector Magnetic Fields
1999mstu.conf    Measuring the Size of Things in the Universe:  HBT Interferometry and Heavy Ion Physics
2004mmu..symp    Measuring and Modeling the Universe
1987meca.symp    MECA Symposium on Mars: Evolution of its Climate and Atmosphere
1989ahoe.work    MECA Workshop on Atmospheric H2O Observations of Earth and Mars.  Physical Processes, Measurements and Interpretations
1975sshm.meet    Meeting on Space Shuttle Missions of the 80's
1988merc.book    Mercury, University of Arizona Press
1967mod..conf    Meteor Orbits and Dust
1977mecr.book    Meteorite Craters, Benchmark Papers in Geology
1979msps.book    Meteorite Structures on Planetary Surfaces
1988mess.book    Meteorites and the Early Solar System
1993mtpb.conf    Meteoroids and their Parent Bodies
1963mair.conf    Meteorological and Astronomical Influences on Radio Wave Propogation
2004mgfd.book    Meteorological and Geophysical Fluid Dynamics
1968miua.conf    Meteorological Investigations of the Upper Atmosphere
2002memi.conf    Meteorology and the Millennium
1982mmsa.rept    Meteors and Meteor Spectra Analysis
1999md98.conf    Meteroids 1998
1991mcmp.conf    Methods in Computational Molecular Physics
1975mcpr...14    Methods in Computational Physics. Volume 14 - Radio astronomy
1984mrt..book    Methods in Radiative Transfer
1974msai.conf    Methods in Stellar Atmosphere and Interplanetary Plasma Research
1980mads.conf    Methods of Abundance Determination for Stars
1973mivs.book    Methods of Investigating Variable Stars
1968mowd.conf    Methods of Obtaining Winds and Densities From Radar Meteor Trail Returns
1960mera.conf    Metrology of Radionuclides
1987ncsu.work    MEVTV Workshop on the Nature and Composition of Surface Units on Mars
    muaa.rept    Michigan Univ. Final Report
1983mca..symp    Microcomputers in Astronomy
1987mfm..symp    Microgravity Fluid Management Symposium
2000mfss.conf    Micropropulsion for Small Spacecraft
1997mba..proc    Microwave Background Anistropies
2000mfia.conf    Mid- and Far-Infrared Astronomy and Future Space Missions
1990mav..book    Middle Atmosphere of Venus
1984maph...14    Middle Atmosphere Program. Handbook for MAP. Volume 14
1985maph...18    Middle Atmosphere Program. Handbook for MAP. Volume 18
1986maph...19    Middle Atmosphere Program. Handbook for MAP, volume 19
1981maph....2    Middle Atmosphere Program. Handbook for MAP, volume 2
1986maph...20    Middle Atmosphere Program. Handbook for MAP, volume 20
1989maph...27    Middle Atmosphere Program. Handbook for MAP, volume 27
1989maph...28    Middle Atmosphere Program. Handbook for MAP, volume 28
1989maph...29    Middle Atmosphere Program. Handbook for MAP, volume 29
1989maph...30    Middle Atmosphere Program. Handbook for MAP. Volume 30
1989maph...31    Middle Atmosphere Program. Handbook for MAP. Volume 31
1983maph....9    Middle Atmosphere Program. Handbook for MAP, volume 9
1987maph...25    Middle Atmosphere Program, Volume 25
2001mkt..book    Mikl\x{00F3}s Konkoly Thege (1842-1916). 100 Years of Observational Astronomy and Astrophysics
1984mcur.conf    Milankovitch and Climate: Understanding the Response to Astronomical Forcing
1997msma.conf    Millimeter and Submillimeter Astronomy at 10 Milli-arcseconds Resolution
1985mswr.symp    Millimeter and Submillimeter Wave Radio Astronomy
1997mvlb.work    Millimeter-VLBI Science Workshop
1988msma.meet    Millimetre and Submillimetre Astronomy
2001misk.conf    Mining the Sky
2000mbos.work    Minor Bodies in the Outer Solar System
1956mgps.conf    Miscelanea Geofisica Publicada Pelo Servico Meteorologico de Angola em Comemoracao do X Aniversario do Servico Meteorologico Nacional
1998mdis.conf    Mission Design and Implementation of Satellite Constellations
1993dpmv.book    Missions, Technologies, and Design of Planetary Mobile Vehicles
1984mpsc.conf    The MK Process and Stellar Classification
1985SAOSR.385    The MMT and the Future of Ground-Based Astronomy
1986mone.work    Model Nebulae
1992mja..rept    Modeling the Jovian Aurora
1989mse..proc    Modeling the Stellar Environment: How and Why?
1975maco.nasa    Modern Achievements of Cosmonautics
1991masp.conf    Modern Analysis of Scattering Phenomena
1999maa..conf    Modern Astrometry and Astrodynamics
1967mamt.book    Modern astrophysics. A memorial to Otto Struve
2002moco.conf    Modern Cosmology
1990mcr..book    Modern Cosmology in Retrospect
1990mmcm.conf    Modern Methods in Celestial Mechanics
1981motc.conf    Modern Observational Techniques for Comets
1967moop.conf    Modern Optics
1998mpse.conf    Modern Problems in Stellar Evolution
1978mtap.conf    Modern Techniques in Astronomical Photography
1990mtia.book    Modern Technology and its Influence on Astronomy.
1990moas.book    Molecular Astrophysics
1998masg.conf    The Molecular Astrophysics of Stars and Galaxies
1991mocl.conf    Molecular Clouds
1995mcsf.conf    Molecular Clouds and Star Formation
2001mhs..conf    Molecular Hydrogen in Space
1973mge..conf    Molecules in the Galactic Environment
1982miis.conf    Molecules in Interstellar Space
2000msl..work    Molecules in Space and in the Laboratory
    MPhy.        Monographs in Physique
1991mont.iafc    Montreal International Astronautical Federation Congress
1967mopl.conf    Moon and Planets
1968mopl.book    Moon and Planets II
1963mmc..book    The Moon Meteorites and Comets
1999mthe.conf    More Things in Heaven and Earth : A Celebration of Physics at the Millennium
1972mqdi.conf    Morphology of the Quiet and Disturbed Ionosphere
1999mdrg.conf    The Most Distant Radio Galaxies
    mms..conf    The Most Massive Stars
1981mms..conf    The Most Massive Stars
1983mpna.conf    The Motion of Planets and Natural and Artifical Satellites
1983pnas.conf    The Motion of Planets and Natural and Artificial Satellites
1992chwe.work    MSATT Workshop on Chemical Weathering on Mars
1987mtst.rept    The M-Type Stars
1983vlba.conf    Multidisciplinary Use of the Very Long Baseline Array
1985mbga.conf    Multifrequency Behaviour of Galactic Accreting Sources
1988msp..conf    Multimode Stellar Pulsations
2000mudy.conf    Multiparticle Dynamics
2003mudy.conf    Multiparticle Dynamics
1981mrbf.conf    Multi-ring basins: Formation and Evolution
1988mwa..work    Multiwavelength Astrophysics
2002mwoc.conf    Multi-Wavelength Observations of Coronal Structure and Dynamics
2001mwoc.conf    Multi-Wavelength Observations of Coronal Structure and Dynamics -- Yohkoh 10th Anniversary Meeting
1979muni.iafc    Munich International Astronautical Federation Congress
    NACAA        NACA Advance Confidential Report
    NACAC        NACA Confidential Report
    NACRA        NACA Research Memorandum A Series
    NACRE        NACA Research Memorandum E Series
    NACRL        NACA Research Memorandum L Series
    NACRB        NACA Restricted Bulletin
    NACRM        NACA Restricted Memorandum
    NACAM        NACA Technical Memorandum
    NACAN        NACA Technical Notes
    NACAR        NACA Technical Report
    NACWA        NACA Wartime Report A Series
    NACWE        NACA Wartime Report E Series
    NACWL        NACA Wartime Report L Series
1981nuri...28    Nagoya University Research Institute of Atmospherics Proceedings, vol. 28
1982nuri...29    Nagoya University Research Institute of Atmospherics Proceedings, vol. 29
1987nuri...34    Nagoya University Research Institute of Atmospherics Proceedings, vol. 34
    ASIB.        NASA Advanced Science Institutes (ASI) Series B
    ASIC.        NASA Advanced Science Institutes (ASI) Series C
    ames.rept    NASA Ames Research Center Technical Report
    nasa..crs    NASA Contractor Report Series
1961gsfc.rept    NASA Goddard Space Flight Center Technical Report
2002nla..work    NASA Laboratory Astrophysics Workshop
1997lrc..rept    NASA Langley Research Center Report
1988mars.conf    The NASA Mars Conference
    msfc.rept    NASA Marshall Space Flight Center Report
    nmso.rept    NASA Marshall Space Flight Center Solar Observatory Report
1988voma.meet    NASA MEVTV Program Working Group Meeting: Volcanism on Mars
    pata.rept    NASA Patent Application
1982plap.nasa    NASA Planetary Atmospheres Program
    plas.rept    NASA Reports of Planetary Astronomy
    nasa..sps    NASA Special Publication Series
    nasa..tms    NASA Technical Memorandum Series
    asee.nasa    NASA/ASEE Summer Faculty Fellowship Program
    nasa.rept    National Aeronautics and Space Administration Report
    ngdc.rept    National Geophysical Data Center Comprehensive Reports
1984nntt.rept    National New Technology Telescope
    ntis.rept    National Technical Information Service Report
1977naa..conf    Native American Astronomy
1983fpea.conf    NATO ASIB Proc. 103: Fundamental Processes in Energetic Atomic Collisions
2003whdw.conf    NATO ASIB Proc. 105: White Dwarfs
1985rcmd.conf    NATO ASIB Proc. 118: Regular and Chaotic Motions in Dynamic Systems
1985cbqs.conf    NATO ASIB Proc. 120: Chaotic Behavior in Quantum Systems: Theory and Applications
1986hic..conf    NATO ASIB Proc. 130: Heavy Ion Collisions
1985fpac.conf    NATO ASIB Proc. 134: Fundamental Processes in Atomic Collision Physics
1986tpgs.conf    NATO ASIB Proc. 138: Topological Structure of Space-Time
1986aus..conf    NATO ASIB Proc. 143: Atoms in Unusual Situations
1986apei.conf    NATO ASIB Proc. 145: Atomic Processes in Electron-Ion and Ion-Ion Collisions
1987gram.conf    NATO ASIB Proc. 151: Giant Resonances in Atoms, Molecules, and Solids
1987psf..conf    NATO ASIB Proc. 153: Physics of Strong Fields
1987scpp.conf    NATO ASIB Proc. 154: Strongly Coupled Plasma Physics
1987pcsc.conf    NATO ASIB Proc. 158: Physics and Chemistry of Small Clusters
1987tche.conf    NATO ASIB Proc. 164: Techinques and Concepts of High-Energy Physics IV
1988fpad.conf    NATO ASIB Proc. 181: Fundamental Processes of Atomic Dynamics
1989smsv.conf    NATO ASIB Proc. 186: Simple Molecular Systems at Very High Density
1988xsas.conf    NATO ASIB Proc. 187: X-ray Spectroscopy in Atomic and Solid State Physics
1989nmhi.conf    NATO ASIB Proc. 205: Nuclear Matter and Heavy Ion Collisions
1989nand.conf    NATO ASIB Proc. 209: New Aspects of Nuclear Dynamics
1989nesa.conf    NATO ASIB Proc. 216A: The Nuclear Equation of State.  Part A: Discovery of Nuclear Shock Waves and the EOS
1989nesb.conf    NATO ASIB Proc. 216B: The Nuclear Equation of State.  Part B: QCD and the Formation of the Quark-Gluon Plasma
1990pmqf.conf    NATO ASIB Proc. 224: Probabilistic Methods in Quantum Field Theory and Quantum Gravity
1990qmcs.conf    NATO ASIB Proc. 230: Quantum Mechanics in Curved Space-Time
1977tteg.conf    NATO ASIB Proc. 27: Topics in Theoretical and Experimental Gravitation Physics
1991tche.conf    NATO ASIB Proc. 275: Techniques and Concepts of High-Energy Physics VI
1992tdqm.conf    NATO ASIB Proc. 299: Time-Dependent Quantum Molecular Dynamics
1974pclb.conf    NATO ASIB Proc. 3: Photon Correlation and Light Beating Spectroscopy
1993sila.conf    NATO ASIB Proc. 316: Super-Intense Laser-Atom Physics
1994tanc.conf    NATO ASIB Proc. 321: Topics in Atomic and Nuclear Collisions
1994hdnm.conf    NATO ASIB Proc. 335: Hot and Dense Nuclear Matter
1994epeu.conf    NATO ASIB Proc. 338: Electroweak Physics and the Early Universe
1995pmci.conf    NATO ASIB Proc. 348: Physics with Mutiply Charged Ions
1995fpp..conf    NATO ASIB Proc. 350: Frontiers in Particle Physics
1978scp..conf    NATO ASIB Proc. 36: Strongly Coupled Plasmas
1997mfp..conf    NATO ASIB Proc. 363: Masses of Fundamental Particles
1997qfqs.conf    NATO ASIB Proc. 364: Quantum Fields and Quantum Space Time
2001crfa.conf    NATO ASIB Proc. 42: Cosmic Radiations: From Astronomy to Particle Physics
1979rdg..conf    NATO ASIB Proc. 44: Recent Developments in Gravitation
1980ampc.conf    NATO ASIB Proc. 53: Atomic and Molecular Processes in Controlled Thermonuclear Fusion
1980cgst.conf    NATO ASIB Proc. 58: Cosmology and Gravitation: Spin, Torsion, Rotation, and Supergravity
1982amct.conf    NATO ASIB Proc. 71: Atomic and Molecular Collision Theory
1981nppb.conf    NATO ASIB Proc. 75: Nonlinear Phenomena in Physics and Biology
1983piie.conf    NATO ASIB Proc. 83: Physics of Ion-Ion and Electron-Ion Collisions
1983ream.conf    NATO ASIB Proc. 87: Relativistic Effects in Atoms, Molecules, and Solids
1983als..conf    NATO ASIB Proc. 95: Advances in Laser Spectroscopy
1983aphi.conf    NATO ASIB Proc. 96: Atomic Physics of Highly Ionized Atoms
1983cocr.proc    NATO ASIC Proc. 107: Composition and Origin of Cosmic Rays
1983dmg..proc    NATO ASIC Proc. 110: Diffuse Matter in Galaxies
1984fegl.proc    NATO ASIC Proc. 117: Formation and Evolution of Galaxies and Large Structures in the Universe
1984pcnr.conf    NATO ASIC Proc. 134: Problems of Collapse and Numerical Relativity
1975ocr..proc    NATO ASIC Proc. 14: Origin of Cosmic Rays
1985ppvu.conf    NATO ASIC Proc. 142: Photophysics and Photochemistry in the Vacuum Ultraviolet
1985ib...proc    NATO ASIC Proc. 150: Interacting Binaries
1985pssl.proc    NATO ASIC Proc. 152: Progress in Stellar Spectral Line Formation Theory
1985sssm.proc    NATO ASIC Proc. 154: Stability of the Solar System and its Minor Natural and Artificial Bodies
1985iss..work    NATO ASIC Proc. 156: Ices in the Solar System
1985masa.proc    NATO ASIC Proc. 157: Molecular Astrophysics: State of the Art and Future Directions
1985cia..conf    NATO ASIC Proc. 161: Compendium in Astronomy
1986crca.proc    NATO ASIC Proc. 162: Cosmic Radiation in Contemporary Astrophysics
1986ninp.proc    NATO ASIC Proc. 163: Nucleosynthesis and its Implications on Nuclear and Particle Physics
1986egxb.work    NATO ASIC Proc. 167: The Evolution of Galactic X-Ray Binaries
1986ssds.proc    NATO ASIC Proc. 169: Seismology of the Sun and the Distant Stars
1986gddu.work    NATO ASIC Proc. 180: Galaxy Distances and Deviations from Universal Expansion
1987paha.proc    NATO ASIC Proc. 191: Polycyclic Aromatic Hydrocarbons and Astrophysics
1987hepa.proc    NATO ASIC Proc. 195: High Energy Phenomena Around Collapsed Stars
1987vheg.proc    NATO ASIC Proc. 199: Very High Energy Gamma Ray Astronomy
1987gal..proc    NATO ASIC Proc. 207: The Galaxy
1987ajte.proc    NATO ASIC Proc. 208: Astrophysical Jets and their Engines
1987ppic.proc    NATO ASIC Proc. 210: Physical Processes in Interstellar Clouds
1988eaun.proc    NATO ASIC Proc. 219: The Early Universe
1988gpcr.proc    NATO ASIC Proc. 220: Genesis and Propagation of Cosmic Rays
1988cfcg.work    NATO ASIC Proc. 229: Cooling Flows in Clusters and Galaxies
1988gesf.conf    NATO ASIC Proc. 232: Galactic and Extragalactic Star Formation
1988flsg.conf    NATO ASIC Proc. 234: Frontiers of Laser Spectroscopy of Gases
1988felm.conf    NATO ASIC Proc. 241: Formation and Evolution of Low Mass Stars
1988htpa.conf    NATO ASIC Proc. 249: Hot Thin Plasmas in Astrophysics
1989gwda.conf    NATO ASIC Proc. 253: Gravitational Wave Data Analysis
1989ssg..conf    NATO ASIC Proc. 263: Solar and Stellar Granulation
1989egf..conf    NATO ASIC Proc. 264: The Epoch of Galaxy Formation
1989dli..conf    NATO ASIC Proc. 274: Diffraction-Limited Imaging with Very Large Telescopes
1976pntr.conf    NATO ASIC Proc. 28: The Physics of Non-Thermal Radio Sources
1989tad..conf    NATO ASIC Proc. 290: Theory of Accretion Disks
1990dmu..conf    NATO ASIC Proc. 296: Dark Matter in the Universe
1990pphc.conf    NATO ASIC Proc. 300: Physical Processes in Hot Cosmic Plasmas
1990bdm..proc    NATO ASIC Proc. 305: Baryonic Dark Matter
1990nstb.conf    NATO ASIC Proc. 306: Neutron Stars and Their Birth Events
1990amml.conf    NATO ASIC Proc. 316: Angular Momentum and Mass Loss for Hot Stars
1990acb..proc    NATO ASIC Proc. 319: Active Close Binaries Proceedings, NATO Advanced Study Institute
1991chsp.conf    NATO ASIC Proc. 323: Chemistry in Space
1991whdw.conf    NATO ASIC Proc. 336: White Dwarfs
1991crsi.conf    NATO ASIC Proc. 337: Cosmic Rays, Supernovae and the Interstellar Medium
1991amey.conf    NATO ASIC Proc. 340: Angular Momentum Evolution of Young Stars
1991sabc.conf    NATO ASIC Proc. 341: Stellar Atmospheres - Beyond Classical Models
1991psfe.conf    NATO ASIC Proc. 342: The Physics of Star Formation and Early Stellar Evolution
1991nsto.conf    NATO ASIC Proc. 344: Neutron Stars
1991otci.conf    NATO ASIC Proc. 348: Observational Tests of Cosmological Inflation
1977dccb.conf    NATO ASIC Proc. 35: Dynamical and Chemical Coupling Between the Neutral and Ionized Atmosphere
1992issa.proc    NATO ASIC Proc. 359: The Infrared and Submillimetre Sky after COBE
1992bhp..conf    NATO ASIC Proc. 364: Black Hole Physics
1992csg..conf    NATO ASIC Proc. 366: Clusters and Superclusters of Galaxies
1992sla..conf    NATO ASIC Proc. 373: The Sun: A Laboratory for Astrophysics
1992sto..work    NATO ASIC Proc. 375: Sunspots. Theory and Observations
1978infa.proc    NATO ASIC Proc. 38: Infrared Astronomy
1993wdao.conf    NATO ASIC Proc. 403: White Dwarfs: Advances in Observation and Theory
1994tad..conf    NATO ASIC Proc. 417: Theory of Accretion Disks - 2
1994coma.conf    NATO ASIC Proc. 422: Cosmical Magnetism
1994aoa..conf    NATO ASIC Proc. 423: Adaptive Optics for Astronomy
1994cpp..conf    NATO ASIC Proc. 427: Cosmology and Particle Physics
1994iltm.conf    NATO ASIC Proc. 436: The Impact of Long-Term Monitoring on Variable Star Research: Astrophysics
1994nngl.conf    NATO ASIC Proc. 445: The Nuclei of Normal Galaxies: Lessons from the Galactic Center
1995ctap.conf    NATO ASIC Proc. 467: Current Topics in Astrofundamental Physics : The Early Universe
1995osd..conf    NATO ASIC Proc. 469: The Opacity of Spiral Disks
1979idsa.proc    NATO ASIC Proc. 47: Instabilities in Dynamical Systems. Applications to Celestial Mechanics
1996epbs.conf    NATO ASIC Proc. 477: Evolutionary Processes in Binary Stars
1997thsu.conf    NATO ASIC Proc. 486: Thermonuclear Supernovae
1997cduc.conf    NATO ASIC Proc. 487: The Cosmic Dust Connection
1997hara.conf    NATO ASIC Proc. 501: High angular resolution in astrophysics
1997cmb..conf    NATO ASIC Proc. 502: The Cosmic Microwave Background
1997gcls.conf    NATO ASIC Proc. 503: Generation of Cosmological Large-Scale Structure.
1998ctap.conf    NATO ASIC Proc. 511: Current Topics in Astrofundamental Physics: Primordial Cosmology
1998mfns.conf    NATO ASIC Proc. 515: The Many Faces of Neutron Stars.
1999dsbs.conf    NATO ASIC Proc. 522: The Dynamics of Small Bodies in the Solar System, A Major Key to Solar System Studies
1999fess.conf    NATO ASIC Proc. 523: Formation and Evolution of Solids in Space
1999poss.conf    NATO ASIC Proc. 532: Planets Outside the Solar System: Theory and Observations
1999iip..conf    NATO ASIC Proc. 537: Interball in the ISTP Program : Studies of the Solar Wind-Magnetosphere-Ionosphere Interaction
1999osps.conf    NATO ASIC Proc. 540: The Origin of Stars and Planetary Systems
1999toc..conf    NATO ASIC Proc. 541: Theoretical and Observational Cosmology
2000vsea.conf    NATO ASIC Proc. 544: Variable Stars as Essential Astrophysical Tools
2001sfu..conf    NATO ASIC Proc. 565: Structure Formation in the Universe
1980xras.proc    NATO ASIC Proc. 60: X-Ray Astronomy
1981spss.proc    NATO ASIC Proc. 68: Solar Phenomena in Stars and Stellar Systems
1974gtnl.conf    NATO ASIC Proc. 7: Group Theory in Non-Linear Problems
1982csp..proc    NATO ASIC Proc. 82: The Comparative Study of the Planets
1982amdc.proc    NATO ASIC Proc. 82: Applications of Modern Dynamics to Celestial Mechanics and Astrodynamics
1982sscr.conf    NATO ASIC Proc. 90: Supernovae: A Survey of Current Research
1979nasm.conf    Natural and Artificial Satellite Motion
1998ncdb.conf    Natural Catastrophes During Bronze Age Civilisations: Archaeological, Geological, Astronomical and Cultural Perspectives
1994ncoa.conf    The Nature of Compact Objects in Active Galactic Nuclei
1980nama.book    The Nature of Matter, Wolfson College Lectures
2003ntgp.conf    The Nature of Time: Geometry, Physics and Perception
    nrl..rept    Naval Research Lab. Report
1993nbpg.conf    N-body Problems and Gravitational Dynamics
1997neo..conf    Near-Earth Objects
1987nngp.proc    Nearly Normal Galaxies. From the Planck Time to the Present
1993ndoq.conf    The Need for a Dedicated Optical Quasar Monitoring Telescope
1982gbhc.work    The Need for Coordinated Space and Ground-Based Observations of Halley's Comet
1978neu1.conf    Neutrino 77, Volume 1
1978neu2.conf    Neutrino 77, Volume 2
1981neu1.conf    Neutrino 81, Volume 1
1981neu2.conf    Neutrino 81, Volume 2
1982neu1.conf    Neutrino '82, Volume 1
1982neu2.conf    Neutrino '82, Volume 2
1991ndns.rept    Neutrino Driven Neutron Star Formation
1985nmle.conf    Neutrino Mass and Low Energy Weak Interactions
1987nmna.conf    Neutrino Masses and Neutrino Astrophysics (Including Supernova 1987a)
2000nemi.conf    Neutrino Mixing
1988neph.work    Neutrino Physics
1984npa..conf    Neutrino Physics and Astrophysics
1986npa..conf    Neutrino Physics and Astrophysics
1998npa..conf    Neutrino Physics and Astrophysics
1997ndmu.conf    Neutrinos, Dark Matter and the Universe
1982neap.conf    The Neutron and its Applications, 1982
1968ncst.conf    Neutron Cross Sections and Technology
2001nsbh.conf    The Neutron Star - Black Hole Connection
1998nspt.conf    Neutron Stars and Pulsars: Thirty Years after the Discovery
2002nsps.conf    Neutron Stars, Pulsars, and Supernova Remnants
1987nep..conf    New and Exotic Phenomena
1990nep..conf    New and Exotic phenomena
1985nagp.meet    New Aspects of Galaxy Photometry
1966neas.book    The New Astronomy
1972neas.conf    The New Astronomy
1977nass.book    The New Astronomy and Space Science Reader
1994ndrk.rept    New Developments Regarding the KT Event and Other Catastrophes in Earth History
1998nenp.conf    New Era in Neutrino Physics
1981nfhs.conf    New Flavours and Hadron Spectroscopy, Volume 2
1987ngst.symp    New Generation Small Telescopes
    nhud.rept    New Hampshire Univ. Report
2001nhcs.conf    New horizons of computational science
1978nias.book    New Ideas in Astrometry
1986niia.conf    New Insights in Astrophysics.  Eight Years of UV Astronomy with IUE
1984npp..conf    New Particle Production, Volume 2
1989nrhi.conf    New Results in Hadronic Interactions
1978nsp..conf    The New Solar Physics
    nssy.book    The New Solar System
1990nssy.book    The New Solar System
1992ntlr.work    New Technologies for Lunar Resource Assessment
1996nths.conf    New Trends for Hamiltonian Systems and Celestial Mechanics
2002miqu.work    New Views on Microquasars
2000nvap.conf    New Vistas in Astrophysics
1990nwus.book    New Windows to the Universe
1998nwap.conf    New Worlds in Astroparticle Physics
2001nwap.conf    New worlds in astroparticle physics
1999nwap.conf    New Worlds in Astroparticle Physics II
1975nfps.rept    Newsletter of the Forum on Physics and Society
1990ngst.conf    The Next Generation Space Telescope
1955nbdp.book    Niels Bohr and the Development of Physics
1965ICRC.        Ninth International Cosmic Ray Conference
2002nmgm.meet    The Ninth Marcel Grossmann Meeting
1980txra.symp    Ninth Texas Symposium on Relativistic Astrophysics
1979stp.....1    NOAA Solar-Terrestrial Predictions Proceedings.  Volume 1.
1979stp.....2    NOAA Solar-Terrestrial Predictions Proceedings.  Volume 2.
    nro..rept    Nobeyama Radio Observatory Report
1982nsco.work    Noise Storm Coordinated Observations, CESRA Workshop #4 Supplement
1996napa.conf    Non-Accelerator Particle Physics
2002napa.conf    Non-Accelerator Particle Physics
1984ntpp.proc    Nonlinear and Turbulent Processes in Physics
1998ndca.conf    Nonlinear Dynamics and Chaos in Astrophysics: A Festschrift in Honor of George Contopoulos.
1979nmsa.conf    Nonlinear Methods of Spectral Analysis P. 9, 1979
1983obvf.proc    Nonlinear, Nonthermal Systems in Astronomy
1989npvp.conf    Nonlinear Phenomena in Vlasov Plasmas
1993npp..conf    Nonlinear Processes in Physics
1997nsia.conf    Nonlinear Signal and Image Analysis
1990nowa.conf    Nonlinear Waves III
1980nnsp.work    Nonradial and Nonlinear Stellar Pulsation
1980nsgr.symp    Non-Solar Gamma-Rays
1978necb.conf    Nonstationary Evolution of Close Binaries
1983nfcp.book    Nonstationary Fluxes of Charged Particles in Near-Earth Space
1974nsps.book    Nonsteady-State Phenomena and Stellar Evolution
1985ntvh.book    Non-thermal and Very High Temperature Phenomena in X-ray Astronomy
1983nam..conf    Nordic Astronomy Meeting on the Nordic Optical Telescope
1997nbgs.conf    Nordic-Baltic Graduate Student Meeting on Extragalactic Astronomy
1981syst.work    North American Workshop on Symbiotic Stars
2000nott.conf    The NOT in the 2000's
1977nors.conf    Novae and Related Stars
1965nns..conf    Novae, Novoides et Supernovae
1992nrao.rept    NRAO Electronics Division Report
1986seti.work    NRAO Workshop on the Search for Extraterrestrial Intelligence
2002nuas.conf    Nuclear Astrophysics
1987nuas.proc    Nuclear Astrophysics, 1987
2000nuas.conf    Nuclear Astrophysics, 2000
1990nuas.symp    Nuclear Astrophysics, 5th Workshop
1991nuas.symp    Nuclear Astrophysics, 6th Workshop
1996nuas.conf    Nuclear Astrophysics, 8th Workshop
1985ndba.conf    Nuclear Data for Basic and Applied Sciences
1962nuin.conf    Nuclear Instruments
1962niu..conf    Nuclear Instruments and their Uses, Volume 1
1972npmb.book    Nuclear, Particle and Many Body Physics, Volume 1
1963nuph.conf    Nuclear Physics
    npu..work    Nuclear Physics in the Universe
1993npu..work    Nuclear Physics in the Universe
1966nrli.conf    Nuclear Reactions in the Low and Intermediate Energy Ranges
1994nsns.conf    Nuclear Shapes and Nuclear Structure At Low Excitation Energies
1962nusp.conf    Nuclear Spectroscopy
2001nffs.conf    Nuclei Far from Stability and Astrophysics
1990nuco.conf    Nuclei in the Cosmos
1993nuco.conf    Nuclei in the Cosmos 2
1974ngbh.proc    Nuclei of Galaxies, Black Holes, and Collapsed Matter
1968nucl.conf    Nucleosynthesis
1985ncnd.conf    Nucleosynthesis : Challenges and New Developments
1997nceg.conf    Nucleosynthesis and Chemical Evolution of Galaxies
1985nuas.conf    Numerical Astrophysics
1969nmtr.book    Numerical Methods in the Theory of Rarefied Gases
1966nmgd.book    Numerical Methods in Gas Dynamics
1990nmns.work    Numerical Modelling of Nonlinear Stellar Pulsations Problems and Prospects
1987nrt..book    Numerical Radiative Transfer
1994nsa..book    Numerical Simulations in Astrophysics
1991opos.conf    Objective-Prism and Other Surveys
1992opc..book    Observational and Physical Cosmology
1999oaaf.conf    Observational Astrophysics in Asia and its Future
1987oahp.proc    Observational Astrophysics with High Precision Data
1982obvf.conf    Observational Basis for Velocity Fields in Stellar Atmospheres
1998oebh.conf    Observational Evidence for the Black Holes in the
1992opps.conf    Observations and Physical Properties of Small Solar System Bodies
2000opsc.conf    Observations and Physical Studies of Comet Hale-Bopp and Other Comets
1965onms.conf    Observations from the Nimbus I Meteorological Satellite
1881otv..book    Observations of the Transit of Venus, December 8-9, 1874
1989cxxu.rept    Observations of Cygnus X-2 at X Ray, UV, Optical and Radio Frequencies
1990orc..work    Observations of Recent Comets
1988onfn.conf    Old and New Forces of Nature
1983onqp.book    Old and New Questions in Physics, Cosmology, Philosophy, and Theoretical Biology
1967oeds.conf    On the Evolution of Double Stars
1999oep..conf    On Einstein's Path, essays in honor of Engelbert Schucking
1986ogff.conf    On Growth and Form: Fractal and Non-Fractal Patters in Physics
1984omer.rept    On Mars:  Exploration of the Red Planet, 1958 - 1978
1985ort..conf    On Relativity Theory
2001NYASA.927    The Onset of Nonlinearity in Cosmology
1980ooun.book    Oort and the Universe
1998oqrp.conf    Open Questions in Relativistic Physics
1978omap....1    Operational Modelling of the Aerospace Propagation Environment, Volume 1
1980oits.conf    Optical and Infrared Telescopes for the 1990's
1983orls.book    Optical and Laser Remote Sensing
1982oras.rept    Optical and Radio Astrometric Sources and Inertial Reference Frames
2000odat.conf    Optical Detectors for Astronomy II: State-of-the-Art at the Turn of the Millenium
1966oiea.book    Optical Instability of the Earth's Atmosphere
1962oit..conf    Optical Instruments and Techinques
1970oit..conf    Optical Instruments and Techniques 1969
2001opme.book    Optical Measurements: Techniques and Applications
1975oopg.meet    Optical Observation Programs Concerning Galactic Structure and Dynamics
1970ott..conf    Optical Telescope Technology
1978otf..conf    Optical Telescopes of the Future
2001opas.conf    Optics and Astronomy
1993oia..conf    Optics in Astronomy: 32nd Herstmonceux Conference
2002ocd..conf    Optics of Cosmic Dust
1987oucd.work    Optimization of the Use of CCD Detectors in Astronomy
1984ost1.work    Orages Solaires de Type I, CESRA Workshop #3
1959orth.conf    Orbit Theory
1989odna.conf    Orbital Dynamics of Natural and Artificial Objects
1986oreg.meet    The Oregon Meeting
1991oca..book    Organic Chemistry of the Atmosphere
2000osa..book    Organizations and Strategies in Astronomy
2002osa..book    Organizations and Strategies in Astronomy III
2003osa..book    Organizations and Strategies in Astronomy IV
1979ode..symp    Origin and Distribution of the Elements
1988ode..conf    Origin and Distribution of the Elements
1987oehu.proc    Origin and Early History of the Universe
1993oeet.conf    Origin and Evolution of the Elements
2004oee..symp    Origin and Evolution of the Elements
1964oeao.conf    The Origin and Evolution of Atmospheres and Oceans
1983oeg..proc    The Origin and Evolution of Galaxies
1989oeps.book    Origin and Evolution of Planetary and Satellite Atmospheres
1987oeps.proc    Origin and Evolution of Planetary and Satellite Systems
1990orea.book    Origin of the Earth
2000orem.conf    Origin of the Earth and Moon
1986ormo.conf    Origin of the Moon
1978orss.book    Origin of the Solar System
1966ossg.book    The Origin of the Solar System; Genesis of the Sun and Planets
2000orel.conf    Origin of Elements in the Solar System, Implications of Post-1957 Observations
1978orli.meet    Origin of Life
1985onhm.rept    Origin of Nonradiative Heating/Momentum in Hot Stars
1988oseg.proc    Origin, Structure and Evolution of Galaxies
1978opm..conf    Origins of Planetary Magnetism
1988oss..conf    Origins of Solar Systems
1991okml.book    The Oskar Klein Memorial Lectures, Vol. 1
1994okml.book    The Oskar Klein Memorial Lectures, Vol. 2
2001okml.book    The Oskar Klein Memorial Lectures, Vol. 3
1974oar..bull    Osservatorio Astronomico Rome Monthly Bulletin
1991oulu.work    Oulu Univ., Fifth EISCAT Scientific Workshop
1989oca..conf    Our Changing Atmosphere
2001oute.book    Our Universe: The Thrill of Extragalactic Exploration
1988togp.symp    The Outer Galaxy
2001ohnf.conf    The Outer Heliosphere: The Next Frontiers
1974oppt.work    Outer Planet Probe Technology Workshop
1995otw..conf    Oxford Torus Workshop
    oxun.rept    Oxford Univ Report
1989odgg.conf    Ozone Deplection, Greenhouse Gases, and Climate Change
1989ozat.conf    Ozone in the Atmosphere
1981otd..conf    Ozone Trend Detectability
1998grco.conf    Pacific Conference on Gravitation and Cosmology
1994pvgt.conf    Panchromatic View of Galaxies. Their Evolutionary Puzzle
1997pbnm.work    Parent-Body and Nebular Modification of Chondritic Materials
1982pari.iafc    Paris International Astronautical Federation Congress
1994ptyr.conf    Parkes: Thirty Years of Radio Astronomy
1990psrj.conf    Parsec-scale radio jets
1998paac.conf    Particle Acceleration in Space Plasmas
1991pana.book    Particle Acceleration Near Accreting Compact Objects
1995pnac.conf    Particle and Nuclear Astrophysics and Cosmology in the Next Millenium
1998pnp..conf    Particle and Nuclear Physics
1993paas.conf    Particle Astrophysics
1990paeu.conf    Particle Astrophysics. The Early Universe and Cosmic Structures
1989pafe.conf    Particle Astrophysics: Forefront Experimental Issues
1994pcrv.work    Particle Capture, Recovery and Velocity/Trajectory Measurement Technologies
1998pace.conf    The Particle Century
1998paco.conf    Particle Cosmology
2001ppeu.conf    Particle Physics and the Early Universe
1989ppas.book    Particle Physics and Astrophysics - Current viewpoints
1995ppci.conf    Particle Physics and Cosmology at the Interface
1989ppc..book    Particle physics in the cosmos : readings from Scientific American magazine
1986paun.conf    Particles and the Universe
1994paun.conf    Particles and the Universe
1998paun.conf    Particles and the Universe
1999pafi.conf    Particles and Fields, Eighth Mexican School
1996pafi.conf    Particles and Fields, VIII.
2000psc..proc    Particles, Strings and Cosmology
2001psc..conf    Particles, Strings, and Cosmology
1999psc..conf    Particles, Strings and Cosmology (PASCOS 98)
1995psc..conf    PASCOS '94
1986ppsr.work    Past and Present Solar Radiation: The Record in Meteoritic and Lunar Regolith Material
1997ppvs.conf    Past and present variability of the solar-terrestrial system: measurement, data analysis and theoretical models
    psu..rept    Pennsylvania State Univ. Report
1970posr.conf    Periodic Orbits Stability and Resonances
1993pstn.conf    Permanent Satellite Tracking Networks for Geodesy and Geodynamics
1993pnap.conf    Perspectives in Neutrinos Atomic Physics and Gravitation
1985pei..conf    Perspectives of Electroweak Interactions, Volume 2
1993phep.conf    Perspectives on High Energy Physics and Cosmology
2001pteu.conf    Phase Transitions in the Early Universe: Theory and Observations
1998ptc..conf    Phase Transitions in Cosmology, Fourth Paris Colloquium
1981pism.conf    Phases of the Interstellar Medium
1984pgt..conf    Phenomenology of Gauge Theories, Volume 1
1994pupf.conf    Phenomenology of Unification from Present to Future
1985phae.book    Photochemistry of Atmospheres: Earth, the Other Planets, and Comets
1963paa..book    Photoelectric Astronomy for Amateurs
1991pid..conf    Photoelectric Image Devices, the McGee Symposium
1981psbs.conf    Photometric and Spectroscopic Binary Systems
1979pomp.conf    Photometric Observations of Minor Planets Orbiting Elementary Asteroids
1980pkdg.conf    Photometry, Kinematics and Dynamics of Galaxies
1997peca.conf    Photon and Electron Collisions with Atoms and Molecules
1980phco.proc    Physical Cosmology
1991phco.conf    Physical Cosmology
1990pcp..book    Physical Cosmology and Philosophy
1986pegf.book    Physical Effects in the Gravitational Fields of Black Holes
1987sici.symp    Physical Interpretation of Solar/Interplanetary and Cometary Intervals
1996ppib.conf    Physical Processe in Interacting Binaries
1987ppcs.work    Physical Processes in Comets, Stars and Active Galaxies
1978ppgd.book    Physical Processes in Gas-Dust Nebulae
1997ppsb.conf    Physical Processes in Symbiotic Binaries and Related Systems
1977ppua.book    Physical Processes of the Upper Atmosphere
1978pans.proc    Physics and Astrophysics of Neutron Stars and Black Holes
1992pcmo.work    Physics and Chemistry of Magma Oceans from 1 Bar to 4 Mbar
1990pcim.conf    Physics and Composition of Interstellar Matter
2000pdla.conf    Physics and Diagnostics of Laboratory and Astrophysical Plasma (PDP-III'2000)
1993ptsq.conf    Physics and Technology of Semiconductor Quantum Devices
    phce.conf    Physics in the 21st Century
1979poeu.conf    Physics of the Expanding Universe
1990pihl.book    Physics of the Inner Heliosphere I
1955phio.conf    Physics of the Ionosphere
1983phjm.book    Physics of the Jovian Magnetosphere
1965phmo.book    Physics of the Moon
1967phmo.conf    Physics of the Moon
1966pmp..book    Physics of the Moon and the Planets
1976pmpq.book    Physics of the Moon and the Planets: Questions of Astrometry
1968pmp..conf    Physics of the Moon and Planets
1976pmp..book    Physics of the Moon and Planets
1969pote.conf    Physics of the One- and Two-Electron Atoms
1990phoh.coll    Physics of the Outer Heliosphere
1988phpl.book    The Physics of the Planets
1962pss..conf    Physics of the Solar System
1970pss..conf    Physics of the Solar System
1972poss.conf    Physics of the Solar System
1986psun....1    Physics of the Sun. Volume 1
1986psun....2    Physics of the Sun. Volume 2
1986psun....3    Physics of the Sun. Volume 3
1974pua..book    Physics of the Universe and Astronomy
1996pada.conf    Physics of Accretion Disks: Advection, Radiation and Magnetic Fields
1994pad..conf    Physics of Accretion Disks Around Compact and Young Stars
1992pagn.conf    Physics of Active Galactic Nuclei
1981paaf.conf    Physics of Auroral Arc Formation, Geophysical Monograph 25
1980podm.conf    Physics of Dense Matter
1996pdp..conf    The Physics of Dust Plasmas
1970pepc.conf    Physics of Elementary Particles and Cosmic Rays
1984pete.conf    Physics of Energy Transport in Extragalactic Radio Sources
1997pgh..conf    The Physics of Galactic Halos
1992pip..work    Physics of Isolated Pulsars
1998phma.conf    Physics of Mass
1973pmnc.conf    The Physics of Mesospheric (Noctilucent) Clouds
1992pngn.conf    Physics of Nearby Galaxies: Nature or Nurture?
1995pns..book    Physics of Neutron Stars
1988nsbh.symp    Physics of Neutron Stars and Black Holes
1988pnsb.conf    Physics of Neutron Stars and Black Holes
1972phpu.conf    The Physics of Pulsars
1964psf..conf    The Physics of Solar Flares
1976pspe.proc    Physics of Solar Planetary Environments
    pspp.book    Physics of Space Plasmas
1984psp..conf    Physics of Space Plasmas
2002psfg.conf    Physics of Star Formation in Galaxies
1981phss.conf    The Physics of Sunspots
1981pvm..book    Physics vade mecum, AIP 50th anniversary
1976pmas.conf    Physique des Mouvements dans les Atmospheres
1970pfa..conf    Physique Fondamentale et Astrophysique
1969plju.book    Planet Jupiter
1997pipr.conf    Planetary and Interstellar Processes Relevant to the Origins of Life
1977plat.conf    Planetary Atmospheres
1978pa...symp    Planetary Atmospheres Symposium
1984plda.work    Planetary Data Workshop
1969ped1.conf    Planetary Electrodynamics, Volume 1
1969ped2.conf    Planetary Electrodynamics, Volume 2
    pggp.rept    Planetary Geology and Geophysics Program Report
1989plge.conf    Planetary Geosciences -- 1988
1990plma.book    Planetary Mapping
1988pre..work    Planetary Radio Emissions II
2001prev.proc    Planetary Radio Emissions V
    psi..rept    Planetary Science Inst. Report
1991plsa.rept    Planetary Sciences: American and Soviet Research
1969psm..conf    Planetary Space Missions
1996psi..work    Planetary Surface Instruments Workshop
1980plwa.conf    Planetary Water
1978pwpp.conf    Planetary Water and Polar Processes
1961plsa.book    Planets and Satellites
1981plap.rept    Plasma Astrophysics
1993penp.conf    Plasma Environments of Non-Magnetic Planets
1969pia..conf    Plasma Instabilities in Astrophysics
1986ppm..conf    Plasma Penetration of Mangetospheres
1990ppsa.conf    Plasma Phenomena in the Solar Atmosphere
1961ppp1.conf    Plasma Physics and the Problem of Controlled Thermonuclear Reactions, Volume 1
1961ppp2.conf    Plasma Physics and the Problem of Controlled Thermonuclear Reactions, Volume 2
1961ppp3.conf    Plasma Physics and the Problem of Controlled Thermonuclear Reactions, Volume 3
1961ppp4.conf    Plasma Physics and the Problem of Controlled Thermonuclear Reactions, Volume 4
    pcnf.rept    Plasma Physics and Controlled Nuclear Fusion
1972ppsr.conf    Plasma Physics and Solar Radioastronomy
1978pumm.conf    Plateau Uplift: Mode and Mechanism
1978pfsl.conf    Pleins Feux sur la Physique Solaire
1990nmim.rept    Plots of the 5-minute Neutron Monitor Intensity and Multiplicities Recorded by the Rome 17-NM64
1997plch.book    Pluto and Charon
1957poat.symp    Polar Atmosphere Symposium
1998pcbp.conf    Polar Cap Boundary Phenomena
1970pimp.book    The Polar Ionosphere and Magnetosphere Processes
1992prmg.work    Polar Regions of Mars: Geology, Glaciology, and Climate History
1988prco.book    Polarized Radiation of Circumstellar Origin
1991pacm.conf    Positional Astronomy and Celestial Mechanics
1993pacm.conf    Positional Astronomy and Celestial Mechanics
1975prbs.conf    Possible Relationships between Solar Activity and Meteorological Phenomena
1975rsam.nasa    Possible Relationships between Solar Activity and Meteorological Phenomena
2001pao..conf    Post-AGB Objects as a Phase of Stellar Evolution
1988prun.proc    Post-Recombination Universe
1977prag.iafc    Prague International Astronautical Federation Congress
1972pmc..book    Precision Measurement and Calibration
1971pmfc.conf    Precision Measurement and Fundamental Constants
1981pmfc.conf    Precision Measurement and Fundamental Constants
1983pmge.conf    Precision Measurement and Gravity Experiment
1993prph.conf    Precision Photometry
1991ppag.proc    Precision Photometry:  Astrophysics of the Galaxy
1987pimd.book    Prediction of Ionospheric and Magnetospheric Disturbances and Solar Activity
1984psfc.book    Prediction of Solar Flares and their Consequences
1966ptp..book    Preludes in Theoretical Physics in honor of V.F. Weisskopf
1958pftm.book    Present and Future of the Telescope of Moderate Size
1974psfa.proc    The Present State and Future of the Astronomical Refraction Investigations
    spie.conf    Presented at the Society of Photo-Optical Instrumentation Engineers (SPIE) Conference
1974plug.nasa    A Primer in Lunar Geology
1983prhe.work    Primordial Helium
1998pnge.conf    Primordial Nuclei and their Galactic Evolution
1990prnu.work    Primordial Nucleosynthesis
    PSA..        Princeton Series in Astrophysics
    PSG..        Princeton Series in Geophysics
    PSP..        Princeton Series in Physics
    prnc.rept    Princeton Univ. Report
2000plbs.conf    Principles of Long Baseline Stellar Interferometry
2000pldm.symp    Probing Luminous and Dark Matter
1981psec.book    The Problem of the Search for Extraterrestrial Civilizations
1986pslu.book    Problem of the Search for Life in the Universe
1974papp.book    Problems in Astrophysics and the Physics of Planetary Atmospheres
1987pcrp.book    Problems in Cosmic-Ray Physics
1975psae.book    Problems in stellar atmospheres and envelopes.
1975sae..book    Problems in Stellar Atmospheres and Envelopes
1989ptpa.book    Problems in Theoretical Physics and Astrophysics
1967poa..book    Problems of Astrometry
1965pase.conf    Problems of Atmospheric and Space Electricity
1966pac..conf    Problems of Atmospheric Circulation
1970pao..conf    Problems of Atmospheric Optics
1970pap..conf    Problems of Atmospheric Physics
1975grav.book    Problems of Gravitation
1973plg..conf    Problems of Lunar Geology
1974pmp..book    Problems of Modern Physics
1978ppeu.book    Problems of Physics and Evolution of the Universe
1981str..book    Problems of Solar-Terrestrial Relationships
1999naos.symp    Proceedings : Nautical Almanac Office
2000immm.conf    Proceedings 232. WE-Heraeus Seminar
1991usra.conf    Proceedings of the 1991 Undergraduate Symposium on Research in Astronomy
1992usra.conf    Proceedings of the 1992 Undergraduate Symposium on Research in Astronomy
1993usra.conf    Proceedings of the 1993 Undergraduate Symposium on Research in Astronomy
1994usra.conf    Proceedings of the 1994 Undergraduate Symposium on Research in Astronomy
1995usra.conf    Proceedings of the 1995 Undergraduate Symposium on Research in Astronomy
1996usra.conf    Proceedings of the 1996 Undergraduate Symposium on Research in Astronomy
1997usra.proc    Proceedings of the 1997 Undergraduate Symposium on Research in Astronomy
1998usra.proc    Proceedings of the 1998 Undergraduate Symposium on Research in Astronomy
1997tcca.conf    Proceedings of the 21st Century Chinese Astronomy Conference
1996pas..meet    Proceedings of the 27th Meeting of the Polish Astronomical Society
1988grra.conf    Proceedings of the 2nd Canadian Conference on General Relativity and Relativistic Astrophysics
1998ceme.symp    Proceedings of the 30th symposium on celestial mechanics
2001ceme.conf    Proceedings of the 32nd Symposium on Celestial Mechanics
1994grra.conf    Proceedings of the 5th Canadian Conference on General Relativity and Relativistic Astrophysics
1997grra.conf    Proceedings of the 6th Canadian Conference on General Relativity and Relativistic Astrophysics
2002evlb.conf    Proceedings of the 6th EVN Symposium
2000elt..conf    Proceedings of the Backaskog workshop on extremely large telescopes
    PCPS.        Proceedings of the Cambridge Philisophical Society
1954auph.conf    Proceedings of the Conference on Auroral Physics
1999pimo.conf    Proceedings of the International Meteor Conference
2000pimo.conf    Proceedings of the International Meteor Conference
2001pimo.conf    Proceedings of the International Meteor Conference
2003pimo.conf    Proceedings of the International Meteor Conference
2004pimo.conf    Proceedings of the International Meteor Conference
1984noas.meet    Proceedings of the Nordic Astronomy Meeting
1988qsal.proc    Proceedings of the QSO Absorption Line Meeting
1973ciap.conf    Proceedings of the Second Conference on the Climatic Impact Assessment
2003enig.conf    Proceedings of the Second ENIGMA Meeting
1996magr.meet    Proceedings of the Seventh Marcel Grossman Meeting on recent developments in theoretical and experimental general relativity, gravitation, and relativistic field theories
2000asfb.proc    Proceedings of the Sixth SFB-375 Ringberg Workshop Astroteilchenphysik
1974ciap.conf    Proceedings of the Third Conference on the Climatic Impact Assessment
1997kphy.work    Proceedings of the Workshop on K Physics
1993obdi.conf    Proceedings of a Workshop on Remote Observing
    fnad.proc    Proceedings of Finnish Astronomers' Days
1994kofu.symp    Proceedings of Kofu Symposium
1983psde.conf    Processing of Scientific Data from the ESA Astrometry Satellite HIPPARCOS, 1st FAST Thinkshop
1985psde.conf    Processing of Scientific Data from the ESA Astrometry Satellite HIPPARCOS, 2nd FAST Thinkshop
1986psde.conf    Processing of Scientific Data from the ESA Astrometry Satellite HIPPARCOS, 3rd FAST Thinkshop
1985pdce.work    Production and Distribution of C, N, O Elements
1938pobv.conf    Professor \x{00D6}sten Bergstrand Vetenskapsmannen Och L\x{00E4}raren
1986pei..conf    Progress in Electroweak Interactions, Volume 1
1975pllf.conf    Progress in Lasers and Laser Fusion
1993pnc..conf    Progress in New Cosmologies : Beyond the Big Bang
1985sslf.proc    Progress in Stellar Spectral Line Formation Theory
1992ptit.conf    Progress in Telescope and Instrumentation Technologies
1964prfi.rept    Project Firefly 1962-1963
1993pesv.conf    Propagation Effects in Space VLBI
1975prw..book    Propagation of Radio Waves
1984prrb.conf    Prospects for Research with Radioactive Beams from Heavy Ion Accelerators
2001psms.conf    Protection of Space Materials from the Space Environment
1987penm.conf    Protostars and Molecular Clouds
1985prpl.conf    Protostars and Planets II
1993prpl.conf    Protostars and Planets III
2000prpl.conf    Protostars and Planets IV
1978ppsf.book    Protostars and Planets: Studies of Star Formation and of the Origin of the Solar System
1999ptgr.conf    Pulsar Timing, General Relativity and the Internal Structure of Neutron Stars
1989puls.book    Pulsars
2003pasb.conf    Pulsars, AXPs and SGRs Observed with BeppoSAX and Other Observatories
1981pbs..work    Pulsating B-Stars
1982pccv.conf    Pulsations in Classical and Cataclysmic Variable Stars
1985qcdb.conf    QCD and Beyond, Vol. 1
1993qheh.conf    QCD and High Energy Hadronic Interactions
1994qheh.conf    QCD and High Energy Hadronic Interactions
1981qlp..conf    QCD and Lepton Physics, Volume 1
2001qhte.conf    QSO Hosts and Their Environments
1989qpps.conf    QSO Physical Properties and Spectra
1999qagt.conf    Quantum Aspects of Gauge Theories, Supersymmetry and Unification
1999quch.conf    Quantum Chromodynamics
1993qcm..conf    Quantum Control and Measurement
1987quco.book    Quantum Cosmology
1969qfnm.conf    Quantum Fluids and Nuclear Matter
1998qugr.conf    Quantum Gravity
1965qoe..conf    Quantum Optics and Electronics
1980qtc..conf    Quantum Theory and Gravitation
1989qtg..book    Quantum Theory and Gravitation
1966qtam.book    Quantum Theory of Atoms, Molecules, and the Solid State, A Tribute to John C. Slater
1990qgp..conf    Quark-Gluon Plasma
1991qal..work    Quasar Absorption Lines
1996quho.conf    Quasar Hosts
2001qarr.conf    Quasars, AGNs and Related Research Across 2000.  Conference on the occasion of L. Woltjer's 70th birthday
1983qgl..conf    Quasars and Gravitational Lenses
1969qhea.conf    Quasars and high-energy astronomy
1965qssg.conf    Quasi-Stellar Sources and Gravitational Collapse
1990qfcc.proc    The Quest for the Fundamental Constants in Cosmology
1980qel..book    The Quest for Extraterrestrial Life
1977rpap.conf    Radar probing of the Auroral plasma
1991rlep.rept    Radars and Lidars in Earth and Planetary Sciences
1977raat.conf    Radiation in the Atmosphere
1963rass.conf    Radio Astronomical and Satellite Studies of the Atmosphere
1967raas.book    Radio Astronomy
2000ralw.conf    Radio Astronomy at Long Wavelengths
1987raas.work    Radio Astronomy from Space
1986racp.work    Radio Continuum Processes in Clusters of Galaxies
1987rapm.work    Radio Emissions from Planetary Magnetospheres
1999rfpp.conf    Radio Frequency Power in Plasmas
2000riss.conf    Radio interferometry : the saga and the science
1980ritg.conf    Radio Interferometry Techniques for Geodesy
1991rst..work    The Radio Schmidt Telescope
1985ras..work    Radio Stars; Proceedings of the Workshop on Stellar Continuum Radio Astronomy
1976rsrt.rept    Radio, Submillimeter, and X-ray Telescopes
1960raso.conf    Radioastronomia Solare
2001ragt.meet    RAGtime 2/3: Workshops on Black Holes and Neutron Stars
1986rfsf.nasa    Rapid Fluctuations in Solar Flares
1991rvos.conf    Rapid Variability of OB-stars: Nature and Diagnostic Value
1960rgd..conf    Rarefied Gas Dynamics
1961rgd..conf    Rarefied Gas Dynamics
1963rgd1.conf    Rarefied Gas Dynamics, Volume 1
1965rgd1.conf    Rarefied Gas Dynamics, Volume 1
1967rgd1.conf    Rarefied Gas Dynamics, Volume 1
1963rgd2.conf    Rarefied Gas Dynamics, Volume 2
1965rgd2.conf    Rarefied Gas Dynamics, Volume 2
1967rgd2.conf    Rarefied Gas Dynamics, Volume 2
    rmus.nasa    Reanalysis of Mariner 9 UV Spectrometer Data for Ozone, Cloud, and Dust Abundances, and Their Interaction Over Climate Timescales
2000racc.conf    Recent Advances and Cross-Century Outlooks in Physics, Interplay between Theory and Experiment
1977agra.rept    Recent Advances in Gamma-Ray Astronomy
1982raoa.conf    Recent Advances in Observational Astronomy
1985rapm.book    Recent Advances in Planetary Meteorology
1982rdea.conf    Recent Developments in Electron-Atom and Electron-Molecule Collision
1962rdgr.book    Recent Developments in General Relativity
1996rdgm.conf    Recent Developments in Gravitation and Mathematical Physics
2001rdpp.conf    Recent Developments in Particle Physics and Cosmology
1999magr.meet    Recent Developments in Theoretical and Experimental General Relativity, Gravitation, and Relativistic Field Theories
1977moff.symp    Recent Results in Infrared Astrophysics
1985cava.rept    Recent Results on Cataclysmic Variables
1983rrsb.conf    Recent Results on Solid Body Magnetic Fields in the Solar System
1988rttp.conf    Recent Topics in Theoretical Physics
1977rcao.conf    Recognition of Compact Astrophysical Objects
1989resp.proc    Reconnection in Space Plasma
1973rgs..conf    Red Giant Stars
1977rseu.conf    Redshifts and the Expansion of the Universe
2002rfg..conf    Reference Frames and Gravitomagnetism
1979riao.symp    Refractional Influences in Astrometry and Geodesy
1984rbcc.conf    Relations Between Chromospheric-Coronal Heating and Mass Loss in Stars
1984rcch.conf    Relative Chromoshperic Coronal Heat and Mass Loss in Stars
1997reas.conf    Relativistic Astrophysics
1984rac..conf    Relativistic Astrophysics and Cosmology
1992rac..conf    Relativistic Astrophysics and Cosmology
1997raco.conf    Relativistic Astrophysics and Cosmology
1997rggr.conf    Relativistic Gravitation and Gravitational Radiation
1989rges.rept    Relativistic Gravitational Experiments in Space
1997rja..proc    Relativistic Jets in AGNs
1970rela.conf    Relativity
1971regr.conf    Relativity and Gravitation
1999rgg..conf    Relativity and Gravitation in General
1983rctm.proc    Relativity, Cosmology, Topological Mass and Supergravity; Proceedings of the Fourth Silarg Symposium on Gravity, Gauge Theories and Supergravity
1999rppc.conf    Relativity, Particle Physics and Cosmology
1967rta1.book    Relativity Theory and Astrophysics. Vol.1: Relativity and Cosmology
1967rta2.book    Relativity Theory and Astrophysics. Vol.2: Galactic Structure
1967rta3.book    Relativity Theory and Astrophysics. Vol.3: Stellar Structure
1993rgrc.conf    The Renaissance of General Relativity and Cosmology
1971rsif.book    Rendiconti della Scuola Internazionale Di Fisica
1989fsrd.work    Report of the Florida Space Research and Development Workshop
1965eqae.conf    Report on Equatorial Aeronomy
    itab.rept    Report on Instrumental and Theoretical Astrophysics
1976rapp.rept    Reports of Accomplishments of Planetology Programs, 1975-1976.
1965rffd.conf    Research Frontiers in Fluid Dynamics
1975rgcr.rept    Research Goals for Cosmic-Ray Astrophysics in the 1980's
1997rpa..work    Research in Particle-Astrophysics
1969rpc..conf    Research in Physics and Chemistry
1970asas.book    Research of the Sun and Stars
1974rpnl.conf    Research Programmes for the New Large Telescopes
1976rbal.symp    Research Utilizing Balloons
1968rla..conf    Resonance Lines in Astrophysics
1991rnes.nasa    Resources of Near-Earth Space
1993rnes.book    Resources of near-earth space
2001ruag.conf    The Restless Universe
1991rhis.conf    The Restoration of HST Images and Spectra
1994rhis.conf    The Restoration of HST Images and Spectra - II
1975rmsi.book    Results and Methods for Studies of Interstellar Matter and Be Stars
1994rppp.conf    Results and Perspectives in Particle Physics
1979rarl.conf    Reunion Astronomica Regional Latinoamericana
1982rupp.book    Revealing the Universe: Prediction and Proof in Astronomy
    RMxAC        Revista Mexicana de Astronomia y Astrofisica Conference Series
2004rcfg.proc    The Riddle of Cooling Flows in Galaxies and Clusters of galaxies
1974risa.nasa    The Rings of Saturn
1995roob.book    Robotic Observatories
1963rsm..conf    Rocket and Satellite Meteorology
1954reua.conf    Rocket Exploration of the Upper Atmosphere
1980raok.rept    Rocznie Astronomiczny Observatory Krakowskiego
1996rftu.proc    Roentgenstrahlung from the Universe
1987rfsm.conf    The Role of Fine-Scale Magnetic Fields on the Structure of the Solar Atmosphere
1992rmkt.conf    The Role of Miklos Konkoly Thege in the History of Astronomy in Hungary
2001rnsg.conf    The Role of Neutrinos, Strings, Gravity, and Variable Cosmological Constant in Elementary Particle Physics
1972rsta.conf    The Role of Schmidt Telescopes in Astronomy
1981rome.iafc    Rome International Astronautical Federation Congress
    roe..rept    Royal Observatory, Edinburgh Report
1987rorn.conf    RS Ophiuchi (1985) and the Recurrent Nova Phenomenon
2002rict.conf    Russian Information, Computing and Telecommunication Resources for Supporting Basic Research
1983rsam.conf    Rydberg States of Atoms and Molecules
1971tdas.conf    Saas-Fee Advanced Course 1: Theorie des Atmospheres Stellaires
1980stfo.conf    Saas-Fee Advanced Course 10: Star Formation
1981aoa..conf    Saas-Fee Advanced Course 11: Activity and Outer Atmosphere of the Sun and Stars
1982modg.proc    Saas-Fee Advanced Course 12: Morphology and Dynamics of GalaxiesSaas-Fee Vol. 12: Morphology and Dynamics of Galaxies
1983apum.conf    Saas-Fee Advanced Course 13: Astrophysical Processes in Upper Main Sequence Stars
1984plan.conf    Saas-Fee Advanced Course 14: Planets
1985hria.conf    Saas-Fee Advanced Course 15: High Resolution in Astronomy
1986nce..conf    Saas-Fee Advanced Course 16: Nucleosynthesis and Chemical Evolution
1988rmgm.conf    Saas-Fee Advanced Course 18: Radiation in Moving Gaseous Media
1972ismt.conf    Saas-Fee Advanced Course 2: Interstellar Matter
1994plas.conf    Saas-Fee Advanced Course 24: Plasma Astrophysics
1995stre.conf    Saas-Fee Advanced Course 25: Stellar Remnants
1998giis.conf    Saas-Fee Advanced Course 26: Galaxies: Interactions and Induced Star Formation
1998cmaf.conf    Saas-Fee Advanced Course 27: Computational Methods for Astrophysical Fluid Flow.
2001stcl.conf    Saas-Fee Advanced Course 28: Star Clusters
1973dses.conf    Saas-Fee Advanced Course 3: Dynamical Structure and Evolution of Stellar Systems
1974magn.conf    Saas-Fee Advanced Course 4: Magnetohydrodynamics
1975ampa.conf    Saas-Fee Advanced Course 5: Atomic and Molecular Processes in Interstellar Clouds
1976gala.conf    Saas-Fee Advanced Course 6: Galaxies
1977asse.conf    Saas-Fee Advanced Course 7: Advanced Stages in Stellar Evolution
1978obco.meet    Saas-Fee Advanced Course 8: Observational Cosmology Advanced Course
1979ehea.conf    Saas-Fee Advanced Course 9: Extragalactic High Energy Astrophysics
1999srms.conf    Sample Return Missions to Small Bodies
1991sdum.nasa    Sand and Dust on Mars
1982mvla.rept    SAO Catalog of Meteorites from Victoria Land, Antarctica
1994spub.rept    Sao Paulo Univ. Brazil Conference Paper
2000satp.work    SARG at TNG: Prespectives for the Year 2000
1982stjp.conf    Satellites of Jupiter
1984satn.book    Saturn
1978satn.nasa    The Saturn System
1965spla.conf    Scattering and Polarization of Light in the Atmosphere
1969stnm.book    Scattering Theory: New Methods and Problems in Atomic, Nuclear, and Particle Physics
2001shem.conf    Science and the Human Explorations of Mars
    saic.rept    Science Applications International Corp. Report
1961sis..book    Science in Space
1999alma.conf    Science with the Atacama Large Millimeter Array (ALMA)
1992swhs.conf    Science with the Hubble Space Telescope
1996swhs.conf    Science with the Hubble Space Telescope - II
2001slbt.work    Science with the Large Binocular Telescope
2003sngh.conf    Science with the New Generation of High Energy Gamma-Ray Experiments : Between Astrophysics and Astroparticle Physics
2002swsi.conf    Science with the Space Interferometry Mission
1999sska.conf    Science with the Square Kilometer Array : a Next Generation World Radio Observatory
1995svlt.conf    Science with the VLT
1997svlt.work    Science with the VLT Interferometer
1998swg..work    Science with Gemini: a South American perspective
1994shsr.conf    Science with High Spatial Resolution Far-Infrared Data
1981giot.proc    Scientific and Experimental Aspects of the Giotto Mission
1970sarr.conf    Scientific Applications of Radio and Radar Tracking in the Space Program
1989saso.rept    Scientific Assessment of Stratospheric Ozone: 1989.  Volume II: Appendix
1983ebro.conf    Scientific Contributions in Commemoration of Ebro Observatory's 75th Anniversary
1982siha.conf    Scientific Importance of High Angular Resolution at Infrared and Optical Wavelengths
1976skls.conf    Scientific investigations on the Skylab Satellite
2001spuv.conf    Scientific Prospects of the Space Ultraviolet Observatory SPECTRUM-UV
1993spsm.rept    Scientific Requirements for Future Solar-Physics Space Missions
1979srst.nasa    Scientific Research with the Space Telescope
1980tpmb.meet    Scientific Seminar on the Theory and Practice of Magnetographic Observations of the Sun, Irkutsk
1977scv..book    Scientists Confront Velikovsky
1970sccl.rept    A Search for Carbon and its Compounds in Lunar Samples from Mare Tranquillitatis
1977seti.conf    The search for extraterrestrial intelligence
1983sgw..work    Search of Gravitational Waves
1984aprm.conf    Second Asian-Pacific Regional Meeting on Astronomy
1981csss....2    Second Cambridge Workshop on Cool Stars, Stellar Systems, and the Sun
1998grwa.conf    Second Edoardo Amaldi Conference on Gravitational Wave Experiments
1997siad.conf    Second International A.D. Sahkarov Conference on Physics
2000mpse.conf    Second International Conference on Mars Polar Science and Exploration
1990smfs.nasa    Second Meeting of Finnish Space Researchers
2001cnoc.conf    The Second National Conference on Astrophysics of Compact Objects
1993rdmw.conf    Second Northeast-Asian Regional Meeting (NARM '92)
1995pcc..conf    Second Paris Cosmology Colloquium
1994assa.symp    Second Symposium of the Astronomical Society of Southern Africa
1986vlt..work    Second Workshop on ESO's Very Large Telescope
1988itp..work    Second Workshop on Improvements to Photometry
1985scgl.work    Second Workshop on Spacecraft Glow
1993inas.book    Selected Papers on Instrumentation in Astronomy
1963nocl.book    Selected Papers on Noctilucent Clouds
1995fthi.conf    Selected Topics in Field Theory, High Energy and Astroparticle Physics
1981scms.book    Seminar of Celestial Mechanics and Space Research
1991sssa....2    Sensor Systems for Space Astrophysics in the 21st Century, Volume 2
    sdra.conf    Serendipitous Discoveries in Radio Astronomy
1983sdra.conf    Serendipitous Discoveries in Radio Astronomy
1981ICRC.        Seventeenth International Cosmic Ray Conference
1995NYASA.759    Seventeeth Texas Symposium on Relativistic Astrophysics and Cosmology
1994emsp.conf    Seventh European Meeting on Solar Physics
2001sf2a.conf    SF2A-2001: Semaine de l'Astrophysique Francaise
2002sf2a.conf    SF2A-2002: Semaine de l'Astrophysique Francaise
2003sf2a.conf    SF2A-2003: Semaine de l'Astrophysique Francaise
1980ssa..conf    Shanghai Symposium on Astronomy
1986tswo.work    SHIRSOG Workshop on Prospects for a New Synoptic High Resolution Spectroscopic Observing Facility
1992shwa....1    Shock Waves, Volume 1
1979snsa.conf    Shuttle to the Next Space Age
1976shco.work    Shuttle-Based Cometary Science Workshop
1975sast.nasa    Significant Accomplishments in Science and Technology
1973sas..conf    Significant Accomplishments in Sciences
1982regr.symp    Silarg-III: Relativity and Gravity
1982sham.conf    Simposio De Historia De La Astronomia en Mexico
1984stfl.work    Site Testing for Future Large Telescopes
2003mars.conf    Sixth International Conference on Mars
1987sowi.conf    Sixth International Solar Wind Conference
1973NYASA.224    Sixth Texas Symposium on Relativistic Astrophysics
1986grun.conf    Sixth Workshop on Grand Unification
1983swoj.conf    Sky with Ocean Joined
1980sfsl.work    Skylab Solar Workshop II
1979slas.nasa    Skylab's Astronomy and Space Science
1993sisp.conf    Small Instruments for Space Physics
1999smea.conf    Small Missions for Energetic Astrophysics : Ultraviolet to Gamma-Ray
1986ssmf.conf    Small Scale Magnetic Flux Concentrations in the Solar Photosphere
1984ssdp.conf    Small-Scale Dynamical Processes in Quiet Stellar Atmospheres
    sao..rept    Smithsonian Astrophysical Observatory Report
1959sai.....1    Societ\x{00E0} Astronomica Italiana Meeting I
1968sai.....8    Societ\x{00E0} Astronomica Italiana Meeting VIII
1967sai....10    Societ\x{00E0} Astronomica Italiana Meeting X
1968sai....11    Societ\x{00E0} Astronomica Italiana Meeting XI
1969sai....12    Societ\x{00E0} Astronomica Italiana Meeting XII
1970sai....13    Societ\x{00E0} Astronomica Italiana Meeting XIII
1971sai....14    Societ\x{00E0} Astronomica Italiana Meeting XIV
1972sai....15    Societ\x{00E0} Astronomica Italiana Meeting XV
1974sai....16    Societ\x{00E0} Astronomica Italiana Meeting XVI
1978swse.book    Software for Space Experiments
1988sohi.rept    The SOHO Mission. Scientific and Technical Aspects of the Instruments
1999soho....9    SOHO-9 Workshop on Helioseismic Diagnostics of Solar Convection and Activity
1999soho.conf    SOHO-9 Workshop on Helioseismic Diagnostics of Solar Convection and Activity
1981sars.work    Solar Active Regions: A monograph from Skylab Solar Workshop III
1968soac.conf    Solar Activity
1977soac.book    Solar Activity
1973sari.conf    Solar Activity and Related Interplanetary and Terrestrial Phenomena
1976saec.book    Solar Activity Effects on Earth and the Physics of Cosmic Rays
1998saco.conf    Solar Analogs: Characteristics and Optimum Candidates.
1988sscd.conf    Solar and Stellar Coronal Structure and Dynamics
1976ssp..conf    Solar and Stellar Pulsation Conference
1998sce..conf    Solar Composition and Its Evolution -- From Core to Corona
1975scea.conf    The Solar Constant and the Earth's Atmosphere
1956sei..conf    Solar Eclipses and the Ionosphere
1970sei..conf    Solar Eclipses and the Ionosphere
1992sers.conf    Solar Electromagnetic Radiation Study for Solar Cycle 22
1998sers.conf    Solar Electromagnetic Radiation Study for Solar Cycle 22
1994seit.conf    The Solar Engine and its Influence on Terrestrial Atmosphere and Climate
1981sfmh.book    Solar Flare Magnetohydrodynamics
1982sofl.symp    Solar Flares
1986sfcp.nasa    Solar Flares and Coronal Physics Using P/OF as a Research Tool
1969sfsr.conf    Solar Flares and Space Research
    sgd..rept    Solar Geophysical Data Reports
1981siwn.conf    Solar instrumentation: What's next?
1991soia.book    Solar Interior and Atmosphere
1994smf..conf    Solar Magnetic Fields
1987sman.work    Solar Maximum Analysis
    smrmmrept    Solar Microwave Radiation Maps Measured at Metsaehovi Radio Research Station
1995somo.conf    Solar Modeling
1994snft.book    Solar Neutrinos. The First Thirty Years
1992soti.book    Solar Observations: Techniques and Interpretation
1977soiv.conf    The Solar Output and its Variation
1972spen.conf    Solar Partical Event of November 1969
1967sp...conf    Solar Physics
1992spai.rept    Solar Physics and Astrophysics at Interferometric Resolution
1985spit.conf    Solar Physics and Interplanetary Travelling Phenomena
1971spas.conf    Solar Physics, Atomic Spectra, and Gaseous Nebulae
1988soph.book    Solar Physics Book
1973srmi.symp    Solar Radiation Measures and Instrumentation
1973sre..conf    Solar Radiations and the Earth
1988srov.proc    Solar Radiative Output Variation
1982srai.conf    Solar Radio Astronomy, Interplanetary Scintillations and Coordination with Spacecraft
1982srs..work    Solar Radio Storms, CESRA Workshop #4
1985srph.book    Solar Radiophysics: Studies of Emission from the Sun at Metre Wavelengths
1962sose.conf    Solar Seeing
1984sses.nasa    Solar Seismology from Space
1986sosy.book    The Solar System
1979sswp.book    Solar System Plasma Physics
1979magn.book    Solar System Plasma Physics. Volume 2 - Magnetospheres
1965ssra.conf    Solar System Radio Astronomy
1973str..conf    Solar Terrestrial Relations
1966sowi.conf    The Solar Wind
1972sowi.conf    Solar Wind
1987sowe.book    Solar Wind and the Earth
1986swne.book    Solar Wind and Near-Earth Processes
    sowi.conf    Solar Wind Conference
1992sws..coll    Solar Wind Seven Colloquium
1994swms.conf    The Solar Wind-Magnetosphere System
1989sxsr.rept    Solar X-Ray Astronomy Sounding Rocket Program
1984sii..conf    Solar/Interplanetary Intervals
1991step.conf    Solar-Terrestrial Energy Program
1993step.conf    Solar-Terrestrial Energy Program
1995step.conf    Solar-Terrestrial Energy Program
1989sote...36    Solar-Terrestrial Events in February-March 1986
1979stiw.conf    Solar-Terrestrial Influences on Weather and Climate
1979stwc.symp    Solar-Terrestrial Influences on Weather and Climate
2002stma.conf    Solar-Terrestrial Magnetic Activity and Space Environment
1974stp.....1    Solar-Terrestrial Physics, Volume 1
1974stp.....2    Solar-Terrestrial Physics, Volume 2
1986stp..conf    Solar-Terrestrial Predictions
1989stss.work    Solar-Terrestrial Science Strategy Workshop
1976swip.nasa    Solar-Wind Interaction with the Planets Mercury, Venus, and Mars
2003ssac.proc    Solid State Astrochemistry
2001scsw.conf    SOLSPA 2001 Euroconference: Solar Cycle and Space Weather
1960siro.conf    Some Ionospheric Results Obtained During the International Geophsysical Year
1976scrv.book    Some Results of the Study of Cosmic Ray Variations
1997stgr.proc    Some Topics on General Relativity and Gravitational Radiation
2001sddm.symp    Sources and Detection of Dark Matter and Dark Energy in the Universe
1995sdmu.conf    Sources of Dark Matter in the Universe
1979sgrr.work    Sources of Gravitational Radiation
1976srca.conf    Southwest Regional Conference for Astronomy and Astrophysics
1985srca.conf    Southwest Regional Conference for Astronomy and Astrophysics, 10
1977srca.conf    Southwest Regional Conference for Astronomy and Astrophysics, 2
1978srca.conf    Southwest Regional Conference for Astronomy and Astrophysics, 3
1979srca.conf    Southwest Regional Conference for Astronomy and Astrophysics, 4
1980srca.conf    Southwest Regional Conference for Astronomy and Astrophysics, 5
1981srca.conf    Southwest Regional Conference for Astronomy and Astrophysics, 6
1982srca.conf    Southwest Regional Conference for Astronomy and Astrophysics, 7
1983srca.conf    Southwest Regional Conference for Astronomy and Astrophysics, 8
1984srca.conf    Southwest Regional Conference for Astronomy and Astrophysics, 9
1982swrc.conf    Southwest Regional Conference on Astronomy and Astrophysics
    sri..rept    Southwest Research Inst. Report
1978spss.book    Soviet Progress in Space Studies: The Second Decade of Space Flight, 1967-1977
1974map..conf    Soviet-American Conference on the Cosmochemistry of the Moon and Planets
1977ccmp.conf    The Soviet-American Conference on Cosmochemistry of the Moon and Planets
1982sfa..meet    Soviet-Finnish Astronomy Meeting
1998sp98.conf    Space 98
1962saa..conf    Space Age Astronomy
1992sesd.rept    Space and Earth Sciences Directorate
1975spam.rept    Space Astrometry
1987asse.rept    Space Astronomy and Solar System Exploration
1961spas.book    Space Astrophysics
1989sccp.book    Space Chemistry and Comparative Planetology
1990sca.....1    Space Conference of the Americas, Volume 1
1991sca..book    Space Construction Activities
1993seeo.work    Space Environment: The Effects on the Optical Properties of Airless Bodies
1977see..book    Space Environment and the Earth
1987spet.rept    Space Environment Technology
1989seem.work    Space Environmental Effects on Materials Workshop
1964sess.conf    Space Exploration and the Solar System
    spmf.conf    Space Manufacturing
    smse.rept    Space Mathematics for the Preparation and the Development of Satellite Exploitations
1980spmi.book    Space Mineralogy
1989spmi.symp    Space Mining and Manufacturing
1979sptc.conf    Space Missions to Comets
1986smhc.rept    Space Missions to Halley's Comet
1978song.rept    Space Oceanography Navigation, and Geodynamics
1966sot..conf    Space Optical Technology Conference
1974spop.conf    Space Optics
1991spsi....1    Space Physics Strategy-Implementation Study. Volume 1
1990sppi.rept    Space Plasma Physics Investigation by Cluster and Regatta
    spre.proc    Space Research
1975srcu.rept    Space Research Conducted in the USSR in 1974
1984srps.conf    Space Research in Stellar Activity and Variability
2000srr2.work    Space Resources Roundtable II
1992sres....1    Space Resources. Volume 1: Scenarios
1992sres....2    Space Resources. Volume 2: Energy, Power, and Transport
1992sres....3    Space Resources. Volume 3: Materials
1986ssap.book    Space Science and Applications: Progress and Potential
1989sser.proc    Space Science and Engineering Research Forum
1988ssfp.rept    Space Science and Fundamental Physics
1981ssca.proc    Space Science Comes of Age: Perspectives in the History of the Space Sciences
1977ssmi.proc    Space Shuttle Missions of the 80's
1986spst.conf    Space Station beyond IOC
1986sspe.nasa    Space Station Planetology Experiments (SSPEX)
1985sssp.book    Space Stations and Space Platforms - Concepts, Design, Infrastructure and Uses
2001sssw.conf    Space Storms and Space Weather Hazards
2001stai.conf    Space Technology and Applications International Forum -- 2001
    spte.symp    Space Technology and Science
1976spte.book    The Space Telescope
1982sto..conf    Space Telescope Observations
    stsc.rept    Space Telescope Science Inst Report
    svdc.rept    Space Vehicle Design Criteria (Environment)
1986ssma.work    Spaceborne Submillimeter Astronomy Mission. A Cornerstone of the ESA Long Term Science Program
1991sfdy.rept    Spacecraft Flight Dynamics
1980scom.proc    Spacecraft Orbital Motion
1998spdy.conf    Spaceflight Dynamics 1998, Volume 100 Part 1, Advances in Astronautical Sciences
1981splb.rept    Spacelab Mission 1 Experiment Descriptions
1982sag..conf    Spacetime and Geometry
1976slcs.nasa    The Specific Light Output of Cesium Iodide Crystals
1989saie.book    The Spectra of Atoms and Ions and Elementary Processes in Plasmas
1965serr.conf    Spectral, Electrophotometrical and Radar Researches of Aurorae and Airglow
1983seg..conf    Spectral Evolution of Galaxies
1992ssr..symp    Spectral Sensing Research
1980ssml.book    Spectres Molecules Simples
1979sssn.book    Spectrophotometric Studies of Stars and Nebulae
1968sgtm.book    Spectroscopic and Group Theoretical Methods in Physics
1986spcp.proc    Spectroscopic and Photometric Classification of Population II Stars
1970saac.book    Spectroscopic Astrophysics. An Assessment of the Contributions of Otto Struve
2001spsp.conf    Spectroscopy from Space
1987soap.conf    Spectroscopy of Astrophysical Plasmas
1998spgr.conf    Spin in Gravity.  Is it Possible to Give an Experimental Basis to Torsion? International School of Cosmology and Gravitation XV Course
    SPPhy        Springer Proceedings in Physics
    SSAOP        Springer Series on Atomic Optical and Plasma Physics
    SSBio        Springer Series on Biophysics
    SSChP        Springer Series on Chemical Physics
    SSNPP        Springer Series on Nuclear and Particle Physics
1985sssb.proc    Stability of the Solar System and its Minor Natural and Artificial Bodies
1995smb..conf    The standard model and beyond
    stan.rept    Stanford Univ. Report
1989stct.proc    Star Catalogues: A Centennial Tribute To A. N. Vyssotsky
1977stcl.symp    Star Cluster Symposium
1983scag.conf    Star Clusters and Associations and their Relation to the Evolution of the Galaxy
1963stev.conf    Star Evolution
    stfo.conf    Star Formation
1993sfgi.conf    Star Formation, Galaxies and the Interstellar Medium
1987sfig.conf    Star Formation in Galaxies
1992sfss.conf    Star Formation in Stellar Systems
1997sfnf.conf    Star Formation Near and Far
1984stfm.work    Star Formation Workshop, Edinburgh
2001sgnf.conf    Starburst Galaxies: Near and Far
1987sbge.proc    Starbursts and Galaxy Evolution
1998stne.conf    Starbursts: Triggers, Nature, and Evolution, Les Houches School
1985sfdg.conf    Star-Forming Dwarf Galaxies and Related Objects
2001stun.conf    The Starry Universe; The Cecilia Payne-Gaposchkin Century
1974smws.conf    Stars and the Milky Way System
1962sgba.book    Stars and Galaxies: Birth, Ageing, and Death in the Universe
1976sgov.meet    Stars and Galaxies from Observational Points of View
1981sss..book    Stars and Star Systems
1996scmj.book    Stars in a Cluster: MT John University Observatory
1980stun.book    The State of the Universe
    suny.rept    State Univ. of New York, Stony Brook Report
2003sca..book    Statistical Challenges in Astronomy
1997scma.conf    Statistical Challenges in Modern Astronomy II
1983stma.rept    Statistical Methods in Astronomy
1963stph.conf    Statistical Physics 3
1996stab.conf    Stellar Abundances
1983spm..conf    Stellar and Planetary Magnetism
1969stas.conf    Stellar Astronomy
1992stas.book    Stellar Astrophysics
1998salg.conf    Stellar astrophysics for the local group: VIII Canary Islands Winter School of Astrophysics
2000stap.conf    Stellar Astrophysics, Proceedings of the Pacific Rim Conference
2002sam..work    Stellar Atmosphere Modeling
1954stat.conf    Stellar Atmospheres
1955stat.conf    Stellar Atmospheres
1983sasp.nasa    Stellar Atmospheric Structural Patterns
1992sccw.conf    Stellar Chromospheres, Coronae and Winds
2001sdcm.conf    Stellar Dynamics: from Classic to Modern
1966stev.conf    Stellar Evolution
1972stev.conf    Stellar Evolution
1987sedo.work    Stellar Evolution and Dynamics in the Outer Halo of the Galaxy
1998sese.conf    Stellar Evolution, Stellar Explosions and Galactic Chemical Evolution
1995sews.book    Stellar Evolution: What Should be Done
1992stma.conf    Stellar Magnetism
1986stpo.meet    Stellar Populations
2001spns.book    Stellar pulsation - Nonlinear Studies
1981sspi.book    Stellar Spectra and Their Interpretation
1983ssse.conf    Stellar Structure and Stellar Evolution
1993NYASA.706    Stochastic Processes in Astrophysics
1985stoc.iafc    Stockholm International Astronautical Federation Congress
1991sqmp.work    Strange Quark Matter in Physics and Astrophysics
1978stra.work    STRATCOM 8 Data Workshop and Suppl.
1996smgh.conf    Strategies for Mars: A Guide to Human Exploration
1993stqg.conf    String Theory and Quantum Gravity '92
1998stcs.conf    String Theory in Curved Space Times, A Collaborative Research Report
1993stqu.conf    String Theory, Quantum Gravity, and the Unification of the Fundamental Interactions
2001stri.conf    Strings
1999sem..conf    Strong and Electroweak Matter '98
1986sigt.conf    Strong Interactions and Gauge Theories, Volume 2
1977scgr.nasa    The Structure and Content of the Galaxy and Galactic Gamma Rays
1997seim.proc    Structure and Evolution of the Intergalactic Medium from QSO Absorption Line System
1992sens.conf    Structure and Evolution of Neutron Stars
1981seng.proc    Structure and Evolution of Normal Galaxies
1993sdce.conf    Structure, Dynamics and Chemical Evolution of Elliptical Galaxies
1998semi.conf    Structure et Evolution du Milieu Inter-Galactique Revele par Raies D'Absorption dans le Spectre des Quasars, 13th Colloque d'Astrophysique de l'Institut d'Astrophysique de Paris
1969scn..conf    Structure of Complex Nuclei
1972stma.conf    The Structure of Matter
1999upse.conf    STScI Symp. Ser.12: Unsolved Problems in Stellar Evolution
1966spgd.book    Studies in Gas Dynamics
2004sgyu.conf    Studies of Galaxies in the Young Universe with New Generation Telescope
1979sscs.conf    Study of the Solar Cycle from Space
1980sscs.nasa    Study of the Solar Cycle from Space
1975ssim.conf    The Study of the Sun and Interplanetary Medium in Three Dimensions
1976sipm.symp    Study of the Sun and Interplanetary Medium in Three Dimensions
1988scge.book    A Study of Clusters of Galaxies and Extragalactic Radio Emission Sources
1982sep..conf    Study of Earth as a Planet
1991sicd.rept    Study of Ion Composition and Dynamics at Comet Halley
1977tipp.symp    Study of Travelling Interplanetary Phenomena 1977
1986svsu.symp    Study of Variable Stars using Small Telescopes
1993sara.conf    Sub-arcsecond Radio Astronomy
1985sma..work    (Sub)Millimeter Astronomy
1982smwa.book    Submillimetre Wave Astronomy
2003suco.conf    Subsurface Conditions
1953sun..book    The Sun
1996sube.conf    The Sun and Beyond
1981sucl.conf    Sun and Climate (Soleil et climat)
1982spls.meet    Sun and Planetary System
1981suas.nasa    The Sun as a Star
1991st...book    The Sun in Time
1978swcl.nasa    Sun, Weather, and Climate
1991saaj.conf    Supercomputing Astronomy and Astrophysics in Japan
1988sca..conf    Super-Computing in Astrophysics
1982sugr.conf    Supergravity '81
1987slrs.work    Superluminal Radio Sources
1988smbh.proc    Supermassive Black Holes
1988slmc.proc    Supernova 1987A in the Large Magellanic Cloud
1988snoy.conf    Supernova 1987A, One Year Later, Results and Perspectives
1998suco.conf    Supernovae and cosmology
2001sgrb.conf    Supernovae and Gamma-Ray Bursts: the Greatest Explosions since the Big Bang
1969str..conf    Supernovae and Their Remnants
1990sjws.conf    Supernovae, Jerusalem Winter School for Theoretical Physics
1988srag.work    Supernovae, Remnants, Active Galaxies, Cosmology
1985stpr.work    Supernovae, their Progenitors and Remnants
1981sssg.conf    Superspace and Supergravity
1986ssau.work    Superstrings, Supergravity, and Unified Theories
1999sqs..conf    Supersymmetries and Quantum Symmetries
1983sas..conf    Supersymmetry and Supergravity
1968stla.conf    Support and Testing of Large Astronomical Mirrors
1980suma.book    Surface of Mars
1970syma.book    Symposia Mathematica
1961aeco.conf    Symposium d'A\x{00E9}ronomie Communications
1966aeco.conf    Symposium d'A\x{00E9}ronomie Communications
1960jeap.conf    Symposium of the July 1959 Events and Associated Phenomena
2001fpam.symp    Symposium on the Frontiers of Physics at Millenium
1972oss..conf    Symposium on the Origin of the Solar System
    xray.symp    Symposium on X-ray Astronomy
    sri..conf    Synchrotron Radiation Instrumentation Conference
1986syim.conf    Synthesis Imaging
1982syma.work    Synthesis Mapping
1999ters.conf    Tackling the Engineering Resources Shortage, Creating New Paradigms for Developing and Retaining Women Engineers
    TIFRL        Tata Institute of Fundamental Research Lectures on Mathematics and Physics
1979tamo.conf    Techniques and Methods of Radio-Astronomic Reception
2001tdpl.symp    Techniques for the detection of planets and life
1977tmra.book    Technology and Methods of Radio-Astronomical Reception
1982tspa.conf    Technology for Space Astrophysics Conference
1975tsse.conf    Technology of Scientific Space Experiments
1974ttt.....2    Technology Today for Tomorrow
1993thtp.nasa    Tectonic History of the Terrestrial Planets
1976tsgp.conf    Tectonics and Structural Geology
    tdar.nasa    Telecommunications and Data Acquisition Report
1987nman.conf    Telemark IV. Neutrino Masses and Neutrino Astrophysics
1974tsbb.nasa    Telescope Systems for Balloon-Borne Researc
1981tesc.book    Telescopes for the 1980s, Annual Reviews Monograph
1967ICRC.        Tenth International Cosmic Ray Conference
2000tcsp.conf    Terrestrial and Cosmic Spherules
1976tpvm.nasa    Terrestrial Photovoltaic Measurements
1985tpcp.conf    Terrestrial Planets:  Comparative Planetology
1978trg..proc    Terrestrial Rare Gases
1992tap..proc    Testing the AGN Paradigm
1996tgra.conf    TeV Gamma-ray Astrophysics. Theory and Observations
2003tsra.symp    Texas in Tuscany. XXI Symposium on Relativistic Astrophysics
    uta..rept    Texas Univ., Austin Report
1980tsup.work    Texas Workshop on Type I Supernovae
1993NYASA.688    Texas/PASCOS '92: Relativistic Astrophysics and Particle Cosmology
    TMPhy        Texts and Monographs in Physics
2001tpea.conf    Theoretical and Practical Elementary Aspects of High Energy Physics
1983tasa.conf    Theoretical Aspects on Structure, Activity, and Evolution of Galaxies
1984tasa.conf    Theoretical Aspects on Structure, Activity, and Evolution of Galaxies: II
1985tasa.conf    Theoretical Aspects on Structure, Activity, and Evolution of Galaxies: III
1991tmcs.conf    Theoretical Modelling of Comet Simulation Experiments
2002tpet.conf    Theoretical Physics at the End of the Twentieth Century
1978tpar.book    Theoretical Principles in Astrophysics and Relativity
1987tphr.conf    Theoretical Problems in High Resolution Solar Physics
1984tpss.conf    Theoretical Problems in Stellar Stability and Oscillations
1975tehe.conf    Theories and Experiments in High-Energy Physics
1996tacv.conf    Theory and Applications of the Cluster Variation and Path Probability Methods
1980tamm.conf    Theory and Applications of Moment Methods in Many-Fermion Systems
1987tolc.conf    Theory and Observational Limits in Cosmology
    tad..conf    Theory of Accretion Disks
1998tbha.conf    Theory of Black Hole Accretion Disks
1989hnis.conf    Thermal and Nonthermal Interactions in Solar Flares
1989tnti.conf    Thermal-Non-Thermal Interactions in Solar Flares
1978tkdf.work    Thermodynamics and Kinetics of Dust Formation in the Space Medium
    thph.conf    Thermophysics Conference
1986thdy.work    Thermosphere Dynamics Workshop II
1986thdy....2    Thermosphere Dynamics Workshop, Volume 2
1997fbs..conf    The Third Conference on Faint Blue Stars
1986seti.conf    Third Decennial US-USSR Conference on SETI
1982sdp..conf    Third Geodetic Symposium on Satellite Doppler Positioning
1989tidt.work    Third Infrared Detector Technology Workshop
1993adst.conf    Third International Conference on Adaptive Structures
2003mpse.conf    Third International Conference on Mars Polar Science and Exploration
2000mons.proc    The Third MONS Workshop: Science Preparation and Target Selection
1996pcc..conf    Third Paris Cosmology Colloquium
1973ICRC.        Thirteenth International Cosmic Ray Conference
1995NYASA.751    Three-Dimensional Systems
1957thsp.conf    The Threshold of Space
1978tfer.conf    Tidal Friction and the Earth's Rotation
1982tfer.conf    Tidal Friction and the Earth's Rotation II
1997tiph.conf    Tidal Phenomena.
1975tdds.conf    Time Determination, Dissemination and Synchronization
1980toky.iafc    Tokyo International Astronautical Federation Congress
1971tmp..book    Topics in Modern Physics
1997ttp..conf    Topics in Theoretical Physics
1998tdc..conf    Topological Defects in Cosmology
1982tsef.conf    Total Solar Eclipse of 16 February, 1980.  Results of Observations
1995pist.conf    Total Solar Eclipse of November 3, 1994
1993tmac.conf    Towards a Major Atmospheric Cherenkov Detector -- II for TeV Astro/Particle Physics
1998tma..conf    Towards the Millennium in Astrophysics, Problems and Prospects. International School of Cosmic Ray Astrophysics 10th Course
1991tpsu.rept    Traces of the Primordial Structure in the Universe
1986tdcm.work    Trajectory Determinations and Collection of Micrometeoroids on the Space Station
1999tpme.conf    Transfer Phenomena in Magnetohydrodynamic and Electroconducting Flows
    tust.nasa    Translation on USSR Science and Technology
1992tapp.conf    Trends in Astroparticle Physics
1994tapp.conf    Trends in Astroparticle-Physics
    TCPS.        Trends in Chemical Physics Series
1982tip..conf    Trends in Physics
    tuft.rept    Tufts Univ. Report
1969tjap.book    Turbulent Jets of Air, Plasma, and Real Gas
    turk.rept    Turku Univ. Report
1971ICRC.        Twelfth International Cosmic Ray Conference
1989ICRC.        Twenty-first International Cosmic Ray Conference
1990taa..conf    Two Astronomical Anniversaries: HCO & SAO
1980tdp..conf    Two Dimensional Photometry
2001tycs.conf    Two Years of Science with Chandra
    tdp..conf    Two-Dimensional Photometry
2000iasn.conf    Type Ia Supernovae, Theory and Cosmology
1981uhur.symp    UHURU Memorial Symposium on X-ray Astronomy
2001udns.conf    Ultracool Dwarfs: New Spectral Types L and T
1997uulh.conf    The Ultraviolet Universe at Low and High Redshift: Probing the Progress of Galaxy Evolution
1997uiia.conf    Uncooled Infrared Imaging Arrays and Systems
1999usra.proc    Undergraduate Symposium on Research in Astronomy
2001usra.proc    Undergraduate Symposium on Research in Astronomy
1983utu..conf    Understanding the Universe. The Impact of Space Astronomy
2000udq..conf    Understanding Deconfinement in QCD
1979uefg.conf    Unification of Elementary Forces and Gauge Theories
1983uft..conf    Unified Field Theories of >4 Dimensions
1994ussl.conf    Unified Symmetry in the Small and in the Large
1987uvmm.conf    A Unified View of the Macro- and the Micro- Cosmos
1990uoam.book    The Universe and its Origins : From Ancient Myth to Present Reality and Fantasy
1977ulki.book    The Universe at Large, Key Issues in Astronomy and Cosmology
1981uuw..proc    Universe at Ultraviolet Wavelengths
1981uviu.nasa    The Universe at Ultraviolet Wavelengths:  The First Two Years of International Ultraviolet Explorer
1926unst.book    The Universe of Stars, Radio Talks from the Harvard Observatory
1998unun.book    The Universe Unfolding
1991umh..conf    Universite Mons-Hainaut
2000upse.conf    Unsolved Problems in Stellar Evolution
2003uucf.conf    The unsolved universe: challenges for the future. JENAM 2002
1992unia.work    Unstable Nuclei in Astrophysics
1998ucb..proc    Untangling Coma Berenices: A New Vision of an Old Cluster
1987umad.nasa    Upper and Middle Atmospheric Density Modeling Requirements for Spacecraft Design and Operations
1959uaaf.conf    The Upper Atmosphere Above F2-Maximum
1977uam..book    The Upper Atmosphere and Magnetosphere, Studies in Geophysics
1974uam..book    The upper atmosphere in motion
1981uaso.conf    Upper Atmosphere Studies by Optical Methods
1982uaso.conf    Upper Atmosphere Studies by Optical Methods
1995umlt.book    The upper Mesosphere and Lower Thermosphere: A Review of Experiment and Theory, Geophysical Monograph 87
1991uran.book    Uranus
1984urnp.nasa    Uranus and Neptune
1990ursi.symp    URSI/IAU Symposium on Radio Astronomical Seeing
1995iugg.rept    U.S. National Report to International Union of Geodesy and Geophysics 1991-1994
1963uasg.proc    The Use of Artificial Satellites for Geodesy
1967uasg.proc    The Use of Artificial Satellites for Geodesy
1972GMS....15    The Use of Artificial Satellites for Geodesy
    uasg.proc    Use of Artificial Satellites for Geodesy and Geodynamics
1974uasg.proc    The Use of Artificial Satellites for Geodesy and Geodynamics
1988usoa.conf    Use of Supercomputers in Observational Astronomy
1998uisr.work    Using in situ Resources for Construction of Planetary Outposts
    ulpr.nasa    Utilization of Local Planetary Resources
1996uxsa.conf    UV and X-ray Spectroscopy of Astrophysical and Laboratory Plasmas
1993uxrs.conf    UV and X-ray Spectroscopy of Laboratory and Astrophysical Plasmas
1994vuae.conf    The Vanishing Universe: Adverse Environmental Impacts on Astronomy
1980vasg.meet    Variability in Stars and Galaxies
1992vob..conf    Variability of Blazars
    vsr..conf    Variable Star Research, an International Perspective
1997vsar.conf    Variables Stars and the Astrophysical Returns of the Microlensing Surveys
1990ver..book    Variations in Earth Rotation
1981vsc..conf    Variations on the Solar Constant
1983vens.book    Venus
1969veat.conf    The Venus Atmosphere
1992vggg.book    Venus Geology, Geochemistry, and Geophysics - Research results from the USSR
1989vst..conf    Venus Geoscience Tutorial and Venus Geologic Mapping
1997veii.conf    Venus II: Geology, Geophysics, Atmosphere, and Solar Wind Environment
1983veu..conf    Very Early Universe
1982vheg.work    Very High Energy Gamma Ray Astronomy
1989vheg.conf    Very High Energy Gamma Ray Astronomy
1997vhep.conf    Very High Energy Phenomena in the Universe; Moriond Workshop
1982vlbi.conf    Very long baseline interferometry techniques
2000lmbd.conf    Very Low-mass Stars and Brown Dwarfs
    vrsp....1    Vibrational-Rotational Spectroscopy for Planetary Atmospheres, Volume 1
    vrsp....2    Vibrational-Rotational Spectroscopy for Planetary Atmospheres, Volume 2
1994vsf..book    Violent Star Formation, from 30 Doradus to QSOs
2001vfae.book    Visions of the Future: Astronomy and Earth Science
1966vsui.conf    Vortr\x{00E4}ge der Sommerschule Untere Ionosph\x{00E4}re
1987cogr.conf    Vth Brazilian School of Cosmology and Gravitation
1999foap.conf    Vulcano Workshop 1998: Frontier Objects in Astrophysics and Particle Physics
1965wsmp.book    Wanderers in the Sky
1991wdir.conf    Warped Disks and Inclined Rings around Galaxies
1992wadc.iafc    Washington, DC International Astronautical Federation Congress
1976wpr..conf    Water in Planetary Regoliths
1986wps..conf    Wave propagation and scattering
1999waph.conf    Wavelets in Physics
1996wta..conf    Wavelets, Theory and Applications
1989wtfm.conf    Wavelets. Time-Frequency Methods and Phase Space
1995waas..773    Waves in Astrophysics, Volume 773
2000win..conf    Weak Interactions and Neutrinos
1983ball.symp    Weather and Climate Responses to Solar Variations
1983wcrs.proc    Weather and Climate Responses to Solar Variations
1989hfur.book    Wegweiser f\x{00FC}r die praktische astronomische
1995wfsd.conf    Wide Field Spectroscopy and the Distant Universe
1969wcrt.conf    Wideband Cruciform Radio Telescope Research
    WSAA.        Wiley Praxis Series in Astronomy and Astrophysics
    WSAPC        Wiley Praxis Series in Atmospheric Physics and Climatology
    WSGeo        Wiley Praxis Series in Geophysics
    WSBPA        Wiley Series in Beam Physics and Accelerator Technology
    WSICP        Wiley Series in Ion Chemistry and Physics
    WSPP.        Wiley Series in Plasma Physics
1968wtsm.conf    Winds and Turbulence in Stratosphere, Mesophere and Ionosphere
1968wrs..conf    Wolf-Rayet Stars
1996wrsf.book    Wolf-Rayet stars in the framework of stellar evolution
    hutx.rept    Workshop held in Houston, TX
1990leur.work    Workshop held in Leura, Australia
1975xtcg.work    Workshop on the Preliminary Results from the S-054 X-ray Telescope and the Correlated Ground-Based Observations
1983aasc.work    Workshop on Astronomy and Astrophysics, Santa Cruz, Calif.
1990bg...work    Workshop on Bulges of Galaxies
2000came.conf    Workshop on Concepts and Approaches for Mars Exploration
2004eisp.work    Workshop on Europa's Icy Shell:  Past, Present, and Future
2003gcg..work    Workshop on Galaxies and Clusters of Galaxies
1988gein.work    Workshop on Geophysical Informatics
1999misp.conf    Workshop on Mars 2001: Integrated Science in Preparation for Sample Return and Human Exploration
1995mto..work    Workshop on Mars Telescopic Observations
2001mses.conf    Workshop on Mercury: Space Environment, Surface, and Interior
1995mfch.work    Workshop on Meteorites from Cold and Hot Deserts
1999wnvm.conf    Workshop on New Views of the Moon II: Understanding the Moon Through the Integration of Diverse Datasets
    plas.work    Workshop on Plasma Astrophysics
1999tesa.conf    Workshop on Thermal Emission Spectroscopy and Analysis of Dust, Disks, and Regoliths
1996wtyi.conf    Workshop on Two Years of Intensive Monitoring of OJ 287 and 3C66A
1989woga.conf    World of Galaxies (Le Monde des Galaxies)
    WSLNP        World Scientific Lecture Notes in Physics
    WSCCP        World Scientific Series in Contemporary Chemical Physics
    WSDCM        World Scientific Series on Directions in Condensed Matter Physics
2003xseh.proc    XEUS - studying the evolution of the hot universe
1998csp..conf    XIVth Consultation on Solar Physics: Conference Proceedings
1994bas..conf    XIXth Meeting of the Brazilian Astronomical Society
1984xue..conf    X-ray and UV Emission from Active Galactic Nuclei
1960xras.conf    X-ray Astronomy
1979xras.proc    X-ray Astronomy
1984xra..conf    X-ray Astronomy '84
1975xrat.rept    X-ray Astronomy and Related Topics
1981xras.nasa    X-ray Astronomy in the 1980's
1972xanf.conf    X-ray Astronomy in the Near Future
1988xraw.book    X-ray Astronomy with EXOSAT
1992xrb..work    The X-ray Background
1976xrbi.nasa    X-ray Binaries
2001xeab.conf    X-ray Emission from Accretion onto Black Holes
1992xrea.conf    X-ray Emission from Active Galactic Nuclei and the Cosmic X-ray Background
1997xisc.conf    X-Ray Imaging and Spectroscopy of Cosmic Hot Plasmas
1985xia..conf    X-ray Instrumentation in Astronomy
1960xmxm.conf    X-ray Microscopy and X-ray Microanalysis
1994xspy.conf    X-ray solar physics from Yohkoh
2002xsac.conf    X-ray Spectroscopy of AGN with Chandra and XMM-Newton
1981xray.symp    X-ray Symposium 1981 (1981)
1975xris.conf    X-Rays in Space - Cosmic, Solar, and Auroral X-Rays, Volume 1
1996bas..conf    XXIth Meeting of the Brazilian Astronomical Society
1995bas..conf    XXth Meeting of the Brazilian Astronomical Society
1995yera.conf    The XXVIIth Young European Radio Astronomers Conference

