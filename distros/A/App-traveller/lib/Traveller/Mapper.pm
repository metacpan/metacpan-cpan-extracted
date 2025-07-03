# Copyright (C) 2009-2021  Alex Schroeder <alex@gnu.org>
# Copyright (C) 2020       Christian Carey
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.
#
# Algorithms based on Traveller ©2008 Mongoose Publishing.

package Traveller::Mapper;
use List::Util qw(shuffle reduce);
use Mojo::Base -base;
use Traveller::Util qw(nearby distance in);
use Traveller::Hex;

has 'hexes' => sub { [] };
has 'routes' => sub { [] };
has 'comm_set';
has 'trade_set';
has 'source';
has 'width';
has 'height';

my $colour_re = qr/#([0-9a-f]{3}){1,2}/i;

my $example = q!Inedgeus     0101 D7A5579-8        G  Fl Ni          A
Geaan        0102 E66A999-7        G  Hi Wa          A
Orgemaso     0103 C555875-5       SG  Ga Lt
Veesso       0105 C5A0369-8        G  De Lo          A
Ticezale     0106 B769799-7    T  SG  Ri             A
Maatonte     0107 C6B3544-8   C    G  Fl Ni          A
Diesra       0109 D510522-8       SG  Ni
Esarra       0204 E869100-8        G  Lo             A
Rience       0205 C687267-8        G  Ga Lo
Rearreso     0208 C655432-5   C    G  Ga Lt Ni
Laisbe       0210 E354663-3           Ag Lt Ni
Biveer       0302 C646576-9   C    G  Ag Ga Ni
Labeveri     0303 A796100-9   CT N G  Ga Lo          A
Sotexe       0408 E544778-3        G  Ag Ga Lt       A
Zamala       0409 A544658-13   T N G  Ag Ga Ht Ni
Sogeeran     0502 A200443-14  CT N G  Ht Ni Va
Aanbi        0503 E697102-7        G  Ga Lo          A
Bemaat       0504 C643384-9   C R  G  Lo Po
Diare        0505 A254430-11   TRN G  Ni             A
Esgeed       0507 A8B1579-11    RN G  Fl Ni          A
Leonbi       0510 B365789-9    T  SG  Ag Ri          A
Reisbeon     0604 C561526-8     R  G  Ni
Atcevein     0605 A231313-11  CT   G  Lo Po
Usmabe       0607 A540A84-15   T   G  De Hi Ht In Po
Onbebior     0608 B220530-10       G  De Ni Po       A
Raraxema     0609 B421768-8    T NSG  Na Po
Xeerri       0610 C210862-9        G  Na
Onreon       0702 D8838A9-2       S   Lt Ri          A
Ismave       0703 E272654-4           Lt Ni
Lara         0704 C0008D9-5       SG  As Lt Na Va    A
Lalala       0705 C140473-9     R  G  De Ni Po
Maxereis     0707 A55A747-12  CT NSG  Ht Wa
Requbire     0802 C9B4200-10       G  Fl Lo          A
Azaxe        0804 B6746B9-8   C    G  Ag Ga Ni       A
Rieddige     0805 B355578-7        G  Ag Ni          A
Usorce       0806 E736110-3        G  Lo Lt          A
Solacexe     0810 D342635-4  P    S   Lt Ni Po       R
!;

sub example {
  return $example;
}

# The empty hex is centered around 0,0 and has a side length of 1,
# a maximum diameter of 2, and a minimum diameter of √3.
my @hex = (  -1,          0,
	   -0.5,  sqrt(3)/2,
	    0.5,  sqrt(3)/2,
	      1,          0,
	    0.5, -sqrt(3)/2,
	   -0.5, -sqrt(3)/2);

