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

our $VERSION = '2017.444';

#-------------------------------------------------------------------------------
# Load speakers
#-------------------------------------------------------------------------------

sub speaker($)                                                                  # Construct a speaker
 {my ($speaker) = @_;                                                           # Speaker details
  package Aws::Polly::Select::Speaker;
  my %l;
  my %p = %$speaker;
  my ($gender, $name, $code, $language) = @p{qw(Gender Id LanguageCode LanguageName)};
  my ($base, $country) = split /-/, $code;
  $gender = lc($gender);
  $language =~ s/\s/-/g;
  bless{name=>$name, gender=>$gender, speaking=>$language,
        written=>$base, country=>lc($country), code=>$code};

  BEGIN                                                                         # Fields and projections
   {for(qw(name gender speaking written country code))
     {Data::Table::Text::genLValueScalarMethods($_);
      package Aws::Polly::Select;
      eval <<END;                                                               # Possible field values as a string
sub $_
 {my %l = map {\$_->$_=>1} &speakers;
  join ' ', sort keys %l;
 }
END
      $@ and confess $@;

      eval <<END;                                                               # Possible field values as an array
sub ${_}AsArray
 {my %l = map {\$_->$_=>1} &speakers;
  sort keys %l;
 }
END
      $@ and confess $@;
     }
   }
 }

sub speakers {map {speaker($_)} @{&speakerDetails}}                             # Speakers

#-------------------------------------------------------------------------------
# Select speakers
#-------------------------------------------------------------------------------

sub select(@)                                                                   ## Select speakers by fields
 {my (%selection) = @_;                                                         # Selection fields: name=>"regular expression" where the field of that name must match the regular expression regardless of case
  my @s;
  for my $speaker(speakers)
   {my $m = 1;
    for my $field(keys %selection)
     {last unless $m;
      my $r = $selection{$field};
      my $v = $speaker->{$field};
      confess "No such field: $field" unless $v;
      $m = $v =~ m/$r/i;                                                        # Case insensitive
     }
    push @s, $speaker if $m;                                                    # Exclude potential speaker unless they match all valid fields
   }
  sort {$a->name cmp $b->name} @s
 }

#-------------------------------------------------------------------------------
# Renew speaker details, but only when AWS changes the list of speakers
#-------------------------------------------------------------------------------

sub Aws::Polly::Select::Speaker::generateSpeech($$$)
 {my ($speaker, $text, $outFile) = @_;                                          # Speaker definition, text, output file

  my $tmpFile = $outFile.'.temp';
  my $speakerId = $speaker->name;
  makePath($outFile);

  if (1)                                                                        # Create speech using Polly
   {my $c = "aws polly synthesize-speech ".
      "--output-format mp3 --text \"$text\" --voice-id $speakerId $tmpFile";
    say STDERR $c;
    print STDERR $_ for qx($c);
   }

  my $maxVol = 1 ? sub                                                          # Find volume
   {my $c = "ffmpeg -i $tmpFile -af \"volumedetect\" -f null /dev/null";
    say STDERR $c;
    my @l = grep {/max_volume: /} qx($c 2>&1);
    if ($l[0] =~ /max_volume: (\S+) dB/)
     {my $v = -$1;
      return "volume=${v}dB"
     }
    ''
   }->() : "volume=1dB";

  if (1)                                                                        # Normalize volume
   {my $filter  = " -af \"$maxVol\"";
    my $c = "ffmpeg -nostats -y -i $tmpFile $filter $outFile";                  # ffmpeg command
    say STDERR $c;
    print STDERR $_ for qx($c);
    unlink $tmpFile;
   }
 }

#-------------------------------------------------------------------------------
# Renew speaker details, but only when AWS changes the list of speakers
#-------------------------------------------------------------------------------

sub renewSpeakerDetailsButOnlyWhenAWSChangesTheListOfSpeakers
 {my $c = "aws polly describe-voices";
  my $j = qx($c);
  my $p = decode_json $j;
  my @voices = sort {$a->{LanguageCode} cmp $b->{LanguageCode}} @{$p->{Voices}};
  say STDERR dump([@voices]);
 }

#-------------------------------------------------------------------------------
# Speaker details from AWS via the method above
#-------------------------------------------------------------------------------

