package Alzabo::Display::SWF::Schema;

use strict;
use warnings;

use SWF qw(:ALL);
use Alzabo::Display::SWF::Util qw/rgb2ary button_shape get_coordinates/;
use Alzabo::Display::SWF::Table;
use Alzabo::Display::SWF::Column;
use Alzabo::Display::SWF::Key;
use GraphViz;
use Alzabo::Runtime;
our $VERSION = '0.01';

SWF::setVersion(5);
my $scale = 5;
SWF::setScale($scale);

sub new {
  my $pkg = shift;
  my %p = @_;
  my $self = {};
  bless $self, $pkg;
  $self->{mov} = new SWF::Movie;
  $self->{ars} = Alzabo::Runtime::Schema->load_from_file(name => $p{name});
  $self->{cfg} = $p{cfg};
  $self->{gvz} = GraphViz->new(  qw/
    layout     neato
    no_overlap 1
    /,
    node  => {qw/ shape   box  fontname Courier /},
    graph => {qw/ splines false /, label => $p{name} },
  );
  return $self;
}

sub create_graph {
  my $self = shift;
  my $g = $self->{gvz};
  my (%fk, %tm);
  my @t = $self->{ars}->tables;
  for my $t ( @t ) {
    my $n = $t->name;
    $tm{$n} = Alzabo::Display::SWF::Table->new(
      $t, $self->{mov}, $scale, $self->{cfg},
    );
    $g->add_node( $n,
      height => ( 2 + $tm{$t->name}->{height} )/72,
      width  => ( 2 + $tm{$t->name}->{width} )/72
    );

    foreach my $fk ($t->all_foreign_keys)  {
      my @from_id = qw( columns_from columns_to );
      my $id1 = join "\0", map { $_->name } map { $fk->$_() }
                           @from_id, qw( table_from table_to );
      $id1 .= "\0";
      $id1 .= join "\0", $fk->cardinality;

      my @to_id = qw( columns_to columns_from );
      my $id2 = join "\0", map { $_->name } map { $fk->$_() }
                           @to_id, qw( table_to table_from );
      $id2 .= "\0";
      $id2 .= join "\0", reverse $fk->cardinality;

      next if $fk{$id1} || $fk{$id2};

      my %p;
      my ($taillabel) = $fk->cardinality;
      $taillabel .= 'd' if $fk->from_is_dependent;

      my ($headlabel) = reverse $fk->cardinality;
      $headlabel .= 'd' if $fk->to_is_dependent;
      $p{taillabel} = $taillabel;
      $p{headlabel} = $headlabel;

      if ($fk->is_one_to_one) {
	$p{dir} = 'none';
	$p{arrowhead} = $fk->from_is_dependent ? 'dot' : 'odot';
	$p{arrowtail} = $fk->to_is_dependent ? 'dot' : 'odot';
      }
      elsif ($fk->is_many_to_one) {
        $p{dir} = 'forward';
	$p{arrowhead} = $fk->from_is_dependent ? 'dot' : 'odot';
	$p{arrowtail} = $fk->to_is_dependent ? 'invdot' : 'invodot';
      }
      else {
	$p{dir} = 'back';
	$p{arrowhead} = $fk->from_is_dependent ? 'invdot' : 'invodot';
	$p{arrowtail} = $fk->to_is_dependent ? 'dot' : 'odot';
      }

      # PLAYED AROUND WITH WEIGHT AND LEN OF EDGES IN ORDER TO MAKE
      # THE PICTURES OF BIG DATABASES SMALLER.
      my @w = map { ( $fk->$_->all_foreign_keys ) } qw/table_from table_to/;
      # $p{weight} = 5 / scalar @w;
      $p{len} = scalar @w / ( 2 * sqrt(scalar @t) );

      $g->add_edge( $fk->table_from->name, $fk->table_to->name, %p );
      $fk{$id1} = $fk{$id2} = 1;
    }
  }
  $self->{tmv} = \%tm;
}

