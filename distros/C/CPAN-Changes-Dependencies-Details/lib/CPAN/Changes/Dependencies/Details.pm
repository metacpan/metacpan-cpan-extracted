use 5.006;    # our
use strict;
use warnings;

package CPAN::Changes::Dependencies::Details;

our $VERSION = '0.001007';

# ABSTRACT: Create CPAN::Changes style file only containing dependency change information

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( extends around );
use MooX::Lsub qw( lsub );
use Carp qw( croak );
use CPAN::Changes::Release;
use CPAN::Changes::Group::Dependencies::Details 0.001001;    # First useful version

extends 'CPAN::Changes';

lsub change_types => sub { [qw( Added Changed Removed )] };
lsub phases       => sub { [qw( configure build runtime test )] };
lsub types        => sub { [qw( requires )] };

sub load        { croak 'This module can only generate dependency details, not read them' }
sub load_string { croak 'This module can only generate dependency details, not read them' }

my $release_keys = [ 'changes',     'version',     'date',         'note', ];
my $group_keys   = [ 'new_prereqs', 'old_prereqs', 'prereqs_diff', 'all_diffs', ];

sub _mk_release {
  my ( $self, $release ) = @_;
  my $input_args   = { %{$release} };
  my $release_args = {};
  my $group_args   = {};

  for my $release_key ( @{$release_keys} ) {
    next unless exists $input_args->{$release_key};
    $release_args->{$release_key} = delete $input_args->{$release_key};
  }

  for my $group_key ( @{$group_keys} ) {
    next unless exists $input_args->{$group_key};
    $group_args->{$group_key} = delete $input_args->{$group_key};
  }

  my $release_object = CPAN::Changes::Release->new( %{$release_args} );

  for my $change_type ( @{ $self->change_types } ) {
    for my $phase ( @{ $self->phases } ) {
      for my $type ( @{ $self->types } ) {
        my $group = CPAN::Changes::Group::Dependencies::Details->new(
          change_type => $change_type,
          phase       => $phase,
          type        => $type,
          %{$group_args},
        );
        next unless $group->has_changes;
        $release_object->attach_group($group);
      }
    }
  }
  return $release_object;
}

around add_release => sub {
  my ( $orig, $self, @releases ) = @_;
  for my $release (@releases) {
    my $release_object = $self->_mk_release($release);
    $self->$orig($release_object);
  }
  return;
};

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Dependencies::Details - Create CPAN::Changes style file only containing dependency change information

=head1 VERSION

version 0.001007

=head1 SYNOPSIS

  use CPAN::Changes::Dependencies::Details;
  my $details = CPAN::Changes::Dependencies::Details->new(
    preamble     => "Some message",
    change_types => [qw( Added Changed Removed )],
    phases       => [qw( build configure runtime test )],
    types        => [qw( requires recommends )],
  );

  $changes->add_release({
    version     => '0.002',
    date        => '2009-07-06',
    old_prereqs => CPAN::Meta->load_file('Dist-Foo-0.001/META.json')->effective_prereqs,
    new_prereqs => CPAN::Meta->load_file('Dist-Foo-0.002/META.json')->effective_prereqs,
  });

  print $changes->serialize;

=head1 DESCRIPTION

This module serves as a utility for producing complex change-logs in C<CPAN::Changes> style,
specifically tailored to conveying the nature of dependency changes between releases.

It typically requires some mechanism external to this code to report the state of prerequisites
at given versions, where it computes their differences and produces sections detailing
the kinds of changes you have elected to itemize.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
