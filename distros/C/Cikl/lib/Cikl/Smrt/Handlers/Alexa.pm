package Cikl::Smrt::Handlers::Alexa;

use strict;
use warnings;
use Cikl::Smrt::Fetchers::Http;
use Cikl::Smrt::Decoders::Zip;
use Cikl::Smrt::Parsers::ParseDelim;
use Cikl::Smrt::HandlerRole;
use namespace::autoclean;
use URI;
use Mouse;
with 'Cikl::Smrt::HandlerRole';

# This file is initially a demonstration of a custom feed handler.


sub name {
  return 'alexa';
};

use constant ALEXA_ZIP => 'http://s3.amazonaws.com/alexa-static/top-1m.csv.zip';

sub _default_event_data {
  my $self = shift;
  return {
    group => 'everyone',
    assessment => 'whitelist'
  };
}

sub _fetcher {
    my $self = shift;
    return Cikl::Smrt::Fetchers::Http->new(
      proxy => $self->proxy(), 
      feedurl => URI->new(ALEXA_ZIP),
      mirror => "/tmp"
    );
}

sub _parser {
    my $self = shift;
    return Cikl::Smrt::Parsers::ParseDelim->new(
      delimiter => ',',
      values => 'rank,address',
      feed_limit => 10,
      config => $self->global_config(),
    );
}

sub _decoder {
    my $self = shift;
    return Cikl::Smrt::Decoders::Zip->new(
      zip_filename => 'top-1m.csv',
    );
}

__PACKAGE__->meta->make_immutable;

1;
