package Cikl::Smrt::FeedParserConfig;

use strict;
use warnings;
use Data::Dumper;
use Config::Simple;
use Try::Tiny;
use Storable qw/dclone/;

use constant FIELDS => {
  group => 'everyone',
  parser => undef,
  detecttime_format => undef,
  detecttime_zone => undef,
  feed => undef,
  source => undef,
  feed_limit => undef,
  feed_user => undef,
  feed_password => undef,
  values => undef,
  skipfirst => undef,
  delimiter => undef,
  fields => undef,
  fields_map => undef,
  mirror => undef,
  zip_filename => undef,
  regex => undef,
  regex_values => undef,
  node => undef,
  node_xpath => undef,
  subnode => undef,
  period => undef,
  disabled => undef,
  elements => undef,
  elements_map => undef,
  attributes => undef, 
  attributes_map => undef
};

use constant REQUIRED_FIELDS => {
  group => 1,
  feed => 1,
  source => 1,
  parser => 1
};

sub new {
  my $class = shift;
  my $config_file = shift;
  my $feed_name = shift;

  my $config;
  my $err;
  try {
    $config = Config::Simple->new($config_file);
  } catch {
    $err = shift;
  };

  if (defined($err)) {
    die "Syntax error while parsing $config_file: $err";
  }

  my $config_data = $config->param(-block => 'default');
  my $feed_rules = $config->param(-block => $feed_name);

  if (!%$feed_rules) {
    die "Unknown section '$feed_name' for $config_file";
  }

  # Override any configuration with sub config.
  map { $config_data->{$_} = $feed_rules->{$_} } keys (%$feed_rules);

  my $self = {};

  my @feed_config_fields = keys(FIELDS);

  # Catch any dynamically named fields.
  foreach my $name (keys(%$config_data)) {
    if ($name =~ /^(regex_|xpath)/) {
      push(@feed_config_fields, $name);
    }
  }
  
  foreach my $name (@feed_config_fields) {
    my $v = delete($config_data->{$name}) || FIELDS->{$name};

    if (defined($v)) {
      $self->{$name} = $v;
    }
  }


  foreach my $required (keys(REQUIRED_FIELDS)) {
    if (!exists($self->{$required})) {
      die "Missing required configuration '$required' from '$config_file' - [$feed_name]";
    }
  }

  bless($self,$class);

  $config_data->{group} = $self->{group};
  $config_data->{source} = $self->{source};
  # The remaining fields will act as defaults for events, when they are created.
  $self->{event_fields} = $config_data;

  return $self;
}

sub feed {
  my $self = shift;
  return $self->{feed};
}

sub parser {
  my $self = shift;
  return $self->{parser};
}

sub default_event_data {
  my $self = shift;
  return (dclone($self->{event_fields}));
}

sub values {
  my $self = shift;
  if (!defined($self->{values})) {
    return undef;
  }
  return split(',',$self->{values});
}

sub fields {
  my $self = shift;
  return split(',',$self->{fields});
}

sub fields_map {
  my $self = shift;
  return split(',',$self->{fields_map});
}

sub _split {
  my $self = shift;
  my $field = shift;
  if (defined($self->{$field})) {
    return split(',',$self->{$field});
  }
  return(undef);
}

sub elements {
  my $self = shift;
  return $self->_split("elements");
}

sub elements_map {
  my $self = shift;
  return $self->_split("elements_map");
}

sub attributes {
  my $self = shift;
  return $self->_split("attributes");
}

sub attributes_map {
  my $self = shift;
  return $self->_split("attributes_map");
}

sub regex_values {
  my $self = shift;
  if (ref($self->{'regex_values'}) eq 'ARRAY') {
    return $self->{'regex_values'};
  }
  return split(',',$self->{'regex_values'});
}

sub regex_for {
  my $self = shift;
  my $name = shift;
  return $self->{"regex_$name"};
}

sub keyed_regex {
  my $self = shift;
  my $key = shift;
  return $self->{"regex_" . $key};
}

sub keyed_regex_values {
  my $self = shift;
  my $key = shift;
  my $v = $self->{"regex_" . $key . "_values"};
  return split(',', $v);
}

sub delimiter { return($_[0]->{delimiter}); }
sub feed_limit { return($_[0]->{feed_limit}); }
sub skipfirst { return($_[0]->{skipfirst}); }
sub regex { return($_[0]->{regex}); }
sub node { return($_[0]->{node}); }
sub subnode { return($_[0]->{subnode}); }

1;