sub header {
  my ($self, $width, $height) = @_;
  # TO DO: support an option for North American “A” paper dimensions (width 215.9 mm, length 279.4 mm)
  $width //= 210;
  $height //= 297;
  my $template = <<EOT;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" version="1.1"
     xmlns:xlink="http://www.w3.org/1999/xlink"
     width="${width}mm"
     height="${height}mm"
     viewBox="%s %s %s %s">
  <desc>Traveller Subsector</desc>
  <defs>
    <style type="text/css"><![CDATA[
      text {
        font-size: 16pt;
        font-family: Optima, "Optima Regular", Optima-Regular, Helvetica, sans-serif;
        text-anchor: middle;
      }
      text a {
        fill: blue;
        text-decoration: underline;
      }
      .coordinates {
        fill-opacity: 0.5;
      }
      .starport, .base {
        font-size: 20pt;
      }
      .direction {
        font-size: 24pt;
      }
      .legend {
        text-anchor: start;
        font-size: 14pt;
      }
      tspan.comm {
        fill: #ff6347; /* tomato */
      }
      line.comm {
        stroke-width: 10pt;
        stroke: #ff6347; /* tomato */
      }
      tspan.trade {
        fill: #afeeee; /* pale turquoise */
      }
      line.trade {
        stroke-width: 6pt;
        stroke: #afeeee; /* pale turquoise */
        fill: none;
      }
      .travelzone {
        opacity: 0.3;
      }
      .amber {
        fill: none;
        stroke-width: 1pt;
        stroke: black;
      }
      .red {
        fill: red;
      }
      #hex {
        stroke-width: 3pt;
        fill: none;
        stroke: black;
      }
      #background {
        fill: inherit;
      }
      #bg {
        fill: inherit;
      }
    ]]></style>
    <polygon id="hex" points="%s,%s %s,%s %s,%s %s,%s %s,%s %s,%s" />
    <polygon id="bg" points="%s,%s %s,%s %s,%s %s,%s %s,%s %s,%s" />
  </defs>
  <rect fill="white" stroke="black" stroke-width="10" id="frame"
        x="%s" y="%s" width="%s" height="%s" />

EOT
  my $scale = 100;
  return sprintf($template,
		 map { sprintf("%.3f", $_ * $scale) }
		 # viewport
		 -0.5, -0.5, 3 + ($self->width - 1) * 1.5, ($self->height + 1.5) * sqrt(3),
		 # empty hex, once for the backgrounds and once for the stroke
		 @hex,
		 @hex,
		 # framing rectangle
		 -0.5, -0.5, 3 + ($self->width - 1) * 1.5, ($self->height + 1.5) * sqrt(3));
}

sub colour {
  my $self = shift;
  my $culture = shift or return "white";
  # The same colours result from the same names.
  my @colours = ("#d3d3d3", "#f5f5f5", "#eaeaea", "#fffeb0", "#fff0f5", "#eee0e5", "#ffe1ff",
                 "#eed2ee", "#c6e2ff", "#fdf5e6", "#e0ffff", "#d1eeee", "#c5fff5", "#eeeee0",
                 "#fff68f", "#eee685", "#fffacd", "#eee9bf", "#ffe7ba", "#ffefdb", "#ffe4e1",
                 "#eed5d2", "#e6e6fa", "#f0ffff", "#c5ffd5", "#e6ffe6", "#d5ffc5", "#f5f5dc");
  my $i = unpack("%32W*", lc $culture) % @colours; # checksum
  return $colours[$i];
}

sub background {
  my $self = shift;
  my $scale = 100;
  return join("\n", map {
    my $hex = $_;
    my $x = $hex->x;
    my $y = $hex->y;
    my $c = $hex->colour || $self->colour($hex->culture);
    sprintf(qq{    <use xlink:href="#bg" x="%.3f" y="%.3f" fill="$c"/>},
            (1 + ($x-1) * 1.5) * $scale,
            ($y - $x%2/2) * sqrt(3) * $scale);
  } @{$self->hexes});
}

