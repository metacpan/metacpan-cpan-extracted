#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2003-05-20
# Last Modified: $Date: 2010-11-02 11:57:52 +0000 (Tue, 02 Nov 2010) $ $Author: zerojinx $
# Id:            $Id: SourceAdaptor.pm 688 2010-11-02 11:57:52Z zerojinx $
# Source:        $Source: /nfs/team117/rmp/tmp/Bio-Das-ProServer/Bio-Das-ProServer/lib/Bio/Das/ProServer/SourceAdaptor.pm,v $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor.pm $
#
# Generic SourceAdaptor. Generates XML and manages callouts for DAS functions
#
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
#
package Bio::Das::ProServer::SourceAdaptor;
use strict;
use warnings;
use HTML::Entities qw(encode_entities_numeric);
use HTTP::Date qw(str2time time2isoz);
use English qw(-no_match_vars);
use Carp;
use File::Spec;

our $VERSION  = do { my ($v) = (q$Revision: 688 $ =~ /\d+/mxsg); $v; };

sub new {
  my ($class, $defs) = @_;
  my $self = {
              'dsn'               => $defs->{'dsn'},
              'port'              => $defs->{'port'},
              'hostname'          => $defs->{'hostname'},
              'baseuri'           => $defs->{'baseuri'},
              'protocol'          => $defs->{'protocol'},
              'config'            => $defs->{'config'}   || {},
              'debug'             => $defs->{'debug'}    || undef,
              '_data'             => {},
              '_sequence'         => {},
              '_features'         => {},
             };

  bless $self, $class;
  $self->init($defs);

  if (exists $self->config->{'example_segment'}) {
    carp q(Warning: the 'example_segment' INI property is deprecated. Please use 'coordinates' instead.);
  }

  return $self;
}

sub init {return;}

sub length { return 0; } ## no critic (Subroutines::ProhibitBuiltinHomonyms)

sub source_uri {
  my $self = shift;
  return $self->{'source_uri'} || $self->config->{'source_uri'} || $self->version_uri;
}

sub version_uri {
  my $self = shift;
  return $self->{'version_uri'} || $self->config->{'version_uri'} || $self->dsn;
}

sub title {
  my $self = shift;
  return $self->{'title'} || $self->config->{'title'} || $self->dsn;
}

sub maintainer {
  my $self = shift;
  return $self->{'maintainer'} || $self->config->{'maintainer'} || q();
}

sub mapmaster {
  my $self = shift;
  return $self->{'mapmaster'} || $self->config->{'mapmaster'};
}

sub description {
  my $self = shift;
  return $self->{'description'} || $self->config->{'description'} || $self->title;
}

sub doc_href {
  my $self = shift;
  return $self->{'doc_href'} || $self->config->{'doc_href'};
}

sub strict_boundaries {
  my $self = shift;
  return $self->{'strict_boundaries'} || $self->config->{'strict_boundaries'};
}

sub known_segments {return;}

sub segment_version {return;}

sub init_segments {return;}

sub dsn {
  my $self = shift;
  return $self->{'dsn'} || 'unknown';
}

sub dsnversion {
  my $self = shift;
  return $self->{dsnversion} || $self->config->{dsnversion} || '1.0';
}

sub dsncreated {
  my $self = shift;
  my $datetime = $self->{dsncreated} || $self->config->{dsncreated};

  if (!$datetime) {
    if (defined $self->hydra && $self->hydra->can('last_modified')) {
      $datetime = $self->hydra->last_modified;
    } elsif (defined $self->transport && $self->transport->can('last_modified')) {
      $datetime = $self->transport->last_modified;
    }
  }

  return $datetime || 0; # epoch
}

sub _parse_config_hash {
    my $str  = shift;
    if ( defined $str ) {
        my @pairs = split qr{\s*[;\|]\s*}mxs, $str;
        if ( @pairs ) {
            return { map { split qr{\s*[=-]>\s*}mxs, $_, 2 } @pairs};
        }
    }
    return {};
}

sub coordinates {
  my $self = shift;

  if (!exists $self->{'coordinates'}) {
    $self->{'coordinates'} = _parse_config_hash( $self->config->{'coordinates'} );
  }

  return $self->{'coordinates'};
}

sub _coordinates {
  my $self = shift;
  my @coords = ();
  while (my ($key, $test_range) = each %{ $self->coordinates() }) {
    my $coord = $Bio::Das::ProServer::COORDINATES->{lc $key};
    if (!$coord) {
      print {*STDERR} $self->dsn . " has unknown coordinate system: $key\n" or croak $ERRNO;
      next;
    }
    if (!$test_range) {
      print {*STDERR} $self->dsn . " has no test range for coordinate system: $key\n" or croak $ERRNO;
      next;
    }
    my %coord = %{ $coord };
    $coord{'test_range'} = $test_range;
    push @coords, \%coord;
  }
  return wantarray ? @coords : \@coords;
}

# Capabilities as rationalised by ProServer
sub _capabilities {
  my $self = shift;

  if (! exists $self->{'_capabilities'} ) {
    my $caps = $self->{'_capabilities'} = { %{ $self->capabilities() } };

    # If a stylesheet has been explicitly provided in the config, it is clearly
    # supposed to be offered so make sure the capaability is set.
    if (! exists ($caps->{'stylesheet'}) &&
       ($self->{'config'}->{'stylesheet'} ||
        $self->{'config'}->{'stylesheetfile'})) {
      $caps->{'stylesheet'} = '1.1';
    }

    # The 'dna' command has been removed, all functionality exists through the
    # 'sequence' command.
    if ( exists $caps->{'dna'} && ! exists $caps->{'sequence'} ) {
      $caps->{'sequence'} = '1.1';
    }
    delete $caps->{'dna'};

    # If not specified, we can check to see if a DAS source will support unknown segment errors
    if ( !(exists $caps->{'error-segment'} || exists $caps->{'unknown-segment'}) &&
          ($self->known_segments()) ) {

      # Reference servers are authoritative for the segment, so implement error-segment
      if ( exists $caps->{'sequence'} ) {
        $caps->{'error-segment'} = '1.0';
      } else {
        $caps->{'unknown-segment'} = '1.0';
      }
    }

    # DAS 1.6: upgrade to version 1.1 of each command
    for my $command (qw(features types entry_points sequence stylesheet)) {
      if ( $caps->{$command} && $caps->{$command} < 1.1 ) {
        $caps->{$command} = 1.1;
      }
    }
  }

  return $self->{'_capabilities'};
}

# Capabilities as declared by the subclass
sub capabilities {
  my $self = shift;

  if (!exists $self->{'capabilities'}) {
    $self->{'capabilities'} = _parse_config_hash( $self->config->{'capabilities'} );
  }

  return $self->{'capabilities'};
}

sub properties {
  my $self = shift;

  if (!exists $self->{'properties'}) {
    $self->{'properties'} = _parse_config_hash( $self->config->{'properties'} );
  }

  return $self->{'properties'};
}

sub start { return 1; }

sub end {
  my ($self, @args) = @_;
  return $self->length(@args);
}

sub server_url {
  my $self = shift;
  my $host      = $self->{'hostname'};
  my $protocol  = $self->{'protocol'}  || 'http';
  my $port      = $self->{'port'}  || q();
  if ($port) {
    $port = ":$port";
  }
  my $baseuri   = $self->{'baseuri'}   || q();
  return "$protocol://$host$port$baseuri";
}

sub source_url {
  my $self = shift;
  return $self->server_url().q(/das/).$self->dsn();
}

sub hydra {
  my $self = shift;
  return $self->config()->{'_hydra'};
}

sub transport {
  my ($self, $transport_name) = @_;
  $transport_name ||= q();
  my $config = $self->config;

  # Copy the config options, 'overwriting' with named-transport values where appropriate
  if ($transport_name) {
    my %config_copy = %{$config};
    while (my ($key, $val) = each %{$config}) {
      if ($key =~ s/^$transport_name\.//mxs) {
        $config_copy{$key} = $val;
      }
    }
    $config = \%config_copy;
  }

  if(!exists $self->{'_transport'}{$transport_name} &&
     defined $config->{'transport'}) {
    my $transport = 'Bio::Das::ProServer::SourceAdaptor::Transport::'.$config->{'transport'};

    eval "require $transport" or carp $EVAL_ERROR; ## no critic(TestingAndDebugging::ProhibitNoStrict BuiltinFunctions::ProhibitStringyEval)
    eval {
      $self->{_transport}->{$transport_name} = $transport->new({
        dsn    => $self->{dsn}, # for debug purposes
        config => $config,
        debug  => $self->{debug},
      });
    } or do {
      carp $EVAL_ERROR;
    };
  }
  return $self->{'_transport'}->{$transport_name};
}

sub config {
  my ($self, $config) = @_;
  if(defined $config) {
    $self->{config} = $config;
  }
  return $self->{config};
}

sub implements {
  my ($self, $method) = @_;
  return $method ? (exists $self->_capabilities()->{$method}):undef;
}

# Ensures UNIX (seconds since epoch) format for 'dsncreated'
sub dsncreated_unix {
  my $self = shift;
  my $datetime = $self->dsncreated();
  if($datetime !~ m/^\d+$/mxs) {
    $datetime = str2time($datetime);
  }
  return $datetime || 0; # if can't be parsed, use epoch
}

# Ensures ISO 8601 (yyyy-mm-ddThh::mm:ssZ) format for 'dsncreated'
sub dsncreated_iso {
  my $self     = shift;
  my $datetime = time2isoz($self->dsncreated_unix);
  $datetime    =~ s/\ /T/mxs;
  return $datetime;
}

sub das_capabilities {
  my $self = shift;
  my $capabilities = $self->_capabilities();
  return join q(; ), map {
    "$_/$capabilities->{$_}"
  } grep {
    defined $capabilities->{$_}
  } keys %{$capabilities};
}

sub authenticator {
  my ($self) = @_;
  my $config = $self->config;

  if (defined $config->{'authenticator'} && !exists $self->{'_auth'}) {
    $self->{'debug'} && carp "Building authenticator for $self->{'dsn'}";
    my $auth = 'Bio::Das::ProServer::Authenticator::'.$config->{'authenticator'};
    eval "require $auth" or do { }; ## no critic(BuiltinFunctions::ProhibitStringyEval)
    my $require_error = $EVAL_ERROR;
    eval {
      $self->{'_auth'} = $auth->new({
                                     'dsn'    => $self->{'dsn'}, # for debug purposes
                                     'config' => $config,
                                     'debug'  => $self->{'debug'},
                                    });
    } or do {
      # Require doesn't necessarily have to succeed, but if there was a problem loading the object it is fatal.
      if ($require_error && !$self->{'_auth'}) {
        croak $require_error;
      }
      croak $EVAL_ERROR;
    };
  }

  return $self->{'_auth'};
}

sub _error { ## no critic (Subroutines::RequireArgUnpacking)
  my $self = shift;
  return sprintf 'ERROR:%d:%d:%s', @_;
}

sub das_dsn {
  my $self = shift;

  my $mapmaster = $self->mapmaster();
  $mapmaster    = $mapmaster ? "<MAPMASTER>$mapmaster</MAPMASTER>" : q();
  my $content   = sprintf q(<DSN><SOURCE id="%s" version="%s">%s</SOURCE>%s<DESCRIPTION>%s</DESCRIPTION></DSN>),
                          $self->dsn(),
                          $self->dsnversion(),
                          $self->title(),
                          $mapmaster,
                          $self->description();

  return ($content);
}

sub unknown_segment {
  my ($self, $seg, $start, $end) = @_;

  if ($self->implements('sequence')) {
    return $self->error_segment($seg, $start, $end);
  }

  $start = $start ? qq( start="$start") : q();
  $end   = $end   ? qq( stop="$end")    : q();
  return qq(<UNKNOWNSEGMENT id="$seg"$start$end />);
}

sub error_segment {
  my ($self, $seg, $start, $end) = @_;
  $start = $start ? qq( start="$start") : q();
  $end   = $end   ? qq( stop="$end")    : q();
  return qq(<ERRORSEGMENT id="$seg"$start$end />);
}

