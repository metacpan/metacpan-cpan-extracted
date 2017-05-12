package Algorithm::ConstructDFA::XS;

use 5.012000;
use strict;
use warnings;
use Data::AutoBimap;
use Storable;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  construct_dfa_xs
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  construct_dfa_xs
);

our $VERSION = '0.23';

require XSLoader;
XSLoader::load('Algorithm::ConstructDFA::XS', $VERSION);

sub construct_dfa_xs {
  my (%o) = @_;
  
  die unless ref $o{is_nullable};
  die unless ref $o{is_accepting} or exists $o{final};
  die unless ref $o{successors} or ref $o{edges_from};
  die unless ref $o{get_label} or ref $o{edges_from};
  die unless exists $o{start} or exists $o{many_start};
  die if ref $o{is_accepting} and exists $o{final};
  die if ref $o{successors} and exists $o{edges_from};
  die if ref $o{get_label} and ref $o{edges_from};
  
  my $class = 'Algorithm::ConstructDFA::XS::Synth';
  
  if (exists $o{edges_from}) {

    my $old_accepting = $o{is_accepting};
    $o{is_accepting} = sub {
      my @config = grep { ref $_ ne $class } @_;
      return $old_accepting->(@config);
    };
    
    $o{get_label} = sub {
      my ($src) = @_;
      return unless ref $src eq $class;
      return (Storable::thaw($$src))->[1];
    };

    my $old_nullable = $o{is_nullable};
    $o{is_nullable} = sub {
      my ($src) = @_;
      
      if (ref $src eq $class) {
        my $deref = $$src;
        my $thawed = Storable::thaw $deref;
        return not defined $thawed->[1];
      }
      
      $old_nullable->($src);
    };

    my $old_edges_from = $o{edges_from};

    $o{successors} = sub {
      my ($src) = @_;
      
      if (ref $src eq $class) {
        return (Storable::thaw $$src)->[2];
      }
      
      my @successors;
      
      for my $edge ($old_edges_from->($src)) {
        my ($dst, $label) = @$edge;
        
        # TODO: theoretically there could be name clashes between the
        # artificial vertex created here and vertices in the original
        # unwrapped input which can interfere with the bimaps mapping
        # stringified vertices to numbers.
        push @successors, bless \(Storable::freeze([$src, $label, $dst])),
          $class;
      }
      
      return @successors;
    };

  }

  if (exists $o{final}) {
    my %in_final = map { $_ => 1 } @{ $o{final} };
    $o{is_accepting} = sub {
      grep { $in_final{$_} } @_
    };
  }

  $o{many_start} //= [$o{start}];
  
  my $dfa = _construct_dfa_xs($o{many_start}, $o{get_label},
    $o{is_nullable}, $o{successors}, $o{is_accepting});
    
  if (exists $o{edges_from}) {
    for (values %$dfa) {
      $_->{Combines} = [ grep {
        ref $_ ne $class;
      } @{ $_->{Combines} } ];
    }
  }
  
  return $dfa;
}

sub _construct_dfa_xs {
  my ($roots, $labelf, $nullablef, $successorsf, $acceptingf) = @_;

  my @todo = map { @$_ } @$roots;
  my %seen;
  my @args;
  my $sm = Data::AutoBimap->new;
  my $rm = Data::AutoBimap->new;
  my %is_start;
  
  for (my $ix = 0; $ix < @$roots; ++$ix) {
    for my $v (@{ $roots->[$ix] }) {
      push @{ $is_start{$v} }, $ix + 1;
    }
  }
  
  while (@todo) {
    my $c = pop @todo;
    
    next if $seen{$c}++;
    
    my $is_nullable = !!$nullablef->($c);
    my $label = $labelf->($c);
    my $label_x = defined $label ? $rm->s2n($label) : undef;
    
    # [vertex, label, nullable, start, successors...]
    my @data = ($sm->s2n($c), $label_x, !!$is_nullable, $is_start{$c} // []);

    for ($successorsf->($c)) {
      push @data, $sm->s2n($_);
      push @todo, $_;
    }
    
    push @args, \@data;
  }

  my %h = _internal_construct_dfa_xs(sub {
    !!$acceptingf->(map { $sm->n2s($_) } @_)
  }, \@args);
  
  for (values %h) {
    $_->{Combines} = [ map { $sm->n2s($_) } @{ $_->{Combines} } ];
  }
  
  for my $v (values %h) {
    my $over = {};
    $over->{ $rm->n2s($_) } = $v->{NextOver}{$_} for keys %{ $v->{NextOver} };
    $v->{NextOver} = $over;
  }

  return \%h;
}

1;

__END__

=head1 NAME

Algorithm::ConstructDFA::XS - C++ version of Algorithm::ConstructDFA

=head1 SYNOPSIS

  use Algorithm::ConstructDFA::XS;
  my $dfa = construct_dfa_xs(...);
  ...

=head1 DESCRIPTION

Replacement for L<Algorithm::ConstructDFA> written in C++.

=head2 FUNCTIONS

=over

=item construct_dfa_xs(...)

Same as C<construct_dfa> in L<Algorithm::ConstructDFA>. The public
API should be the same between the two modules if the version numbers
match.

=back

=head2 EXPORTS

The function C<construct_dfa_xs> by default.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2014 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
