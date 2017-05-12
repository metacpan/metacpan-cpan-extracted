#########
# Author:        Andy Jenkinson, andy.jenkinson@ebi.ac.uk
# Maintainer:    $Author: zerojinx $
# Created:       ?
# Last Modified: $Date: 2010-11-02 11:57:52 +0000 (Tue, 02 Nov 2010) $
# Id$
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/file.pm $
#
package Bio::Das::ProServer::SourceAdaptor::file;

use strict;
use warnings;

use Carp;
use base qw(Bio::Das::ProServer::SourceAdaptor);

our $VERSION = do { my ($v) = (q$Revision $ =~ /\d+/mxsg); $v; };
our @FEATURE_KEYS = qw(method method_label note link linktxt score
  segment start end ori phase feature_id feature_label
  type typetxt typecategory typesubparts typesuperparts typereference
  group_id grouplabel grouptype groupnote grouplink grouplinktxt);

sub init {
  my $self = shift;
  $self->config->{'cols'} || croak(q(The 'cols' INI attribute is not set!));
  $self->config->{'feature_query'} || croak(q(The 'feature_query' INI attribute is not set!));
  $self->config->{'transport'} ||= 'file'; # can override if desired...
  $self->{'extras'} = [];
  for my $key (@FEATURE_KEYS) {
    if ($self->config->{$key}) {
      push @{ $self->{'extras'} }, $key;
    }
  }
  $self->{'capabilities'}{'features'} = '1.0';
  $self->{'capabilities'}{'types'}    = '1.0';
  if ($self->config->{'fid_query'}) {
    $self->{'capabilities'}{'feature-by-id'} = '1.0';
  }
  if ($self->config->{'gid_query'}) {
    $self->{'capabilities'}{'group-by-id'} = '1.0';
  }
  if ($self->config->{'stylesheet'} || $self->config->{'stylesheetfile'}) {
    $self->{'capabilities'}{'stylesheet'} = '1.0';
  }
  return;
}