#########
# code refactoring function to generate the link parts of the DAS response
#
sub _gen_link_das_response {
  my ($self, $link, $linktxt) = @_;
  my $response = q();

  #########
  # if $link is a reference to and array or hash use their contents as multiple links
  #
  if(ref $link eq 'ARRAY') {
    while(my $k = shift @{$link}) {
      my $v;
      if (ref $linktxt eq 'ARRAY') {
        $v = shift @{$linktxt};
      } elsif ($linktxt) {
        $v = $linktxt;
      }

      $response .= $v ? qq(<LINK href="$k">$v</LINK>)
                      : qq(<LINK href="$k" />);
    }

  } elsif(ref $link eq 'HASH') {
    for my $k (sort { $link->{$a} cmp $link->{$b} } keys %{$link}) {
      $response .= $link->{$k} ? qq(<LINK href="$k">$link->{$k}</LINK>)
                               : qq(<LINK href="$k" />);
    }

  } elsif($link) {
    $response .= $linktxt ? qq(<LINK href="$link">$linktxt</LINK>)
                          : qq(<LINK href="$link" />);
  }
  return $response;
}

#########
# Recursive application of entity escaping
#
sub _encode {
  my ($self, $datum) = @_;
  if(!ref $datum) {
    return;
  }

  if(ref $datum eq 'HASH') {
    my $encoded = {};
    while(my ($k, $v) = each %{$datum}) {
      if(defined $k) {
        encode_entities_numeric($k);
      }
      if(ref $v) {
        $self->_encode($v);
      } elsif(defined $v) {
        encode_entities_numeric($v);
      }
      $encoded->{$k} = $v;
    }
    %{$datum} = %{$encoded};

  } elsif(ref $datum eq 'ARRAY') {
    @{$datum} = map { (ref $_)?$self->_encode($_):defined$_?encode_entities_numeric($_):$_; } @{$datum};

  } elsif(ref $datum eq 'SCALAR') {
    if(defined ${$datum}) {
      ${$datum} = encode_entities_numeric(${$datum});
    }
  }

  return $datum;
}

sub _features_from_groups {
  my ($self, $features) = @_;

  my %cache = ();
  my @features;

  for my $feature (@{ $features }) {

    # Copy the feature because we're going to modify it
    $feature = { %{ $feature } };
    push @features, $feature;

    my $group      = delete $feature->{'group'} || delete $feature->{'group_id'} || next;
    my $feature_id = $feature->{'id'}    || $feature->{'feature_id'} || q();
    my $groups = {};

    #########
    # if $group is a hash reference treat its keys as the multiple groups to be reported for this feature
    #
    if (ref $group eq 'HASH') {
      $groups = $group;
    }

    #####
    # if $group is a ref to an array then use group_id of the hashs in that array as the key in a new hash
    #
    elsif (ref $group eq 'ARRAY') {
      for my $g (@{$group}) {
        $groups->{$g->{'group_id'}} = $g;
      }
    }

    #########
    # otherwise there is just one group
    #
    else {
      $groups->{$group} = { };
      for my $key (qw(grouplabel grouptype groupnote grouplink grouplinktxt)) {
        $groups->{$group}->{$key} = delete $feature->{$key};
      }
    }

    for my $group_id (grep { $_ && (substr $_, 0, 1) ne '_' } keys %{$groups}) {

      # Create the parent if this is the first time we have encountered the group
      my $parent = $cache{$group_id};
      if (! $parent ) {
        my $groupinfo = $groups->{$group_id};
        $parent = $cache{$group_id} = {
          'id'     => $group_id,
        };
        for my $key (qw(segment segment_version segment_start segment_end)) {
          my $v = $feature->{$key};
          if ($v) {
            $parent->{$key} = $v;
          }
        }
        for my $key (qw(label type note link linktxt target)) {
          my $v = $groupinfo->{"group$key"} || $groupinfo->{$key};
          if ($v) {
            $parent->{$key} = $v;
          }
        }
      }

      # Add the ID of this feature to the parent feature
      if (! $parent->{'part'} ) {
        $parent->{'part'} = [ $feature_id ];
      } elsif (ref $parent->{'part'} eq 'ARRAY') {
        push @{ $parent->{'part'} }, $feature_id;
      } else {
        $parent->{'part'} = [ $parent->{'part'}, $feature_id ];
      }

      # Add the ID of the parent feature to this feature
      if (! $feature->{'parent'} ) {
        $feature->{'parent'} = [ $group_id ];
      } elsif (ref $feature->{'parent'} eq 'ARRAY') {
        push @{ $feature->{'parent'} }, $group_id;
      } else {
        $feature->{'parent'} = [ $feature->{'parent'}, $group_id ]
      }

    } # end group loop

  } # end feature loop

  return ( values %cache, @features);
}

#########
# code refactoring function to generate the feature parts of the DAS response
#
sub _gen_feature_das_response {
  my ($self, $feature, $categorize) = @_;
  $self->_encode($feature);

  my $response  = q();
  my $start     = $feature->{'start'};
  my $end       = $feature->{'end'};
  my $note      = $feature->{'note'}         || q();
  my $id        = $feature->{'id'}           || $feature->{'feature_id'}    || q();
  my $label     = $feature->{'label'}        || $feature->{'feature_label'};
  my $type      = $feature->{'type'}         || q();
  my $typetxt   = $feature->{'typetxt'};
  my $method    = $feature->{'method'}       || q();
  my $method_l  = $feature->{'method_label'};
  my $score     = $feature->{'score'};
  my $ori       = $feature->{'ori'};
  my $phase     = $feature->{'phase'};
  my $link      = $feature->{'link'}         || q();
  my $linktxt   = $feature->{'linktxt'}      || q();
  my $target    = $feature->{'target'};
  my $parent    = $feature->{'parent'}       || q();
  my $part      = $feature->{'part'}         || q();
  my $cat       = defined $feature->{'typecategory'}   ? qq( category="$feature->{'typecategory'}")     : defined $feature->{'type_category'}   ? qq( category="$feature->{'type_category'}")     : q();
  my $subparts  = defined $feature->{'typesubparts'}   ? qq( subparts="$feature->{'typesubparts'}")     : defined $feature->{'typessubparts'}   ? qq( subparts="$feature->{'typessubparts'}")     : q();
  my $supparts  = defined $feature->{'typesuperparts'} ? qq( superparts="$feature->{'typesuperparts'}") : defined $feature->{'typessuperparts'} ? qq( superparts="$feature->{'typessuperparts'}") : q();
  my $ref       = defined $feature->{'typereference'}  ? qq( reference="$feature->{'typereference'}")   : defined $feature->{'typesreference'}  ? qq( superparts="$feature->{'typesreference'}")  : q();
  my $type_cv   = defined $feature->{'type_cvid'}      ? qq( cvId="$feature->{'type_cvid'}")            : $type =~ m/(SO|BS|MOD):\d+/mxs        ? qq( cvId="$type")                               : q();
  my $method_cv = defined $feature->{'method_cvid'}    ? qq( cvId="$feature->{'method_cvid'}")          : $cat  =~ m/(ECO:\d+)/mxs              ? qq( cvId="$1")                                  : q();

  if (!$categorize) {
    $cat = q();
  }

  $response .= $label ? qq(<FEATURE id="$id" label="$label">) : qq(<FEATURE id="$id">);
  $response .= qq(<TYPE id="$type"$type_cv$cat$ref$subparts$supparts);
  if ($typetxt) {
    $response .= qq(>$typetxt</TYPE>);
  } else {
    $response .= q( />);
  }
  $response .= qq(<METHOD id="$method"$method_cv);
  if ($method_l) {
    $response .= qq(>$method_l</METHOD>);
  } else {
    $response .= q( />);
  }
  (defined $start)  and $response .= qq(<START>$start</START>);
  (defined $end)    and $response .= qq(<END>$end</END>);
  (defined $score)  and $response .= qq(<SCORE>$score</SCORE>);
  (defined $phase)  and $response .= qq(<PHASE>$phase</PHASE>);
  (defined $ori)    and $response .= qq(<ORIENTATION>$ori</ORIENTATION>);

  #########
  # Allow the 'note' tag to point to an array of notes.
  #
  if(ref $note eq 'ARRAY' ) {
    for my $n (grep { $_ } @{$note}) {
      $response .= qq(<NOTE>$n</NOTE>);
    }

  } elsif($note) {
    $response .= qq(<NOTE>$note</NOTE>)
  }

  #########
  # Target can be an array of hashes
  #
  if($target && (ref $target eq 'ARRAY')) {
    for my $t (@{$target}) {
      $response .= sprintf q(<TARGET%s%s%s>%s</TARGET>),
                           $t->{'id'}    ?qq( id="$t->{'id'}")       :q(),
                           $t->{'start'} ?qq( start="$t->{'start'}") :q(),
                           $t->{'stop'}  ?qq( stop="$t->{'stop'}")   :q(),
                           $t->{'targettxt'} || $t->{'target'} || sprintf q(%s:%d,%d), $t->{'id'}, $t->{'start'}, $t->{'stop'};
    }

  } elsif($feature->{'target_id'}) {
    $response .= sprintf q(<TARGET%s%s%s>%s</TARGET>),
      $feature->{'target_id'}    ?qq( id="$feature->{'target_id'}")       :q(),
      $feature->{'target_start'} ?qq( start="$feature->{'target_start'}") :q(),
      $feature->{'target_stop'}  ?qq( stop="$feature->{'target_stop'}")   :q(),
      $feature->{'targettxt'} || $feature->{'target_id'} || $feature->{'target'} ||
        sprintf q(%s:%d,%d), $feature->{'target_id'},
                             $feature->{'target_start'},
                             $feature->{'target_stop'};
  }

  $response .= $self->_gen_link_das_response($link, $linktxt);

  #########
  # Allow the 'parent' tag to point to an array of parent IDs.
  #
  if(ref $parent eq 'ARRAY' ) {
    for my $p (grep { $_ } @{$parent}) {
      $response .= qq(<PARENT id="$p" />);
    }
  } elsif($parent) {
    $response .= qq(<PARENT id="$parent" />)
  }

  #########
  # Allow the 'part' tag to point to an array of part IDs.
  #
  if(ref $part eq 'ARRAY' ) {
    for my $p (grep { $_ } @{$part}) {
      $response .= qq(<PART id="$p" />);
    }
  } elsif($part) {
    $response .= qq(<PART id="$part" />)
  }

  $response .= q(</FEATURE>);
  return $response;
}

