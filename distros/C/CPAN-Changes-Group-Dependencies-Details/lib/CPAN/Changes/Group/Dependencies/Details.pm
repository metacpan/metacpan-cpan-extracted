use 5.006;
use strict;
use warnings;

package CPAN::Changes::Group::Dependencies::Details;

our $VERSION = '0.001006';

# ABSTRACT: Full details of dependency changes.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has extends );

use MooX::Lsub qw( lsub );
use Carp qw( croak );
use CPAN::Changes 0.30;
use CPAN::Changes::Group;
use CPAN::Meta::Prereqs::Diff;
## no critic (ProhibitConstantPragma)
use constant STRICTMODE => 1;
use charnames ':full';

my $formatters = {
  'toggle' => sub {
    return sub {
      my $diff   = shift;
      my $output = $diff->module;
      if ( $diff->requirement ne '0' ) {
        $output .= q[ ] . $diff->requirement;
      }
      return $output;
    };
  },
  'change' => sub {
    my $self       = shift;
    my $arrow_join = $self->arrow_join;
    return sub {
      my $diff = shift;
      return $diff->module . q[ ] . $diff->old_requirement . $arrow_join . $diff->new_requirement;
    };
  },
};

my $valid_change_types = {
  'Added' => {
    method   => 'is_addition',
    notation => 'toggle',
  },
  'Changed' => {
    method   => 'is_change',
    notation => 'change',
  },
  'Upgrade' => {
    method => sub { $_[0]->is_change && $_[0]->is_upgrade },
    notation => 'change',
  },
  'Downgrade' => {
    method => sub { $_[0]->is_change && $_[0]->is_downgrade },
    notation => 'change',
  },
  'Removed' => {
    method   => 'is_removal',
    notation => 'toggle',
  },
};

my $isa_checks = { map { $_ => {} } qw( change_type phase type ) };

if (STRICTMODE) {

  $isa_checks->{change_type} = {
    isa => sub {
      local $" = q[, ];
      croak "change_type must be one of <@{ keys %{$valid_change_types } }>, not $_[0]"
        unless exists $valid_change_types->{ $_[0] };
    },
  };

  my $valid_phases = { map { $_ => 1 } qw( configure build runtime test develop ) };

  $isa_checks->{phase} = {
    isa => sub {
      local $" = q[, ];
      croak "phase must be one of <@{ keys %{$valid_phases } }>, not $_[0]" unless exists $valid_phases->{ $_[0] };
    },
  };

  my $valid_types = { map { $_ => 1 } qw( requires recommends suggests conflicts ) };

  $isa_checks->{type} = {
    isa => sub {
      local $" = q[, ];
      croak "type must be one of <@{ keys %{$valid_types } }>, not $_[0]" unless exists $valid_types->{ $_[0] };
    },
  };
}

extends 'CPAN::Changes::Group';














has change_type => ( is => 'ro', required => 1, %{ $isa_checks->{change_type} } );














has phase => ( is => 'ro', required => 1, %{ $isa_checks->{phase} } );













has type => ( is => 'ro', required => 1, %{ $isa_checks->{type} } );








lsub new_prereqs => sub { croak q{required parameter <new_prereqs> missing} };








lsub old_prereqs => sub { croak q{required parameter <old_prereqs> missing} };












lsub arrow_join => sub { qq[\N{NO-BREAK SPACE}\N{RIGHTWARDS ARROW}\N{NO-BREAK SPACE}] };











lsub name_split => sub { q[ / ] };











lsub name_type_split => sub { q[ ] };
















lsub name => sub {
  my ($self) = @_;
  return $self->change_type . $self->name_split . $self->phase . $self->name_type_split . $self->type;
};

# Mostly internal plumbing attributes but should be ok for experts to work with
lsub change_type_method   => sub { $valid_change_types->{ $_[0]->change_type }->{method} };
lsub change_type_notation => sub { $valid_change_types->{ $_[0]->change_type }->{notation} };

lsub change_formatter => sub {
  my ($self) = @_;
  return $formatters->{ $self->change_type_notation }->($self);
};

lsub prereqs_diff => sub {
  my ($self) = @_;
  return CPAN::Meta::Prereqs::Diff->new( old_prereqs => $self->old_prereqs, new_prereqs => $self->new_prereqs, );
};

