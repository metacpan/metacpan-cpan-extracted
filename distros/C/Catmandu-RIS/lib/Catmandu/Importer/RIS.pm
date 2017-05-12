package Catmandu::Importer::RIS;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Importer::CSV;
use Catmandu::Util qw(:is :array);
use Moo;

with 'Catmandu::Importer';

has sep_char => (is => 'ro', default => sub {'\s+-?\s*'});
has human    => (is => 'ro');
has ris      => (is => 'lazy');

sub _build_ris {
    my $self = shift;
    my $hash = {};

    if ($self->human && -r $self->human) {
      my $importer = Catmandu->importer('CSV', 
        file => $self->human, 
        header => 0 , 
        fields => 'name,value' ,
        sep_char => ',',
      );
      $importer->each(sub {
          my $item = shift;
          $hash->{$item->{name}} = $item->{value};
      });
    }
    else {
      while(<DATA>) {
          chomp;
          my ($n,$v) = split('\s*,\s*',$_,2);
          $hash->{$n} = $v;
      }
    }
    $hash;
}

sub generator {
    my ($self) = @_;
    sub {
        state $fh = $self->fh;
        state $sep_char = $self->sep_char;
        state $pattern  = qr/$sep_char/;
        state $line;
        state $data;
        my $previous_key= '';
        while($line = <$fh>) {

            chomp($line);
            next if $line eq '';
            # Remove BOM
            $line =~ s/^\x{feff}//;
            $line =~ s/^\s\s/$previous_key/;

            my ($key,$val) = split($pattern,$line,2);

            if ($key eq 'ER') {
                my $tmp = $data;
                $data = {};
                return $tmp;
            }
            else {
                $key = $self->ris->{$key} if $self->human && exists $self->ris->{$key};

                $previous_key = $key;
                $val =~ s/\r// if defined $val;
                # handle repeated fields
                if ($data->{$key}) {
                  $data->{$key} = [ grep { is_string $_ } @{$data->{$key}} ] if is_array_ref $data->{$key};
                	$data->{$key} = [ $data->{$key} ] if is_string $data->{$key};
                  push @{$data->{$key}}, $val;
                } else {
                  $data->{$key} = $val;
                }
            } 
        }
        return undef;
    };
}

1;

=head1 NAME

Catmandu::Importer::RIS - a RIS importer

=head1 SYNOPSIS

Command line interface:

  catmandu convert RIS < input.txt

  # Use the --human option to translate RIS tags into human readable strings
  catmandu convert RIS --human 1 < input.txt

  # Provide a comma separated mapping file to translate RIS tags
  catmandu convert RIS --human mappings/my_tags.txt < input.txt

In Perl code:

  use Catmandu::Importer::RIS;

  my $importer = Catmandu::Importer::RIS->new(file => "/foo/bar.txt");

  my $n = $importer->each(sub {
    my $hashref = $_[0];
    # ...
  });

=head1 CONFIGURATION

=over

=item sep_char

Set a field separator

=item human 

If set to 1, then RIS tries to translate tags into human readable strings. If set to
a file name, then RIS will read the file as a comma delimited lists of tag/string
translations. E.g.

    catmandu convert RIS --human mappings/my_tags.txt < input.txt

where mappings/my_tags.txt like:

    A2,Secondary-Author 
    A3,Tertiary-Author 
    A4,Subsidiary-Author 
    AB,Abstract 
    AD,Author-Address 
    AF,Notes
    .
    .
    .

=back

=head1 METHODS

=head2 new(file => $filename, fh => $fh , fix => [...])

Create a new RIS importer for $filename. Use STDIN when no filename is given.

The constructor inherits the fix parameter from L<Catmandu::Fixable>. When given,
then any fix or fix script will be applied to imported items.

=head2 count

=head2 each(&callback)

=head2 ...

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

__DATA__
TY,Type-of-Reference
ER,End-of-Reference
A2,Secondary-Author
A3,Tertiary-Author
A4,Subsidiary-Author
AB,Abstract
AD,Author-Address
AF,Notes
AN,Accession-Number
AU,Author
BP,Beginning-Page
BS,Book-Series-Subtitle
C1,Custom-1
C2,Custom-2
C3,Custom-3
C4,Custom-4
C5,Custom-5
C6,Custom-6
C7,Custom-7
C8,Custom-8
CA,Caption
CP,Cited-Patent
CR,Cited-References
CY,Place-Published
DA,Date
DB,Name-of-Database
DE,Author-Keywords
DO,DOI
DP,Database-Provide
DT,Document-Type
EM,Email-Address
EP,Ending-Page
ET,Edition
FN,File-Type
GA,ISI-Document-Delivery-Number
IS,Issue
J2,Alternate-Title
J9,29-Character-Source-Title-Abreviation
JI,ISO-Source-Title-Abbreviation
KW,Keywords
L1,File-Attachments
L4,Figure
LA,Language
LB,Label
ID,KeyWords-Plus
IS,Number
M3,Type-of-Work
N1,Notes
NR,Cited-Reference-Count
NV,Number-of-Volumes
OP,Original-Publication
PA,Publisher-Address
PB,Publisher
PD,Publication-Date
PG,Page-Count
PI,Publisher-City
PN,Part-Number
PT,Publication-Type
PU,Publisher
PY,Year
RP,Reprint-Address
SC,Research-Area
SE,Book-Series-Title
SI,Special-Issue
SN,ISSN
SO,Full-Source-Title
SU,Supplement
TI,Title
TC,Times-Cited
UT,ISI-Unique-Article-Identifier
VL,Volume
VR,File-Format-Version-Number
WC,Web-of-Science-Categories
WP,Publisher-Web-Address