sub das_features {
  my ($self, $opts) = @_;
  my $response      = q();
  $self->_encode($opts);
  $self->init_segments($opts->{'segments'});

  my $categorize = $opts->{'categorize'} && $opts->{'categorize'} eq 'no' ? 0 : 1;

  #########
  # features on segments
  #
  for my $seg (@{$opts->{'segments'}}) {
    my ($seg, $coords) = split /:/mxs, $seg;
    my ($start, $end)  = split /,/mxs, $coords || q();
    $seg ||= q();

    #########
    # If the requested segment is known to be not available it is an unknown or error segment.
    #
    my @known_segments = $self->known_segments();
    if(@known_segments && !scalar grep { /^$seg$/mxs } @known_segments) {
      $response .= $self->unknown_segment($seg);
      next;
    }

    # The bounds of the segment (if known).
    my $segstart        = $self->start($seg);
    my $segend          = $self->end($seg);
    #########
    # If the request is known to be out of range it is an error segment.
    #
    if($self->strict_boundaries()) {
      if ( ($start && $segstart && $start < $segstart) || ($end && $segend && $end > $segend ) ) {
        $response .= $self->error_segment($seg, $start, $end);
        next;
      }
    }

    my @features = $self->build_features({
                                          'segment'    => $seg,
                                          'start'      => $start,
                                          'end'        => $end,
                                          'types'      => $opts->{'types'},      # array
                                          'categories' => $opts->{'categories'}, # array
                                          'maxbins'    => $opts->{'maxbins'},    # scalar
                                         });

    my $segver = (scalar @features ? $features[0]->{'segment_version'} : undef)
      || $self->segment_version($seg) || q();

    my $response_start = $start || $segstart;
    my $response_end   = $end   || $segend;

    $response .= sprintf qq(<SEGMENT id="%s"%s%s%s>\n),
                         $seg,
                         $segver ? qq( version="$segver") : q(),
                         # The actual sequence positions we are querying for:
                         $response_start ? qq( start="$response_start") : q(),
                         $response_end   ? qq( stop="$response_end")    : q();

    # For legacy SourceAdaptor subclasses, convert groups to parent/part
    if ( $self->capabilities()->{'features'} < 1.1 ) {
      @features = $self->_features_from_groups( \@features );
    }

    for my $feature (@features) {
      # Apply filters here
      if (@{ $opts->{'categories'} || [] }) {
        my $s = $feature->{'typecategory'} || $feature->{'type_category'} || q();
        if (!scalar grep { $_ eq $s } @{ $opts->{'categories'} }) {
          next;
        }
      }
      if (@{ $opts->{'types'} || [] }) {
        my $s = $feature->{'type'} || q();
        if (!scalar grep { $_ eq $s } @{ $opts->{'types'} }) {
          next;
        }
      }
      $response .= $self->_gen_feature_das_response($feature, $categorize);
    }

    $response .= qq(\n</SEGMENT>\n);
  }

  #########
  # features overlapping a feature with a specific id
  #
  for my $fid (@{$opts->{'features'}}) {

    # Request features that overlap $fid - should get at least 1 feature, all on the same segment
    my @f = $self->build_features({
                                   'feature_id' => $fid,
                                   'types'      => $opts->{'types'},      # array
                                   'categories' => $opts->{'categories'}, # array
                                   'maxbins'    => $opts->{'maxbins'},    # scalar
                                  });

    # For legacy SourceAdaptor subclasses, convert groups to parent/part
    if ( $self->capabilities()->{'features'} < 1.1 ) {

      if (! scalar @f ) {
        # For legacy SourceAdaptor subclasses, parents are actually groups
        # so we need to handle cases where $fid is actually a group ID
        push @f, $self->build_features({
                                        'group_id'   => $fid,
                                        'types'      => $opts->{'types'},      # array
                                        'categories' => $opts->{'categories'}, # array
                                        'maxbins'    => $opts->{'maxbins'},    # scalar
                                       });
      }

      @f = $self->_features_from_groups( \@f );
    }

    if (! scalar @f ) {
      $response .= $self->error_feature($fid);
      next;
    }

    my ($seg, $segstart, $segend, $segver, $tmp) = (q(), q(), q(), q(), q());
    for my $feature (@f) {

      # If this is the feature we requested, use it to deduce the segment
      my $feature_id = $feature->{'id'} || $feature->{'feature_id'} || q();
      if ($feature_id eq $fid ) {
        $seg      = $feature->{'segment'}         || q();
        $segver   = $feature->{'segment_version'} || $self->segment_version($seg) || q();
        $segstart = $feature->{'start'}           || $self->start($seg) || q();
        $segend   = $feature->{'end'}             || $self->end($seg)   || q();
      }

      # Apply filters here
      if (@{ $opts->{'categories'} || [] }) {
        my $s = $feature->{'typecategory'} || $feature->{'type_category'} || q();
        if (!scalar grep { $_ eq $s } @{ $opts->{'categories'} }) {
          next;
        }
      }
      if (@{ $opts->{'types'} || [] }) {
        my $s = $feature->{'type'} || q();
        if (!scalar grep { $_ eq $s } @{ $opts->{'types'} }) {
          next;
        }
      }

      $tmp .= $self->_gen_feature_das_response($feature, $categorize);
    }

    $response .= sprintf qq(<SEGMENT id="%s"%s%s%s>\n),
                     $seg,
                     $segver ? qq( version="$segver") : q(),
                     # The actual sequence positions we are querying for:
                     $segstart ? qq( start="$segstart") : q(),
                     $segend   ? qq( stop="$segend")    : q();
    $response   .= qq($tmp\n);
    $response   .= qq(</SEGMENT>\n);
  }

  return $response;
}

sub error_feature {
  my ($self, $f) = @_;
  return qq(<SEGMENT id=""><UNKNOWNFEATURE id="$f" /></SEGMENT>);
}

sub das_sequence {
  my ($self, $segref) = @_;
  $self->_encode($segref);

  my @known_segments = $self->known_segments();

  my $response = q();
  for my $seg (@{$segref->{'segments'}}) {
    my ($seg, $coords) = split /:/mxs, $seg;
    my ($start, $end)  = split /,/mxs, $coords || q();

    #########
    # If the requested segment is known to be not available it is an unknown or error segment.
    #
    if(@known_segments && !scalar grep { /^$seg$/mxs } @known_segments) {
      $response .= $self->unknown_segment($seg);
      next;
    }

    # The bounds of the segment (if known).
    my $segstart        = $self->start($seg);
    my $segend          = $self->end($seg);

    #########
    # If the request is known to be out of range it is an error segment.
    #
    if($self->strict_boundaries()) {
      if ( ($start && $segstart && $start < $segstart) || ($end && $segend && $end > $segend ) ) {
        $response .= $self->error_segment($seg, $start, $end);
        next;
      }
    }

    # The actual sequence positions we are querying for.
    my $actstart        = $start || $segstart || q();
    my $actend          = $end   || $segend   || q();
    my $sequence       = $self->sequence({
                                          'segment' => $seg,
                                          'start'   => $start,
                                          'end'     => $end,
                                         });
    $self->_encode($sequence);
    my $seq            = $sequence->{'seq'};
    my $version        = $sequence->{'version'} || $self->segment_version($seg)     || q();
    my $label          = $sequence->{'label'}    ? qq( label="$sequence->{'label'}") : q();
    $actstart ||= 1;
    $actend   ||= CORE::length($seq) + ($actstart-1);
    $response         .= qq(  <SEQUENCE id="$seg" start="$actstart" stop="$actend" version="$version"$label>\n$seq\n  </SEQUENCE>\n);
  }

  return $response;
}

sub das_types {
  my ($self, $opts) = @_;
  $self->_encode($opts);
  my $response      = q();
  my $data          = {};

  if(!scalar @{$opts->{'segments'}}) {
    $data->{'anon'} = [];
    push @{$data->{'anon'}}, $self->build_types();

  } else {
    for my $seg (@{$opts->{'segments'}}) {
      my ($seg, $coords) = split /:/mxs, $seg;
      my ($start, $end)  = split /,/mxs, $coords || q();

      #########
      # If the requested segment is known to be not available it is an unknown or error segment.
      #
      my @known_segments = $self->known_segments();
      if(@known_segments && !scalar grep { /^$seg$/mxs } @known_segments) {
        $response .= $self->unknown_segment($seg);
        next;
      }

      # The bounds of the segment (if known).
      my $segstart        = $self->start($seg);
      my $segend          = $self->end($seg);

      #########
      # If the request is known to be out of range it is an error segment.
      #
      if($self->strict_boundaries()) {
        if ( ($start && $segstart && $start < $segstart) || ($end && $segend && $end > $segend ) ) {
          $response .= $self->error_segment($seg, $start, $end);
          next;
        }
      }

      # The actual sequence positions we are querying for.
      my $actstart        = $start || $segstart || q();
      my $actend          = $end   || $segend   || q();
      push @{$data->{"$seg:$actstart,$actend"}}, $self->build_types({
             'segment' => $seg,
             'start'   => $start,
             'end'     => $end,
      });
    }
  }

  for my $key (keys %{$data}) {
    my ($seg, $coords) = split /:/mxs, $key;
    my ($start, $end)  = split /,/mxs, $coords || q();

    if ($seg ne 'anon') {
      my $version = $self->segment_version($seg) || q();
      $response .= sprintf qq(<SEGMENT id="%s"%s%s%s>\n),
                       $seg,
                       $version ? qq( version="$version") : q(),
                       # The actual sequence positions we are querying for:
                       $start ? qq( start="$start") : q(),
                       $end   ? qq( stop="$end")    : q();

    } else {
      $response .= qq(<SEGMENT>\n);
    }

    for my $type (@{$data->{$key}}) {
      $self->_encode($type);
      my $cat   = $type->{category}     || $type->{typecategory} || $type->{type_category};
      my $desc  = $type->{description}  || $type->{typetxt};
      my $cv    = $type->{type_cvid}    || $type->{c_ontology};
      my $count = $type->{count};
      $response .= sprintf q(<TYPE id="%s"%s%s%s),
                           $type->{type} || q(),
                           $cv           ? qq( cvId="$cv")         : q(),
                           $cat          ? qq( category="$cat")     : q(),
                           $desc         ? qq( description="$desc") : q();
      if ($count) {
        $response .= qq(>$count</TYPE>\n);
      } else {
        $response .= qq( />\n);
      }
    }
    $response .= qq(</SEGMENT>\n);
  }

  return $response;
}

sub build_types {
  my ($self, $args) = @_;
  my $types = ();
  for my $feat ( $self->build_features($args) ) {
    my $key = $feat->{'type'};
    $types->{$key} ||= {
      'type'        => $key,
      'description' => $feat->{'typetxt'},
      'type_cvid'   => $feat->{'type_cvid'},
      'category'    => $feat->{'typecategory'} || $feat->{'type_category'},
      'count'       => 0,
    };
    $types->{$key}{'count'}++;
  }
  return values %{ $types };
}

sub das_entry_points {
  my ($self, $opts) = @_;

  my ($rows_start, $rows_end) = split /-/mxs, ($opts->{'rows'} || q()); # e.g. 11-20
  my @eps = $self->build_entry_points();
  my $total = scalar @eps;

  if (!$rows_start || $rows_start < 1) {
    $rows_start = 1;
  }
  if (!$rows_end || $rows_end > $total) {
    $rows_end = $total;
  }
  # Check arguments
  if ($rows_end < 1 || $rows_start > $total || $rows_start > $rows_end) {
    return _error(400, 402, "Requested rows are outside the valid range (1-$total)");
  }

  my $content = sprintf qq(  <ENTRY_POINTS href="%s/entry_points" total="%d" start="%d" end="%d">\n),
                        $self->source_url,
                        $total,
                        $rows_start,
                        $rows_end;

  for (my $i=$rows_start-1; $i<$rows_end; $i++) { ## no critic (ControlStructures::ProhibitCStyleForLoops)
    my $ep = $eps[$i];
    $self->_encode($ep);

    my $start  = $ep->{'start'};
    my $stop   = $ep->{'stop'};
    my $length = $ep>{'length'};
    if (!$start && ($stop || $length)) {
      $start = 1;
    }
    if (!$stop && $length) {
      $stop = ($length - $start) + 1;
    }

    my $subparts = $ep->{'subparts'} && $ep->{'subparts'} eq 'yes' ? q( subparts="yes") : q();
    $content    .= sprintf q(<SEGMENT id="%s"%s%s%s%s>%1$s</SEGMENT>), ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
                           $ep->{'segment'} || q{},
                           $start && $stop ? qq( start="$start") : q(),
                           $start && $stop ? qq( stop="$stop")   : q(),
                           $ep->{'subparts'} ? qq( subparts="$ep->{'subparts'}") : q(),
                           $ep->{'ori'}      ? qq( orientation="$ep->{'ori'}")   : q();
  }

  $content .= qq(\n  </ENTRY_POINTS>\n);

  return $content;
}

sub build_entry_points {
  my $self = shift;
  return map { { 'segment' => $_, 'length' => $self->length($_) } } $self->known_segments();
}

sub das_stylesheet {
  my $self = shift;
  my $defaultfile = File::Spec->catfile( $self->config->{'styleshome'},
                                         $self->config->{'stylesheetfile'} );
  return $self->_plain_response('stylesheet', $defaultfile) || q(<?xml version="1.0" standalone="yes"?><!DOCTYPE DASSTYLE SYSTEM "http://www.biodas.org/dtd/dasstyle.dtd"><DASSTYLE><STYLESHEET version="1.1"><CATEGORY id="default"><TYPE id="default"><GLYPH><BOX><FGCOLOR>red</FGCOLOR><FONT>sanserif</FONT><BGCOLOR>black</BGCOLOR></BOX></GLYPH></TYPE></CATEGORY></STYLESHEET></DASSTYLE>);
}

