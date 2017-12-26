#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Select AWS Polly speakers with specified characteristics
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

package Aws::Polly::Select;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Table::Text qw(:all);
use Data::Dump qw(dump);
use utf8;

our $VERSION = '20171217';

BEGIN
 {my @fields = qw(Gender Id LanguageCode LanguageName Name Written Country);    # Field names

  for my $field(@fields)                                                        # Generate methods to get attributes from each speaker
   {package Aws::Polly::Select::Speaker;
    Data::Table::Text::genLValueScalarMethods($field);
   }

  for my $field(@fields)                                                        # Generate methods that get all the values of each attribute of each speaker
   {my $s = <<'END';
sub XXX {&fieldValues("XXX")}
END
    $s =~ s(XXX) ($field)gs;
    eval $s;
    $@ and confess $@;
   }
 }

sub fieldValues($)                                                              # All the values a specified field can take
 {my ($field) = @_;
  my %l;
  my @s = @{&speakerDetails};
  for my $speaker(@s)
   {if (my $v = $speaker->{$field})
     {$l{$v}++
     }
   }
  sort keys %l;
 }

#-------------------------------------------------------------------------------
# Select speakers
#-------------------------------------------------------------------------------

sub speaker(@)                                                                  # Select speakers by fields
 {my (%selection) = @_;                                                         # Selection fields: name=>"regular expression" where the field of that name must match the regular expression regardless of case
  my @s;
  for my $speaker(@{&speakerDetails})                                           # Check each speaker
   {my $m = 1;                                                                  # Speaker matches so far
    for my $field(keys %selection)                                              # Continue with the speaker as long as they match on all the supplied fields -  these fields are our shorter simpler names not AWS's longer more complicated names
     {last unless $m;
      my $r = $selection{$field};                                               # Regular expression to match
      my $v = $speaker->{$field};                                               # Value of this field for this speaker
      confess "No such field: $field" unless $v;
      $m = $v =~ m/$r/;                                                         # Case insensitive
     }
    push @s, $speaker if $m;                                                    # Exclude potential speaker unless they match all valid fields
   }
  sort {$a->Id cmp $b->Id} @s
 }

#-------------------------------------------------------------------------------
# Blessed speaker details
#-------------------------------------------------------------------------------

sub speakerDetails
 {my $s = &speakerDetailsFromAWS;
  for(@$s)
   {package Aws::Polly::Select::Speaker;
    bless $_;
    ($_->Written) = split /-/, $_->LanguageCode;                                # Add written code
   }
  $s
 }

#-------------------------------------------------------------------------------
# Speaker ids as a hash
#-------------------------------------------------------------------------------

sub speakerIds
 {my $s = speakerDetails;
   +{map{$_->Id => $_} @$s}
 }

#-------------------------------------------------------------------------------
# Speaker details from AWS via:
#  renewSpeakerDetailsButOnlyWhenAWSChangesTheListOfSpeakers()
#-------------------------------------------------------------------------------