sub create_movie {
  my $self = shift;
  local $_ = $self->{gvz}->as_text;

  # DIMENSION OF THE GRAPH/MOVIE
  my ($x, $y) =
  ( $self->{X}, $self->{Y} ) = /graph \[.*bb="0,0,(\d+),(\d+)".*\];/;
  my $m = $self->{mov};
  $m->setDimension( $x+10, $y+10 );

  # POSITIONS OF TABLES IN THE MOVIE
  my %tm = %{ $self->{tmv} };
  for my $t ( $self->{ars}->tables ) {
    my $n = $t->name;
    /^\s*$n\s\[.*pos="(\d+),(\d+)".*\];/m
      or die "Didn't find table $n in GraphViz Output";
    $tm{$n}->{dx} = $1 - int($tm{$n}->{width} / 2);
    $tm{$n}->{dy} = $y - ( $2 + 6 + int($tm{$n}->{height} / 2) );
  }

  # TABLE KEYS (PRIMARY AND FOREIGN)
  my $cfg = $self->{cfg};
  my @primary_fill = rgb2ary( $cfg->{table}{key}{primary} );
  my @foreign_fill = rgb2ary( $cfg->{table}{key}{foreign} );
  my $ew = $cfg->{table}{edge}{width};

  for my $t ( $self->{ars}->tables ) {
    my $n = $t->name;
    for my $fk ($t->all_foreign_keys)  {
      if ($n eq $fk->table_from->name) {
        my $tn = $fk->table_to->name;
        for my $c_pair ($fk->column_pairs) {
          # $c_from = Alzabo::Display::SWF::Column Object
          my $c_from = $tm{$n}->{column_by_name}{$c_pair->[0]->name};
          $c_from->{is_foreign_key} = 1;
          my $cn = $c_pair->[1]->name;
          # $c_to = Alzabo::Display::SWF::Column Object
          my $c_to = $tm{$tn}->{column_by_name}{$cn};
          push @{ $c_from->{foreign_keys} }, {
            name => $cn,
            xy => [
              $tm{$tn}->{dx} - $tm{$n}->{dx},
              $tm{$tn}->{dy} - $tm{$n}->{dy} + $c_to->{dy} - $c_from->{dy}
            ]
          };
        }
      }
      else {
        for my $c ($fk->columns_to) {
          my $co = $tm{$n}->{column_by_name}{$c->name};
          $co->{is_foreign_key} = 1;
        }
      }
    }
    for my $c ($t->columns) {
      my $co = $tm{$n}->{column_by_name}{$c->name};
      $co->{is_primary_key} = 1 if $c->is_primary_key;
      my $cs = new Alzabo::Display::SWF::Key qw/r 6 segments 4/,
        name           => $n.$c->name,
        linestyle_up   => [ $scale*$ew,
                            rgb2ary( $cfg->{table}{linestyle}{color} ) ],
        linestyle_over => [ $scale*$ew,
                            rgb2ary( $cfg->{column}{color}{fg}{over} ) ],
        opac           => hex( $cfg->{table}{edge}{opacity} );
      if ( $co->{is_primary_key} ) {
        if ( $co->{is_foreign_key} ) {
             $cs->{fill2} = [ @primary_fill ];
             $cs->{fill1} = [ @foreign_fill ];
        }
        else { $cs->{fill1} = [ @primary_fill ] }
      }
      else {
        if ( $co->{is_foreign_key} ) {
             $cs->{fill1} = [ @foreign_fill ];
        }
      }
      my $k;
      if ( $co->{is_primary_key} or $co->{is_foreign_key} ) {
        $k = $cs->indicator( $co->{foreign_keys} );
        my $ki = $m->add($k);
        push @{ $tm{$n}->{keys} }, $ki;
      }
      else { push @{ $tm{$n}->{keys} }, undef }
      my $ci = $m->add($co->{sprite});
      push @{ $tm{$n}->{columns} }, $ci;
    }

    $tm{$n}->moveTo($tm{$n}->{dx}, $tm{$n}->{dy});
  }

  # EDGES BETWEEN TABLES
  my @xy = /(\w+)\s-[->]\s(\w+)\s.*
             pos="s,(\d+),(\d+) \s
                  e,(\d+),(\d+) \s
                  \d+,\d+ \s [^"]*\d+,\d+
                 "/xg;
  my @edge;
  for my $i ( map $_*6, 0 .. scalar(@xy)/6 - 1 ) {
    local $_;
    my ($t1, $t2) = map $tm{$xy[$_]}, $i, $i+1;
    my ($x1, $y1, $x2, $y2) = map $xy[$_], $i+2 .. $i+5;
    $y1 = $y - $y1;
    $y2 = $y - $y2;
    ($x1, $y1) = get_coordinates($t1, $x1, $y1);
    ($x2, $y2) = get_coordinates($t2, $x2, $y2);
    $y1 += 6; $y2 += 6;
    my $edge = new SWF::Shape;
    $edge->setLineStyle( $cfg->{schema}{edge}{width} * $scale,
                         rgb2ary( $cfg->{schema}{color}{fg} ),
                         hex( $cfg->{schema}{edge}{opacity} ) );
    $edge->movePenTo($x1, $y1);
    if ( $xy[$i] eq $xy[$i+1] ) {
      my ($xc, $yc);
      if ( $x1 == $x2 ) {
        local $_ = int( ($y2 - $y1)/2 );
        $yc = $y1 + $_;
        $xc = $x1 > $t1->{dx} ? $x1 + abs : $x1 - abs;
      }
      else {
        local $_ = int( ($x2 - $x1)/2 );
        $xc = $x1 + $_;
        $yc = $y1 > $t1->{dy} ? $y1 + abs : $y1 - abs;
      }
      $edge->drawCurveTo( $xc, $yc, $x2, $y2 );
    }
    else { $edge->drawLineTo($x2, $y2) }
  push @edge, $edge;
  }

  my $f = new SWF::Font $cfg->{fdb_dir} . '/' . $cfg->{schema}{fdb} . '.fdb';
  my @c_fg = rgb2ary( $cfg->{schema}{color}{fg} );
  my @c_bg = rgb2ary( $cfg->{schema}{color}{bg} );
  my $sn = $self->{ars}->name;
  my $t = new Alzabo::Display::SWF::Text $sn, $f, @c_fg;
  my $w = $t->getStringWidth($sn);

  my $bs1 = button_shape($w, @c_bg);
  my $bs2 = button_shape($w, @c_bg);

  my $b = new SWF::Button;
  $b->addShape($bs1, SWF::Button::SWFBUTTON_HIT);
  $b->addShape($bs1, SWF::Button::SWFBUTTON_UP);
  $b->addShape($bs2, SWF::Button::SWFBUTTON_OVER);
  $b->setAction(
    new SWF::Action("play();"),
    SWF::Button::SWFBUTTON_MOUSEDOWN
  );
  my $bi = $m->add($b);

  my @lp = /graph \[.*lp="(\d+),(\d+)".*\];/ or die;
  $bi->moveTo($lp[0], $y - $lp[1]);
  my $ti = $m->add($t);
  $ti->moveTo($lp[0] + 1, $y - $lp[1] + 11);
  $m->nextFrame;
  $m->add(new SWF::Action("stop();"));
  $m->nextFrame;
  for my $edge (@edge) { $m->add($edge) }
  $m->nextFrame();
  $m->add(new SWF::Action("stop();"));
  $m->nextFrame();
}

sub save {
  my ($self, $file) = @_;
  $self->{mov}->save( $file );
}

sub dim { ($_[0]->{X}, $_[0]->{Y}) }

1;