sub das_sourcedata {
  my ($self, $opts) = @_;

  #########
  # The metadata for each source is built from:
  # 1. the adaptor
  # 2. the adaptor config
  # 3. global config

  # Opening tag for this source implementation (version)
  my $resp = sprintf qq[    <VERSION uri="%s" created="%s">\n], $self->version_uri(), $self->dsncreated_iso();

  # Co-ordinate systems (key can be URI or description, value is test range)
  my $coords = $self->_coordinates();
  for my $coord (@{$coords}) {
    my $taxid   = $coord->{taxid}   ? qq[ taxid="$coord->{taxid}"]     : q();
    my $version = $coord->{version} ? qq[ version="$coord->{version}"] : q();
    $resp .= sprintf qq[      <COORDINATES uri="%s" source="%s" authority="%s"%s%s test_range="%s">%s</COORDINATES>\n],
                     $coord->{uri},
                     $coord->{source},
                     $coord->{authority},
                     $taxid,
                     $version,
                     $coord->{test_range},
                     $coord->{description};
  }

  # Supported commands
  # Capabilities are of form 'features' => '1.0'
  my $caps = $self->_capabilities();
  $resp .= sprintf qq[      <CAPABILITY type="das1:sources" query_uri="%s" />\n], $self->source_url();
  while (my ($cap, $ver) = each %{$caps}) {
    my $type      = 'das'.(int $ver);
    my $query_uri = (exists $Bio::Das::ProServer::WRAPPERS->{$cap})? (sprintf q[ query_uri="%s/%s"], $self->source_url, $cap): q();
    $resp .= qq[      <CAPABILITY type="$type:$cap"$query_uri />\n];
  }

  # Custom properties
  my $props = $self->properties();
  while (my ($name, $value) = each %{$props}) {
    my @values = (ref $value && ref $value eq 'ARRAY')? @{$value} : ($value);
    for my $detail (@values) {
      $resp .= sprintf qq[      <PROP name="%s" value="%s" />\n], $name, $detail;
    }
  }

  $resp .= qq(    </VERSION>\n);

  #########
  # Full data for all versions of a source
  #
  if(!$opts->{'skip_open'}) {
    $resp = sprintf qq[  <SOURCE uri="%s" title="%s" doc_href="%s" description="%s">\n    <MAINTAINER email="%s" />\n%s],
                    $self->source_uri(),
                    $self->title(),
                    $self->doc_href() || $self->source_url(),
                    $self->description(),
                    $self->maintainer(), $resp;
  }

  if(!$opts->{'skip_close'}) {
    $resp .= qq[  </SOURCE>\n];
  }

  return $resp;
}

sub das_xsl {
  my ($self, $opts) = @_;
  my $call = $opts->{call};

  if(!$call) {
    return q();
  }

  my ($type)      = $call =~ m/(.+)\.xsl$/mxs;
  my $defaultfile = File::Spec->catfile($self->config()->{'styleshome'}, "xsl_$call");
  my $response    = $self->_plain_response($type.q(_xsl), $defaultfile);

  if(!$response) {
    carp qq(Unable to parse $type XSL from disk);
  }

  return $response;
}

sub _plain_response {
  my ($self, $cfghead, $default) = @_;
  if(!$cfghead) {
    return q();
  }

  if($self->config->{$cfghead}) {
    #########
    # Inline static
    #
    return $self->config->{$cfghead};

  } else {
    my $filedata;
    for my $filename ($self->config->{"${cfghead}file"}, $default) {
      #########
      # import static file
      #
      last if $filedata;
      if ($filename) {

        if ($self->{'debug'}) {
          carp "Trying to read file: $filename";
        }
        if (-e $filename) {
          my ($fn) = $filename =~ m{([a-z\d_\./\-]+)}mixs;
          eval {
            open my $fh, q(<), $fn or croak "Opening $filename '$fn': $ERRNO";
            local $RS = undef;
            $filedata = <$fh>;
            close $fh or croak $ERRNO;
            1;
          } or do {
            carp $EVAL_ERROR;
          };
        } elsif ($self->{'debug'}) {
          carp "File does not exist: $filename";
        }
      }
    }

    #########
    # Cache unless configured not to do so
    #
    if(($self->config->{"cache${cfghead}file"}||'yes') eq 'yes') {
      $self->{"${cfghead}file"} ||= $filedata;
    }

    $filedata and return $filedata;
  }
  return;
}

sub das_alignment {
  my ($self, $opts) = @_;
  $self->_encode($opts);
  my $response      = q();
  my $sub_coos      = $opts->{'subcoos'} || q();
  my $rows          = $opts->{'rows'}    || q();
  my $cols          = $opts->{'cols'}    || q();

  my @queries = grep { $_ } @{ $opts->{'queries'} };
  if (!scalar @queries) {
    return _error(400, 402, q(The 'query' parameter is required.));
  }
  my @subjects = grep { $_ } @{ $opts->{'subjects'} };
  if (scalar @subjects && $rows) {
    return _error(400, 402, q(The 'subject' and 'rows' parameters may not both be present in the same request.));
  }
  if ($rows && $rows !~ /^\d+-\d+/mxs) {
    return _error(400, 402, q(The 'rows' parameter must be of format: 'START-END'));
  }
  if ($cols && $cols !~ /^\d+-\d+/mxs) {
    return _error(400, 402, q(The 'cols' parameter must be of format: 'START-END'));
  }

  my @known_segments = $self->known_segments();

  for my $query (@queries) {

    #########
    # If the requested segment is known to be not available it is an unknown or error segment.
    #
    if (scalar @known_segments && !scalar grep { /^$query$/mxs } @known_segments) {
      $response .= $self->unknown_segment($query);
      next;
    }

    #########
    # The build_alignment should be implemented by the SourceAdaptor subclass
    #
    for my $ali ($self->build_alignment($query, $rows, \@subjects, $sub_coos, $cols)) {
      $self->_encode($ali);
      $response .= sprintf qq(<alignment%s%s%s%s%s>\n),
                           $ali->{'name'}     ?qq( name="$ali->{'name'}"):q(),
                           $ali->{'type'}     ?qq( alignType="$ali->{'type'}"):q(),
                           $ali->{'max'}      ?qq( max="$ali->{'max'}"):q(),
                           $ali->{'position'} ?qq( position="$ali->{'position'}"):q(),
                           $ali->{'description'} ?qq( description="$ali->{'description'}"):q();

      for my $ali_obj (grep { $_ } @{$ali->{'alignObj'}}) {
        $response .= _gen_align_object_response($ali_obj);
      }

      for my $score (@{$ali->{'scores'}}) {
        $response .= _gen_align_score_response($score);
      }

      for my $block (@{$ali->{'blocks'}}) {
        $response .= _gen_align_block_response($block);
      }

      for my $geo3d (@{$ali->{'geo3D'}}) {
        $response .= _gen_align_geo3d_response($geo3d);
      }
      $response .= qq(</alignment>\n);
    } # end alignment loop

  } #Êend query ID loop

  return $response;
}

# Helper method for use by subclasses in order to implement the row filtering
# functionality of the alignment command
sub restrict_alignment_rows {
  my ($self, $alignment, $rows, $subjects, $sub_coos) = @_;

  if (!$rows && !scalar @{ $subjects }) {
    return;
  }

  my @ali_obs = grep { $_ } @{ $alignment->{'alignObj'} };
  my @allowed_objects = ();
  my @allowed_blocks  = ();
  my %allowed_int_ids = ();
  $alignment->{'alignObj'} = \@allowed_objects;

  if ($rows) {
    my ($row_start, $row_end) = split /-/mxs, $rows;
    $row_start = $row_start < 1 ? 0 : $row_start - 1;
    $row_end   = $row_end > @ali_obs ? @ali_obs : $row_end;
    for (my $i=$row_start; $i<$row_end; $i++) { ## no critic (ControlStructures::ProhibitCStyleForLoops)
      my $ali_obj = $ali_obs[$i];
      push @allowed_objects, $ali_obj;
      $allowed_int_ids{$ali_obj->{'id'} || $ali_obj->{'intID'}} = 1;
    }
  }

  if (scalar @{ $subjects }) {
    my %positions;

    # First assign a row position to each subject in the alignment
    for (my $i=0; $i<@ali_obs; $i++) { ## no critic (ControlStructures::ProhibitCStyleForLoops)
      my $ali_obj = $ali_obs[$i];
      # Only match on the correct coordinate system...
      my $ali_coos = $ali_obj->{'dbCoordSys'}  || $ali_obj->{'coos'};
      if ($sub_coos && $ali_coos && $sub_coos ne $ali_coos) {
        next;
      }
      my $id = $ali_obj->{'dbAccession'} || $ali_obj->{'accession'} || $ali_obj->{'id'} || $ali_obj->{'intID'};
      $positions{$id} = $i+1;
    }

    # Process each subject filter to obtain a range of positions
    for my $raw (@{ $subjects }) {
      my ($subject,$before,$after) = split /[:,]/mxs, $raw;
      $before ||= 0;
      $after  ||= 0;
      my $mid = $positions{$subject} || next;
      my $lo = $mid - $before;
      my $hi = $mid + $after;
      $lo = $lo < 1 ? 0 : $lo - 1;
      $hi = $hi > @ali_obs ? @ali_obs : $hi;
      for (my $i=$lo; $i<$hi; $i++) { ## no critic (ControlStructures::ProhibitCStyleForLoops)
        my $ali_obj = $ali_obs[$i];
        push @allowed_objects, $ali_obj;
        $allowed_int_ids{$ali_obj->{'id'} || $ali_obj->{'intID'}} = 1;
      }

    }
  }

  for my $block (@{ $alignment->{'blocks'} }) {
    my @allowed_segments = ();
    for my $segment (@{ $block->{'segments'} }) {
      $allowed_int_ids{$segment->{'id'} || $segment->{'objectId'}} || next;
      push @allowed_segments, $segment;
    }
    scalar @allowed_segments || next;
    $block->{'segments'} = \@allowed_segments;
    push @allowed_blocks, $block;
  }
  $alignment->{'blocks'} = \@allowed_blocks;

  return;
}

sub restrict_alignment_columns {
  my ($self, $alignment, $cols) = @_;

  if ($cols) {
    my @ali_obs = grep { $_ } @{ $alignment->{'alignObj'} };
    my %ali_obs = map { ($_->{'id'} || $_->{'intID'}) => $_ } @ali_obs;
    my @allowed_blocks; # filtered blocks

    # alter blocks
    # a block is a single horizontal section, with at least 2 object segments
    my $block_start;
    my $block_end = 0;
    my $block_num = 0;

    BLOCK: for my $block (sort { ($a->{'blockOrder'}||1) <=> ($b->{'blockOrder'}||1) } @{ $alignment->{'blocks'} }) {
      $block_start = $block_end + 1;
      $block_end   = undef;

      # First things first, work out how big this block is; it may be outside
      # the range filter entirely

      my $segment = $block->{'segments'}->[0];
      my $segment_id = $segment->{'id'} || $segment->{'objectId'};
      my $cigar = $segment->{'cigar'} || q();
      my $sequence = $ali_obs{$segment_id}->{'sequence'};

      # If the segment is a cigar, we have to work out how big the block is
      # in alignment coordinates
      if ($cigar) {
        my $block_length = 0;
        my $tmp = $cigar;
        while ($tmp) {
          $tmp =~ s/^(\d*)[MID]//msx || croak 'Unexpected cigar format: '.substr($cigar, 0, 8).'...';
          $block_length += ($1 || 1);
        }
        $block_end = $block_start + $block_length - 1;
      }
      # Otherwise the block represents all matches, i.e. alignment
      # coordinates is the same as object coordinates
      elsif ($segment->{'start'} && $segment->{'end'}) {
        $block_end = $block_start + ($segment->{'end'} - $segment->{'start'});
      }
      # If there is no cigar and no start/end, the segment represents the
      # whole of the sequence
      elsif ($sequence) {
        $segment->{'start'} = 1;
        my $block_length = $segment->{'end'} = CORE::length($sequence);
        $block_end = $block_start + $block_length - 1;
      }
      # There is no way to find the length of each object, so no way to
      # filter by column. Indeed there is no need, as the alignment
      # construction is implicitly all matches.
      else {
        return;
      }


      my @allowed_segments;

      SEGMENT: for my $segment (@{ $block->{'segments'} }) {
        $segment = $self->_restrict_alignment_columns_segment($segment,
                                                              $cols,
                                                              $block_start, $block_end);
        if ($segment) {
          push @allowed_segments, $segment;
        }
      }

      if (scalar @allowed_segments) {
        push @allowed_blocks, $block;
        $block->{'blockOrder'} = scalar @allowed_blocks;
        $block->{'segments'} = \@allowed_segments;
      }
    }
    $alignment->{'blocks'} = \@allowed_blocks;
  }

  return;
}