sub speakerDetailsFromAWS
 {[
  {  Gender => "Female",
    Id => "Gwyneth",
    LanguageCode => "cy-GB",
    LanguageName => "Welsh",
    Name => "Gwyneth",
  },
  {
    Gender => "Female",
    Id => "Naja",
    LanguageCode => "da-DK",
    LanguageName => "Danish",
    Name => "Naja",
  },
  {
    Gender => "Male",
    Id => "Mads",
    LanguageCode => "da-DK",
    LanguageName => "Danish",
    Name => "Mads",
  },
  {
    Gender => "Female",
    Id => "Vicki",
    LanguageCode => "de-DE",
    LanguageName => "German",
    Name => "Vicki",
  },
  {
    Gender => "Female",
    Id => "Marlene",
    LanguageCode => "de-DE",
    LanguageName => "German",
    Name => "Marlene",
  },
  {
    Gender => "Male",
    Id => "Hans",
    LanguageCode => "de-DE",
    LanguageName => "German",
    Name => "Hans",
  },
  {
    Gender => "Male",
    Id => "Russell",
    LanguageCode => "en-AU",
    LanguageName => "Australian English",
    Name => "Russell",
  },
  {
    Gender => "Female",
    Id => "Nicole",
    LanguageCode => "en-AU",
    LanguageName => "Australian English",
    Name => "Nicole",
  },
  {
    Gender => "Female",
    Id => "Emma",
    LanguageCode => "en-GB",
    LanguageName => "British English",
    Name => "Emma",
  },
  {
    Gender => "Male",
    Id => "Brian",
    LanguageCode => "en-GB",
    LanguageName => "British English",
    Name => "Brian",
  },
  {
    Gender => "Female",
    Id => "Amy",
    LanguageCode => "en-GB",
    LanguageName => "British English",
    Name => "Amy",
  },
  {
    Gender => "Male",
    Id => "Geraint",
    LanguageCode => "en-GB-WLS",
    LanguageName => "Welsh English",
    Name => "Geraint",
  },
  {
    Gender => "Female",
    Id => "Aditi",
    LanguageCode => "en-IN",
    LanguageName => "Indian English",
    Name => "Aditi",
  },
  {
    Gender => "Female",
    Id => "Raveena",
    LanguageCode => "en-IN",
    LanguageName => "Indian English",
    Name => "Raveena",
  },
  {
    Gender => "Female",
    Id => "Joanna",
    LanguageCode => "en-US",
    LanguageName => "US English",
    Name => "Joanna",
  },
  {
    Gender => "Female",
    Id => "Salli",
    LanguageCode => "en-US",
    LanguageName => "US English",
    Name => "Salli",
  },
  {
    Gender => "Male",
    Id => "Matthew",
    LanguageCode => "en-US",
    LanguageName => "US English",
    Name => "Matthew",
  },
  {
    Gender => "Female",
    Id => "Kimberly",
    LanguageCode => "en-US",
    LanguageName => "US English",
    Name => "Kimberly",
  },
  {
    Gender => "Female",
    Id => "Kendra",
    LanguageCode => "en-US",
    LanguageName => "US English",
    Name => "Kendra",
  },
  {
    Gender => "Male",
    Id => "Justin",
    LanguageCode => "en-US",
    LanguageName => "US English",
    Name => "Justin",
  },
  {
    Gender => "Male",
    Id => "Joey",
    LanguageCode => "en-US",
    LanguageName => "US English",
    Name => "Joey",
  },
  {
    Gender => "Female",
    Id => "Ivy",
    LanguageCode => "en-US",
    LanguageName => "US English",
    Name => "Ivy",
  },
  {
    Gender => "Male",
    Id => "Enrique",
    LanguageCode => "es-ES",
    LanguageName => "Castilian Spanish",
    Name => "Enrique",
  },
  {
    Gender => "Female",
    Id => "Conchita",
    LanguageCode => "es-ES",
    LanguageName => "Castilian Spanish",
    Name => "Conchita",
  },
  {
    Gender => "Female",
    Id => "Penelope",
    LanguageCode => "es-US",
    LanguageName => "US Spanish",
    Name => "Penélope,",
  },
  {
    Gender => "Male",
    Id => "Miguel",
    LanguageCode => "es-US",
    LanguageName => "US Spanish",
    Name => "Miguel",
  },
  {
    Gender => "Female",
    Id => "Chantal",
    LanguageCode => "fr-CA",
    LanguageName => "Canadian French",
    Name => "Chantal",
  },
  {
    Gender => "Male",
    Id => "Mathieu",
    LanguageCode => "fr-FR",
    LanguageName => "French",
    Name => "Mathieu",
  },
  {
    Gender => "Female",
    Id => "Celine",
    LanguageCode => "fr-FR",
    LanguageName => "French",
    Name => "Céline",
  },
  {
    Gender => "Male",
    Id => "Karl",
    LanguageCode => "is-IS",
    LanguageName => "Icelandic",
    Name => "Karl",
  },
  {
    Gender => "Female",
    Id => "Dora",
    LanguageCode => "is-IS",
    LanguageName => "Icelandic",
    Name => "Dóra",
  },
  {
    Gender => "Male",
    Id => "Giorgio",
    LanguageCode => "it-IT",
    LanguageName => "Italian",
    Name => "Giorgio",
  },
  {
    Gender => "Female",
    Id => "Carla",
    LanguageCode => "it-IT",
    LanguageName => "Italian",
    Name => "Carla",
  },
  {
    Gender => "Male",
    Id => "Takumi",
    LanguageCode => "ja-JP",
    LanguageName => "Japanese",
    Name => "Takumi",
  },
  {
    Gender => "Female",
    Id => "Mizuki",
    LanguageCode => "ja-JP",
    LanguageName => "Japanese",
    Name => "Mizuki",
  },
  {
    Gender => "Female",
    Id => "Seoyeon",
    LanguageCode => "ko-KR",
    LanguageName => "Korean",
    Name => "Seoyeon",
  },
  {
    Gender => "Female",
    Id => "Liv",
    LanguageCode => "nb-NO",
    LanguageName => "Norwegian",
    Name => "Liv",
  },
  {
    Gender => "Male",
    Id => "Ruben",
    LanguageCode => "nl-NL",
    LanguageName => "Dutch",
    Name => "Ruben",
  },
  {
    Gender => "Female",
    Id => "Lotte",
    LanguageCode => "nl-NL",
    LanguageName => "Dutch",
    Name => "Lotte",
  },
  {
    Gender => "Female",
    Id => "Maja",
    LanguageCode => "pl-PL",
    LanguageName => "Polish",
    Name => "Maja",
  },
  {
    Gender => "Male",
    Id => "Jan",
    LanguageCode => "pl-PL",
    LanguageName => "Polish",
    Name => "Jan",
  },
  {
    Gender => "Female",
    Id => "Ewa",
    LanguageCode => "pl-PL",
    LanguageName => "Polish",
    Name => "Ewa",
  },
  {
    Gender => "Male",
    Id => "Jacek",
    LanguageCode => "pl-PL",
    LanguageName => "Polish",
    Name => "Jacek",
  },
  {
    Gender => "Female",
    Id => "Vitoria",
    LanguageCode => "pt-BR",
    LanguageName => "Brazilian Portuguese",
    Name => "Vitória",
  },
  {
    Gender => "Male",
    Id => "Ricardo",
    LanguageCode => "pt-BR",
    LanguageName => "Brazilian Portuguese",
    Name => "Ricardo",
  },
  {
    Gender => "Female",
    Id => "Ines",
    LanguageCode => "pt-PT",
    LanguageName => "Portuguese",
    Name => "Inês",
  },
  {
    Gender => "Male",
    Id => "Cristiano",
    LanguageCode => "pt-PT",
    LanguageName => "Portuguese",
    Name => "Cristiano",
  },
  {
    Gender => "Female",
    Id => "Carmen",
    LanguageCode => "ro-RO",
    LanguageName => "Romanian",
    Name => "Carmen",
  },
  {
    Gender => "Female",
    Id => "Tatyana",
    LanguageCode => "ru-RU",
    LanguageName => "Russian",
    Name => "Tatyana",
  },
  {
    Gender => "Male",
    Id => "Maxim",
    LanguageCode => "ru-RU",
    LanguageName => "Russian",
    Name => "Maxim",
  },
  {
    Gender => "Female",
    Id => "Astrid",
    LanguageCode => "sv-SE",
    LanguageName => "Swedish",
    Name => "Astrid",
  },
  {
    Gender => "Female",
    Id => "Filiz",
    LanguageCode => "tr-TR",
    LanguageName => "Turkish",
    Name => "Filiz",
  },
  ];
 }

