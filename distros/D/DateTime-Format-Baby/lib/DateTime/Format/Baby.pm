# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Perl DateTime extension for displaying a time in baby-style.
#     Copyright (C) 2003, 2015, 2016 Rick Measham and Jean Forget
#
#     See the license in the embedded documentation below.
#
package DateTime::Format::Baby;

use utf8;
use strict;
use warnings;
use vars qw($VERSION);
use DateTime;
use Carp;

$VERSION = '1.0200';

my %languages = (
    'en'      => {numbers => [qw /one two three four five six seven
                                      eight nine ten eleven twelve/],
                  format  => "The big hand is on the %s " .
                             "and the little hand is on the %s",
                  big     => [qw/big long large minute/],
                  little     => [qw/little small short hour/]},

    'br'      => {numbers => [qw /um dois três quatro cinco seis
                                     sete oito nove dez onze doze/],
                  format  => "O ponteiro grande está no %s " .
                             "e o ponteiro pequeno está no %s"},

    'de'      => {numbers => [qw /Eins Zwei Drei Vier Fünf Sechs Sieben
                                       Acht Neun Zehn Elf Zwölf/],
                  format  => "Der große Zeiger ist auf der %s " .
                             "und der kleine Zeiger ist auf der %s",
                  big     => [qw/groß lang groß Minute/],
                  little     => [qw/wenig klein Kurzschluß Stunde/]},

    'du'      => {numbers => [qw /een twee drie vier vijf zes zeven
                                      acht negen tien elf twaalf/],
                  format  => "De grote wijzer is op de %s " .
                             "en de kleine wijzer is op de %s"},

    'es'      => {numbers => [qw /uno dos tres cuatro cinco seis siete
                                      ocho nueve diez once doce/],
                  format  => "La manecilla grande está sobre el %s " .
                             "y la manecilla pequeña está sobre el %s",
                  big     => [qw/grande grande minuto/, 'de largo'],
                  little     => [qw/poco pequeño cortocircuito hora/]},
                             

    'fr'      => {numbers => [qw /un deux trois quatre cinq six sept
                                     huit neuf dix onze douze/],
                  format  => "La grande aiguille est sur le %s " .
                             "et la petite aiguille est sur le %s",
                  big     => [qw/grand long grand minute/],
                  little     => [qw/peu petit court heure/]},

    'it'      => {numbers => ['a una', 'e due', 'e tre', 'e quattro',
                                       'e cinque', 'e sei', 'e sette',
                                       'e otto', 'e nove', 'e dieci',
                                       'e undici', 'e dodici'],
                  format  => "La lancetta lunga e' sull%s " .
                             "e quella corta e' sull%s",
                  big     => [qw/grande lungamente grande minuto/],
                  little     => [qw/piccolo piccolo short ora/]},

    'no'      => {numbers => [qw /en to tre fire fem seks syv
                                     åtte ni ti elleve tolv/],
                  format  => "Den store viseren er på %s " .
                             "og den lille viseren er på %s"},

    'se'      => {numbers => [qw /ett tvÂ tre fyra fem sex sju
                                      Âtta nio tio elva tolv/],
                  format  => "Den stora visaren är på %s " .
                             "och den lilla visaren är på %s"},

    'swedish chef'
              => {numbers => [qw /one tvu three ffuoor ffeefe six
                                      sefen eight nine ten elefen tvelfe/],
                  format  => "Zee beeg hund is un zee %s und zee little " .
                             "hund is un zee %s. Bork, bork, bork!"},

    'warez'   => {numbers => [qw {()nE TW0 7HR3e f0uR f|ve 5ix 
                                       ZE\/3n E|6hT n1nE TeN 3L3v3gn 7wELv3}],
                  format  => 'T|-|3 bIG h4|\||) Yz 0n thE %s ' .
                             'and 7|-|3 lIttlE |-|aND |S 0|\| Th3 %s'},
	'custom'  => 1,
);