sub _restrict_alignment_columns_segment {
  my ($self, $segment, $cols, $block_start, $block_end) = @_;

  my @allowed_segments;
  my $cigar = $segment->{'cigar'} || q();
  my ($start, $end) = split /-/mxs, $cols;

  # If the block lies completely outside the requested slice, skip it entirely
  if ($block_end < $start || $block_start > $end) {
#   warn "Block $block_start - $block_end lies completely outside slice $start - $end";
    return;
  }

  # If the block lies completely inside the requested slice, include it verbatim
  if ($block_start >= $start && $block_end <= $end) {
#   warn "Block $block_start - $block_end lies completely inside slice $start - $end";
    return $segment;
  }

  # Otherwise the block straddles at least one end of the slice, so it
  # must be adjusted
# warn "Block $block_start - $block_end lies partially inside slice $start - $end";

  # No cigar string means the block is contiguous matches. We only need
  # to edit the start/end of each segment
  if (!$cigar) {
    if ($block_start < $start) {
      $segment->{'start'} += ($start - $block_start);
    }
    if ($block_end > $end) {
      $segment->{'end'} -= ($block_end - $end);
    }
    return $segment;
  }

  # Otherwise we must adjust the cigar string... (this is pretty hairy)
  $segment->{'cigar'} = q();
  my $piece_end = $block_start - 1;
  my $segment_piece_end = ($segment->{'start'} || 1) - 1;
  my $start_adjustment_flag = 0;
  my $piece;

  while ($cigar) {
    $cigar =~ s/^(\d*)([MID])//mxs || croak 'Unexpected cigar format: '.substr($cigar, 0, 8).'...';
    my ($piece_length, $piece_type) = ($1, $2);
    $piece_length ||= 1;
    # Advance the alignment coordinates:
    my $piece_start  = $piece_end + 1;
    $piece_end += $piece_length;
    $piece = q();

    my $segment_piece_start = $segment_piece_end;
    if ($piece_type eq 'M') {
      # Advance the segment coordinates:
      $segment_piece_start += 1;
      $segment_piece_end += $piece_length;
    }

#              warn "--$piece_length$piece_type--";
#              warn "  Piece: $piece_start - $piece_end ...... $segment_piece_start - $segment_piece_end";

    # unless cigar piece is completely outside the slice
    if ($piece_start <= $end && $piece_end >= $start) {

      # handle cases where the slice start was in a previous (gap) piece
      if ($piece_type eq 'M' && $start_adjustment_flag) {
        $segment->{'start'} = $segment_piece_start;
        $start_adjustment_flag = 0;
      }

      # are we moving over the slice start boundary?
      if ($piece_start <= $start && $piece_end >= $start) {
        my $chop_from_front = $start - $piece_start;
        $piece_length -= $chop_from_front;
        if ($piece_type eq 'M') {
          $segment->{'start'} = $segment_piece_start + $chop_from_front;
        }
        # the start of the slice is in a gap for this segment...
        else {
          $start_adjustment_flag = 1;
          delete $segment->{'start'};
        }
      }
      # are we moving over the slice end boundary?
      if ($piece_start <= $end && $piece_end >= $end) {
        my $chop_from_back = $piece_end - $end;
        $piece_length -= $chop_from_back;
        if ($piece_type eq 'M') {
          $segment->{'end'} = $segment_piece_end - $chop_from_back;
        }
        # the end of the slice is in a gap for this segment...
        else {
          $segment->{'end'} = $segment_piece_end;
        }
      }

      $piece_length = $piece_length > 1 ? $piece_length : q();
      $piece = $piece_length . $piece_type;
    }

    $segment->{'cigar'} .= $piece;
  }

  # Unless the edited cigar is all gaps, include the edited segment
  if ($segment->{'cigar'} =~ m/M/mxs) {
    return $segment;
  }

  return;
}

sub _gen_align_object_response {
  my ($ali_obj) = @_;
  my $children  = 0;

  my $response = sprintf q(  <alignObject objectVersion="%s" intObjectId="%s" dbSource="%s" dbVersion="%s" dbAccessionId="%s"%s dbCoordSys="%s">),
                 $ali_obj->{'version'}     || q(),
                 $ali_obj->{'id'}          || $ali_obj->{'intID'}     || q(),
                 $ali_obj->{'dbSource'}    || q(),
                 $ali_obj->{'dbVersion'}   || q(),
                 $ali_obj->{'dbAccession'} || $ali_obj->{'accession'} || q(),
                 $ali_obj->{'chain'} ? qq( chain="$ali_obj->{'chain'}") : q(),
                 $ali_obj->{'dbCoordSys'}  || $ali_obj->{'coos'} || q();

  for my $detail (@{$ali_obj->{'aliObjectDetail'}}) {
    $children++;
    my $value = $detail->{'value'} || $detail->{'detail'};
    $response .= sprintf qq(\n    <alignObjectDetail dbSource="%s" property="%s"%s>),
                         $detail->{'dbSource'} || $detail->{'source'}   || q(),
                         $detail->{'property'} || q(),
                         $value?qq(>$value</alignObjectDetail):q(/);

  }

  #Finally if the sequence is present, add this
  if(my $seq = $ali_obj->{'sequence'}) {
    $children++;
    $response .= qq(\n    <sequence>$seq</sequence>);
  }

  #Finish off the ALIGNOBJECT
  if($children) {
    $response .= qq(\n  </alignObject>\n);

  } else {
     #bit of a hack, but makes nice well formed xml
    chop $response; # This will remove the >
    $response .= qq( />\n);
  }
  return $response;
}

sub _gen_align_score_response {
  my($score) = @_;
  return sprintf qq(  <score methodName="%s" value="%s" />\n),
                 $score->{'method'} || q(),
                 $score->{'score'}  || '0';
}

sub _gen_align_block_response {
  my($block) = @_;

  #########
  # The code assumes that if a block is passed in, it has an alignment
  # segment.  Although the code would not break, I doubt that it would validate
  # against the schema.
  #

  #########
  # Block tag with required and optional attributes
  #
  my $response .= sprintf qq(  <block blockOrder="%s"%s>\n),
                          $block->{'blockOrder'} || 1,
                          $block->{'blockScore'}?qq( blockScore="$block->{'blockScore'}"):q();

  for my $segment (@{$block->{'segments'}}) {
    $response .= sprintf q(    <segment intObjectId="%s"%s%s%s%s),
                         $segment->{'id'} || $segment->{'objectId'},
                         (exists $segment->{'start'})?qq( start="$segment->{'start'}"):q(),
                         (exists $segment->{'end'})  ?qq( end="$segment->{'end'}"):q(),
                         $segment->{'orientation'}?qq( orientation="$segment->{'orientation'}"):q(),
                         $segment->{'cigar'}?qq(>\n      <cigar>$segment->{'cigar'}</cigar>\n    </segment>\n):qq( />\n);
  }

  #########
  # close the block
  #
  $response .= qq(  </block>\n);
  return $response;
}

sub _gen_align_geo3d_response {
  my($geo3d) = @_;

  #########
  # The geo3d is a reference to a 2D array.
  #
  my $response = q();
  my $id       = $geo3d->{'id'} || $geo3d->{'intObjectId'} || q();
  my $vector   = $geo3d->{'vector'};
  my $matrix   = $geo3d->{'matrix'};

  $response .= qq(  <geo3D intObjectId="$id">\n);

  if($vector && $matrix) { #These are both required
    my $x      = $vector->{'x'} || '0.0';
    my $y      = $vector->{'y'} || '0.0';
    my $z      = $vector->{'z'} || '0.0';
    $response .= qq(    <vector x="$x" y="$y" z="$z" />\n);
    $response .= q(    <matrix);

    for my $m1 (0,1,2) {
      for my $m2 (0,1,2) {
        my $coordinate = $matrix->[$m1]->[$m2] || '0.0';
        my $n1         = $m1 + 1;#Bit of a hack, but ensures data integrity between the array and xml with next to no effort.
        my $n2         = $m2 + 1;#ditto
        $response     .= qq( mat$n1$n2="$coordinate");
      }
    }
    $response .= qq( />\n);
  }
  $response .= qq(  </geo3D>\n);
  return $response;
}

sub das_structure {
  my($self, $opts) = @_;
  $self->_encode($opts);
  my $response     = q();

  # Get the arguments
  my $query  = $opts->{'query'};
  my $chains = $opts->{'chains'} || [];
  my $models = $opts->{'models'} || [];

  # Validate the arguments
  if (!$query) {
    return _error(400, 402, q(The 'query' parameter is required));
  }
  for my $chain (@{ $chains }) {
    $chain =~ m/^[A-Za-z0-9]$/mxs || return _error(400, 402, "Requested chain ($chain) must be a single alphanumeric character");
  }
  for my $model (@{ $models }) {
    $model =~ m/^\d+$/mxs || return _error(400, 402, "Requested model ($model) must be an integer");
  }

  #########
  # If the requested segment is known to be not available it is an unknown or error segment.
  #
  my @known_segments = $self->known_segments();
  if(@known_segments && !scalar grep { /^$query$/mxs } @known_segments) {
    return $self->unknown_segment($query);
  }

  #The build_structure should be specified by the sourceAdaptor subclass

  my $structure = $self->build_structure($query, $chains, $models);
  $self->_encode($structure);

  for my $obj (@{$structure->{'objects'}}) {
    $response .= _gen_object_response($obj);
  }

  for my $chain (@{$structure->{'chains'}}) {
    # Apply chain and model filters here, in case the adaptor didn't
    if (scalar @{ $chains }) {
      if (!scalar grep { $chain->{'id'} eq $_ } @{ $chains }) {
        next;
      }
    }
    if (scalar @{ $models }) {
      if (!scalar grep { $chain->{'modelNumber'} eq $_ } @{ $models }) {
        next;
      }
    }
    $response .= _gen_chain_response($chain);
  }

  # Maybe we should filter chains and models from the connections, but this is
  # expensive and probably not necessary.
  for my $connect (@{$structure->{'connects'}}) {
    $response .= _gen_connect_response($connect);
  }

  return $response;
}

sub _gen_object_response {
  my ($object) = @_;
  my $children = 0;

  my $response .= sprintf q(<object objectVersion="%s" dbSource="%s" dbVersion="%s" dbAccessionId="%s" dbCoordSys="%s">),
                          $object->{'objectVersion'} || q(),
                          $object->{'dbSource'}      || q(),
                          $object->{'dbVersion'}     || q(),
                          $object->{'dbAccessionId'} || q(),
                          $object->{'dbCoordSys'}    || 'PDBresnum,Protein Structure';

  for my $obj_detail (@{$object->{'objectDetails'}}) {
    $children++;
    $response .= sprintf q(<objectDetail dbSource="%s" property="%s">%s</objectDetail>),
                         $obj_detail->{'source'}   || q(),
                         $obj_detail->{'property'} || q(),
                         $obj_detail->{'detail'}   || q();
  }

  #########
  # Finish off the object
  #
  if($children) {
    $response .= q(</object>);

  } else {
    #########
    # bit of a hack, but makes nice well formed xml
    # Remove the trailing '>' and self-close
    #
    chop $response;
    $response .= q( />);
  }
  return $response;
}

sub _gen_chain_response {
  my ($chain) = @_;

  #########
  # Set up the chain properties, chain id, swisprot mapping and model number.
  #
  my $id = $chain->{'id'} || q();
  if($id =~ /null/mxs) {
    $id = q();
  }

  my $response .= sprintf q(<chain id="%s" %s>),
                          $id,
                          $chain->{'modelNumber'}?qq(model="$chain->{'modelNumber'}"):q();

  #########
  # Now add the "residues" to the chain
  #
  for my $group (@{$chain->{'groups'}}) {
    my $gid   = $group->{'id'};
    my $icode = $group->{'icode'} || q();

    #########
    # Residue properties
    #
    $response .= sprintf q(<group type="%s" groupID="%s" name="%s" %s>),
                         $group->{'type'},
                         $gid,
                         $group->{'name'},
                         $icode ? qq(insertCode="$icode") : q();

    #########
    # Add the atoms to the chain
    #
    for my $atom (@{$group->{'atoms'}}) {
      $response .= sprintf q(<atom x="%s" y="%s" z="%s" atomName="%s" atomID="%s"%s%s%s/>),
                           (map { $atom->{$_} } qw(x y z atomName atomId)),
                           (map { $atom->{$_}?qq( $_="$atom->{$_}"):q() } qw(occupancy tempFactor altLoc));

    }
    #close group tag
    $response .= q(</group>);
  }

  #close chain tag
  $response .= q(</chain>);
  return $response;
}