sub speakerDetails{[
  {
    Gender => "Female",
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
    Name => "Pen\xE9lope",
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
    Name => "C\xE9line",
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
    Name => "D\xF3ra",
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
    Gender => "Female",
    Id => "Mizuki",
    LanguageCode => "ja-JP",
    LanguageName => "Japanese",
    Name => "Mizuki",
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
    Name => "Vit\xF3ria",
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
    Name => "In\xEAs",
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
    Gender => "Male",
    Id => "Maxim",
    LanguageCode => "ru-RU",
    LanguageName => "Russian",
    Name => "Maxim",
  },
  {
    Gender => "Female",
    Id => "Tatyana",
    LanguageCode => "ru-RU",
    LanguageName => "Russian",
    Name => "Tatyana",
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
 ]}

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

 ok qw(Penelope) eq  join " ", map {$_->name}

   Aws::Polly::Select::select

     country=>qr(us), gender=>qr(female), speaking=>qr(Spanish);

=head1 Description

 Aws::Polly::Select::select(key=>qr(value), ...)

Returns zero or more Amazon Web Services Polly speaker definitions which match
the hash of characteristics provided. Each hash key must name one of the
b<KEY>s given below, the value for the key should be a regular expression to
select against the possible b<VALUES> listed beside each key.  Please take care
with case or code qr()i;

 KEY        VALUES

 written    cy da de en es fr is it ja nb nl pl pt ro ru sv tr

 code       cy-GB da-DK de-DE en-AU en-GB en-GB-WLS en-IN en-US
            es-ES es-US fr-CA fr-FR is-IS it-IT     ja-JP nb-NO
            nl-NL pl-PL pt-BR pt-PT ro-RO ru-RU     sv-SE tr-TR

 country    au br ca de dk es fr gb in is it jp nl no pl pt ro ru se tr us

 gender     Female Male

 speaking   Australian-English Brazilian-Portuguese British-English
            Canadian-French Castilian-Spanish Danish Dutch French German
            Icelandic Indian-English Italian Japanese Norwegian Polish Portuguese
            Romanian Russian Swedish Turkish US-English US-Spanish Welsh
            Welsh-English

The returned speaker definitions have the following B<METHOD>s which will yield
one of th specified b<VALUES> for each speaker definition:

 METHOD     VALUES

 written    cy da de en es fr is it ja nb nl pl pt ro ru sv tr

 code       cy-GB da-DK de-DE en-AU en-GB en-GB-WLS en-IN en-US es-ES es-US
            fr-CA fr-FR is-IS it-IT ja-JP nb-NO     nl-NL pl-PL pt-BR pt-PT
            ro-RO ru-RU sv-SE tr-TR

 name       Amy Astrid Brian Carla Carmen Celine Chantal Conchita Cristiano
            Dora Emma Enrique Ewa Filiz Geraint Giorgio Gwyneth Hans Ines Ivy
            Jacek Jan Joanna Joey Justin Karl Kendra Kimberly Liv Lotte Mads
            Maja Marlene Mathieu Maxim Miguel Mizuki Naja Nicole Penelope
            Raveena Ricardo Ruben Russell Salli Tatyana Vitoria

 speaking   Australian-English Brazilian-Portuguese British-English
            Canadian-French Castilian-Spanish Danish Dutch French German
            Icelandic Indian-English Italian Japanese Norwegian Polish
            Portuguese Romanian Russian Swedish Turkish US-English US-Spanish
            Welsh Welsh-English

 gender     female male

 country    au br ca de dk es fr gb in is it jp nl no pl pt ro ru se tr us


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
use Test::More tests=>11;

ok join(" ", Aws::Polly::Select::written)  eq join(" ", qw(cy da de en es fr is it ja nb nl pl pt ro ru sv tr));
ok join(" ", Aws::Polly::Select::code)     eq join(" ", qw(cy-GB da-DK de-DE en-AU en-GB en-GB-WLS en-IN en-US es-ES es-US fr-CA fr-FR is-IS it-IT ja-JP nb-NO nl-NL pl-PL pt-BR pt-PT ro-RO ru-RU sv-SE tr-TR));
ok join(" ", Aws::Polly::Select::name)     eq join ' ', qw(Amy Astrid Brian Carla Carmen Celine Chantal Conchita Cristiano Dora Emma Enrique Ewa Filiz Geraint Giorgio Gwyneth Hans Ines Ivy Jacek Jan Joanna Joey Justin Karl Kendra Kimberly Liv Lotte Mads Maja Marlene Mathieu Maxim Miguel Mizuki Naja Nicole Penelope Raveena Ricardo Ruben Russell Salli Tatyana Vitoria);
ok join(" ", Aws::Polly::Select::speaking)   eq join ' ', qw(Australian-English Brazilian-Portuguese British-English Canadian-French Castilian-Spanish Danish Dutch French German Icelandic Indian-English Italian Japanese Norwegian Polish Portuguese Romanian Russian Swedish Turkish US-English US-Spanish Welsh Welsh-English);
ok join(" ", Aws::Polly::Select::gender)   eq join ' ', qw(female male);
ok join(" ", Aws::Polly::Select::country)  eq join ' ', qw(au br ca de dk es fr gb in is it jp nl no pl pt ro ru se tr us);
ok join(" ", map{$_->name} &Aws::Polly::Select::select(qw(written en)))                              eq join(' ', qw(Amy Brian Emma Geraint Ivy Joanna Joey Justin Kendra Kimberly Nicole Raveena Russell Salli));
ok join(" ", map{$_->name} &Aws::Polly::Select::select(qw(code en-GB)))                              eq join(' ', qw(Amy Brian Emma Geraint));
ok join(" ", map{$_->name} &Aws::Polly::Select::select(qw(country gb gender female)))                eq join(' ', qw(Amy Emma Gwyneth));
ok qw(Penelope) eq  join " ", map {$_->name} Aws::Polly::Select::select qw(country us gender female speaking Spanish);
ok qw(Penelope) eq  join " ", map {$_->name} Aws::Polly::Select::select country=>qr(us), gender=>qr(female), speaking=>qr(Spanish);