sub build_features {
  my ($self, $args) = @_;

  my $segment = $args->{'segment'} || q();
  my $start   = $args->{'start'}   || q();
  my $end     = $args->{'end'}     || q();
  my $feature = $args->{'feature_id'} || q();
  my $group   = $args->{'group_id'}   || q();

  my $query;
  if ($segment) {
    $query = $self->config->{'feature_query'} || q();
    $query =~ s/%segment/$segment/mxs;
    $query =~ s/%start/$start/mxs;
    $query =~ s/%end/$end/mxs;
  } elsif ($feature) {
    $query = $self->config->{'fid_query'} || q();
    $query =~ s/%feature_id/$feature/mxs;
  } elsif ($group) {
    $query = $self->config->{'gid_query'} || q();
    $query =~ s/%group_id/$group/mxs;
  } else {
    $query = 'field0 like .*';
  }

  if (!$query) {
    carp("Query type not supported. Args given: segment=$segment, feature_id=$feature, group_id=$group");
    return ();
  }

  my ($rows, $nums) = $self->transport->query( $query );
  my @nums = @{ $nums };
  my @cols  = split /,/mxs, $self->config->{'cols'};
  my @features = ();

  for my $row (@{ $rows }) {
    my $row_num = shift @nums; # the original row num in the file, can be used as a feature ID
    my @parts = @{ $row };
    # First, assign column names to each of the matching rows
    my %standard = ();
    for my $col (@cols) {
      if ($col =~ m/^(note|link|linktxt|target)$/mxs) {
        $standard{$col} ||= [];
        push @{ $standard{$col} }, shift @parts;
      } else {
        $standard{$col} = shift @parts;
      }
    }
    # If not specified in the config file, fill in what we know from the request
    $standard{'segment'}       ||= $segment;
    $standard{'segment_start'} ||= $start;
    $standard{'segment_end'}   ||= $end;
    if (!$standard{'feature_id'} && !$standard{'id'}) {
      $standard{'feature_id'} = $feature || $row_num;
    }

    # Next, "fill in" the properties from the INI file
    my %extra = ();
    for my $key (@{$self->{'extras'}}) {
      my $val = $self->config->{$key};
      # Replace any placeholders with actual data
      for my $col (@cols) {
        my $cell = $standard{$col};
        if (ref $cell && ref $cell eq 'ARRAY') {
          $cell = $cell->[0];
        }
        $val =~ s/%$col/$cell/mxsg;
      }
      $extra{$key} = $val;
    }
    my %f = (%extra, %standard);
    push @features, \%f;
  }

  return @features;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::file - adaptor for file-based DAS sources

=head1 VERSION

$Revision: 688 $

=head1 SYNOPSIS

See L<Bio::Das::ProServer::SourceAdaptor|Bio::Das::ProServer::SourceAdaptor>

=head1 DESCRIPTION

This SourceAdaptor plugin allows for a full-featured DAS source (implementing
the features command) to be created from one of a variety of simple text files.
Fields that are not present in the data file may optionally be provided in the
source's configuration, in which case these data will be "filled in".
See the CONFIGURATION section for full details/examples.

=head1 AUTHOR

Andy Jenkinson <andy.jenkinson@ebi.ac.uk>

=head1 SUBROUTINES/METHODS

=head2 init

Initialises the adaptor, performing some optimisation and setting the
appropriate capabilities of the DAS source depending on the queries that are
configured in the INI configuration.

=head2 build_features

Builds feature structures. Called by the das_features and build_types methods.

=head1 CONFIGURATION AND ENVIRONMENT
  
  [sourcename]
  state         = on
  adaptor       = file
  coordinates   = NCBI_36,Chromosome,Homo sapiens -> X:100,200
  mapmaster     = http://www.ensembl.org/das/Homo_sapiens.NCBI36.reference
  homepage      = http://www.example.com/project/
  title         = Example source
  description   = An example DAS source backed by a flat file
  # Transport parameters:
  filename      = %serverroot/eg/data/mysimple.txt
  cache         = yes
  # Adaptor parameters:
  cols          = segment,start,end,ori,type
  feature_query = field0 = %segment and field2 >= %start and field1 <= %end
  fid_query     = field3 = %feature_id
  gid_query     = field4 = %group_id

=head3 filename (required)

Text file location

=head3 cache (optional)

Cache file contents - faster but increases memory footprint

=head3 cols (required)

The order of the columns in the data file, separated by commas

=head3 feature_query (required)

The query to use for segment-based queries. %segment, %start and %end will be
replaced with their respective values from a DAS request.

=head3 fid_query (optional)

The query to use for feature ID-based queries. %feature_id will be replaced with
the appropriate value from a DAS request.

=head3 gid_query (optional)

The query to use for group ID-based queries. %group_id will be replaced with
the appropriate value from a DAS request.

=head3 "fill-in" attributes

By specifying other parameters in the INI configuration, it is possible to "fill
in" attributes that are not included as columns in the data file. For example,
if all features were generated using the same method, it can be specified in the
INI file:

  [mysource]
  ...
  # Fill-in properties:
  typecategory  = transcription
  method        = Genscan

The supported parameters are:

  method method_label note link linktxt score segment start end ori phase
  feature_id feature_label type typetxt typecategory typesubparts typesuperparts
  typereference group_id grouplabel grouptype groupnote grouplink grouplinktxt

It is also possible for such properties to include placeholders, which will be
dynamically substituted for the appropriate column in each feature:

  [mysource]
  ...
  # Fill-in properties:
  link   = http://example.com?chromosome=%segment;type=%type

=head1 BUGS AND LIMITATIONS

Although this module supports the "filling in" of feature properties from the
source's INI configuration, it only supports the setting of scalar values.
It is therefore not possible to set more than one note, link or group.

Also, the setting of "target" properties in this way is at present not supported
(each feature's target is likely to be dynamic anyway).

=head1 DIAGNOSTICS

=head1 INCOMPATIBILITIES

=head1 DEPENDENCIES

Bio::Das::ProServer::SourceAdaptor

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 EMBL-EBI

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