#-------------------------------------------------------------------------------
# Test
#-------------------------------------------------------------------------------

sub test
 {eval join('', <Aws::Polly::Select::DATA>) || die $@
 }

test unless caller();

# Documentation
#extractDocumentation unless caller;

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

1;

=pod

=encoding utf-8

=head1 Name

Aws::Polly::Select - Select AWS Polly speakers with specified characteristics

=head1 Synopsis

 use Aws::Polly::Select;

 my ($speaker)  =  Aws::Polly::Select::speaker
   LanguageCode => qr(us)i,
   Gender       => qr(female)i,
   LanguageName => qr(Spanish)i;

 ok $speaker->Id eq q(Penelope);

=head1 Description

 Aws::Polly::Select::speaker(key=>qr(value), ...)

Returns zero or more Amazon Web Services Polly speaker definitions which match
the hash of characteristics provided. Each hash B<key> must name one of the
B<KEY>s given below, the value for the key should be a regular expression to
select against the possible B<VALUES> listed beside each key.  Please take care
with the case of the values or use B<qr(...)i> to make the selection case
insensitive.

  KEY           VALUES

  Gender        Female Male

  Id            Aditi Amy Astrid Brian Carla Carmen Celine Chantal Conchita
                Cristiano Dora Emma Enrique Ewa Filiz Geraint Giorgio Gwyneth Hans Ines Ivy
                Jacek Jan Joanna Joey Justin Karl Kendra Kimberly Liv Lotte Mads Maja Marlene
                Mathieu Matthew Maxim Miguel Mizuki Naja Nicole Penelope Raveena Ricardo Ruben
                Russell Salli Seoyeon Takumi Tatyana Vicki Vitoria

  LanguageCode  cy-GB da-DK de-DE en-AU en-GB en-GB-WLS en-IN en-US es-ES es-US
                fr-CA fr-FR is-IS it-IT ja-JP ko-KR nb-NO nl-NL pl-PL pt-BR pt-PT ro-RO ru-RU
                sv-SE tr-TR

  LanguageName  Australian English Brazilian Portuguese British English Canadian
                French Castilian Spanish Danish Dutch French German Icelandic Indian English
                Italian Japanese Korean Norwegian Polish Portuguese Romanian Russian Swedish
                Turkish US English US Spanish Welsh Welsh English

  Written       cy da de en es fr is it ja ko nb nl pl pt ro ru sv tr

