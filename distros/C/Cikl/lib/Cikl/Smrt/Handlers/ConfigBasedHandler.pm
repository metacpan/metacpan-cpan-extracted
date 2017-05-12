package Cikl::Smrt::Handlers::ConfigBasedHandler;

use strict;
use warnings;

use Encode qw/encode_utf8/;
use Cikl::Smrt::FeedParserConfig;
use Cikl::Smrt::Parsers;
use Cikl::Smrt::Decoders::AutoDecoder;
use Cikl::Smrt::Fetchers;
use Cikl::Smrt::HandlerRole;
use URI;

use Mouse;
with 'Cikl::Smrt::HandlerRole';

sub name {
  return 'config_based';
};

use namespace::autoclean;

has 'feedparser_config' => (
  is => 'ro',
  isa => 'Cikl::Smrt::FeedParserConfig',
  required => 1
);

sub _build_detecttime_format {
  my $self = shift;
  return $self->feedparser_config->{detecttime_format};
}

sub _build_detecttime_zone {
  my $self = shift;
  return $self->feedparser_config->{detecttime_zone};
}

sub _refresh {
  my $self = shift;
  return $self->feedparser_config->{refresh};
}

sub _default_event_data {
  my $self = shift;
  return $self->feedparser_config->default_event_data;
}

sub _fetcher {
    my $self = shift;
    my $fetchers = Cikl::Smrt::Fetchers->new();
    my $feedparser_config = $self->feedparser_config;
    my $feedurl = URI->new($feedparser_config->feed());
    my $fetcher_class = $fetchers->lookup($feedurl);
    if (!defined($fetcher_class)) {
      die("Could not determine fetcher");
    }

    my %args = (%$feedparser_config, proxy => $self->proxy(), feedurl => $feedurl);

    return $fetcher_class->new(%args);
}

sub _parser {
    my $self = shift;
    my $parsers = Cikl::Smrt::Parsers->new();
    my $parser_name = $self->feedparser_config->parser;
    my $parser_class = $parsers->get($parser_name);
    if (!defined($parser_class)) {
      die("Could not find a parser for parser=$parser_name. Valid parsers: " . $parsers->valid_parser_names_string);
    }
    my %args = (%{$self->feedparser_config}, config => $self->feedparser_config);
    
    return $parser_class->new(%args);
}

sub _decoder {
    my $self = shift;
    my $feedparser_config = $self->feedparser_config;
    my $feedurl = URI->new($feedparser_config->feed());
    my %decoder_args = (%$feedparser_config);
    return Cikl::Smrt::Decoders::AutoDecoder->new(
      feedurl => $feedurl,
      decoder_args => \%decoder_args
    );
}

__PACKAGE__->meta->make_immutable;

1;

