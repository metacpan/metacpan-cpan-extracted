use 5.006; # our
use strict;
use warnings;

package CPAN::Meta::Prereqs::Diff;

our $VERSION = '0.001004';

# ABSTRACT: Compare dependencies between releases using CPAN::Meta.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo 1.000008 qw( has );
use Scalar::Util qw( blessed );
use CPAN::Meta::Prereqs::Diff::Addition;
use CPAN::Meta::Prereqs::Diff::Removal;
use CPAN::Meta::Prereqs::Diff::Change;
use CPAN::Meta::Prereqs::Diff::Upgrade;
use CPAN::Meta::Prereqs::Diff::Downgrade;








has 'new_prereqs' => ( is => ro =>, required => 1 );








has 'old_prereqs' => ( is => ro =>, required => 1 );

has '_real_old_prereqs' => (
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return $_[0]->_get_prereqs( $_[0]->old_prereqs ) },
);
has '_real_new_prereqs' => (
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return $_[0]->_get_prereqs( $_[0]->new_prereqs ) },
);

sub _dep_add {
  my ( undef, $phase, $type, $module, $requirement ) = @_;
  return CPAN::Meta::Prereqs::Diff::Addition->new(
    phase       => $phase,
    type        => $type,
    module      => $module,
    requirement => $requirement,
  );
}

sub _dep_remove {
  my ( undef, $phase, $type, $module, $requirement ) = @_;
  return CPAN::Meta::Prereqs::Diff::Removal->new(
    phase       => $phase,
    type        => $type,
    module      => $module,
    requirement => $requirement,
  );
}

## no critic (Subroutines::ProhibitManyArgs)
sub _dep_change {
  my ( undef, $phase, $type, $module, $old_requirement, $new_requirement ) = @_;
  if ( $old_requirement =~ /[<>=, ]/msx or $new_requirement =~ /[<>=, ]/msx ) {
    return CPAN::Meta::Prereqs::Diff::Change->new(
      phase           => $phase,
      type            => $type,
      module          => $module,
      old_requirement => $old_requirement,
      new_requirement => $new_requirement,
    );
  }
  require version;
  if ( version->parse($old_requirement) > version->parse($new_requirement) ) {
    return CPAN::Meta::Prereqs::Diff::Downgrade->new(
      phase           => $phase,
      type            => $type,
      module          => $module,
      old_requirement => $old_requirement,
      new_requirement => $new_requirement,
    );
  }
  if ( version->parse($old_requirement) < version->parse($new_requirement) ) {
    return CPAN::Meta::Prereqs::Diff::Upgrade->new(
      phase           => $phase,
      type            => $type,
      module          => $module,
      old_requirement => $old_requirement,
      new_requirement => $new_requirement,
    );
  }
  return;
}

sub _get_prereqs {
  my ( undef, $input_prereqs ) = @_;
  if ( ref $input_prereqs and blessed $input_prereqs ) {
    return $input_prereqs if $input_prereqs->isa('CPAN::Meta::Prereqs');
    return $input_prereqs->effective_prereqs if $input_prereqs->isa('CPAN::Meta');
  }
  if ( ref $input_prereqs and 'HASH' eq ref $input_prereqs ) {
    require CPAN::Meta::Prereqs;
    return CPAN::Meta::Prereqs->new($input_prereqs);
  }
  require Carp;
  my $message = <<'EOF';
prereqs parameters take either CPAN::Meta::Prereqs, CPAN::Meta,
or a valid CPAN::Meta::Prereqs hash structure.
EOF
  Carp::croak($message);
}

sub _phase_rel_diff {
  my ( $self, $phase, $type ) = @_;

  my %old_modules = %{ $self->_real_old_prereqs->requirements_for( $phase, $type )->as_string_hash };
  my %new_modules = %{ $self->_real_new_prereqs->requirements_for( $phase, $type )->as_string_hash };

  my @all_modules = do {
    my %all_modules = map { $_ => 1 } keys %old_modules, keys %new_modules;
    sort { $a cmp $b } keys %all_modules;
  };

  my @out_diff;

  for my $module (@all_modules) {
    if ( exists $old_modules{$module} and exists $new_modules{$module} ) {

      # no change
      next if $old_modules{$module} eq $new_modules{$module};

      # change
      push @out_diff, $self->_dep_change( $phase, $type, $module, $old_modules{$module}, $new_modules{$module} );
      next;
    }
    if ( exists $old_modules{$module} and not exists $new_modules{$module} ) {

      # remove
      push @out_diff, $self->_dep_remove( $phase, $type, $module, $old_modules{$module} );
      next;
    }

    # add
    push @out_diff, $self->_dep_add( $phase, $type, $module, $new_modules{$module} );
    next;

  }
  return @out_diff;
}













































