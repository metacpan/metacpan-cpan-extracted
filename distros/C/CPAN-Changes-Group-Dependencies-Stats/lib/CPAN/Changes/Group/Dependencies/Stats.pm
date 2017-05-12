use 5.006;
use strict;
use warnings;

package CPAN::Changes::Group::Dependencies::Stats;

our $VERSION = '0.002008';

# ABSTRACT: Create a Dependencies::Stats section detailing summarized differences

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( extends has );
use Carp qw( croak );
use CPAN::Changes 0.30;
use CPAN::Changes::Group;
use CPAN::Meta::Prereqs::Diff;
use MooX::Lsub qw( lsub );
use charnames qw( :full );

extends 'CPAN::Changes::Group';







lsub name             => sub { 'Dependencies::Stats' };
lsub prelude          => sub { [] };
lsub new_prereqs      => sub { croak 'Required attribute <new_prereqs> was not provided' };
lsub old_prereqs      => sub { croak 'Required attribute <old_prereqs> was not provided' };
lsub symbol_Added     => sub { q[+] };
lsub symbol_Upgrade   => sub { qq[\N{UPWARDS ARROW}] };
lsub symbol_Downgrade => sub { qq[\N{DOWNWARDS ARROW}] };
lsub symbol_Removed   => sub { q[-] };
lsub symbol_Changed   => sub { q[~] };

lsub prereqs_diff => sub {
  my ($self) = @_;
  return CPAN::Meta::Prereqs::Diff->new(
    new_prereqs => $self->new_prereqs,
    old_prereqs => $self->old_prereqs,
  );
};

lsub _diff_items => sub {
  my ($self)  = @_;
  my (@diffs) = $self->prereqs_diff->diff(
    phases => [qw( configure build runtime test develop )],
    types  => [qw( requires recommends suggests conflicts )],
  );
  return \@diffs;
};

no Moo;













sub has_changes {
  my ($self) = @_;
  return @{ $self->_diff_items } > 0;
}

sub _phase_rel_changes {
  my ( $self, $phase, $rel, $phases ) = @_;
  return unless exists $phases->{$phase};
  return unless exists $phases->{$phase}->{$rel};

  my $stash = $phases->{$phase}->{$rel};

  my @parts;
  for my $type (qw( Added Upgrade Downgrade Removed Changed )) {
    next if 1 > $stash->{$type};
    next unless my $method = $self->can( 'symbol_' . $type );
    push @parts, $self->$method() . $stash->{$type};
  }
  return unless @parts;
  return join q[ ], @parts;
}

sub _phase_changes {
  my ( $self, $phase, $phases ) = @_;

  my @out;
  my @extra;

  if ( my $recommends = $self->_phase_rel_changes( $phase, 'recommends', $phases ) ) {
    push @extra, 'recommends: ' . $recommends;
  }
  if ( my $suggested = $self->_phase_rel_changes( $phase, 'suggests', $phases ) ) {
    push @extra, 'suggests: ' . $suggested;
  }

  if ( my $required = $self->_phase_rel_changes( $phase, 'requires', $phases ) ) {
    push @out, $required;
  }
  if (@extra) {
    push @out, sprintf '(%s)', join q[, ], @extra;
  }
  if (@out) {
    return sprintf '%s: %s', $phase, join q[ ], @out;
  }
  return;
}

sub _phase_rel_stats {
  my ($self) = @_;
  my $phases = {};

  for my $diff ( @{ $self->_diff_items } ) {
    my $phase_m = $diff->phase;

    my $rel = $diff->type;

    if ( not exists $phases->{$phase_m} ) {
      $phases->{$phase_m} = {};
    }
    if ( not exists $phases->{$phase_m}->{$rel} ) {
      $phases->{$phase_m}->{$rel} = { Added => 0, Upgrade => 0, Downgrade => 0, Removed => 0, Changed => 0 };
    }
    my $stash = $phases->{$phase_m}->{$rel};

    $stash->{Added}++   if $diff->is_addition;
    $stash->{Removed}++ if $diff->is_removal;
    if ( $diff->is_change ) {
      $stash->{Upgrade}++   if $diff->is_upgrade;
      $stash->{Downgrade}++ if $diff->is_downgrade;
      if ( not $diff->is_upgrade and not $diff->is_downgrade ) {
        $stash->{Changed}++;
      }
    }
  }
  return $phases;
}








































sub changes {
  my ($self) = @_;
  my @changes = @{ $self->prelude };

  my $phases = $self->_phase_rel_stats;

  for my $phase ( sort keys %{$phases} ) {
    push @changes, $self->_phase_changes( $phase, $phases );
  }
  return \@changes;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

CPAN::Changes::Group::Dependencies::Stats - Create a Dependencies::Stats section detailing summarized differences

=head1 VERSION

version 0.002008

=head1 SYNOPSIS

  use CPAN::Changes::Release 0.29;
  use CPAN::Changes::Group::Dependencies::Stats;

  my $s = CPAN::Changes::Group::Dependencies::Stats->new(
    prelude     => [ 'Change statistics since 1.00' ],
    new_prereqs => CPAN::Meta->load_file('Dist-Foo-1.01/META.json')->effective_prereqs,
    old_prereqs => CPAN::Meta->load_file('Dist-Foo-1.00/META.json')->effective_prereqs,
  );

  # Currently slightly complicated due to groups themselves
  # not presently being pluggable.
  my $rel = CPAN::Changes::Release->new( version => '1.01' );
  $rel->attach( $s ) if $s->has_changes;
  $rel->serialize();

  # RESULT
  #
  # [ Dependencies::Stats ]
  #   - Change statistics since 1.00
  #   - build: -1 (recommends: -1)
  #   - configure: +1 -1 (recommends: +1 -1)
  #   - develop: +5 -5 (suggests: +2 -1)
  #   - test: (recommends: +1 ↑1)

=head1 DESCRIPTION

This module is a utility tool that produces short, summarized details about changes in dependencies between two sets
of prerequisites such that one can visually identify at a glance the general nature of the dependency changes without
being swamped by the specifics, only looking into the specifics when the summary indicates it is warranted.

This aims to be a utility to assist downstream in quickly assessing effort when performing manual updates.

=head1 METHODS

=head2 C<has_changes>

Returns whether this group has any interesting changes or not.

  if ( $group->has_changes ) {
    $release->attach_group( $group );
  } else {
    $release->delete_group( $group->name );
  }

=head2 C<changes>

Returns a list of change entries.

  my $changes = $object->changes;
  say $_ for @{$changes};

Format:

  %phase: %requiredstats (%optlabel: %optstats, ...)

C<%phase> is one of C<configure>, C<build>, C<runtime>, C<develop>, C<test>

C<%optlabel> is one of C<recommends>, C<suggests>

C<%requiredstats> and C<%optstats> are strings of stat changes:

  %symbol%number %symbol%number ...

C<%symbol> is:

  +   a dependency previously unseen in this phase/rel was added.
  ↑   a dependency in this phase/rel had its version requirement increased.
  ↓   a dependency in this phase/rel had its version requirement decreased.
  -   this phase/rel had a dependency removed
  ~   a dependency type where either side was a complex version requirement changed in some way.

For instance, this L<diff|https://metacpan.org/diff/file?target=ETHER/Moose-2.1210/META.json&source=ETHER/Moose-2.1005/META.json> would display as:

  [ Dependencies::Stats ]
    - configure: +2
    - develop: +12 ↑3 -2 (suggests: +58)
    - runtime: +3
    - test: +1 ↓1 -1 (recommends: +2)

Which is far less scary ☺

=for Pod::Coverage FOREIGNBUILDARGS

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
