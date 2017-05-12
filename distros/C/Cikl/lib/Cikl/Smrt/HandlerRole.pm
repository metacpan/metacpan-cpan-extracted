package Cikl::Smrt::HandlerRole;

use strict;
use warnings;
use Cikl::Client::Factory;
use Cikl::Smrt::ClientBroker;
use Cikl::Smrt::Decoders::Null;
use Cikl::EventBuilder;
use Cikl::Smrt::Broker;
use Config::Simple;
use Try::Tiny;
use AnyEvent;
use Coro;
use DateTime;

use Mouse::Role;
use Cikl::Logging;
use Net::SSLeay;
Net::SSLeay::SSLeay_add_ssl_algorithms();

use namespace::autoclean;

my $logger = get_logger();

requires 'name';
requires '_default_event_data';

has 'global_config' => (
  is => 'ro',
  isa => 'Config::Simple',
  required => 1
);

has 'event_builder' => (
  is => 'ro',
  isa => 'Cikl::EventBuilder',
  lazy => 1,
  builder => "_event_builder"
);

has 'default_event_data' => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  builder => "_default_event_data"
);

has 'refresh' => (
  is => 'ro',
  isa => 'Bool',
  lazy => 1,
  builder => "_refresh"
);

has 'not_before' => (
  is => 'ro', 
  isa => 'DateTime',
  required => 1,
  default => sub {return DateTime->now()->subtract(days => 3);}
);

has 'proxy' => (
  is => 'ro',
  required => 0
);

has 'fetcher' => (
  is => 'ro',
  isa => 'Cikl::Smrt::Fetcher',
  lazy => 1,
  builder => "_fetcher"
);

has 'parser' => (
  is => 'ro',
  isa => 'Cikl::Smrt::Parser',
  lazy => 1,
  builder => "_parser"
);

has 'decoder' => (
  is => 'ro',
  isa => 'Cikl::Smrt::DecoderRole',
  lazy => 1,
  builder => "_decoder"
);

has 'detecttime_format' => (
  is => 'ro',
  isa => 'Maybe[Str]',
  required => 0,
  lazy => 1,
  builder => '_build_detecttime_format'
);

has 'detecttime_zone' => (
  is => 'ro',
  isa => 'Maybe[Str]',
  required => 0,
  lazy => 1,
  builder => '_build_detecttime_zone'
);


sub _build_detecttime_format {
  return undef;
}

sub _build_detecttime_zone {
  return undef;
}

sub _event_builder {
  my $self = shift;
  return Cikl::EventBuilder->new(
    not_before => $self->not_before()->epoch(),
    default_event_data => $self->default_event_data(),
    refresh => $self->refresh(),
    detecttime_format => $self->detecttime_format(),
    detecttime_zone => $self->detecttime_zone()
  ) 
}

sub _refresh {
  return 0;
}

sub get_client {
  my $self = shift;
  my $client_config = $self->global_config()->get_block('client');
  return Cikl::Client::Factory->instantiate($client_config);
}

sub process {
    my $self = shift;
    my ($err, $ret);
    
    my $client = $self->get_client();

    my $broker = Cikl::Smrt::ClientBroker->new(
      client => $client,
      builder => $self->event_builder()
    );
    try {
      my ($err) = $self->parse($broker);
      if ($err) {
        die($err);
      }
    } catch {
      $err = shift;
    } finally {
      if ($client) {
        $client->shutdown();
      }
    };
    if ($err) {
      return($err);
    }

    $logger->debug('records to be processed: '.$broker->count() . ", too old: " . $broker->count_too_old());
    if ($broker->count_failed() > 0) {
      $logger->debug('failed to create events: '. $broker->count_failed());
    }

    if($broker->count() == 0){
      if ($broker->count_too_old() != 0) {
        $logger->debug('your goback is too small, if you want records, increase the goback time');
      }
      return (undef, 'no records');
    }

    return(undef);
}

sub fetch { 
    my $self = shift;
    my $cv = AnyEvent->condvar;
    my $fetcher = $self->fetcher();

    async {
      try {
        $cv->send($fetcher->fetch());
      } catch {
        $cv->croak(shift);
      };
    };
    while (!($cv->ready())) {
      Coro::AnyEvent::sleep(1);
    }
    my $fh = $cv->recv();

    # auto-decode the content if need be
    return $self->decode($fh);

    ## TODO MPR : This looks like a hack for the utf8 and CR stuff below.
    #return(undef,$ret) if($feedparser_config->{'cikl'} && $feedparser_config->{'cikl'} eq 'true');

    ## Commenting this out as I haven't run into any issues, yet.  
    # encode to utf8
    #$ret = encode_utf8($ret);
    
    # remove any CR's
    #$ret =~ s/\r//g;
}

sub parse {
    my $self = shift;
    my $broker = shift;

    my $fh = $self->fetch();
    
    my $return = $self->parser()->parse($fh, $broker);

    $fh->close() or die($!);
    undef $fh;

    return(undef);
}

# Just pass things through. This can be overridden by subclasses.
sub decode {
    my $self = shift;
    my $content_ref = shift;
    return $self->decoder->decode($content_ref);
}

sub _decoder {
    # Use a default decoder of 'Null', just because we're nice.
    return Cikl::Smrt::Decoders::Null->new();
}


1;