sub new {
    my $class = shift;
	my %args;
	if (scalar @_ == 1) {
		$args{language} = shift;
	} elsif (scalar @_ %2) {
		croak ("DateTime::Format::Baby must be given either one parameter (a language) or a hash");
	} else {
		%args = @_;
	}
	$args{language}	||= 'en';
        unless (exists $languages{$args{language}}) {
                croak "I do not know the language '$args{language}'. The languages I do know are: "
                      . join(', ', $class->languages);
        }

        $args{numbers}  ||= $languages{$args{language}}{numbers};
        $args{format}   ||= $languages{$args{language}}{format};
        $args{big}      ||= $languages{$args{language}}{big};
        $args{little}   ||= $languages{$args{language}}{little};
	
	unless ($args{numbers}) {
		croak "I have no numbers for that language.";
	}
	unless ($args{format}) {
		croak "I have no format for that language.";
	}
	
    return bless \%args, $class;
}

sub languages {
	return sort keys %languages;
}

sub language {
	my $self = shift;
	my $language = shift;
	
	if ($language) {
                unless (exists $languages{$language}) {
                        croak "I do not know the language '$language'. The languages I do know are: "
                              . join(', ', $self->languages);
                }

                $self->{language}   = $language;
                $self->{numbers}    = $languages{$language}{numbers};
                $self->{format}     = $languages{$language}{format};
                $self->{big}        = $languages{$language}{big};
                $self->{little}     = $languages{$language}{little};
	}
	return $self->{language};
}

sub parse_datetime {
    my ( $self, $date ) = @_;

    my ($littlenum,$bignum);

    if ($self->{big} && $self->{little}) {
        my $format  = $self->{format};
        my $numbers = '(' . join('|', @{$self->{numbers}}) . ')';
        my $big     = '(' . join('|', @{$self->{big}})     . ')';
        my $little  = '(' . join('|', @{$self->{little}})  . ')';

        (undef, $littlenum) = $date =~ /$little.*?$numbers/i;
        (undef, $bignum   ) = $date =~ /$big.*?$numbers/i;

    } else {
        my $regex = $self->{format};
        $regex    =~s/\%s/(\\w+)/g;
        
        ($bignum,$littlenum) = $date =~ /$regex/;
    }
            
    unless ($bignum && $littlenum) {
        croak "Sorry, I didn't understand '$date' in '" . $self->language . "'";
    }

    my %reverse;
    @reverse{map { lc } @{$self->{numbers}}} = (1..12);
    
    my $hours   = $reverse{lc($littlenum)} * 1;
    my $minutes = $reverse{lc($bignum   )} * 5;
    
    $hours-- if $minutes > 30;
    if ($minutes == 60) {
        $minutes = 0; $hours++;
    }
    return DateTime->new(year=>0, hour=>$hours, minute=>$minutes);
}

sub parse_duration {
    croak "DateTime::Format::Baby doesn't do durations.";
}

sub format_datetime {
    my ( $self, $dt ) = @_;

    my ($hours, $minutes) = ($dt->hour, $dt->minute);

    $hours ++ if $minutes > 30;

    # Turn $hours into 1 .. 12 format.
    $hours  %= 12;
    $hours ||= 12;

    # Round minutes to nearest 5 minute.
    $minutes   = sprintf "%.0f" => $minutes / 5;
    $minutes ||= 12;

    return sprintf $self->{format} => @{$self->{numbers}} [$minutes -1, $hours -1];
}

sub format_duration {
    croak "DateTime::Format::Baby doesn't do durations.";
}


# Ending a module with whatever, which risks to be zero, is wrong.
# Ending a module with 1 is boring. So, let us end it with:
1985;
# Hint: directed by CS, with RG, MB and AD
# Or 1987, directed by LN, with TS, SG and TD
__END__

=head1 NAME

DateTime::Format::Baby - Parse and format baby-style time

=head1 SYNOPSIS

  use DateTime::Format::Baby;

  my $Baby = DateTime::Format::Baby->new('en');
  my $dt = $Baby->parse_datetime('The big hand is on the twelve and the little hand is on the six.');

  $Baby->language('fr');

  print $Baby->format_datetime($dt);
  # -> La grande aiguille est sur le douze et la petite aiguille est sur le six

Extended example, with a fancy clockface (seen in L<Acme::Time::Asparagus>).

  use DateTime::Format::Baby;
  my $baby = DateTime::Format::Baby->new(language => 'en',
                                         numbers  => [
                 'Tomato',      'Eggplant',        'Carrot',     'Garlic',
                 'Green Onion', 'Pumpkin',         'Asparagus',  'Onion',
                 'Corn',        'Brussels Sprout', 'Red Pepper', 'Cabbage',
                 ]
              );
  my $dt = DateTime->new(year => 1964, month  => 10, day    => 16,
                         hour =>   17, minute => 36, second =>  0
           );

  print $baby->format_datetime($dt);
  # -> The big hand is on the Asparagus and the little hand is on the Pumpkin

