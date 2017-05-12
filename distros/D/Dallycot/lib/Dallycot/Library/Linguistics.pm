package Dallycot::Library::Linguistics;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Core library of useful functions for functions

use strict;
use warnings;

use utf8;
use Dallycot::Library;

use Dallycot::Context;
use Dallycot::Parser;
use Dallycot::Processor;

use Dallycot::TextResolver;

use Lingua::StopWords;

BEGIN {
  eval {
    require Lingua::YALI::LanguageIdentifier;
  }
}
# use Lingua::ConText;
use Lingua::Sentence;

use Carp qw(croak);
use Promises qw(deferred collect);

use Mojo::DOM;

use experimental qw(switch);

ns 'http://www.dallycot.net/ns/linguistics/1.0#';

#====================================================================
#
# Textual/Linguistic functions

define 'sentences' => (
  hold => 0,
  arity => 1,
  options => {}
), sub {
  my( $engine, $options, $text ) = @_;

  if(!$text -> isa('Dallycot::Value::String')) {
    croak 'sentences expects a string text';
  }

  my $splitter = Lingua::Sentence->new($text->lang);

  return Dallycot::Value::Vector->new(
    map { Dallycot::Value::String->new($_) }
    split(/\n/, $splitter->split($text->value))
  );
};

# define 'clinical-context' => (
#   hold => 0,
#   arity => 2,
#   options => {}
# ), sub {
#   my( $engine, $options, $concept, $text ) = @_;
#
#   if(!$concept->isa('Dallycot::Value::String')) {
#     croak 'context expects a string concept';
#   }
#   if(!$text->isa('Dallycot::Value::String')) {
#     croak 'context expects a string text';
#   }
#
#   my $result = Lingua::ConText::applyContext(
#     $concept->value,
#     $text->value
#   );
#
#   return Dallycot::Value::Vector->new(
#     map { Dallycot::Value::String -> new($_) }
#     @{$result}
#   );
# };

define
  'stop-words' => (
  hold    => 0,
  arity   => 1,
  options => {}
  ),
  sub {
  my ( $engine, $options, $language ) = @_;

  my $d = deferred;

  if ( !$language->isa('Dallycot::Value::String') ) {
    $d->reject("stop-words expects a string argument");
  }
  else {
    my $lang  = $language->value;
    my @words = sort
      keys %{ Lingua::StopWords::getStopWords( $lang, 'UTF-8' ) || {} };
    $d->resolve( Dallycot::Value::Vector->new( map { Dallycot::Value::String->new( $_, $lang ) } @words ) );
  }

  return $d->promise;
  };

my %language_codes_for_classifier = qw(
  af afr
  am amh
  ar ara
  an arg
  az aze
  be bel
  bn ben
  bs bos
  br bre
  bg bul
  ca cat
  cs ces
  cv chv
  co cos
  cy cym
  da dan
  de deu
  el ell
  en eng
  eo epo
  et est
  eu eus
  fo fao
  fa fas
  fi fin
  fr fra
  fy fry
  gd gla
  ga gle
  gl glg
  gu guj
  ht hat
  sh hbs
  he heb
  hi hin
  hr hrv
  hu hun
  hy hye
  io ido
  ia ina
  id ind
  is isl
  it ita
  jv jav
  ja jpn
  kn kan
  ka kat
  kk kaz
  ko kor
  ku kur
  la lat
  lv lav
  li lim
  lt lit
  lb ltz
  ml mal
  mr mar
  mk mkd
  mg mlg
  mn mon
  mi mri
  ms msa
  my mya
  ne nep
  nl nld
  nn nno
  no nor
  oc oci
  os oss
  pl pol
  pt por
  qu que
  ro ron
  ru rus
  sk slk
  sl slv
  es spa
  sq sqi
  sr srp
  su sun
  sw swa
  sv swe
  ta tam
  tt tat
  te tel
  tg tgk
  tl tgl
  th tha
  tr tur
  uk ukr
  ur urd
  uz uzb
  vi vie
  vo vol
  wa wln
  yi yid
  yo yor
  zh zho
);