The above B<KEY>s can be used as methods to get the corresponding B<VALUE>'s
from each speaker defintion returned by L<select|/select>.

  ok $speaker->LanguageCode eq q(es-US);

=head2 speakerIds()

Use speakerIds() to get a hash of speaker details by speaker id:

  my $speaker = Aws::Polly::Select::speakerIds->{Vicki};

  is_deeply $speaker,
   {Gender       => "Female",
    Id           => "Vicki",
    LanguageCode => "de-DE",
    LanguageName => "German",
    Name         => "Vicki",
    Written      => "de",
   };

Each of the fields describing a speaker may be accessed as a method, for example:

  ok $speaker->Gender       eq "Female";
  ok $speaker->LanguageName eq "German";
  ok $speaker->Written      eq "de";

=head1 Installation

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut

__DATA__
use Test::More tests=>14;

my @gender = Aws::Polly::Select::Gender;
is_deeply [@gender], [qw(Female Male)], "Gender";

my @id = Aws::Polly::Select::Id;
is_deeply [@id], [qw(Aditi Amy Astrid Brian Carla Carmen Celine Chantal),
                  qw(Conchita Cristiano Dora Emma Enrique Ewa Filiz),
                  qw(Geraint Giorgio Gwyneth Hans Ines Ivy Jacek Jan Joanna),
                  qw(Joey Justin Karl Kendra Kimberly Liv Lotte Mads Maja),
                  qw(Marlene Mathieu Matthew Maxim Miguel Mizuki Naja Nicole),
                  qw(Penelope Raveena Ricardo Ruben Russell Salli Seoyeon),
                  qw(Takumi Tatyana Vicki Vitoria)], "Id";