sub grid {
  my $self = shift;
  my $scale = 100;
  my $doc;
  $doc .= join("\n",
	       map {
		 my $n = shift;
		 my $x = int($_/$self->height+1);
		 my $y = $_ % $self->height + 1;
		 my $svg = sprintf(qq{    <use xlink:href="#hex" x="%.3f" y="%.3f"/>\n},
				   (1 + ($x-1) * 1.5) * $scale,
				   ($y - $x%2/2) * sqrt(3) * $scale);
		 $svg   .= sprintf(qq{    <text class="coordinates" x="%.3f" y="%.3f">}
		 		 . qq{%02d%02d</text>\n},
				   (1 + ($x-1) * 1.5) * $scale,
				   ($y - $x%2/2) * sqrt(3) * $scale - 0.6 * $scale,
				   $x, $y);
	       } (0 .. $self->width * $self->height - 1));
  return $doc;
}

sub legend {
  my $self = shift;
  my $scale = 100;
  my $doc;
  my $uwp = '';
  if ($self->source) {
    $uwp = ' – <a xlink:href="' . $self->source . '">UWP</a>';
  }
  $doc .= sprintf(qq{    <text class="legend" x="%.3f" y="%.3f">◉ gas giant}
		  . qq{ – ■ Imperial consulate – ☼ TAS facility – ▲ scout base}
		  . qq{ – ★ naval base – π research station – ☠ pirate base}
		  . qq{ – <tspan class="comm">▮</tspan> communication}
		  . qq{ – <tspan class="trade">▮</tspan> trade$uwp</text>\n},
		  -10, ($self->height + 1) * sqrt(3) * $scale);
  $doc .= sprintf(qq{    <text class="direction" x="%.3f" y="%.3f">coreward</text>\n},
		  $self->width/2 * 1.5 * $scale, -0.13 * $scale);
  $doc .= sprintf(qq{    <text transform="translate(%.3f,%.3f) rotate(90)"}
		  . qq{ class="direction">trailing</text>\n},
		  ($self->width + 0.4) * 1.5 * $scale, $self->height/2 * sqrt(3) * $scale);
  $doc .= sprintf(qq{    <text class="direction" x="%.3f" y="%.3f">rimward</text>\n},
		  $self->width/2 * 1.5 * $scale, ($self->height + 0.7) * sqrt(3) * $scale);
  $doc .= sprintf(qq{    <text transform="translate(%.3f,%.3f) rotate(-90)"}
		  . qq{ class="direction">spinward</text>\n},
		  -0.1 * $scale, $self->height/2 * sqrt(3) * $scale);
  return $doc;
}

sub footer {
  my $self = shift;
  my $doc;
  my $y = 10;
  my $debug = ''; # for developers
  for my $line (split(/\n/, $debug)) {
    $doc .= qq{<text xml:space="preserve" class="legend" y="$y" stroke="red">}
      . $line . qq{</text>\n};
    $y += 20;
  }
  $doc .= qq{</svg>\n};
  return $doc;
}

sub initialize {
  my ($self, $map, $wiki, $source) = @_;
  $self->source($source);
  $self->width(0);
  $self->height(0);
  my @lines = split(/\n/, $map);
  $self->initialize_map($wiki, \@lines);
  $self->initialize_routes(\@lines);
}