sub diff {
  my ( $self, %options ) = @_;
  my @phases = @{ exists $options{phases} ? $options{phases} : [qw( configure build runtime test )] };
  my @types  = @{ exists $options{types}  ? $options{types}  : [qw( requires recommends suggests conflicts )] };

  my @out_diff;

  for my $phase (@phases) {
    for my $type (@types) {
      push @out_diff, $self->_phase_rel_diff( $phase, $type );
    }
  }
  return @out_diff;

}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Meta::Prereqs::Diff - Compare dependencies between releases using CPAN::Meta.

=head1 VERSION

version 0.001004

=head1 SYNOPSIS

  use CPAN::Meta::Prereqs::Diff;


  my $diff = CPAN::Meta::Prereqs::Diff->new(
    new_prereqs => CPAN::Meta->load_file('Dist-Foo-1.01/META.json')->effective_prereqs
    old_prereqs => CPAN::Meta->load_file('Dist-Foo-1.00/META.json')->effective_prereqs
  );
  my @changes = $diff->diff(
    phases => [qw( runtime build configure test )],
    types  => [qw( requires suggests configures conflicts )],
  );

  ## Here, the examples with printf are not needed because ->describe exists
  ## But they're there any way for example reasons.

  for my $dep (@prereqs) {
    if ( $dep->is_addition ) {
      # runtime.requires: + Foo::Bar 0.4
      printf "%s.%s : + %s %s",
        $dep->phase, $dep->type, $dep->module, $dep->requirement;
      next;
    }
    if ( $dep->is_removal ) {
      # runtime.requires: - Foo::Bar 0.4
      printf "%s.%s : - %s %s",
        $dep->phase, $dep->type, $dep->module, $dep->requirement;
      next;
    }
    if ( $dep->is_change ) {
      if ( $dep->is_upgrade ) {
        # runtime.requires: ↑ Foo::Bar 0.4 → 0.5
        printf "%s.%s : \x{2191} %s \x{2192} %s",
          $dep->phase, $dep->type, $dep->module, $dep->old_requirement, $dep->new_requirement;
        next;
      }
      if ( $dep->is_downgrade ) {
        # runtime.requires: ↓ Foo::Bar 0.5 → 0.4
        printf "%s.%s : \x{2193} %s %s \x{2192} %s",
          $dep->phase, $dep->type, $dep->module, $dep->old_requirement, $dep->new_requirement;
        next;
      }
      # changes that can't be easily determined upgrades or downgrades
      # runtime.requires: ~ Foo::Bar >=0.5, <=0.7 → >=0.4, <=0.8
      printf "%s.%s : ~ %s %s \x{2192} %s",
        $dep->phase, $dep->type, $dep->module, $dep->old_requirement, $dep->new_requirement;
      next;
    }
  }

=head1 DESCRIPTION

This module allows relatively straight forward routines for comparing and itemizing
two sets of C<CPAN::Meta> prerequisites, plucking out kinds of changes that are interesting.

=head1 METHODS

=head2 C<diff>

  my @out = $diff->diff( %options );

Returns a list of C<Objects> that C<do> L<< C<CPAN::Meta::Prereqs::Diff::Role::Change>|CPAN::Meta::Prereqs::Diff::Role::Change >>, describing the changes between C<old_prereqs> and C<new_prereqs>

=over 4

=item * L<< C<Addition>|CPAN::Meta::Prereqs::Diff::Addition >>

=item * L<< C<Change>|CPAN::Meta::Prereqs::Diff::Change >>

=item * L<< C<Upgrade>|CPAN::Meta::Prereqs::Diff::Upgrade >>

=item * L<< C<Downgrade>|CPAN::Meta::Prereqs::Diff::Downgrade >>

=item * L<< C<Removal>|CPAN::Meta::Prereqs::Diff::Removal >>

=back

=head3 C<diff.%options>

=head4 C<diff.options.phases>

  my @out = $diff->diff(
    phases => [ ... ]
  );

  ArrayRef
  default         = [qw( configure build runtime test )]
  valid options   = [qw( configure build runtime test develop )]

=head4 C<diff.options.types>

  my @out = $diff->diff(
    types => [ ... ]
  );

  ArrayRef
  default         = [qw( requires recommends suggests conflicts )]
  valid options   = [qw( requires recommends suggests conflicts )]

=head1 ATTRIBUTES

=head2 C<new_prereqs>

  required
  HashRef | CPAN::Meta::Prereqs | CPAN::Meta

=head2 C<old_prereqs>

  required
  HashRef | CPAN::Meta::Prereqs | CPAN::Meta

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