my @lc = Aws::Polly::Select::LanguageCode;
is_deeply [@lc], [qw(cy-GB da-DK de-DE en-AU en-GB en-GB-WLS en-IN en-US),
                  qw(es-ES es-US fr-CA fr-FR is-IS it-IT ja-JP ko-KR nb-NO),
                  qw(nl-NL pl-PL pt-BR pt-PT ro-RO ru-RU sv-SE tr-TR)],
                  "LanguageCode";

my @ln = Aws::Polly::Select::LanguageName;
is_deeply [@ln], [
  "Australian English",
  "Brazilian Portuguese",
  "British English",
  "Canadian French",
  "Castilian Spanish",
  "Danish",
  "Dutch",
  "French",
  "German",
  "Icelandic",
  "Indian English",
  "Italian",
  "Japanese",
  "Korean",
  "Norwegian",
  "Polish",
  "Portuguese",
  "Romanian",
  "Russian",
  "Swedish",
  "Turkish",
  "US English",
  "US Spanish",
  "Welsh",
  "Welsh English",
], "LanguageName";

my @written = Aws::Polly::Select::Written;
is_deeply [@written],
          [qw(cy da de en es fr is it ja ko nb nl pl pt ro ru sv tr)],
          "Written";

is_deeply [map{$_->Id} &Aws::Polly::Select::speaker(qw(Written en))],
          [qw(Aditi Amy Brian Emma Geraint Ivy Joanna Joey Justin),
           qw(Kendra Kimberly Matthew Nicole Raveena Russell Salli)], "en";

is_deeply [map{$_->Id} &Aws::Polly::Select::speaker(qw(LanguageCode en-GB))],
          [qw(Amy Brian Emma Geraint)], "en-GB";

is_deeply [map{$_->Id} &Aws::Polly::Select::speaker(
           LanguageCode=>qr(gb)i, Gender=>qr(female)i)],
           [qw(Amy Emma Gwyneth)], "en-GB, female";

is_deeply [qw(Penelope)],
          [map {$_->Id} Aws::Polly::Select::speaker
             LanguageCode=>qr(us)i,
             Gender      =>qr(female)i,
             LanguageName=>qr(Spanish)i], "Penelope";

if (0)                                                                          # Get new speakers
 {my %old =                              map {$_->{Name}=>1} @{&speakerDetails};
  my %new = map {$_=>1} grep {!$old{$_}} map {$_->{Name}}    renewSpeakerDetailsButOnlyWhenAWSChangesTheListOfSpeakers;
  say STDERR "New speakers  = ", dump(\%new) ;
 }

if (0)                                                                          # Write speaker specifications for documentation
 {my $s;
  my @fields = qw(Gender Id LanguageCode LanguageName Written);
  for my $f(@fields)
   {$s->{$f} = {map {$_->{$f}=>1} @{&speakerDetails}};
   }
  my %lc =  map {substr($_, 0, 2)=>1} keys %{$s->{LanguageCode}};
  my @r;
  push @r, [qw(KEY VALUES)],
           ["Written", join ' ', sort keys %lc];
  for my $f (@fields)
   {push @r, [$f,        join ' ', sort keys %{$s->{$f}}];
   }
  say STDERR indentString(formatTableBasic(\@r), '  ');
 }

if (1)
 {my ($speaker) = Aws::Polly::Select::speaker
    LanguageCode=>qr(us)i,
    Gender      =>qr(female)i,
    LanguageName=>qr(Spanish)i;

  ok $speaker->Id eq q(Penelope);
 }

is_deeply speakerIds->{Vicki},
  {Gender       => "Female",
    Id           => "Vicki",
    LanguageCode => "de-DE",
    LanguageName => "German",
    Name         => "Vicki",
    Written      => "de",
   };

if (1)
 {my $speaker  = speakerIds->{Vicki};
  ok $speaker->Gender       eq "Female";
  ok $speaker->LanguageName eq "German";
  ok $speaker->Written      eq "de";
 }