sub _gen_connect_response {
  my ($connect)    = @_;
  my $response     = q();
  my $atom_serial  = $connect->{'atomSerial'} || undef;
  my $connect_type = $connect->{'type'}       || q();

  if($atom_serial) {
    $response .= qq(<connect atomSerial="$atom_serial" type="$connect_type">);

    for my $atom (@{$connect->{'atom_ids'}}) {
      $response .= qq(<atomid atomID="$atom"/>);
    }
    $response .= q(</connect>);
  }
  return $response;
}

sub das_interaction {
  my ($self, $opts) = @_;
  $self->_encode($opts);

  my $operation   = $opts->{'operation'} || 'intersection';
  my $interactors = $opts->{'interactors'};
  my $details = {};
  for (@{ $opts->{'details'} }) {
    my ($key, $val) = split /,/mxs, $_;
    $key =~ s/^property://mxs;
    if(defined $val) {
      $val =~ s/^value://mxs;
    }
    $details->{$key} = $val;
  }

  my $struct = $self->build_interaction({
                                         interactors => $interactors,
                                         details     => $details,
                                         operation   => $operation,
                                        });
  $self->_encode($struct);

  my $response = q();
  for my $interactor (@{ $struct->{interactors} }) {
    $response .= _gen_interactor_response($interactor);
  }

  for my $interaction (@{ $struct->{interactions} }) {
    $response .= _gen_interaction_response($interaction);
  }

  return $response;

}

sub _gen_interactor_response {
  my ($interactor) = @_;

  my $response = sprintf q(<INTERACTOR intId="%s" shortLabel="%s" dbSource="%s" dbAccessionId="%s" dbCoordSys="%s"),
                         $interactor->{id}          || 'unknown',
                         $interactor->{label}       || $interactor->{name} || $interactor->{id} || 'unknown',
                         $interactor->{dbSource}    || 'unknown',
                         $interactor->{dbAccession} || $interactor->{id}   || 'unknown',
                         $interactor->{dbCoordSys}  || 'unknown';
  if($interactor->{dbSourceCvId}) {
    $response .= sprintf q( dbSourceCvId="%s"), $interactor->{dbSourceCvId};
  }
  if($interactor->{dbVersion}) {
    $response .= sprintf q( dbVersion="%s"), $interactor->{dbVersion};
  }
  $response .= (exists $interactor->{details} || exists $interactor->{sequence}) ? q(>) : q(/>);

  my $details = $interactor->{details} || [];
  if (ref $details eq 'HASH') {
    $details = [$details];
  }

  for my $detail (@{$details}) {
    $response .= _gen_interaction_detail_response($detail);
  }

  if (my $sequence = $interactor->{sequence}) {
    if (! ref $sequence) {
      $sequence = {sequence=>$sequence};
    }
    $response .= sprintf q(<SEQUENCE%s%s>%s</SEQUENCE>),
                         $sequence->{start} ? qq( start="$sequence->{start}") : q(),
                         $sequence->{end}   ? qq( end="$sequence->{end}")     : q(),
                         $sequence->{sequence};
  }

  if(exists $interactor->{details} || exists $interactor->{sequence}) {
    $response .= q(</INTERACTOR>);
  }

  return $response;
}

sub _gen_interaction_response {
  my ($interaction) = @_;

  my $response = sprintf q(<INTERACTION name="%s" dbSource="%s" dbAccessionId="%s"),
                         $interaction->{label}       || $interaction->{name}  || 'unknown',
                         $interaction->{dbSource}    || 'unknown',
                         $interaction->{dbAccession} || $interaction->{label} || $interaction->{name} || 'unknown';
  if($interaction->{dbSourceCvId}) {
    $response .= sprintf q( dbSourceCvId="%s"), $interaction->{dbSourceCvId};
  }
  if($interaction->{dbVersion}) {
    $response .= sprintf q( dbVersion="%s"), $interaction->{dbVersion};
  }
  $response .= q(>);

  my $details = $interaction->{details} || [];
  if (ref $details eq 'HASH') {
    $details = [$details];
  }

  for my $detail (@{$details}) {
    $response .= _gen_interaction_detail_response($detail);
  }

  for my $participant (@{ $interaction->{participants} }) {
    $response .= qq(<PARTICIPANT intId="$participant->{id}");
    $response .= exists $participant->{details} ? q(>) : q(/>);
    $details = $participant->{details} || [];

    if (ref $details eq 'HASH') {
      $details = [$details];
    }

    for my $detail (@{$details}) {
      $response .= _gen_interaction_detail_response($detail);
    }
    $response .= exists $participant->{details} ? q(</PARTICIPANT>) : q();
  }
  $response .= q(</INTERACTION>);
  return $response;
}

sub _gen_interaction_detail_response {
  my ($details) = @_;

  my $response = sprintf q(<DETAIL property="%s" value="%s"),
                         $details->{property} || $details->{key},
                         $details->{value}    || $details->{details};
  if($details->{propertyCvId}) {
    $response .= sprintf q( propertyCvId="%s"), $details->{propertyCvId};
  }
  if($details->{valueCvId}) {
    $response .= sprintf q( valueCvId="%s"), $details->{valueCvId};
  }

  if ($details->{start}) {
    $response .= q(>);
    $response .= sprintf q(<RANGE start="%s" end="%s"),
                         $details->{start},
                         $details->{end} || $details->{start};
    if($details->{startStatus}) {
      $response .= sprintf q( startStatus="%s"), $details->{startStatus};
    }
    if($details->{endStatus}) {
      $response .= sprintf q( endStatus="%s"), $details->{endStatus};
    }
    if($details->{startStatusCvId}) {
      $response .= sprintf q( startStatusCvId="%s"), $details->{startStatusCvId};
    }
    if($details->{endStatusCvId}) {
      $response .= sprintf q( endStatusCvId="%s"), $details->{endStatusCvId};
    }
    $response .= q(/></DETAIL>);
  } else {
    $response .= q(/>);
  }

  return $response;
}

sub das_volmap {
  my ($self, $opts) = @_;
  $self->_encode($opts);

  my $segment = $opts->{query} || q();
  #########
  # If the requested segment is known to be not available it is an unknown or error segment.
  #
  my @known_segments = $self->known_segments();
  if ( !$segment || (@known_segments && !scalar grep { /^$segment$/mxs } @known_segments) ) {
    return $self->unknown_segment($segment);
  }

  my $volmap = $self->build_volmap($segment);
  $self->_encode($volmap);
  my $response = sprintf q(<VOLMAP id="%s" class="%s" type="%s" version="%s">),
                         $volmap->{id},
                         $volmap->{class},
                         $volmap->{type},
                         $volmap->{version};
  my $link    = $volmap->{link};
  my $linktxt = $volmap->{linktxt} || $link;

  if (ref $link && ref $link eq 'HASH') {
    my @tmp = keys %{ $link };
    $linktxt = $link->{$tmp[0]};
    $link    = $tmp[0];
  }

  $response .= qq(<LINK href="$link">$linktxt</LINK></VOLMAP>);

  my $notes = $volmap->{note} || [];
  if(!ref $notes) {
    $notes = [$notes];
  }

  for (@{$notes}) {
    $response .= sprintf q(<NOTE>%s</NOTE>), $_;
  }

  return $response;
}