my %language_codes_from_classifier = reverse %language_codes_for_classifier;

define
  'build-language-classifier-languages' => (
  hold    => 0,
  arity   => 0,
  options => {}
  ),
  sub {
  my ($engine) = @_;

  if(!defined $Lingua::YALI::LanguageIdentifier::VERSION) {
    return Dallycot::Value::Vector->new();
  }

  my $d = deferred;

  $d->resolve( Dallycot::Value::Vector->new(
    map { Dallycot::Value::String->new($_) }
    grep { $_ }
    map { $language_codes_from_classifier{$_} }
    @{Lingua::YALI::LanguageIdentifier -> new -> get_available_languages}
  ) );

  return $d->promise;
};

define 'language-classifier-languages' => 'build-language-classifier-languages()';

define 'classify-text-language' => (
  hold    => 0,
  arity   => 1,
  options => { 'languages' => Dallycot::Value::Vector -> new(Dallycot::Value::String->new('en')) }
  ), sub {
  my ( $engine, $options, $text ) = @_;

  if ( !$text -> isa('Dallycot::Value::String') && !$text->isa('Dallycot::Value::URI') ) {
    croak "language-classify requires a String or URI as a second argument";
  }
  if( !$options->{'languages'} -> isa('Dallycot::Value::Vector') ) {
    croak "language-classifier's 'languages' option requires a vector of strings";
  }
  my @languages =
    grep { $_ }
    map { $language_codes_for_classifier{ $_ -> value } }
    grep { $_->isa('Dallycot::Value::String') }
    $options->{'languages'}->values;

  if(!@languages) {
    croak "language-classifier's 'languages' option requires a vector of strings";
  }
  if(!defined $Lingua::YALI::LanguageIdentifier::VERSION) {
    return Dallycot::Value::Vector->new();
  }

  my $identifier = Lingua::YALI::LanguageIdentifier->new;
  $identifier->add_language($_) for @languages;

  given ( blessed $text ) {
    when ('Dallycot::Value::String') {
      my $result = $identifier->identify_string( $text->value );
      return Dallycot::Value::String -> new(
        $language_codes_from_classifier{
          $result -> [0] -> [0]
        }
      );
    }
    when ('Dallycot::Value::URI') {
      return $text -> resolve_content -> then(
        sub {
          my ($body) = @_;
          my $content = '';
          given ( blessed $body ) {
            when ('HTML') {    # content-type: text/html
                               # we want to strip out the HTML and keep only text in the
                               # <body /> outside of <script/> tags
              my $dom = Mojo::DOM->new( $body->{'value'} );
              $content = $dom->find('body')->all_text;
            }
            when ('Dallycot::Value::String') {    # content-type: text/plain
              $content = $body->value;
            }
            when ('XML') {       # content-type: text/xml (TEI, etc.)
              my $dom = Mojo::DOM->new->xml(1)->parse( $body->{'value'} );
              $content = $dom->all_text;
            }
            default {
              croak "Unable to extract text from " . $text->{'value'};
            }
          }
          my $worked = eval {
            # TODO: make '4096' a tunable parameter
            # algorithm takes a *long* time with large strings
            my $result = $identifier->identify_string( substr( $content, 0, 4096 ) );
            Dallycot::Value::String -> new(
              $language_codes_from_classifier{
                $result -> [0] -> [0]
              }
            );
          };
          if ($@) {
            croak $@;
          }
          elsif ( !$worked ) {
            croak "Unable to identify language.";
          }
          else {
            return $worked;
          }
        }
      );
    }
    default {
      croak "language-classify requires a String or URI as a second argument";
    }
  }
};

define 'stop-word-languages' => '<<da nl en fi fr de hu it no pt es sv ru>>';

1;
