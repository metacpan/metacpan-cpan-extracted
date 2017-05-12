#!/usr/bin/perl

use strict;
use warnings;

use Date::Biorhythm;
use Date::Calc::Object qw(:all);
use SVG::Graph;
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;

my $jb = Date::Biorhythm->new(
  {
    birthday => Date::Calc::Object->new(0, 1975, 12, 6),
    name     => 'JB',
  }
);

my $yy = Date::Biorhythm->new(
  {
    birthday => Date::Calc::Object->new(0, 1972, 1, 17),
    name     => 'YY',
  }
);



my $i     = 0;
my $limit = 90;
my $start_date = Date::Calc::Object->today;
my @jb;
my @yy;
$jb->day($start_date);
$yy->day($start_date);
while ($i < $limit) {
  push @jb, {
    day   => $jb->day,
    index => $i,
    map { $_ => $jb->value($_) } qw(emotional intellectual physical)
  };
  push @yy, {
    day   => $yy->day,
    index => $i,
    map { $_ => $yy->value($_) } qw(emotional intellectual physical)
  };
  $i++;
  $jb->next();
  $yy->next();
}

my @merged;
for ($i = 0; $i < @jb; $i++) {
  $merged[$i] = {
    day   => $jb[$i]{day},
    index => $i,
    (map { $_ => (($jb[$i]{$_} + $yy[$i]{$_}) / 2) } qw(emotional intellectual physical)),
    jb_emotional => $jb[$i]{emotional},
    yy_emotional  => $yy[$i]{emotional},
  }
}

use IO::All;
use Data::Dump qw(dump);
io('merged.pl') < dump(\@merged);

my @color_sets = (
  {
    emotional    => '#88ccff',
    intellectual => '#4488ff',
    physical     => '#2244ff',
  },
  {
    emotional    => '#ff88cc',
    intellectual => '#ff8844',
    physical     => '#ff4422',
  },
  {
    emotional    => '#ccffcc',
    intellectual => '#ccccff',
    physical     => '#ffcccc',
  },
  { },
);

my %color = %{ shift @color_sets };

my $graph = SVG::Graph->new(width => $limit * 20, height => 800, margin => 160);

my $did_axis = 0;

foreach my $person (\@jb, \@yy, \@merged) {
  foreach my $cycle (qw(emotional intellectual physical)) {
    my @datum = map { SVG::Graph::Data::Datum->new(x => $_->{index}, y => ($_->{$cycle}) * 10) } @$person;
    my $data = SVG::Graph::Data->new(data => \@datum);
    my $frame = $graph->add_frame();
    $frame->add_data($data);
    $frame->add_glyph(
      'axis' => (
        x_absolute_ticks => 1,
        y_absolute_ticks => 1,
        y_intercept      => 0,
        x_tick_labels    => [ map { my $d = $_->{day}; sprintf('%d/%02d/%02d', $d->year, $d->month, $d->day) } @$person ],
        y_tick_labels    => [ map { $_ * 10 } (-10 .. 10) ],
        stroke           => 'black',
        'stroke-width'   => 2,
      )
    ) unless ($did_axis);
    $did_axis++;

    $frame->add_glyph(
      'bezier' => (
        stroke         => $color{$cycle},
        fill           => $color{$cycle},
        'fill-opacity' => 0.50,
      )
    );
  }
  %color = %{ shift @color_sets };
}

#print the graphic
print $graph->draw;
