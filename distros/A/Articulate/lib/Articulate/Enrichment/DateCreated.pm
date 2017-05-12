package Articulate::Enrichment::DateCreated;
use strict;
use warnings;

use Text::Markdown;
use Moo;

=head1 NAME

Articulate::Enrichment::DateCreated - add a creation date to the meta

=head1 METHODS

=head3 enrich

Sets the creation date (C<meta.schema.core.dateCreated>) to the current time, unless it already has a defined value.

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
  $item->meta->{schema}->{core}->{dateCreated} //= "$now";
  return $item;
}

1;
