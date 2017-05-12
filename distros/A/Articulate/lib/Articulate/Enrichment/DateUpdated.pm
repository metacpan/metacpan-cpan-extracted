package Articulate::Enrichment::DateUpdated;
use strict;
use warnings;

use Text::Markdown;
use Moo;

=head1 NAME

Articulate::Enrichment::DateUpdated - add a update date to the meta

=head1 METHODS

=head3 enrich

Sets the update date (C<meta.schema.core.dateUpdated>) to the current
time.

=cut

use DateTime;

sub _now {
  DateTime->now;
}

sub enrich {
  my $self    = shift;
  my $item    = shift;
  my $request = shift;
  my $now     = _now;
  $item->meta->{schema}->{core}->{dateUpdated} = "$now";
  return $item;
}

1;
