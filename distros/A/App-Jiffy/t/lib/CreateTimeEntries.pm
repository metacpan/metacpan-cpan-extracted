package CreateTimeEntries;

use strict;
use warnings;

use App::Jiffy::TimeEntry;

use parent qw( Exporter );

our @EXPORT = qw/generate/;

sub generate {
  my $cfg     = shift;
  my $entries = shift;

  my $now = DateTime->now( time_zone => 'local' );

  for my $i ( 0 .. $#$entries ) {
    my $entry = $entries->[$i];
    my $start_time;

    if ( ref $entry->{start_time} eq 'CODE' ) {
      $start_time = $entry->{start_time}->();
    } elsif ( ref $entry->{start_time} eq 'HASH' ) {
      $start_time = $now->clone->subtract( %{ $entry->{start_time} } );
    }

    # Default
    $start_time //=
      $now->clone->subtract( hours => ( scalar(@$entries) - $i ) );

    App::Jiffy::TimeEntry->new(
      title => $entry->{title} // 'Beep Boop',
      start_time => $start_time,
      cfg        => $cfg,
    )->save;
  }
}

1;