sub cleanup {
  my $self  = shift;
  my $debug = $self->{debug};

  if(!$self->config->{autodisconnect}) {
    $debug and print {*STDERR} "${self}::cleanup retaining transports\n";
    return;

  } else {
    if(!$self->{_transport}) {
      $debug and print {*STDERR} "${self}::cleanup no transports loaded\n";
      return;
    }

    for my $name (keys %{$self->{_transport}}) {
      my $transport = $self->transport($name);
      if($self->config->{autodisconnect} eq 'yes') {
        eval {
          $transport->disconnect();
          $debug and print {*STDERR} qq(${self}::cleanup performed forced transport disconnect\n);
          1;
        } or do {
        };

      } elsif($self->config->{autodisconnect} =~ /(\d+)/mxs) {
        my $now = time;
        if($now - $transport->init_time() > $1) {
          eval {
            $transport->disconnect();
            $transport->init_time($now);
            $debug and print {*STDERR} qq(${self}::cleanup performed timed transport disconnect\n);
            1;
          } or do {
          };
        }
      }
    }

  }
  return;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor - base class for sources

=head1 VERSION

$Revision: 688 $

=head1 SYNOPSIS

A base class implementing stubs for all SourceAdaptors.

=head1 DESCRIPTION

SourceAdaptor.pm generates XML and manages callouts for DAS request
handling.

If you're extending ProServer, this class is probably what you need to
inherit. The build_* methods are probably the ones you need to
extend. build_features() in particular.

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>

Andy Jenkinson <andy.jenkinson@ebi.ac.uk>

=head1 SUBROUTINES/METHODS

=head2 new - Constructor

  my $oSourceAdaptor = Bio::Das::ProServer::SourceAdaptor::<implementation>->new({
    'dsn'      => q(),
    'port'     => q(),
    'hostname' => q(),
    'protocol' => q(),
    'baseuri'  => q(),
    'config'   => q(),
    'debug'    => 1,
  });

  Generally this would only be invoked on a subclass

=head2 init - Post-construction initialisation, passed the first argument to new()

  $oSourceAdaptor->init();

=head2 length - Returns the segment-length given a segment

  my $sSegmentLength = $oSourceAdaptor->length('DYNA_CHICK');
  
  By default returns 0

=head2 mapmaster - Mapmaster for this source.

  my $sMapMaster = $oSourceAdaptor->mapmaster();
  
  By default returns configuration 'mapmaster' setting

=head2 description - Description for this source.

  my $sDescription = $oSourceAdaptor->description();
  
  By default returns configuration 'description' setting or $self->title

=head2 doc_href - Location of a homepage for this source.

  my $sDocHref = $oSourceAdaptor->doc_href();
  
  By default returns configuration 'doc_href' setting

=head2 title - Short title for this source.

  my $title = $oSourceAdaptor->title();
  
  By default returns configuration 'title' setting or $self->source_uri

=head2 source_uri - URI for all versions of a source.

  my $uriS = $oSourceAdaptor->source_uri();
  
  By default returns configuration 'source_uri' setting or $self->dsn

=head2 version_uri - URI for a specific version of a source.

  my $uriV = $oSourceAdaptor->version_uri();
  
  By default returns configuration 'version_uri' setting or $self->source_uri

=head2 maintainer - Contact email for this source.

  my $email = $oSourceAdaptor->maintainer();
  
  By default returns configuration 'maintainer' setting, server setting or an empty string

=head2 strict_boundaries - Whether to return error segments for out-of-range queries

  my $strict = $oSourceAdaptor->strict_boundaries(); # boolean
  
  By default returns configuration 'strict_boundaries' setting, server setting or nothing (false)

=head2 build_features - (subclasses only) Fetch feature data

This call is made by das_features(). It is passed one of:

 { 'segment'    => $,
   'start'      => $,
   'end'        => $,
   'types'      => [$,$,...],
   'categories' => [$,$,...],
   'maxbins'    => $ }        # if support is indicated by the 'maxbins' capability

OR, if support is indicated by the 'feature-by-id' capability:

 { 'feature_id' => $,
   'types'      => [$,$,...],
   'categories' => [$,$,...],
   'maxbins'    => $ }        # if support is indicated by the 'maxbins' capability

When running in legacy mode, it may also be passed:

 { 'group_id'   => $,
   'types'      => [$,$,...],
   'categories' => [$,$,...],
   'maxbins'    => $ }        # if support is indicated by the 'maxbins' capability

The 'types' and 'categories' parameters are filters. They do not need to be
honoured as the das_features method will do this for you. They are included in
case you wish to use them to improve performance.

The method must return an array of hash references, i.e.
 ( {},{}...{} )

Each hash returned represents a single feature and should contain a
subset of the following keys and types. For scalar types (i.e. numbers
and strings) refer to the specification on biodas.org.

 segment                       => $               # segment ID (if not provided)
 id       || feature_id        => $               # feature ID
 label    || feature_label     => $               # feature text label
 start                         => $               # feature start position
 end                           => $               # feature end position
 ori                           => $               # feature strand
 phase                         => $               # feature phase
 type                          => $               # feature type ID
 type_cvid                     => $               # feature type controlled vocabulary ID
 typetxt                       => $               # feature type text label
 typecategory || type_category => $               # feature type category
 typesubparts                  => $               # feature has subparts
 typesuperparts                => $               # feature has superparts
 typereference                 => $               # feature is reference
 method                        => $               # annotation method ID
 method_cvid                   => $               # annotation method controlled vocabulary ID
 method_label                  => $               # annotation method text label
 score                         => $               # annotation score
 note                          => $ or [$,$,$...] # feature text note
 ##########################################################################
 # For one or more links:
 link                          => $ or [$,$,$...] # feature link href
 linktxt                       => $ or [$,$,$...] # feature link label
 # For hash-based links:
 link                          => {
                                   $ => $,        # href => label
                                   ...
                                  }
 ###############################################################################
 # For a single target:
 target_id                     => $               # target ID
 target_start                  => $               # target start position
 target_stop                   => $               # target end position
 targettxt                     => $               # target text label
 # For multiple targets:
 target                        => scalar or [{
                                              id        => $,
                                              start     => $,
                                              stop      => $,
                                              targettxt => $,
                                             },{}...]
 ###############################################################################
 # For hierarchical relationships:
 parent                        => $ or [$,$,$...] # parent feature IDs
 part                          => $ or [$,$,$...] # child feature IDs
 ###############################################################################

When running in legacy mode, the following may also be included:

 # For a single group:
 group_id                      => $               # feature group ID
 grouplabel                    => $               # feature group text label
 grouptype                     => $               # feature group type ID
 groupnote                     => $               # feature group text note
 grouplink                     => $               # feature group ID
 grouplinktxt                  => $               # feature group ID
 # For multiple groups:
 group                         => [{
                                    grouplabel   => $
                                    grouptype    => $
                                    groupnote    => $
                                    grouplink    => $
                                    grouplinktxt => $
                                    note         => $ or [$,$,$...]
                                    target       => [{
                                                      id        => $
                                                      start     => $
                                                      stop      => $
                                                      targettxt => $
                                                     }],
                                   }, {}...]
 ###############################################################################

=head2 sequence - (Subclasses only) fetch sequence data

This call is made by das_sequence(). It is passed:

 { 'segment'    => $, 'start' => $, 'end' => $ }

It is expected to return a hash reference:

 {
  seq     => $,
  version => $, # can also be specified with the segment_version method
  label   => $, # optional human readable label
 }

For details of the data constraints refer to the specification on biodas.org.

=head2 build_types - (Subclasses only) fetch type data

This call is made by das_types(). If no specific segments are requested by the
client, it is passed no arguments. Otherwise it is passed:

 { 'segment'    => $, 'start' => $, 'end' => $ }

It is expected to return an array of hash references, i.e.
 ( {},{}...{} )

Each hash returned represents a single type and should contain a
subset of the following keys and values. For scalar types (i.e. numbers
and strings) refer to the specification on biodas.org.

 type                                       => $ # required
 type_cvid || c_ontology                    => $
 typetxt   || description                   => $
 category  || typecategory || type_category => $
 count                                      => $

=head2 build_entry_points - (Subclasses only) fetch entry_points data

This call is made by das_entry_points(). It is not passed any args

and is expected to return an array of hash references, i.e.
 ( {},{}...{} )

Each hash returned represents a single entry_point and should contain a
subset of the following keys and values. For scalar types (i.e. numbers
and strings) refer to the specification on biodas.org.

 segment  => $
 length   => $
 subparts => $
 start    => $
 stop     => $
 ori      => $

=head2 build_alignment - (Subclasses only) fetch alignment data

This call is made by das_alignment(). It is passed these arguments:

 (
  $,        # query ID (either subject or alignment, depending on the source)
  $,        # range of rows (X-Y)
  [ $, $ ], # subjects (ID[:X,Y])
  $,        # subject coordinate system
  $         # range of columns (X-Y)
 )

The  that the query ID is required; all other arguments are optional. The
optional arguments pertain to restricting parts of the alignment(s). This method
must perform that restriction and should consider the most efficient mechanism
to do so, but default implementations exist if needed (see the restrict_alignment_rows
and restrict_alignment_columns methods).

The method is expected to return an array of alignment hash references:

 (
  {
   name        => $,
   description => $,
   type        => $,
   max         => $,
   position    => $,
   alignObj => [
                {
                 id              => $, # internal object ID
                 version         => $,
                 dbSource        => $,
                 dbVersion       => $,
                 dbAccession     => $,
                 chain           => $, # structure chain ID, if applicable
                 dbCoordSys      => $,
                 sequence        => $,
                 aliObjectDetail => [
                                     {
                                      property => $,
                                      value    => $,
                                      dbSource => $,
                                     },
                                    ],
                },
               ],
   scores   => [
                {
                 method => $,
                 score  => $,
                },
               ],
   blocks   => [
                {
                 blockOrder => $,
                 blockScore => $,
                 segments   => [
                                {
                                 id          => $, # internal object ID
                                 start       => $,
                                 end         => $,
                                 orientation => $, # + / - / undef
                                 cigar       => $,
                                },
                               ],
               ],
   geo3D    => [
                {
                 id
                 vector => {
                            x => $,
                            y => $,
                            z => $,
                           },
                 matrix => [
                            [$,$,$], # mat11, mat12, mat13
                            [$,$,$], # mat21, mat22, mat23
                            [$,$,$], # mat31, mat32, mat33
                           ],
                },
               ],
  }
 )

=head2 restrict_alignment_rows - Filter an alignment according to row/subject

This method may be called by subclasses in the build_alignment method. It exists
as a helper to enable subclasses to easily implement the row filtering
capability of the alignment command. It expects these arguments:

 (
  $,        # alignment hashref
  $,        # rows, of format START-END
  [ $, $ ], # subjects, of format ID[:BEFORE,AFTER]
  $         # subject coordinate system
 )

Subclasses can pass these arguments as they are received from the das_alignment
method verbatim, without modification. This method will modify the alignment
hashref and return.

The algorithm will apply two filters: one for each of the 'subjects' and 'rows'
arguments. In the former case, the row identified by a subject ID (looking first
at the object's dbAccession and then its internal ID) plus a surrounding range
(if specified) will be retained. In the latter case, the specific requested rows
will be retained. All other rows are discarded. Note that the filter acts on
both the alignObjects and segments within the alignment. If after filtering a
block contains no segments, it is not retained.

=head2 restrict_alignment_columns - Filter an alignment according to column

This method may be called by subclasses in the build_alignment method. It exists
as a helper to enable subclasses to easily implement the column filtering
capability of the alignment command. It expects these arguments:

 (
  $,        # alignment hashref
  $,        # cols, of format START-END
 )

Subclasses can pass these arguments as they are received from the das_alignment
method verbatim, without modification. This method will modify the alignment
hashref and return.

The algorithm will modify the alignment such that only alignment blocks that at
least partially lie within the requested range of columns will be retained. Within
such blocks, only segments that lie at least partially within the requested range
will be retained. Finally, the segment start, end and cigar properties will be
adjusted to reflect the new composition of the alignment. Note that the sequence
of an alignObject (if present) is never changed - this refers to the entire object
rather than a segment of it and is therefore not affected.

=head2 build_structure - (Subclasses only) fetch structure data

This call is made by das_structure(). It is passed these arguments:

 (
  $,        # query ID
  [ $, $ ], # chain ID filters
  [ $, $ ], # model number filters
 )

Note that the query ID is required, the other arguments may be empty arrayrefs.

It is expected to return a hash reference representing a structure:

 {
  # Structure objects:
  objects  => [
               dbAccessionId => $, # the ID of the object in the source database
               objectVersion => $, # the version of the object in the source database
               dbSource      => $, # the source database
               dbVersion     => $, # the version of the source database
               dbCoordSys    => $, # the name of the object's coordinate system
               objectDetails => [
                                 source   => $, # the source of the property
                                 property => $, # name
                                 detail   => $, # value
                                ]
              ],
  # Structural chains, containing groups and atoms:
  chains   => [
               id          => $,
               modelNumber => $,
               groups      => [
                               id    => $, # unique identifier in the structure
                               name  => $, # e.g. ALA
                               type  => $, # amino|nucleotide|hetatom
                               icode => $, # insertion code
                               atoms => [
                                         x          => $, # X coordinate
                                         y          => $,
                                         z          => $,
                                         atomId     => $, # unique ID within the structure
                                         atomName   => $, # label, e.g. "CA"
                                         occupancy  => $, # floating point
                                         tempFactor => $, # floating point
                                         altLoc     => $, # conformation ID
                                        ]
                              ],
              ],
  # Atom connections:
  connects => [
               type       => $, # e.g. bond
               atomSerial => $, # source atomId
               atom_ids   => [
                              $, $, $, # target atomId(s)
                             ],
              ],
 }

=head2 build_interaction - (Subclasses only) fetch interaction data

This call is made by das_interaction(). It is passed this structure:

 # For request:
 # /interaction?interactor=$;interactor=$;detail=property:$;detail=property:$,value:$
 {
  interactors => [$, $, ..],
  details     => {
                  $ => undef, # property exists
                  $ => $,     # property has a certain value
                 },
 }

It is expected to return a hash reference of interactions and interactors where 
all the requested interactors are part of the interaction:

 {
  interactors => [
                  {
                   id            => $,
                   label || name => $,
                   dbSource      => $,
                   dbSourceCvId  => $, # controlled vocabulary ID
                   dbVersion     => $,
                   dbAccession   => $,
                   dbCoordSys    => $, # co-ordinate system
                   sequence      => $,
                   details       => [
                                     {
                                      property        => $,
                                      value           => $,
                                      propertyCvId    => $,
                                      valueCvId       => $,
                                      start           => $, 
                                      end             => $,
                                      startStatus     => $,
                                      endStatus       => $,
                                      startStatusCvId => $,
                                      endStatusCvId   => $,
                                     },
                                     ..
                                    ],
                  },
                  ..
                 ],
  interactions => [
                   {
                    label || name => $,
                    dbSource      => $,
                    dbSourceCvId  => $,
                    dbVersion     => $,
                    dbAccession   => $,
                    details       => [
                                      {
                                       property     => $,
                                       value        => $,
                                       propertyCvId => $,
                                       valueCvId    => $,
                                      },
                                      ..
                                     ],
                    participants  => [
                                      {
                                       id      => $,
                                       details => [
                                                   {
                                                    property        => $,
                                                    value           => $,
                                                    propertyCvId    => $,
                                                    valueCvId       => $,
                                                    start           => $,
                                                    end             => $,
                                                    startStatus     => $,
                                                    endStatus       => $,
                                                    startStatusCvId => $,
                                                    endStatusCvId   => $,
                                                   },
                                                   ..
                                                  ],
                                      },
                                      ..
                                     ],
                   },
                   ..
                  ],
 }

=head2 build_volmap - (Subclasses only) fetch volume map data

This call is made by das_volmap(). It is passed a single 'query' argument.

It is expected to return a hash reference for a single volume map:

 {
  id      => $,
  class   => $,
  type    => $,
  version => $,
  link    => $,                  # href for data
  linktxt => $,                  # text
  note    => $  OR  [ $, $, .. ]
 }

=head2 init_segments - hook for optimising results to be returned.

  By default - do nothing
  Not necessary for most circumstances, but useful for deciding on what sort
  of coordinate system you return the results if more than one type is available.

  $self->init_segments() is called inside das_features() before build_features().

=head2 known_segments - returns a list of valid segments that this adaptor knows about

  my @aSegmentNames = $oSourceAdaptor->known_segments();

=head2 segment_version - gives the version of a segment (MD5 under certain circumstances) given a segment name

  my $sVersion = $oSourceAdaptor->segment_version($sSegment);

=head2 dsn - get accessor for this sourceadaptor's dsn

  my $sDSN = $oSourceAdaptor->dsn();

=head2 dsnversion - get accessor for this sourceadaptor's dsn version

  my $sDSNVersion = $oSourceAdaptor->dsnversion();
  
  By default returns $self->{'dsnversion'}, configuration 'dsnversion' setting or '1.0'

=head2 dsncreated - get accessor for this sourceadaptor's update time (variable format)
  
  # e.g. '2007-09-20T15:26:23Z'      -- ISO 8601, Coordinated Universal Time
  # e.g. '2007-09-20T16:26:23+01:00' -- ISO 8601, British Summer Time
  # e.g. '2007-09-20 07:26:23 -08'   -- indicating Pacific Standard Time
  # e.g. 1190301983                  -- UNIX
  # e.g. '2007-09-20'
  my $sDSNCreated = $oSourceAdaptor->dsncreated(); 
  
  By default tries and returns the following:
    1. $self->{'dsncreated'}
    2. configuration 'dsncreated' setting
    3. adaptor's 'last_modified' method (if it exists)
    4. zero (epoch)

=head2 dsncreated_unix - this sourceadaptor's update time, in UNIX format

  # e.g. 1190301983
  my $sDSNCreated = $oSourceAdaptor->dsncreated_unix();

=head2 dsncreated_iso - this sourceadaptor's update time, in ISO 8601 format

  # e.g. '2007-09-20T15:26:23Z'
  my $sDSNCreated = $oSourceAdaptor->dsncreated_iso();

=head2 coordinates - Returns this sourceadaptor's supported coordinate systems

  my $hCoords = $oSourceAdaptor->coordinates();
  
  Hash contains a key-value pair for each coordinate system, the key being
  either the URI or description, and the value being a suitable test range.
  
  By default returns an empty hash reference

=head2 _coordinates : Returns this sourceadaptor's supported coordinate systems in "full" format

  my $aCoords = $oSourceAdaptor->_coordinates();
  
  Returns the fully-annotated co-ordinate systems this adaptor supports, as an
  array or array reference (depending on context):
    [
     {
      'description' => 'NCBI_36,Chromosome,Homo sapiens',
      'uri'         => 'http://www.dasregistry.org/dasregistry/coordsys/CS_DS40',
      'taxid'       => '9606',
      'authority'   => 'NCBI',
      'source'      => 'Chromosome',
      'version'     => '36',
      'test_range'  => '1:11000000,12000000',
     },
     {
      ...
     },
    ]
  
  The co-ordinate system details are read in from disk by Bio::Das::ProServer.
  By default returns an empty array.

  DO NOT OVERRIDE THIS METHOD IN SUBCLASSES.

=head2 capabilities - Returns this sourceadaptor's supported capabilities

  my $hCapabilities = $oSourceAdaptor->capabilities();
  
  Hash contains a key-value pair for each command, the key being the command
  name, and the value being the implementation version.
  
  By default returns an empty hash.

=head2 _capabilities - Returns this sourceadaptor's supported capabilities, as rationalised by ProServer

  my $hCapabilities = $oSourceAdaptor->_capabilities();
  
  Hash contains a key-value pair for each command, the key being the command
  name, and the value being the implementation version.
  
  By default returns an empty hash.

  DO NOT OVERRIDE THIS METHOD IN SUBCLASSES.

=head2 properties - Returns custom properties for this sourceadaptor

  my $hProps = $oSourceAdaptor->properties();
  
  Hash contains key-scalar or key-array pairs for custom properties.
  
  By default returns an empty hash reference

=head2 start - get accessor for segment start given a segment

  my $sStart = $oSourceAdaptor->start('DYNA_CHICK');

  By default returns 1

=head2 end - get accessor for segment end given a segment

  my $sEnd = $oSourceAdaptor->end('DYNA_CHICK');
  
  By default returns $self->length

=head2 server_url - Get the URL for the server (not including the /das)

  my $sUrl = $oSourceAdaptor->server_url();

=head2 source_url - Get the full URL for the source

  my $sUrl = $oSourceAdaptor->source_url();

=head2 hydra - Get the relevant B::D::PS::SourceHydra::<...> configured for this adaptor, if there is one

  my $oHydra = $oSourceAdaptor->hydra();

=head2 transport - Build the relevant B::D::PS::SA::Transport::<...> configured for this adaptor

  my $oTransport = $oSourceAdaptor->transport();
  
  OR
  
  my $oTransport1 = $oSourceAdaptor->transport('foo');
  my $oTransport2 = $oSourceAdaptor->transport('bar');

=head2 authenticator : Build the B::D::PS::Authenticator::<...> configured for this adaptor

  my $oAuthenticator = $oSourceAdaptor->authenticator();

  Authenticators are built only if explicitly configured in the INI file, e.g.:
  [mysource]
  state         = on
  adaptor       = simple
  authenticator = ip
  
  See L<Bio::Das::ProServer::Authenticator|Bio::Das::ProServer::Authenticator> for more details.

=head2 config - get/set config settings for this adaptor

  $oSourceAdaptor->config($oConfig);

  my $oConfig = $oSourceAdaptor->config();

=head2 implements - helper to determine if an adaptor implements a request based on its capabilities

  my $bIsImplemented = $oSourceAdaptor->implements($sDASCall); # e.g. $sDASCall = 'sequence'

=head2 das_capabilities - DAS-response capabilities header support

  my $sHTTPHeader = $oSourceAdaptor->das_capabilities();

=head2 unknown_segment - DAS-response unknown/error segment error response

  my $sXMLResponse = $sa->unknown_segment();

  Reference sources (i.e. those implementing the 'sequence' command) will return an <ERRORSEGMENT> element.
  Annotation sources will return an <UNKNOWNSEGMENT> element.

=head2 error_segment - DAS-response error segment error response

  my $sXMLResponse = $sa->error_segment();

  Returns an <ERRORSEGMENT> element.

=head2 error_feature - DAS-response unknown feature error

  my $sXMLResponse = $sa->error_feature();

=head2 das_features - DAS-response for 'features' request

  my $sXMLResponse = $sa->das_features();

  See the build_features method for details of custom implementations.

=head2 das_sequence - DAS-response for sequence request

  my $sXMLResponse = $sa->das_sequence();

  See the sequence method for details of custom implementations.

=head2 das_types - DAS-response for 'types' request

  my $sXMLResponse = $sa->das_types();

  See the build_types method for details of custom implementations.

=head2 das_entry_points - DAS-response for 'entry_points' request

  my $sXMLResponse = $sa->das_entry_points();

  See the build_entry_points method for details of custom implementations.

=head2 das_interaction - DAS-response for 'interaction' request

  my $sXMLResponse = $sa->das_interaction();

  See the build_interaction method for details of custom implementations.

=head2 das_volmap - DAS-response for 'volmap' request

  my $sXMLResponse = $sa->das_volmap();

  See the build_volmap method for details of custom implementations.

=head2 das_stylesheet - DAS-response for 'stylesheet' request

  my $sXMLResponse = $sa->das_stylesheet();

  By default will use (in order of preference):
    the "stylesheet" INI property (inline XML)
    the "stylesheetfile" INI property (XML file location)
    the "stylesheetfile" INI property, prepended with the "styleshome" property
    a default stylesheet

=head2 das_sourcedata - DAS-response for 'sources' request

  my $sXMLResponse = $sa->das_sourcedata();

  Provides information about the DAS source for use in the sources command,
  such as title, description, coordinates and capabilities.

=head2 das_dsn - DAS-response (non-standard) for 'dsn' request

  my $sXMLResponse = $sa->das_dsn();

=head2 das_xsl - DAS-response (non-standard) for 'xsl' request

  my $sXSLResponse = $sa->das_xsl();

=head2 das_alignment - DAS-response for 'alignment' request

  my $sXMLResponse = $sa->das_alignment();

  See the build_alignment method for details of custom implementations.

  Example Response:

<alignment>
  <alignObject>
    <alignObjectDetail />
    <sequence />
  </alignObject>
  <score/>
  <block>
    <segment>
      <cigar />
    </segment>
  </block>
  <geo3D>
    <vector />
    <matrix mat11="float" mat12="float" mat13="float"
            mat21="float" mat22="float" mat23="float"
            mat31="float" mat32="float" mat33="float" />
  </geo3D>
</alignment>

=head2 _gen_align_object_response

 Title    : _gen_align_object_response
 Function : Formats alignment object into dasalignment xml
 Args     : align data structure
 Returns  : Das Response string encapuslating aliObject

=head2 _gen_align_score_response

 Title   : _gen_align_score_response
 Function: Formats input score data structure into dasalignment xml
 Args    : score data structure
 Returns : Das Response string from alignment score

=head2 _gen_align_block_response

 Title   : _gen_align_block_response
 Function: Formats an input block data structure into 
         : dasalignment xml
 Args    : block data structure
 Returns : Das Response string from alignmentblock

=head2 _gen_align_geo3d_response

  Title    : genAlignGeo3d
  Function : Formats geo3d data structure into alignment matrix xml
  Args     : data structure containing the vector and matrix
  Returns  : String containing the DAS response xml

=head2 das_structure 

 Title    : das_structure
 Function : This produces the das repsonse for a pdb structure
 Args     : query options.  Currently, this will that query, chain and modelnumber.
          : The only part of the specification that this does not adhere to is the range argument. 
          : However, I think this argument is a potential can of worms!
 returns  : string containing Das repsonse for the pdb structure
 comment  : See http://www.efamily.org.uk/xml/das/documentation/structure.shtml for more information 
          : on the das structure specification.

 Example Response:
<object dbAccessionId="1A4A" intObjectId="1A4A" objectVersion="29-APR-98" dbSource="PDB" dbVersion="20040621" dbCoordSys="PDBresnum,Protein Structure" />
<chain id="A" SwissprotId="null">
  <group name="ALA" type="amino" groupID="1">
    <atom atomID="1" atomName=" N  " x="-19.031" y="16.695" z="3.708" />
    <atom atomID="2" atomName=" CA " x="-20.282" y="16.902" z="4.404" />
    <atom atomID="3" atomName=" C  " x="-20.575" y="18.394" z="4.215" />
    <atom atomID="4" atomName=" O  " x="-20.436" y="19.194" z="5.133" />
    <atom atomID="5" atomName=" CB " x="-20.077" y="16.548" z="5.883" />
    <atom atomID="6" atomName="1H  " x="-18.381" y="17.406" z="4.081" />
    <atom atomID="7" atomName="2H  " x="-18.579" y="15.781" z="3.874" />
    <atom atomID="8" atomName="3H  " x="-19.018" y="16.844" z="2.68" />
  </group>
  <group name="HOH" type="hetatm" groupID="219">
    <atom atomID="3057" atomName=" O  " x="-17.904" y="13.635" z="-7.538" />
    <atom atomID="3058" atomName="1H  " x="-18.717" y="14.098" z="-7.782" />
    <atom atomID="3059" atomName="2H  " x="-17.429" y="13.729" z="-8.371" />
  </group>
</chain>
<connect atomSerial="26" type="bond">
  <atomID atomID="25" />
  <atomID atomID="242" />
</connect>

=head2 _gen_object_response

 Title    : _gen_object_response
 Function : Formats the supplied structure object data structure into dasstructure xml
 Args     : object data structure
 Returns  : Das Response string encapuslating 'object'
 Comment  : The object response allows the details of the coordinates to be descriped. For example
          : the fact that the coos are part of a pdb file.

=head2 _gen_chain_response

 Title    : _gen_chain_response
 Function : Formats the supplied chain object data structure into dasstructure xml
 Args     : chain data structure
 Returns  : Das Response string encapuslating 'chain'
 Comment  : Chain objects contain all of the atom positions (including hetatoms).
          : The groups are typically residues or ligands.

=head2 _gen_connect_response

 Title    : _gen_connect_response
 Function : Formats the supplied connect data structure into dasstructure xml
 Args     : connect data structure
 Returns  : Das Response string encapuslating "connect"
 Comment  : Such objects are specified to enable groups of atoms to be connected together.

=head2 cleanup : Post-request garbage collection

=head1 CONFIGURATION AND ENVIRONMENT

Used within Bio::Das::ProServer::Config, eg/proserver and of course all subclasses.

=head1 DIAGNOSTICS

set $self->{'debug'} = 1

=head1 DEPENDENCIES

=over

=item L<HTML::Entities|HTML::Entities>

=item L<HTTP::Date|HTTP::Date>

=item L<English|English>

=item L<Carp|Carp>

=back

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

None reported

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 The Sanger Institute

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
