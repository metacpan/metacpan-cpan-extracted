package DBIx::Class::Schema::Diff::Source;
use strict;
use warnings;

use Moo;
with 'DBIx::Class::Schema::Diff::Role::Common';

use Types::Standard qw(:all);
use Try::Tiny;
use List::MoreUtils qw(uniq);

use DBIx::Class::Schema::Diff::InfoPacket;

has 'name',       required => 1, is => 'ro', isa => Str;
has 'old_source', required => 1, is => 'ro', isa => Maybe[HashRef];
has 'new_source', required => 1, is => 'ro', isa => Maybe[HashRef];

has '_schema_diff', required => 1, is => 'ro', isa => InstanceOf[
  'DBIx::Class::Schema::Diff::Schema'
];

has 'added', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  defined $self->new_source && ! defined $self->old_source
}, init_arg => undef, isa => Bool;

has 'deleted', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  defined $self->old_source && ! defined $self->new_source
}, init_arg => undef, isa => Bool;


has 'columns', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  
  my ($o,$n) = ($self->old_source,$self->new_source);
  
  # List of all columns in old, new, or both:
  my @columns = uniq(try{keys %{$o->{columns}}}, try{keys %{$n->{columns}}});
  
  return {
    map { $_ => DBIx::Class::Schema::Diff::InfoPacket->new(
      name        => $_,
      old_info    => $o ? $o->{columns}{$_} : undef,
      new_info    => $n ? $n->{columns}{$_} : undef,
      _source_diff => $self,
    ) } @columns 
  };

}, init_arg => undef, isa => HashRef;


has 'relationships', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  
  my ($o,$n) = ($self->old_source,$self->new_source);
  
  # List of all relationships in old, new, or both:
  my @rels = uniq(try{keys %{$o->{relationships}}}, try{keys %{$n->{relationships}}});
  
  return {
    map { $_ => DBIx::Class::Schema::Diff::InfoPacket->new(
      name        => $_,
      old_info    => $o ? $o->{relationships}{$_} : undef,
      new_info    => $n ? $n->{relationships}{$_} : undef,
      _source_diff => $self,
    ) } @rels
  };
  
}, init_arg => undef, isa => HashRef;


has 'constraints', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  
  my ($o,$n) = ($self->old_source,$self->new_source);
  
  # List of all unique_constraint_names in old, new, or both:
  my @consts = uniq(try{keys %{$o->{constraints}}}, try{keys %{$n->{constraints}}});
  
  return {
    map { $_ => DBIx::Class::Schema::Diff::InfoPacket->new(
      name        => $_,
      old_info    => $o ? $o->{constraints}{$_} : undef,
      new_info    => $n ? $n->{constraints}{$_} : undef,
      _source_diff => $self,
    ) } @consts
  };
  
}, init_arg => undef, isa => HashRef;


has 'isa_diff', is => 'ro', lazy => 1, default => sub {
  my $self = shift;

  my ($o,$n) = ($self->old_source,$self->new_source);

  my $o_isa = $o ? $o->{isa} : [];
  my $n_isa = $n ? $n->{isa} : [];
  
  my $AD = Array::Diff->diff($o_isa,$n_isa);
  my $diff = [
    (map {'-'.$_} @{$AD->deleted}),
    (map {'+'.$_} @{$AD->added})
  ];

  return scalar(@$diff) > 0 ? $diff : undef;

}, init_arg => undef, isa => Maybe[ArrayRef];



has 'diff', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  # There is no reason to diff in the case of added/deleted:
  return { _event => 'added'   } if ($self->added);
  return { _event => 'deleted' } if ($self->deleted);
  
  my $diff = {};
  
  $diff->{columns} = { map {
    $_->diff ? ($_->name => $_->diff) : ()
  } values %{$self->columns} };
  delete $diff->{columns} unless (keys %{$diff->{columns}} > 0);
  
  $diff->{relationships} = { map {
    $_->diff ? ($_->name => $_->diff) : ()
  } values %{$self->relationships} };
  delete $diff->{relationships} unless (keys %{$diff->{relationships}} > 0);
  
  $diff->{constraints} = { map {
    $_->diff ? ($_->name => $_->diff) : ()
  } values %{$self->constraints} };
  delete $diff->{constraints} unless (keys %{$diff->{constraints}} > 0);
  
  my $o_tbl = try{$self->old_source->{table_name}} || '';
  my $n_tbl = try{$self->new_source->{table_name}} || '';
  $diff->{table_name} = $n_tbl unless ($o_tbl eq $n_tbl);
  
  $diff->{isa} = $self->isa_diff if ($self->isa_diff);
  
  # TODO: other data points TDB 
  # ...
  
  # No changes:
  return undef unless (keys %$diff > 0);
  
  $diff->{_event} = 'changed';
  return $diff;
  
}, init_arg => undef, isa => Maybe[HashRef];


1;


__END__

=pod

=head1 NAME

DBIx::Class::Schema::Diff::Source - internal object class for DBIx::Class::Schema::Diff

=head1 DESCRIPTION

This class is used internally by L<DBIx::Class::Schema::Diff> and is not meant to be called directly. 

Please refer to the main L<DBIx::Class::Schema::Diff> documentation for more info.

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
