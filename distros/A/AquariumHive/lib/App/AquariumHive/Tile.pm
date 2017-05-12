package App::AquariumHive::Tile;
BEGIN {
  $App::AquariumHive::Tile::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: 
$App::AquariumHive::Tile::VERSION = '0.003';
use Moo;
use Carp qw( croak );
use HTML::Entities;

# leave white first!
my @light_colors = qw(
  white
  lime
  green
  teal
  cyan
  cobalt
  indigo
  violet
  pink
  magenta
  red
  orange
  amber
  yellow
  lightBlue
  lightTeal
  lightOlive
  lightOrange
  lightPink
  lightRed
  lightGreen
);

# leave black first!
my @dark_colors = qw(
  black
  emerald
  crimson
  brown
  olive
  steel
  mauve
  taupe
  gray
  dark
  darker
  darkBrown
  darkCrimson
  darkMagenta
  darkIndigo
  darkCyan
  darkCobalt
  darkTeal
  darkEmerald
  darkGreen
  darkOrange
  darkRed
  darkPink
  darkViolet
  darkBlue
);

my $last_random = 0;

sub random_bgcolor {
  $last_random++;
  $last_random = 1 if ($last_random > scalar @light_colors);
  return $light_colors[$last_random];
}

# http://metroui.org.ua/global.html
has bgcolor => (
  is => 'lazy',
);

sub _build_bgcolor { random_bgcolor() }

has colspan => (
  is => 'lazy',
);

sub _build_colspan { 1 }

has rowspan => (
  is => 'lazy',
);

sub _build_rowspan { 1 }

has id => (
  is => 'ro',
  predicate => 1,
);

has class => (
  is => 'ro',
  predicate => 1,
);

has js => (
  is => 'ro',
  predicate => 1,
);

has content => (
  is => 'ro',
  required => 1,
);

has html => (
  is => 'lazy',
);

sub _build_centered { 1 }

sub _build_html {
  my ( $self ) = @_;
  my %attr = $self->can('html_attributes')
    ? (%{$self->html_attributes}) : ();
  $attr{'data-ss-colspan'} = $self->colspan unless $self->colspan == 1;
  $attr{'data-ss-rowspan'} = $self->rowspan unless $self->rowspan == 1;
  my @classes = qw( app-tile );
  push @classes, 'bg-'.$self->bgcolor;
  push @classes, $self->class if $self->has_class;
  $attr{'class'} = join(' ',@classes);
  $attr{'id'} = $self->id if $self->has_id;
  return '<div '.join(' ',map {
    $_.'="'.encode_entities($attr{$_}).'"'
  } keys %attr).'>'.$self->content.'</div>';
}

1;

__END__

=pod

=head1 NAME

App::AquariumHive::Tile -  

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
