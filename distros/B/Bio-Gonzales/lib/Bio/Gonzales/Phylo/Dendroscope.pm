#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Phylo::Dendroscope;

use Mouse;

use warnings;
use strict;
use Carp;

use 5.010;
use Color::Spectrum qw/generate/;
use Data::Dumper;
use List::MoreUtils qw/any/;
use List::Util qw/sum/;
use Bio::Gonzales::Util::Graphics::Color::Generator;

our $VERSION = '0.0546'; # VERSION

has file => ( is => 'rw', required => 1 );

sub _mean {
  return sum(@_) / @_;
}

=head1 NAME

Bio::Gonzales::Phylo::Dendroscope - Color phylogenetic trees in Dendroscope format

=head1 SYNOPSIS

    use Bio::Gonzales::Phylo::Dendroscope;

    my $file = "/path/to/dendroscope.tree";
    my $v->Bio::Gonzales::Phylo::Dendroscope(file => $file);
    
    $v->color_by_groups( $newfile, [ [ node_label1, node_label3, node_label5], [node_label2, node_label22, node_label51] ]);

=head1 DESCRIPTION
    
    Colors node labels of phylogenetic trees in Dendroscope file format

=head1 METHODS

=head2 $v->color_by_groups($newfile, $groups)

Colors the labels given in $groups and saves the resulting tree in $newfile.
See L<SYNOPSIS> for structure of $groups.

=cut

sub color_by_groups {
  my ( $self, $to_file, $id_groups ) = @_;

  my @colors = $self->_create_distinct_colors( scalar @{$id_groups} );

  say STDERR "using colors: " . Dumper \@colors;

  my %id_color_map;
  for my $id_group ( @{$id_groups} ) {
    my $color = shift @colors;

    %id_color_map = ( %id_color_map, map { $_ => $color } @{$id_group} );
  }
  $self->_update_id_background( $to_file, \%id_color_map );
}

sub _update_id_background {
  my ( $self, $file, $id_color_map ) = @_;

  open my $phy_fh,     '<', $self->file or croak "Can't open filehandle: $!";
  open my $new_phy_fh, '>', $file       or croak "Can't open filehandle: $!";

  my $node_section;
  while (<$phy_fh>) {

    $node_section = 0 if (/^edges$/);

    my $color     = 'null';
    my $textcolor = '0 0 0';
    if (
      $node_section &&     # are we in a node section?
      /lb='([^']+)'/ &&    # find node id in dendroscope file
      any { /^\Q$1\E/ || $1 =~ /\Q$_\E/ } keys %{$id_color_map}
      # check for matches, firstly does a dendroscope id match the beginning of a
      # group id or secondly is a group id part of a dendroscope id?
      )
    {
      my @ids = grep { $1 =~ /\Q$_\E/ || /^\Q$1\E/ } keys %{$id_color_map};
      say STDERR "Found matching group: $ids[0] -- $1";
      die "ids ambigous $1:" . join( "//", @ids ) if ( @ids != 1 );
      $color = $id_color_map->{ $ids[0] };

      if ( _mean( split /\s+/, $color ) > 127 ) {
        $textcolor = '0 0 0';
      } else {
        $textcolor = '255 255 255';
      }

      say STDERR "$ids[0] -- $color -- $textcolor";
    }

    #substitute foreground/text color
    if (/lc=(\d+\s+){3}/) {
      s/lc=(\d+\s+){3}/lc=$textcolor /;
    } else {
      s/^(\d+:.*\s+)(lb=)/$1lc=$textcolor $2/;
    }

    #substitute background color
    if (/lk=(\d+\s+){3}/) {
      s/lk=(\d+\s+){3}/lk=$color /;
    } else {
      s/^(\d+:.*\s+)(lb=)/$1lk=$color $2/;
    }

    $node_section = 1 if (/^nodes$/);

    print $new_phy_fh $_;
  }
}

sub _create_distinct_colors {
  my ( $self, $num_colors ) = @_;

  my $t      = Bio::Gonzales::Util::Graphics::Color::Generator->new;
  my @colors = $t->generate_as_string($num_colors);
  return @colors;
}

1;

__END__

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