lsub all_diffs => sub {
  my ($self) = @_;
  ## Note: this filters here because the differ is faster that way
  ## But end users may still pass unfiltered copies of all_diffs
  return [ $self->prereqs_diff->diff( phases => [ $self->phase ], types => [ $self->type ], ) ];
};

lsub relevant_diffs => sub {
  my ($self) = @_;
  my $method = $self->change_type_method;
  my $phase  = $self->phase;
  my $type   = $self->type;

  # This phase filters the values from all_diffs
  # which should mostly filters by change type, but also filters on criteria
  # in case of all_diffs being raw.
  return [ grep { $_->$method() and $_->phase eq $phase and $_->type eq $type } @{ $self->all_diffs } ];
};








sub has_changes {
  my ($self) = @_;
  return unless @{ $self->all_diffs };
  return unless @{ $self->relevant_diffs };
  return 1;
}
















sub changes {
  my ($self) = @_;
  return [] unless $self->has_changes;
  my $formatter = $self->change_formatter;
  return [ map { $formatter->($_) } @{ $self->relevant_diffs } ];
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Group::Dependencies::Details - Full details of dependency changes.

=head1 VERSION

version 0.001006

=head1 SYNOPSIS

  my $old_prereqs => CPAN::Meta->load_file('Dist-Foo-1.01/META.json')->effective_prereqs,
  my $new_prereqs => CPAN::Meta->load_file('Dist-Foo-1.01/META.json')->effective_prereqs,

  my $group =  CPAN::Changes::Group::Dependencies::Details->new(
    old_prereqs => $old_prereqs,
    new_prereqs => $new_prereqs,
    change_type => 'Added',
    phase       => 'runtime',
    type        => 'requires',
  );

  my $release = CPAN::Changes::Release->new(
    version => '0.01',
    date    => '2014-07-26',
  );

  $release->attach_group( $group ) if $group->has_changes;

=head1 DESCRIPTION

This is simple an element of refactoring in my C<dep_changes> script.

It is admittedly not very useful in its current incarnation due to needing quite a few instances
to get anything done with them, but that's mostly due to design headaches about thinking of I<any> way to solve a few problems.

=head1 METHODS

=head2 C<has_changes>

Returns true/false indicating whether or not C<relevant> changes were found between
the two given C<_prereqs> properties.

=head2 C<changes>

Returns a list of change entries:

  Added / Removed

      Module::Name      # For unversioned module additions/removals
      Module::Name 0.30 # For versioned

  Changed / Upgrade / Downgrade

      Module::Name <OLDREQ> → <NEWREQ>

=head1 ATTRIBUTES

=head2 C<change_type>

B<REQUIRED:>
One of the following indicating the type of change this group represents.

  Added     : Dependencies are new to this phase
  Changed   : The version component of this dependency changed in some way
  Upgrade   : A newer version of this dependency is required.
  Downgrade : The requirement of this dependency is no longer so stringent.
  Removed   : A dependency previously in this phase was removed.

=head2 C<phase>

B<REQUIRED:>
One of the following phases indicating the phase this group will pertain to

  configure
  build
  runtime
  test
  develop

=head2 C<type>

B<REQUIRED:>
One of the following types indicating the severity of the dependency this group will pertain to

  requires
  recommends
  suggests
  conflicts

=head2 C<new_prereqs>

B<LIKELY REQUIRED>:
C<HashRef>,C<CPAN::Meta> or C<CPAN::Meta::Prereqs> structure for I<'new'> dependencies.

=head2 C<old_prereqs>

B<LIKELY REQUIRED>:
C<HashRef>,C<CPAN::Meta> or C<CPAN::Meta::Prereqs> structure for I<'new'> dependencies.

=head2 C<arrow_join>

The delimiter to separate change family entries.

Default:

  #\N{NO-BREAK SPACE}\N{RIGHTWARDS ARROW}\N{NO-BREAK SPACE}
  q[ → ]

=head2 C<name_split>

Used to define C<name>.

Default:

  q[ / ]

=head2 C<name_type_split>

Used to separate C<phase> and C<type> in C<name>

Default:

  q[ ]

=head2 C<name>

The name of the group.

If not specified, is generated from other attributes

  Added / runtime requires

  |___|------------------- change_type
       |_|---------------- name_split
          |_____|--------- phase
                 ||------- name_type_split
                  |______| type

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
