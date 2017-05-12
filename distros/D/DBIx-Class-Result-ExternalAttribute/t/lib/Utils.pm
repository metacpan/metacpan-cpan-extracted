package t::lib::Utils;

use strict;
use warnings;

use base 'Exporter';
use vars '@EXPORT';

@EXPORT = qw/ populate_database /;

sub populate_database
{
  my $schema = shift;

  my @artists = (['Michael Jackson'], ['Eminem']);
  $schema->populate('Artist', [
    [qw/name/],
    @artists,
    ]);

  my %year_old = (
    'Michael Jackson' => 56,
    'Eminem' => 36,
  );

  my @artist_attributes;
  foreach my $lp (keys %year_old) {
    my $artist = $schema->resultset('Artist')->find({
        name => $lp
      });
    push @artist_attributes, [ $artist->id, $year_old{$lp} ];
  }

  $schema->populate('ArtistAttribute', [
    [qw/ artist_id year_old/],
    @artist_attributes,
    ]);
}

1;