=head1 DESCRIPTION

This module understands baby talk in a variety of languages.

=head1 METHODS

This class offers the following methods.

=over 4

=item * new($language) or new(%hash)

As usual, this class method returns an instance of the class.

The method can receive either a single parameter specifying the language,
or a hash with various parameters (note: not a hash reference, a real
hash, in other words a list with an even number of elements). The hash may
contain the following keys:

=over 4

=item * language

Two-char code of a language (ISO 639-1) or special cases "Swedish chef" and "warez".

=item * numbers

Array reference containing the twelve numbers on the clockface. Number "1" is in position 0,
number "2" is in position 1, until number "12" which is in position 11.

=item * format

The skeleton of the output baby-talk sentence, with C<%s> to mark where the values for the
big hand and the little hand will be inserted.

=item * big

The various names for the big hand, in an array reference. The position within
the array does not matter.

=item * little

Same thing for the little hand.

=back

=item * parse_datetime($string)

Given baby talk, this method will return a new
C<DateTime> object.

For some languages (en, de, es, fr and it) parsing uses a regexp on various synonyms
for 'big' and 'little'. For all other languages, the module only understands the same
phrase that it would give using format_datetime().

If given baby talk that it can't parse, this method may either die or get confused.
Don't try things like "The big and little hands are on the six and five, respectively."

=item * format_datetime($datetime)

Given a C<DateTime> object, this methods returns baby talk. Remember though that babies
only understand time (even then, without am/pm)

=item * language($language)

When given a language, this method sets its language appropriately.

This method returns the current language. (After processing as above)

=item * languages()

This method return a list of known languages.

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list.  See L<http://lists.perl.org/> for more details.

=head1 KNOWN ISSUES AND BUGS

No known bug, only known issues.

As Abigail said in his module L<Acme::Time::Baby>, the "Baby" part of the module name
is a misnomer, because you have to be at least a toddler to read a clockface and
describe it in a complete sentence with a correct syntax (even if a simple one). On the
other hand, the common phrase is not "toddler talk", but "baby talk". Therefore
L<Acme::Time::Baby> keeps its name L<Acme::Time::Baby> and L<DateTime::Format::Baby>
keeps its name L<DateTime::Format::Baby>.

Baby talk does not implement years, months, days or even AM/PM. It's more for amusement
than anything else.

You may think that a roundtrip like this:

  my $string       = $baby->format_datetime($datetime);
  my $new_datetime = $baby->parse_datetime($string);

should give the same value with a 5-minute fuzz factor.  This is not the case for two
reasons. As stated above, babies (or toddlers) do not understand the AM/PM factor. So
there can be a 12-hour skip in the roundtrip. The second reason is that when the time
is a few minutes past the half-hour (say xx:31 or xx:32), the small hand is not on the
same number as when the time is exactly on the half-hour. So there is a 1-hour jump
forward during such a round-trip.

As already said above, baby talk does not include convoluted sentences as: "The big and
little hands are on the six and five, respectively" or "Both hands are on the five".

=head1 AUTHOR

Rick Measham <rickm@cpan.org> (BigLug on PerlMonks)

Co-maintainer: Jean Forget (JFORGET at cpan dot org)

This code is a DateTime version of L<Acme::Time::Baby> (copyright 2002 by Abigail)
with the ability to parse strings added by Rick Measham.

=head1 CONTRIBUTIONS

Abigail's original module contained a language list that is plagarised here. 
See the documentation for L<Acme::Time::Baby> for language acknowledgements.

If you have additional language data for this module, please also pass it on to
Abigail. This module is not meant to replace the original. Rather it is a DateTime
port of that module.

=head1 COPYRIGHT

This program is copyright 2003, 2015, 2016 by Rick Measham and Jean Forget

This program is based on code that is copyright 2002 by Abigail. 

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 SEE ALSO

L<Acme::Time::Baby>

L<Acme::Time::Asparagus>

datetime@perl.org mailing list

L<http://datetime.perl.org/>

=cut