sub initialize_map {
  my ($self, $wiki, $lines) = @_;
  foreach (@$lines) {
    # parse Traveller UWP, with optional name
    my ($name, $x, $y,
	$starport, $size, $atmosphere, $hydrographic, $population,
	$government, $law, $tech, $bases, $rest) =
	  /(?:([^>\r\n\t]*?)\s+)?(\d\d)(\d\d)\s+([A-EX])([\dA])([\dA-F])([\dA])([\dA-C])([\dA-F])([\dA-L])-(\d{1,2}|[\dA-HJ-NP-Z])(?:\s+([PCTRNSG ]+)\b)?(.*)/;
    # alternative super simple name, coordinates, optional size (0-9), optional bases (PCTRNSG), optional travel zones (AR)
    ($name, $x, $y, $size, $bases, $rest) =
      /([^>\r\n\t]*?)\s+(\d\d)(\d\d)(?:\s+(\d)\b)?(?:\s+([PCTRNSG ]+)\b)?(.*)/
	unless $x and $y;
    next unless $x and $y;
    $self->width($x) if $x > $self->width;
    $self->height($y) if $y > $self->height;
    my @tokens = split(' ', $rest);
    my @colours = grep(/^$colour_re$/, @tokens);
    my %trade = map { $_ => 1 } grep(/^[A-Z][A-Za-z]$/, @tokens);
    my ($culture) = grep /^\[.*\]$/, @tokens; # culture in square brackets
    my ($travelzone) = grep /^([AR])$/, @tokens;    # amber or red travel zone
    # avoid uninitialized values warnings in the rest of the code
    map { $$_ //= '' } (\$size,
			\$atmosphere,
			\$hydrographic,
			\$population,
			\$government,
			\$law,
			\$starport,
			\$travelzone);
    # get "hex" values, but accept letters beyond F! (excepting I and O)
    map { $$_ = $$_ ge 'P' and $$_ le 'Z' ? 23 + ord($$_) - 80
	      : $$_ ge 'J' and $$_ le 'N' ? 18 + ord($$_) - 74
	      : $$_ ge 'A' and $$_ le 'H' ? 10 + ord($$_) - 65
	      : $$_ eq '' ? 0
	      : $$_ } (\$size,
		       \$atmosphere,
		       \$hydrographic,
		       \$population,
		       \$government,
		       \$law);
    my $hex = Traveller::Hex->new(
      name => $name,
      x => $x,
      y => $y,
      starport => $starport,
      population => $population,
      size => $size,
      travelzone => $travelzone,
      trade => \%trade,
      culture => $culture // '',
      colour => shift(@colours) || $self->colour($culture));
    $hex->url("$wiki$name") if $wiki;
    if ($bases) {
      for my $base (split(//, $bases)) {
	$hex->base($base);
      }
    }
    $self->add($hex);
  }
}

sub add {
  my ($self, $hex) = @_;
  push(@{$self->hexes}, $hex);
}

sub initialize_routes {
  my ($self, $lines) = @_;
  foreach (@$lines) {
    # parse non-standard routes
    my ($from, $to, $type, $colour) = /^(\d\d\d\d)-(\d\d\d\d)\s+(C|T)\b\s*($colour_re)?/i;
    next unless $type;
    if (lc($type) eq 'c') {
      $self->comm_set(1); # at least one hex here has comm
      push(@{$self->at($from)->comm}, $self->at($to)); # a property of the hex
    } else {
      $self->trade_set(1); # at least one hex here has trade
      my $from_hex = $self->at($from);
      my $to_hex = $self->at($to);

      push(@{$self->routes}, [$from_hex, $to_hex]); # a property of the mapper
    }
  }
}

sub at {
  my ($self, $coord) = @_;
  my ($x, $y) = $coord =~ /(\d\d)(\d\d)/;
  foreach my $hex (@{$self->hexes}) {
    return $hex if $hex->x == $x and $hex->y == $y;
  }
}

sub communications {
  # connect all the class A starports, naval bases, and Imperial
  # consulates
  my ($self) = @_;
  return if $self->comm_set;
  my @candidates = ();
  foreach my $hex (@{$self->hexes}) {
    push(@candidates, $hex)
      if $hex->starport eq 'A'
	or $hex->naval
	or $hex->consulate;
  }
  # every system has a link to its neighbours
  foreach my $hex (@candidates) {
    my @ar = nearby($hex, 2, \@candidates);
    $hex->comm(\@ar);
  }
  # eliminate all but the best connections if the system has
  # amber or red travel zone
  foreach my $hex (@candidates) {
    next unless $hex->travelzone;
    my $best;
    foreach my $other (@{$hex->comm}) {
      if (not $best
	  or $other->starport lt $best->starport
	  or $other->starport eq $best->starport
	  and distance($hex, $other) < distance($hex, $best)) {
	$best = $other;
      }
    }
    $hex->eliminate(grep { $_ != $best } @{$hex->comm});
  }
}

sub trade {
  # connect In or Ht with As, De, Ic, Ni
  # connect Hi or Ri with Ag, Ga, Wa
  my ($self) = @_;
  return if $self->trade_set;
  # candidates need to be on a travel route, i.e. must have fuel
  # available; skip worlds with a red travel zone
  my @candidates = ();
  foreach my $hex (@{$self->hexes}) {
    push(@candidates, $hex)
      if ($hex->starport =~ /^[A-D]$/
	  or $hex->gasgiant
	  or $hex->trade->{Wa})
	and $hex->travelzone ne 'R';
  }
  # every system has a link to its partners
  foreach my $hex (@candidates) {
    my @routes;
    if ($hex->trade->{In} or $hex->trade->{Ht}) {
      foreach my $other (nearby($hex, 4, \@candidates)) {
	if ($other->trade->{As}
	    or $other->trade->{De}
	    or $other->trade->{Ic}
	    or $other->trade->{Ni}) {
	  my @route = $self->route($hex, $other, 4, \@candidates);
	  push(@routes, \@route) if @route;
	}
      }
    } elsif ($hex->trade->{Hi} or $hex->trade->{Ri}) {
      foreach my $other (nearby($hex, 4, \@candidates)) {
	if ($other->trade->{Ag}
	    or $other->trade->{Ga}
	    or $other->trade->{Wa}) {
	  my @route = $self->route($hex, $other, 4, \@candidates);
	  push(@routes, \@route) if @route;
	}
      }
    }
    $hex->routes(\@routes);
  }
  $self->routes($self->minimal_spanning_tree($self->edges(@candidates)));
}

sub edges {
  my $self = shift;
  my @edges;
  my %seen;
  foreach my $hex (@_) {
    foreach my $route (@{$hex->routes}) {
      my ($start, @route) = @{$route};
      foreach my $end (@route) {
	# keep everything unidirectional
	next if exists $seen{$start}{$end} or exists $seen{$end}{$start};
	push(@edges, [$start, $end, distance($start,$end)]);
	$seen{$start}{$end} = 1;
	$start = $end;
      }
    }
  }
  return @edges;
}

sub minimal_spanning_tree {
  # http://en.wikipedia.org/wiki/Kruskal%27s_algorithm
  my $self = shift;
  # Initialize a priority queue Q to contain all edges in G, using the
  # weights as keys.
  my @Q = sort { @{$a}[2] <=> @{$b}[2] } @_;
  # Define a forest T ← Ø; T will ultimately contain the edges of the MST
  my @T;
  # Define an elementary cluster C(v) ← {v}.
  my %C;
  my $id;
  foreach my $edge (@Q) {
    # edge u,v is the minimum weighted route from u to v
    my ($u, $v) = @{$edge};
    # $u = $u->name;
    # $v = $v->name;
    # prevent cycles in T; add u,v only if T does not already contain
    # a path between u and v; also silence warnings
    if (not $C{$u} or not $C{$v} or $C{$u} != $C{$v}) {
      # Add edge (v,u) to T.
      push(@T, $edge);
      # Merge C(v) and C(u) into one cluster, that is, union C(v) and C(u).
      if ($C{$u} and $C{$v}) {
	my @group;
	foreach (keys %C) {
	  push(@group, $_) if $C{$_} == $C{$v};
	}
	$C{$_} = $C{$u} foreach @group;
      } elsif ($C{$v} and not $C{$u}) {
	$C{$u} = $C{$v};
      } elsif ($C{$u} and not $C{$v}) {
	$C{$v} = $C{$u};
      } elsif (not $C{$u} and not $C{$v}) {
	$C{$v} = $C{$u} = ++$id;
      }
    }
  }
  return \@T;
}

sub route {
  # Compute the shortest route between two hexes no longer than a
  # certain distance and choosing intermediary steps from the array of
  # possible candidates.
  my ($self, $from, $to, $distance, $candidatesref, @seen) = @_;
  # my $indent = ' ' x (4-$distance);
  my @options;
  foreach my $hex (nearby($from, $distance < 2 ? $distance : 2, $candidatesref)) {
    push (@options, $hex) unless in($hex, @seen);
  }
  return unless @options and $distance;
  if (in($to, @options)) {
    return @seen, $from, $to;
  }
  my @routes;
  foreach my $hex (@options) {
    my @route = $self->route($hex, $to, $distance - distance($from, $hex),
			     $candidatesref, @seen, $from);
    if (@route) {
      push(@routes, \@route);
    }
  }
  return unless @routes;
  # return the shortest one
  my @shortest;
  foreach my $route (@routes) {
    if ($#{$route} < $#shortest or not @shortest) {
      @shortest = @{$route};
    }
  }
  return @shortest;
}

sub trade_svg {
  my $self = shift;
  my $data = '';
  my $scale = 100;
  foreach my $edge (@{$self->routes}) {
    my $u = @{$edge}[0];
    my $v = @{$edge}[1];
    my ($x1, $y1) = ($u->x, $u->y);
    my ($x2, $y2) = ($v->x, $v->y);
    $data .= sprintf(qq{    <line class="trade" x1="%.3f" y1="%.3f" x2="%.3f" y2="%.3f" />\n},
		     (1 + ($x1-1) * 1.5) * $scale, ($y1 - $x1%2/2) * sqrt(3) * $scale,
		     (1 + ($x2-1) * 1.5) * $scale, ($y2 - $x2%2/2) * sqrt(3) * $scale);
  }
  return $data;
}

sub svg {
  my ($self, $width, $height) = @_;
  my $data = $self->header($width, $height);
  $data .= qq{  <g id='background'>\n};
  $data .= $self->background;
  $data .= qq{  </g>\n\n};
  $data .= qq{  <g id='comm'>\n};
  foreach my $hex (@{$self->hexes}) {
    $data .= $hex->comm_svg();
  }
  $data .= qq{  </g>\n\n};
  $data .= qq{  <g id='routes'>\n};
  $data .= $self->trade_svg();
  $data .= qq{  </g>\n\n};
  $data .= qq{  <g id='grid'>\n};
  $data .= $self->grid;
  $data .= qq{  </g>\n\n};
  $data .= qq{  <g id='legend'>\n};
  $data .= $self->legend();
  $data .= qq{  </g>\n\n};
  $data .= qq{  <g id='system'>\n};
  foreach my $hex (@{$self->hexes}) {
    $data .= $hex->system_svg();
  }
  $data .= qq{  </g>\n};
  $data .= $self->footer();
  return $data;
}

sub text {
  my ($self) = @_;
  my $data = "Trade Routes:\n";
  foreach my $edge (@{$self->routes}) {
    my $u = @{$edge}[0];
    my $v = @{$edge}[1];
    $data .= $u->name . " - " . $v->name . "\n";
  }
  $data .= "\n";
  $data .= "Raw Data:\n";
  foreach my $hex (@{$self->hexes}) {
    foreach my $routeref (@{$hex->routes}) {
      $data .= join(' - ', map {$_->name} @{$routeref}) . "\n";
    }
  }
  $data .= "\n";
  $data .= "Communications:\n";
  foreach my $hex (@{$self->hexes}) {
    foreach my $comm (@{$hex->comm}) {
      $data .= $hex->name . " - " . $comm->name . "\n";;
    }
  }
  return $data;
}

1;
